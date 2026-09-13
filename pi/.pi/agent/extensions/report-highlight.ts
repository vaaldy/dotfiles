import type { ExtensionAPI, Theme } from "@earendil-works/pi-coding-agent";
import { AssistantMessageComponent } from "@earendil-works/pi-coding-agent";
import { Box, Markdown } from "@earendil-works/pi-tui";

const PATCH_KEY = Symbol.for("pi-report-highlight.update-content");
let theme: Theme | undefined;

function frameReport(component: any, message: any, isStreaming: boolean): void {
	if (!Array.isArray(message?.content) || message.content.some((content: any) => content.type === "toolCall")) return;
	if (!component.__reportHighlight && isStreaming) return;

	const children = component.contentContainer?.children;
	if (!Array.isArray(children)) return;
	let framed = false;
	for (let i = 0; i < children.length; i++) {
		if (children[i] instanceof Markdown) {
			const box = new Box(1, 0, (text) => theme?.bg("customMessageBg", text) ?? text);
			box.addChild(children[i]);
			children[i] = box;
			framed = true;
		}
	}
	if (framed) component.__reportHighlight = true;
}

function patchRenderer(): void {
	const proto = AssistantMessageComponent.prototype as any;
	const original = proto.updateContent;
	if (typeof original !== "function" || original[PATCH_KEY]) return;

	function patchedUpdateContent(this: any, message: any, isStreaming = this.isStreaming) {
		const result = original.call(this, message, isStreaming);
		frameReport(this, message, isStreaming);
		return result;
	}
	patchedUpdateContent[PATCH_KEY] = true;
	proto.updateContent = patchedUpdateContent;
}

export default function reportHighlight(pi: ExtensionAPI) {
	patchRenderer();

	pi.on("session_start", (_event, ctx) => {
		theme = ctx.ui.theme;
		patchRenderer();
	});
	pi.on("agent_start", (_event, ctx) => {
		theme = ctx.ui.theme;
	});
	pi.on("turn_start", (_event, ctx) => {
		theme = ctx.ui.theme;
	});
}
