#!/usr/bin/env node
import { spawn } from 'node:child_process';
import { createHash, randomUUID } from 'node:crypto';
import { existsSync, readFileSync, writeFileSync, mkdirSync, openSync, closeSync, unlinkSync, realpathSync, linkSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Harness, createRegistry, defineDoc, defineExtension, defineTask } from '@earendil-works/pi-durable';
import { openNodeSqliteStorage } from '@earendil-works/pi-durable/storage/sqlite/node';
import { BACKGROUND_CONTEXT as context } from '@earendil-works/chord/context';
import { createModels } from '@earendil-works/pi-ai';

const self = fileURLToPath(import.meta.url);
const stages = ['implement', 'validate', 'negativeControl', 'review'];
const hash = value => createHash('sha256').update(value).digest('hex');
const json = file => JSON.parse(readFileSync(file, 'utf8'));
const seal = (file, value) => {
  const temporary = `${file}.${randomUUID()}.tmp`;
  writeFileSync(temporary, JSON.stringify(value, null, 2) + '\n', { flag: 'wx', flush: true });
  try { linkSync(temporary, file); }
  finally { unlinkSync(temporary); }
};
const alive = pid => {
  try { process.kill(pid, 0); return true; } catch (error) {
    if (error.code === 'ESRCH') return false;
    throw error;
  }
};
const fail = message => { throw new Error(message); };

function loadPlan(file) {
  const plan = json(file);
  if (typeof plan.goal !== 'string' || !plan.goal.trim()) fail('A goal is required');
  if (!Number.isFinite(plan.maxWallSeconds) || plan.maxWallSeconds <= 0) fail('maxWallSeconds must be positive');
  if (!Number.isInteger(plan.maxPhases) || plan.maxPhases < 1 || !Array.isArray(plan.phases) || !plan.phases.length || plan.phases.length > plan.maxPhases) fail('Invalid phase budget');
  const ids = new Set();
  for (const phase of plan.phases) {
    if (!/^[a-zA-Z0-9][a-zA-Z0-9_-]{0,79}$/.test(phase.id) || ids.has(phase.id)) fail('Invalid or duplicate phase id');
    ids.add(phase.id);
    if (!path.isAbsolute(phase.cwd ?? '')) fail('cwd must be an absolute directory');
    phase.cwd = realpathSync(phase.cwd);
    if (!Number.isFinite(phase.timeoutSeconds) || phase.timeoutSeconds <= 0) fail('timeoutSeconds must be positive');
    for (const field of ['hypothesis', 'falsificationCriterion', ...stages]) {
      if (typeof phase[field] !== 'string' || !phase[field].trim()) fail(`Missing ${field}`);
    }
    if (!Array.isArray(phase.artifacts) || !phase.artifacts.length) fail('Declare at least one artifact');
    for (const artifact of phase.artifacts) {
      if (typeof artifact !== 'string' || path.isAbsolute(artifact) || artifact.split(/[\\/]/).includes('..')) fail('Artifacts must be relative paths within cwd');
    }
  }
  plan.concurrency ??= 1;
  if (!Number.isInteger(plan.concurrency) || plan.concurrency < 1 || plan.concurrency > 3) fail('concurrency must be between 1 and 3');
  for (let i = 0; i < plan.phases.length; i++) {
    const phase = plan.phases[i];
    phase.dependsOn ??= i ? [plan.phases[i - 1].id] : [];
    if (!Array.isArray(phase.dependsOn) || new Set(phase.dependsOn).size !== phase.dependsOn.length || phase.dependsOn.some(id => !ids.has(id) || id === phase.id)) fail('Invalid dependencies');
  }
  const visited = new Set();
  while (visited.size < ids.size) {
    const ready = plan.phases.filter(p => !visited.has(p.id) && p.dependsOn.every(id => visited.has(id)));
    if (!ready.length) fail('Dependency cycle');
    ready.forEach(p => visited.add(p.id));
  }
  return plan;
}

function artifacts(phase) {
  return phase.artifacts.map(name => {
    const file = realpathSync(path.resolve(phase.cwd, name));
    if (!file.startsWith(phase.cwd + path.sep)) fail('Artifact escapes cwd');
    const bytes = readFileSync(file);
    return { path: name, bytes: bytes.length, sha256: hash(bytes) };
  });
}

