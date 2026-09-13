import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { existsSync, statSync, readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { resolve, isAbsolute, join } from "node:path";
import { homedir } from "node:os";

const ALIASES_FILE = join(homedir(), ".pi", "agent", "btw-aliases.json");

function loadAliases(): Record<string, string> {
  try {
    if (existsSync(ALIASES_FILE)) {
      return JSON.parse(readFileSync(ALIASES_FILE, "utf8"));
    }
  } catch {}
  return {};
}

function saveAlias(alias: string, fullPath: string) {
  try {
    const dir = join(homedir(), ".pi", "agent");
    mkdirSync(dir, { recursive: true });
    const aliases = loadAliases();
    aliases[alias.toLowerCase()] = fullPath;
    writeFileSync(ALIASES_FILE, JSON.stringify(aliases, null, 2) + "\n", "utf8");
  } catch {}
}

async function queryZoxide(pi: ExtensionAPI, token: string): Promise<string | null> {
  const res = await pi.exec("zoxide", ["query", token]).catch(() => null);
  if (res && res.code === 0 && res.stdout.trim()) {
    const candidate = res.stdout.trim();
    if (existsSync(candidate) && statSync(candidate).isDirectory()) {
      return candidate;
    }
  }
  return null;
}

async function listZoxide(pi: ExtensionAPI): Promise<string[]> {
  const res = await pi.exec("zoxide", ["query", "-l"]).catch(() => null);
  if (res && res.code === 0 && res.stdout.trim()) {
    return res.stdout
      .trim()
      .split("\n")
      .map((s) => s.trim())
      .filter((s) => s.length > 0 && existsSync(s));
  }
  return [];
}

async function resolveTargetDir(
  pi: ExtensionAPI,
  ctx: any,
  input: string
): Promise<{ targetDir: string; prompt: string }> {
  const trimmed = input.trim();
  if (!trimmed) return { targetDir: ctx.cwd, prompt: "" };

  const match = trimmed.match(/^("[^"]+"|\S+)(.*)$/);
  if (!match) return { targetDir: ctx.cwd, prompt: trimmed };

  let firstToken = match[1];
  const rest = match[2].trim();

  // Strip wrapping quotes
  if (firstToken.startsWith('"') && firstToken.endsWith('"')) {
    firstToken = firstToken.slice(1, -1);
  }

  // 1. Direct path check (e.g. /path/to/dir, ./rel/dir, ~/Documents/...)
  const expanded = firstToken.startsWith("~")
    ? firstToken.replace(/^~(?=$|\/|\\)/, homedir())
    : firstToken;
  const candidatePath = isAbsolute(expanded) ? expanded : resolve(ctx.cwd, expanded);

  try {
    if (existsSync(candidatePath) && statSync(candidatePath).isDirectory()) {
      return { targetDir: candidatePath, prompt: rest };
    }
  } catch {}

  // 2. Check remembered alias cache
  const aliases = loadAliases();
  const lowerToken = firstToken.toLowerCase();
  if (aliases[lowerToken] && existsSync(aliases[lowerToken])) {
    return { targetDir: aliases[lowerToken], prompt: rest };
  }

  // 3. Query zoxide for fuzzy match
  const zoxideMatch = await queryZoxide(pi, firstToken);
  if (zoxideMatch) {
    if (ctx.mode === "tui") {
      const ok = await ctx.ui.confirm(
        `Resolve "${firstToken}"?`,
        `Jump to: ${zoxideMatch}\n\n(Confirmed aliases will be remembered automatically)`
      );
      if (ok) {
        saveAlias(lowerToken, zoxideMatch);
        return { targetDir: zoxideMatch, prompt: rest };
      } else {
        // User declined: treat the entire input as prompt in current directory
        return { targetDir: ctx.cwd, prompt: trimmed };
      }
    } else {
      return { targetDir: zoxideMatch, prompt: rest };
    }
  }

  return { targetDir: ctx.cwd, prompt: trimmed };
}

export default function (pi: ExtensionAPI) {
  let subagentPaneId: string | null = null;

  async function closeSubagentPane(ctx: any) {
    if (!subagentPaneId) {
      ctx.ui.notify("No active subagent pane found", "info");
      return;
    }
    const pane = subagentPaneId;
    subagentPaneId = null;
    const res = await pi.exec("tmux", ["kill-pane", "-t", pane]).catch(() => null);
    if (res && res.code === 0) {
      ctx.ui.notify("Subagent pane closed", "info");
    } else {
      ctx.ui.notify("Subagent pane was already closed", "info");
    }
  }

  pi.registerCommand("btw", {
    description: "Spawn a subagent in RH tmux pane with zoxide fuzzy dir resolution",
    handler: async (args, ctx) => {
      let rawInput = (args || "").trim();

      if (rawInput === "close" || rawInput === "q" || rawInput === "exit") {
        await closeSubagentPane(ctx);
        return;
      }

      // Interactive directory selector if requested via /btw ? or /btw select
      if (rawInput === "?" || rawInput === "select" || rawInput === "pick") {
        if (ctx.mode === "tui") {
          const dirs = await listZoxide(pi);
          if (dirs.length > 0) {
            const chosen = await ctx.ui.select("Select target directory for subagent:", dirs);
            if (!chosen) return;
            rawInput = chosen;
          }
        }
      }

      const { targetDir, prompt } = await resolveTargetDir(pi, ctx, rawInput);
      const inTmux = Boolean(process.env.TMUX);

      if (inTmux) {
        // If an old subagent pane exists, close it first before opening a fresh one
        if (subagentPaneId) {
          await pi.exec("tmux", ["kill-pane", "-t", subagentPaneId]).catch(() => null);
          subagentPaneId = null;
        }

        const notifyMsg = prompt
          ? `Spawning subagent in ${targetDir}: "${prompt}"`
          : `Spawning subagent pane in ${targetDir}...`;
        ctx.ui.notify(notifyMsg, "info");

        // Use login zsh to ensure full environment, NVM, PATH, and zoxide tracking
        const shellCmd = prompt
          ? `cd ${JSON.stringify(targetDir)} && zsh -l -c "pi ${JSON.stringify(prompt).replace(/"/g, '\\"')}"`
          : `cd ${JSON.stringify(targetDir)} && zsh -l -c "pi"`;

        // -c targetDir locks pane_current_path for lazygit (prefix g) and other tmux hooks
        // -h splits side-by-side to create a right-hand (RH) pane
        const tmuxArgs = [
          "split-window",
          "-h",
          "-l",
          "45%",
          "-c",
          targetDir,
          "-P",
          "-F",
          "#{pane_id}",
          shellCmd,
        ];

        const res = await pi.exec("tmux", tmuxArgs).catch((err: any) => {
          ctx.ui.notify(`Failed to split tmux: ${err.message}`, "error");
          return null;
        });

        if (res && res.code === 0) {
          subagentPaneId = res.stdout.trim();
        } else if (res) {
          ctx.ui.notify(`tmux error: ${res.stderr}`, "error");
        }
      } else {
        // Fallback when outside tmux
        if (!prompt) {
          ctx.ui.notify("Outside tmux: Please provide a prompt, e.g. /btw <question>", "warning");
          return;
        }
        ctx.ui.notify(`Querying subagent in ${targetDir}: "${prompt}"...`, "info");
        const res = await pi.exec("pi", ["-p", prompt], { cwd: targetDir }).catch((err: any) => ({
          stdout: "",
          stderr: err.message,
          code: 1,
        }));
        if (res.code === 0 && res.stdout) {
          ctx.ui.notify(res.stdout.trim().slice(0, 300), "info");
        } else {
          ctx.ui.notify(`Subagent query failed: ${res.stderr}`, "error");
        }
      }
    },
  });

  pi.registerCommand("btw-close", {
    description: "Close the active /btw subagent tmux pane",
    handler: async (_args, ctx) => {
      await closeSubagentPane(ctx);
    },
  });

  pi.on("session_shutdown", async () => {
    if (subagentPaneId) {
      await pi.exec("tmux", ["kill-pane", "-t", subagentPaneId]).catch(() => null);
      subagentPaneId = null;
    }
  });
}
