import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, readFileSync, realpathSync, rmSync, statSync, symlinkSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';

const installer = fileURLToPath(new URL('../install-macos.sh', import.meta.url));
const template = fileURLToPath(new URL('../pi/.pi/agent/models.json', import.meta.url));

test('installer preserves private model config and maintains template links', () => {
  const scratch = mkdtempSync(join(tmpdir(), 'dotfiles-models-'));
  try {
    for (const scenario of ['private', 'missing', 'symlink']) {
      const home = join(scratch, scenario);
      const target = join(home, '.pi/agent/models.json');
      mkdirSync(join(home, '.pi/agent'), { recursive: true });
      if (scenario === 'private') writeFileSync(target, '{"private":"keep-local"}\n', { mode: 0o600 });
      if (scenario === 'symlink') symlinkSync(join(scratch, 'old-models.json'), target);
      for (let run = 0; run < 2; run++) {
        execFileSync('bash', [installer], { env: { ...process.env, HOME: home }, stdio: 'pipe' });
        if (scenario === 'private') {
          assert.equal(readFileSync(target, 'utf8'), '{"private":"keep-local"}\n');
          assert.equal(statSync(target).mode & 0o777, 0o600);
        } else {
          assert.equal(realpathSync(target), realpathSync(template));
        }
      }
    }
  } finally {
    rmSync(scratch, { recursive: true, force: true });
  }
});