// The worker owns an exclusive claim BEFORE it can run any business command.
async function worker(dir) {
  const input = json(path.join(dir, 'input.json'));
  seal(path.join(dir, 'claim.json'), { token: input.token, pid: process.pid, startedAt: Date.now() });
  const results = [];
  let timedOut = false;
  let current;
  const deadline = input.deadline;
  const timer = setTimeout(() => {
    timedOut = true;
    if (current) {
      try { process.kill(-current.pid, 'SIGKILL'); } catch (error) { if (error.code !== 'ESRCH') throw error; }
    }
  }, Math.max(1, deadline - Date.now()));
  try {
    for (const stage of stages) {
      if (timedOut || Date.now() >= deadline) { timedOut = true; break; }
      const start = Date.now();
      const fd = openSync(path.join(dir, `${stage}.log`), 'a');
      const result = await new Promise((resolve, reject) => {
        current = spawn('/bin/sh', ['-c', input.phase[stage]], {
          cwd: input.phase.cwd, detached: true, stdio: ['ignore', fd, fd],
          env: { ...process.env, DURABLE_PHASE_DIR: dir, DURABLE_PHASE_ID: input.phase.id },
        });
        current.once('error', reject);
        current.once('spawn', () => seal(path.join(dir, `${stage}.process.json`), { pid: current.pid, startedAt: start, deadline }));
        current.once('exit', (code, signal) => resolve({ stage, code, signal, durationMs: Date.now() - start }));
      }).finally(() => { closeSync(fd); current = undefined; });
      results.push(result);
      if (result.code !== 0) break;
    }
    const passed = !timedOut && results.length === stages.length && results.every(r => r.code === 0);
    seal(path.join(dir, 'exit.json'), {
      token: input.token, startedAt: deadline - input.allowedMs, finishedAt: Date.now(),
      passed, timedOut, results, artifacts: passed ? artifacts(input.phase) : [],
    });
  } finally { clearTimeout(timer); }
}

const State = defineDoc({
  kind: 'shared.durable-loop', version: 1, scope: 'conversation', history: 'rewindable', fork: 'current', checkpointWhen: () => false,
  initial: () => ({ planHash: '', startedAt: 0, phases: {} }),
});

