import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync, readFileSync, existsSync, rmSync, mkdirSync, unlinkSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { spawn, spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const runner = fileURLToPath(new URL('./runner.mjs', import.meta.url));
const pause = ms => new Promise(resolve => setTimeout(resolve, ms));
function fixture(t, overrides = {}) {
  const cwd = mkdtempSync(path.join(tmpdir(), 'durable-loop-test-'));
  t.after(() => rmSync(cwd, { recursive: true, force: true }));
  const run = path.join(cwd, 'run');
  const planFile = path.join(cwd, 'plan.json');
  const phase = { id: 'one', cwd, timeoutSeconds: 10, hypothesis: 'A command runs once', falsificationCriterion: 'Duplicate execution or invalid evidence', implement: 'echo execution >> count; echo data > artifact', validate: 'test -s artifact', negativeControl: 'test ! -e nonexistent', review: 'test "$(wc -l < count)" -eq 1', artifacts: ['artifact'], ...overrides };
  const plan = { goal: 'Test recovery and failure gates', maxWallSeconds: 30, maxPhases: 1, phases: [phase] };
  writeFileSync(planFile, JSON.stringify(plan));
  const invoke = (...args) => spawnSync(process.execPath, [runner, ...args], { encoding: 'utf8', timeout: 20000 });
  return { cwd, run, planFile, phase, plan, invoke, execute: () => invoke('run', run, planFile) };
}
function passed(result) { assert.equal(result.status, 0, result.stderr + result.stdout); }

test('gates pass, repeat run does not duplicate, artifacts are sealed', t => {
  const f = fixture(t);
  passed(f.execute());
  passed(f.execute());
  assert.equal(readFileSync(path.join(f.cwd, 'count'), 'utf8'), 'execution\n');
  writeFileSync(path.join(f.cwd, 'artifact'), 'mutated');
  const result = f.execute();
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /evidence changed/);
});

for (const stage of ['implement', 'validate', 'negativeControl', 'review']) {
  test(`${stage} failure stops the phase and cannot pass on rerun`, t => {
    const f = fixture(t, { [stage]: 'exit 7' });
    assert.notEqual(f.execute().status, 0);
    const receipt = JSON.parse(readFileSync(path.join(f.run, 'one', 'receipt.json')));
    assert.equal(receipt.verdict, 'FAIL');
    assert.equal(receipt.results.at(-1).code, 7);
    assert.notEqual(f.execute().status, 0);
  });
}

test('timeout fails and preserves its original deadline', t => {
  const f = fixture(t, { timeoutSeconds: 0.3, implement: 'sleep 3; echo bad > artifact' });
  assert.notEqual(f.execute().status, 0);
  const exit = JSON.parse(readFileSync(path.join(f.run, 'one', 'exit.json')));
  assert.equal(exit.timedOut, true);
  assert.equal(existsSync(path.join(f.cwd, 'artifact')), false);
});

test('killed supervisor resumes detached work without duplicate execution', async t => {
  const f = fixture(t, { implement: 'echo execution >> count; sleep 1; echo data > artifact' });
  const child = spawn(process.execPath, [runner, 'run', f.run, f.planFile], { stdio: 'ignore' });
  const closed = new Promise(resolve => child.once('exit', resolve));
  const deadline = Date.now() + 5000;
  while (!existsSync(path.join(f.cwd, 'count'))) {
    assert.ok(Date.now() < deadline, 'worker failed to start');
    await pause(20);
  }
  const busy = f.execute();
  assert.notEqual(busy.status, 0);
  assert.match(busy.stderr, /EEXIST/);
  child.kill('SIGKILL');
  await closed;
  passed(f.invoke('unlock', f.run));
  passed(f.execute());
  assert.equal(readFileSync(path.join(f.cwd, 'count'), 'utf8'), 'execution\n');
});

test('dependency graph runs ready work without waiting for unrelated lanes', t => {
  const f = fixture(t);
  const a = path.join(f.cwd, 'a');
  const b = path.join(f.cwd, 'b');
  const c = path.join(f.cwd, 'c');
  [a, b, c].forEach(dir => mkdirSync(dir));
  const base = { ...f.phase, validate: 'test -s artifact', negativeControl: 'test ! -e nonexistent', review: 'test -s artifact' };
  f.plan.maxPhases = 3;
  f.plan.concurrency = 2;
  f.plan.phases = [
    { ...base, id: 'p1', cwd: a, dependsOn: [], implement: 'echo data > artifact' },
    { ...base, id: 'slow', cwd: b, dependsOn: [], implement: 'sleep 1.5; echo data > artifact' },
    { ...base, id: 'p2', cwd: c, dependsOn: ['p1'], implement: 'test -s ../a/artifact; test ! -e ../b/artifact; echo data > artifact' },
  ];
  writeFileSync(f.planFile, JSON.stringify(f.plan));
  passed(f.execute());
  const receipt = JSON.parse(readFileSync(path.join(f.run, 'p2', 'receipt.json')));
  assert.equal(receipt.verdict, 'PASS');
});

