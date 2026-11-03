import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, readFileSync, readdirSync, realpathSync, rmSync, statSync, symlinkSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';

const installer = fileURLToPath(new URL('../install-macos.sh', import.meta.url));
const template = fileURLToPath(new URL('../pi/.pi/agent/models.json', import.meta.url));
const settingsTemplate = fileURLToPath(new URL('../pi/.pi/agent/settings.json', import.meta.url));
const revision = '53310dcfec14df2d4600c6dd7edc9a2e29dc0cd0';

test('installer preserves private config, merges session policy and installs pinned tools', () => {
  const scratch = mkdtempSync(join(tmpdir(), 'dotfiles-session-tools-'));
  try {
    const bin = join(scratch, 'bin');
    const log = join(scratch, 'commands.log');
    mkdirSync(bin);
    writeFileSync(join(bin, 'git'), `#!/usr/bin/env bash
set -eu
printf 'git|%s\\n' "$*" >> "$TEST_COMMAND_LOG"
if [[ "$1" == clone ]]; then mkdir -p "$3";
elif [[ "$*" == *"rev-parse HEAD" ]]; then printf '%s\\n' "\${TEST_NUNC_REVISION}";
elif [[ "$*" == *"status --porcelain" ]]; then printf '%s' "\${TEST_NUNC_DIRTY:-}"; fi
`, { mode: 0o755 });
    writeFileSync(join(bin, 'npm'), '#!/usr/bin/env bash\nprintf "npm|%s|%s\\n" "$PWD" "$*" >> "$TEST_COMMAND_LOG"\n', { mode: 0o755 });
    const env = { ...process.env, PATH: `${bin}:${process.env.PATH}`, TEST_COMMAND_LOG: log, TEST_NUNC_REVISION: revision };
    for (const scenario of ['private', 'private-no-window', 'missing', 'symlink']) {
      const home = join(scratch, scenario);
      const target = join(home, '.pi/agent/models.json');
      const settings = join(home, '.pi/agent/settings.json');
      const privateSettings = {
        private: 'keep-local', defaultModel: 'keep-local-model',
        nunc: { memoryTools: false, toolResultCleanup: false },
        compaction: { enabled: false, modelOverrides: {
          'local/model': { reserveTokens: 30000 },
          'openai-codex/gpt-6.1-sol': { reserveTokens: 16384, keepRecentTokens: 12345 },
        } },
        packages: ['npm:local-only', 'npm:pi-smart-compact@10.7.3'],
      };
      const original = JSON.stringify(privateSettings) + '\n';
      const privateModels = JSON.stringify({ private: 'keep-local', ...(scenario === 'private' ? {
        providers: { 'openai-codex': { modelOverrides: {
          'gpt-6.1-sol': { contextWindow: 1050000 },
          'gpt-6.1-terra': { contextWindow: 500000 },
        } } },
      } : {}) }) + '\n';
      mkdirSync(join(home, '.pi/agent'), { recursive: true });
      if (scenario.startsWith('private')) {
        writeFileSync(target, privateModels, { mode: 0o600 });
        writeFileSync(settings, original, { mode: 0o600 });
      }
      if (scenario === 'symlink') {
        symlinkSync(join(scratch, 'old-models.json'), target);
        symlinkSync(join(scratch, 'old-settings.json'), settings);
      }
      for (let run = 0; run < 2; run++) {
        execFileSync('bash', [installer], { env: { ...env, HOME: home }, stdio: 'pipe' });
        if (scenario.startsWith('private')) {
          assert.equal(readFileSync(target, 'utf8'), privateModels);
          assert.equal(statSync(target).mode & 0o777, 0o600);
          const actual = JSON.parse(readFileSync(settings, 'utf8'));
          assert.deepEqual(actual, {
            ...privateSettings,
            nunc: { memoryTools: true, toolResultCleanup: false },
            compaction: { enabled: false, modelOverrides: {
              'local/model': { reserveTokens: 30000 },
              'openai-codex/gpt-6.1-sol': { reserveTokens: scenario === 'private' ? 650000 : 16384, keepRecentTokens: 12345 },
              ...(scenario === 'private' ? { 'openai-codex/gpt-6.1-terra': { reserveTokens: 100000 } } : {}),
            } },
            packages: ['npm:local-only', '~/.pi/agent/local-packages/pi-nunc'],
          });
          assert.equal(statSync(settings).mode & 0o777, 0o600);
          const backups = readdirSync(join(home, '.pi/agent')).filter(name => name.startsWith('settings.json.bak.'));
          assert.equal(backups.length, 1);
          assert.equal(readFileSync(join(home, '.pi/agent', backups[0]), 'utf8'), original);
        } else {
          assert.equal(realpathSync(target), realpathSync(template));
          assert.equal(realpathSync(settings), realpathSync(settingsTemplate));
        }
        assert.equal(realpathSync(join(home, '.pi/agent/scripts/durable-loop')), realpathSync(fileURLToPath(new URL('../pi/.pi/agent/scripts/durable-loop', import.meta.url))));
      }
    }
    const commands = readFileSync(log, 'utf8').split('\n');
    assert.equal(commands.filter(line => line.startsWith('git|clone ')).length, 4);
    assert.equal(commands.filter(line => line.endsWith('|run build')).length, 8);
    assert.equal(commands.filter(line => line.endsWith('|ci --ignore-scripts --no-audit --no-fund')).length, 16);
    for (const override of [{ TEST_NUNC_DIRTY: ' M src/index.ts' }, { TEST_NUNC_REVISION: 'different-revision' }]) {
      assert.throws(() => execFileSync('bash', [installer], { env: { ...env, ...override, HOME: join(scratch, 'private') }, stdio: 'pipe' }), error => error.status === 1 && /Nunc checkout must be clean/.test(error.stderr.toString()));
    }
    assert.equal(readFileSync(log, 'utf8').split('\n').filter(line => line.includes('|run build')).length, 8);
  } finally {
    rmSync(scratch, { recursive: true, force: true });
  }
});
