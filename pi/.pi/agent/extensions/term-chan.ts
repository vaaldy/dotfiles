import type { ExtensionAPI, ExtensionFactory } from "@earendil-works/pi-coding-agent";
import { homedir } from "node:os";
import { join } from "node:path";
import { pathToFileURL } from "node:url";

const integrationPath = process.env.TERM_CHAN_PI_INTEGRATION
  ?? join(process.env.XDG_DATA_HOME ?? join(homedir(), ".local", "share"), "term-chan", "src", "integrations", "pi.js");
const model = "google/gemini-3.5-flash";

type TermChanIntegration = {
  default: ExtensionFactory;
  createPiExtension?: (options: { model: string }) => ExtensionFactory;
};

export default async function termChan(pi: ExtensionAPI): Promise<void> {
  const integration = await import(pathToFileURL(integrationPath).href) as TermChanIntegration;
  const factory = integration.createPiExtension?.({ model }) ?? integration.default;
  await factory(pi);
}