const Phase = defineTask({
  name: 'shared.phase', version: 1,
  initial: input => ({ phase: 'prepare', dir: input.dir, deadline: input.deadline, token: input.token }),
  phases: {
    prepare: async (task, runtime, ctx) => {
      const checkpoint = task.state.checkpoint;
      // Persist intent before spawning. Resume never repeats an uncertain launch.
      await runtime.commit(() => ({ status: 'running', checkpoint: { ...checkpoint, phase: 'launch' } }), ctx);
    },
    launch: async (task, runtime, ctx) => {
      const checkpoint = task.state.checkpoint;
      const marker = path.join(checkpoint.dir, 'launch.json');
      if (!existsSync(marker)) {
        seal(marker, { token: checkpoint.token, at: Date.now() });
        const fd = openSync(path.join(checkpoint.dir, 'worker.log'), 'a');
        const child = spawn(process.execPath, [self, '_worker', checkpoint.dir], { detached: true, stdio: ['ignore', fd, fd] });
        closeSync(fd);
        await new Promise((resolve, reject) => { child.once('spawn', resolve); child.once('error', reject); });
        child.unref();
      }
      await runtime.sleepUntil(runtime.now() + 100, { ...checkpoint, phase: 'monitor' }, ctx);
    },
    monitor: async (task, runtime, ctx) => {
      const checkpoint = task.state.checkpoint;
      if (existsSync(path.join(checkpoint.dir, 'exit.json'))) {
        await runtime.commit(() => ({ status: 'running', checkpoint: { ...checkpoint, phase: 'gate' } }), ctx);
        return;
      }
      if (Date.now() > checkpoint.deadline + 2000) fail('Missing exit evidence after deadline; reconcile worker, never relaunch automatically');
      if (existsSync(path.join(checkpoint.dir, 'claim.json'))) {
        const claim = json(path.join(checkpoint.dir, 'claim.json'));
        if (claim.token !== checkpoint.token || !alive(claim.pid)) fail('Worker lost without exit evidence; reconcile before continuing');
      }
      await runtime.sleepUntil(runtime.now() + 100, checkpoint, ctx);
    },
    gate: async (task, runtime, ctx) => {
      const checkpoint = task.state.checkpoint;
      const inputFile = path.join(checkpoint.dir, 'input.json');
      const input = json(inputFile);
      if (JSON.stringify(input) !== JSON.stringify(task.input)) fail('Phase input changed');
      const exitFile = path.join(checkpoint.dir, 'exit.json');
      const exit = json(exitFile);
      if (exit.token !== checkpoint.token) fail('Exit evidence has wrong identity');
      const passed = exit.passed === true && exit.timedOut === false && exit.finishedAt <= checkpoint.deadline &&
        exit.results.length === stages.length && exit.results.every((r, i) => r.stage === stages[i] && r.code === 0) &&
        JSON.stringify(exit.artifacts) === JSON.stringify(artifacts(input.phase));
      const receipt = {
        phase: input.phase.id, token: checkpoint.token, planHash: input.planHash,
        verdict: passed ? 'PASS' : 'FAIL', exitSha256: hash(readFileSync(exitFile)),
        artifacts: exit.artifacts, results: exit.results, inputSha256: hash(readFileSync(inputFile)),
        logs: exit.results.map(result => ({ stage: result.stage, sha256: hash(readFileSync(path.join(checkpoint.dir, `${result.stage}.log`))) })),
        processes: exit.results.map(result => ({ stage: result.stage, sha256: hash(readFileSync(path.join(checkpoint.dir, `${result.stage}.process.json`))) })),
      };
      const receiptFile = path.join(checkpoint.dir, 'receipt.json');
      if (existsSync(receiptFile)) {
        if (JSON.stringify(json(receiptFile)) !== JSON.stringify(receipt)) fail('Sealed receipt changed');
      } else seal(receiptFile, receipt);
      // This transaction is the authoritative ledger; receipt failure cannot be ignored.
      await runtime.commit(async tx => {
        const state = await tx.doc(State, runtime.conversationId);
        state.phases[input.phase.id] = { taskId: task.id, verdict: receipt.verdict, receiptSha256: hash(readFileSync(receiptFile)) };
        return { status: 'terminal', outcome: passed
          ? { status: 'completed', result: receipt }
          : { status: 'failed', error: { message: `Quality gate failed: ${input.phase.id}` } } };
      }, ctx);
    },
  },
  // Aborting the scheduler is not proof that detached commands stopped.
  abort: (_task, runtime, ctx) => runtime.commit(() => ({ status: 'terminal', outcome: { status: 'aborted' } }), ctx),
});

