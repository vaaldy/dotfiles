import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { appendFile, mkdir, readFile, realpath } from "node:fs/promises";
import { isAbsolute, join, resolve } from "node:path";

type Exec = ExtensionAPI["exec"];

export async function setupPromptsRepo(cwd: string, exec: Exec): Promise<boolean> {
  const parent = await exec("git", ["-C", cwd, "rev-parse", "--show-toplevel"]);
  if (parent.code !== 0) return false;

  const root = parent.stdout.trim();
  const prompts = join(root, "prompts");
  await mkdir(prompts, { recursive: true });

  let changed = false;
  const excludeResult = await exec("git", ["-C", root, "rev-parse", "--git-path", "info/exclude"]);
  if (excludeResult.code !== 0) throw new Error(excludeResult.stderr.trim());

  const exclude = isAbsolute(excludeResult.stdout.trim())
    ? excludeResult.stdout.trim()
    : resolve(root, excludeResult.stdout.trim());
  await mkdir(resolve(exclude, ".."), { recursive: true });
  const contents = await readFile(exclude, "utf8").catch(() => "");
  if (!contents.split(/\r?\n/).includes("/prompts/")) {
    await appendFile(exclude, `${contents && !contents.endsWith("\n") ? "\n" : ""}/prompts/\n`);
    changed = true;
  }

  const nested = await exec("git", ["-C", prompts, "rev-parse", "--show-toplevel"]);
  const hasOwnGit = nested.code === 0
    && await realpath(nested.stdout.trim()) === await realpath(prompts);
  if (!hasOwnGit) {
    const initialized = await exec("git", ["-C", prompts, "init", "--quiet"]);
    if (initialized.code !== 0) throw new Error(initialized.stderr.trim());
    changed = true;
  }

  return changed;
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    try {
      if (await setupPromptsRepo(ctx.cwd, pi.exec.bind(pi))) {
        ctx.ui.notify("Configured independent prompts/ repository", "info");
      }
    } catch (error) {
      ctx.ui.notify(`prompts/ setup failed: ${error instanceof Error ? error.message : error}`, "warning");
    }
  });
}