test('default dependency chain waits for prior phase', t => {
  const f = fixture(t);
  f.plan.maxPhases = 2;
  f.plan.concurrency = 2;
  f.plan.phases.push({ ...f.phase, id: 'two', implement: 'test -s artifact; echo second > second', review: 'test -s second', artifacts: ['second'] });
  writeFileSync(f.planFile, JSON.stringify(f.plan));
  passed(f.execute());
  assert.equal(JSON.parse(readFileSync(path.join(f.run, 'two', 'receipt.json'))).verdict, 'PASS');
});

test('missing exit evidence never passes or launches again', async t => {
  const f = fixture(t, { timeoutSeconds: 0.8 });
  const child = spawn(process.execPath, [runner, 'run', f.run, f.planFile], { stdio: 'ignore' });
  const closed = new Promise(resolve => child.once('exit', resolve));
  const inputFile = path.join(f.run, 'one', 'input.json');
  const deadline = Date.now() + 5000;
  while (!existsSync(inputFile)) { assert.ok(Date.now() < deadline); await pause(5); }
  // A worker killed before it produces exit evidence must not be replayed.
  while (!existsSync(path.join(f.run, 'one', 'claim.json'))) { assert.ok(Date.now() < deadline); await pause(5); }
  child.kill('SIGKILL');
  await closed;
  await pause(300);
  const exitFile = path.join(f.run, 'one', 'exit.json');
  if (existsSync(exitFile)) unlinkSync(exitFile);
  passed(f.invoke('unlock', f.run));
  const result = f.execute();
  assert.notEqual(result.status, 0);
  assert.equal(readFileSync(path.join(f.cwd, 'count'), 'utf8'), 'execution\n');
});

test('receipt write failure cannot advance the ledger', t => {
  const f = fixture(t, { review: 'mkdir "$DURABLE_PHASE_DIR/receipt.json"' });
  const result = f.execute();
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /faulted/);
  assert.notEqual(f.execute().status, 0);
});

test('independent phases sharing a working directory are serialized', t => {
  const f = fixture(t);
  f.plan.maxPhases = 2;
  f.plan.concurrency = 2;
  f.plan.phases[0].dependsOn = [];
  f.plan.phases[0].implement = 'mkdir busy; sleep 0.2; echo data > artifact; rmdir busy';
  f.plan.phases[0].review = 'test -s artifact';
  f.plan.phases.push({ ...f.phase, id: 'two', dependsOn: [], implement: 'mkdir busy; echo second > second; rmdir busy', review: 'test -s second', artifacts: ['second'] });
  writeFileSync(f.planFile, JSON.stringify(f.plan));
  passed(f.execute());
});

test('sealed command logs cannot be silently changed', t => {
  const f = fixture(t);
  passed(f.execute());
  writeFileSync(path.join(f.run, 'one', 'review.log'), 'edited');
  assert.match(f.execute().stderr, /evidence changed/);
});

test('dependency cycles and run budget are rejected', t => {
  const f = fixture(t);
  f.plan.phases[0].dependsOn = ['one'];
  writeFileSync(f.planFile, JSON.stringify(f.plan));
  assert.match(f.execute().stderr, /Invalid dependencies/);
  f.plan.phases[0].dependsOn = [];
  f.plan.maxWallSeconds = -1;
  writeFileSync(f.planFile, JSON.stringify(f.plan));
  assert.match(f.execute().stderr, /maxWallSeconds/);
});

test('changed plans and escaped artifact paths are rejected', t => {
  const f = fixture(t);
  passed(f.execute());
  f.plan.goal = 'Different goal';
  writeFileSync(f.planFile, JSON.stringify(f.plan));
  assert.match(f.execute().stderr, /Plan changed/);
  f.plan.phases[0].artifacts = ['../escape'];
  writeFileSync(f.planFile, JSON.stringify(f.plan));
  assert.match(f.execute().stderr, /Artifacts must be relative/);
});
