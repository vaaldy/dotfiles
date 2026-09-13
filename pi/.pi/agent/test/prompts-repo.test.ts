import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { mkdtemp, readFile, realpath, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";
import { test } from "node:test";
import { setupPromptsRepo } from "../extensions/prompts-repo.ts";

const run = promisify(execFile);

test("creates one independent prompts repository and parent exclusion", async () => {
  const root = await mkdtemp(join(tmpdir(), "prompts-repo-"));
  let initCalls = 0;
  const exec = async (command: string, args: string[]) => {
    if (args.includes("init")) initCalls++;
    try {
      const result = await run(command, args);
      return { ...result, code: 0, killed: false };
    } catch (error: any) {
      return { stdout: error.stdout ?? "", stderr: error.stderr ?? "", code: error.code ?? 1, killed: false };
    }
  };

  try {
    await run("git", ["-C", root, "init", "--quiet"]);
    assert.equal(await setupPromptsRepo(root, exec as any), true);
    assert.equal(await setupPromptsRepo(root, exec as any), false);
    assert.equal(initCalls, 1);

    const prompts = join(root, "prompts");
    const nestedRoot = (await run("git", ["-C", prompts, "rev-parse", "--show-toplevel"])).stdout.trim();
    assert.equal(await realpath(nestedRoot), await realpath(prompts));
    assert.equal((await run("git", ["-C", prompts, "remote"])).stdout, "");

    const excludePath = (await run("git", ["-C", root, "rev-parse", "--git-path", "info/exclude"])).stdout.trim();
    const exclude = await readFile(join(root, excludePath), "utf8");
    assert.equal(exclude.split("\n").filter((line) => line === "/prompts/").length, 1);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
});
