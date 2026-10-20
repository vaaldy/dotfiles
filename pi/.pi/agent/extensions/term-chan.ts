import type { ExtensionAPI, ExtensionFactory } from "@earendil-works/pi-coding-agent";
import { homedir } from "node:os";
import { join } from "node:path";
import { pathToFileURL } from "node:url";

const integrationPath = process.env.TERM_CHAN_PI_INTEGRATION
  ?? join(homedir(), "Projects", "term-chan", "src", "integrations", "pi.js");
const provider = "openai-codex";
const model = "gpt-6-luna";
const character = "nadeshiko-px";

type TermChanIntegration = {
  default: ExtensionFactory;
  createPiExtension?: (options: { provider: string; model: string; character: string; reasoningEffort: string }) => ExtensionFactory;
};

export default async function termChan(pi: ExtensionAPI): Promise<void> {
  const integration = await import(pathToFileURL(integrationPath).href) as TermChanIntegration;
  const factory = integration.createPiExtension?.({ provider, model, character, reasoningEffort: "none" }) ?? integration.default;
  await factory(pi);
}
