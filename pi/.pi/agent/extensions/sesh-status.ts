import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  const pane = process.env.TMUX_PANE;
  if (!process.env.TMUX || !pane || !process.stdin.isTTY) return;

  async function status(state: "idle" | "working" | "clear") {
    const args = ["set-option", "-p", "-t", pane!];
    if (state === "clear") args.push("-u", "@pi_sesh_status");
    else args.push("@pi_sesh_status", `${process.pid} ${state} ${Math.floor(Date.now() / 1000)}`);
    // The pane or tmux server may already be gone at shutdown.
    await pi.exec("tmux", args, { timeout: 500 }).catch(() => {});
  }

  pi.on("session_start", (_event, ctx) => ctx.mode === "tui" ? status("idle") : undefined);
  pi.on("agent_start", (_event, ctx) => ctx.mode === "tui" ? status("working") : undefined);
  pi.on("agent_settled", (_event, ctx) => ctx.mode === "tui" ? status("idle") : undefined);
  pi.on("session_shutdown", (_event, ctx) => ctx.mode === "tui" ? status("clear") : undefined);
}