async function run(directory, planFile) {
  const dir = path.resolve(directory);
  mkdirSync(dir, { recursive: true });
  const lock = path.join(dir, 'supervisor.lock');
  const lockFd = openSync(lock, 'wx');
  let harness;
  try {
    writeFileSync(lockFd, JSON.stringify({ pid: process.pid }));
    const plan = loadPlan(planFile);
    const planHash = hash(JSON.stringify(plan));
    const registry = createRegistry();
    registry.install(defineExtension({ name: 'shared-loop', tasks: [Phase] }));
    harness = await Harness.open(await openNodeSqliteStorage(path.join(dir, 'state.sqlite')), { registry, models: createModels() }, context);
    const root = await harness.root(context);
    await root.commit(async tx => {
      const state = await tx.doc(State, root.id);
      if (state.planHash && state.planHash !== planHash) fail('Plan changed; use a new run directory');
      if (!state.planHash) { state.planHash = planHash; state.startedAt = Date.now(); }
    }, context);
    const complete = new Set();
    const execute = async phase => {
      const state = await harness.snapshot(State, root.id, context);
      const phaseDir = path.join(dir, phase.id);
      if (state.phases[phase.id]) {
        const recorded = state.phases[phase.id];
        const receiptFile = path.join(phaseDir, 'receipt.json');
        if (recorded.receiptSha256 !== hash(readFileSync(receiptFile))) fail('Receipt changed');
        const receipt = json(receiptFile);
        if (receipt.verdict !== 'PASS' || JSON.stringify(receipt.artifacts) !== JSON.stringify(artifacts(phase)) || receipt.exitSha256 !== hash(readFileSync(path.join(phaseDir, 'exit.json'))) || receipt.inputSha256 !== hash(readFileSync(path.join(phaseDir, 'input.json'))) || receipt.logs.some(log => log.sha256 !== hash(readFileSync(path.join(phaseDir, `${log.stage}.log`)))) || receipt.processes.some(record => record.sha256 !== hash(readFileSync(path.join(phaseDir, `${record.stage}.process.json`))))) fail('Previous phase failed or evidence changed');
        return;
      }
      // Find the existing task before admitting work; waiting starts the scheduler.
      const graph = (await harness.taskGraph(context)).value;
      let existing = Object.values(graph.tasks).find(node => node.kind === 'shared.phase' && node.state?.checkpoint?.dir === phaseDir);
      let taskId = existing?.id;
      if (!taskId) {
        const remaining = state.startedAt + plan.maxWallSeconds * 1000 - Date.now();
        if (remaining <= 0) fail('Run wall-clock budget exhausted');
        mkdirSync(phaseDir, { recursive: true });
        const inputFile = path.join(phaseDir, 'input.json');
        let input;
        if (existsSync(inputFile)) {
          input = json(inputFile);
          if (input.planHash !== planHash) fail('Phase input identity changed');
        } else {
          const allowedMs = Math.min(phase.timeoutSeconds * 1000, remaining);
          input = { phase, planHash, dir: phaseDir, token: randomUUID(), allowedMs, deadline: Date.now() + allowedMs };
          seal(inputFile, input);
        }
        await root.commit(async tx => { taskId = await tx.createTask(Phase, input, { ownership: { kind: 'conversation' } }); }, context);
      }
      const settled = await harness.waitForTask(taskId, context);
      if (settled.state.outcome?.status !== 'completed') fail(`Phase ${phase.id} did not pass: ${JSON.stringify(settled.state.outcome)}`);
    };
    const active = new Map();
    let failure;
    while (complete.size < plan.phases.length) {
      if (!failure) {
        const ready = plan.phases.filter(p => !complete.has(p.id) && !active.has(p.id) && p.dependsOn.every(id => complete.has(id)));
        for (const phase of ready) {
          const overlaps = [...active.keys()].some(id => {
            const other = plan.phases.find(p => p.id === id);
            return other.cwd === phase.cwd || other.cwd.startsWith(phase.cwd + path.sep) || phase.cwd.startsWith(other.cwd + path.sep);
          });
          if (!overlaps && active.size < plan.concurrency) {
            active.set(phase.id, execute(phase).then(() => ({ id: phase.id }), error => ({ id: phase.id, error })));
          }
        }
      }
      if (!active.size) { if (failure) throw failure; fail('No schedulable phase'); }
      const result = await Promise.race(active.values());
      active.delete(result.id);
      if (result.error) failure ??= result.error;
      else complete.add(result.id);
      // Stop admitting new work on failure, but let already-running lanes settle.
      if (failure && !active.size) throw failure;
    }
    console.log(JSON.stringify(await harness.snapshot(State, root.id, context), null, 2));
  } finally {
    try { if (harness) await harness.close(context); }
    finally { closeSync(lockFd); unlinkSync(lock); }
  }
}

try {
  const [command, directory, plan] = process.argv.slice(2);
  if (command === '_worker') await worker(path.resolve(directory));
  else if (command === 'run' && directory && plan) await run(directory, path.resolve(plan));
  else if (command === 'unlock' && directory) {
    const lock = path.resolve(directory, 'supervisor.lock');
    const owner = json(lock);
    if (!Number.isInteger(owner.pid) || owner.pid <= 0 || alive(owner.pid)) fail('Lock owner is live or unknown');
    unlinkSync(lock);
    console.log('Removed dead supervisor lock; detached workers were not stopped');
  } else fail('Usage: runner.mjs run <run-directory> <plan.json> | unlock <run-directory>');
} catch (error) { console.error(error.stack); process.exitCode = 1; }
