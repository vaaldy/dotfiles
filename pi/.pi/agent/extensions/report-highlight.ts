import type { ExtensionAPI, Theme } from "@earendil-works/pi-coding-agent";
import { AssistantMessageComponent } from "@earendil-works/pi-coding-agent";
import { Box, Markdown } from "@earendil-works/pi-tui";

const PATCH_KEY = Symbol.for("pi-report-highlight.update-content");
const RENDER_PATCH_KEY = Symbol.for("pi-report-highlight.argon-render");
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
	const originalRender = proto.render;
	if (typeof originalRender === "function" && !originalRender[RENDER_PATCH_KEY]) {
		function patchedRender(this: any, width: number) {
			const message = this.lastMessage;
			if (message?.provider === "openrouter" && message.model === "google/gemini-4-argon" &&
				message.content.some((content: any) => content.type === "toolCall") &&
				message.content.some((content: any) => content.type === "text")) {
				try {
					this.updateContent({ ...message, content: message.content.filter((content: any) => content.type !== "text") }, this.isStreaming);
				} finally {
					this.lastMessage = message;
				}
			}
			return originalRender.call(this, width);
		}
		patchedRender[RENDER_PATCH_KEY] = true;
		proto.render = patchedRender;
	}

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
