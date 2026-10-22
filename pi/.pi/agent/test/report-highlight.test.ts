import assert from "node:assert/strict";
import { registerHooks } from "node:module";
import { test } from "node:test";

const stub = `
export class Markdown { constructor(text) { this.text = text; } }
export class Box {
  children = [];
  addChild(child) { this.children.push(child); }
}
export class AssistantMessageComponent {
  contentContainer = { children: [] };
  updateContent(message, isStreaming = false) {
    this.lastMessage = message;
    this.isStreaming = isStreaming;
    this.contentContainer.children = message.content
      .filter(block => block.type === 'text')
      .map(block => new Markdown(block.text));
  }
  render() { return this.contentContainer.children; }
}`;
const stubUrl = `data:text/javascript,${encodeURIComponent(stub)}`;
registerHooks({
  resolve(specifier, context, next) {
    if (["@earendil-works/pi-coding-agent", "@earendil-works/pi-tui"].includes(specifier)) {
      return { url: stubUrl, shortCircuit: true };
    }
    return next(specifier, context);
  },
});
const { default: reportHighlight } = await import("../extensions/report-highlight.ts");
// Import the identical class instance used by the extension.
const { AssistantMessageComponent } = await import(stubUrl);

test("only OpenRouter Argon tool commentary is hidden, without changing messages", () => {
  const handlers = new Map();
  const pi = { on: (event, handler) => handlers.set(event, handler) };
  reportHighlight(pi as never);
  // A package may replace updateContent after this extension loads.
  const previous = AssistantMessageComponent.prototype.updateContent;
  AssistantMessageComponent.prototype.updateContent = function(message, streaming) {
    return previous.call(this, message, streaming);
  };
  handlers.get("session_start")({}, { ui: { theme: { bg: (_color, text) => text } } });
  const render = AssistantMessageComponent.prototype.render;
  reportHighlight(pi as never);
  assert.equal(AssistantMessageComponent.prototype.render, render);

  for (const [provider, model, toolCall, hidden] of [
    ["openrouter", "google/gemini-4-argon", true, true],
    ["openrouter", "google/gemini-4-argon", false, false],
    ["openrouter", "google/gemini-4-other", true, false],
    ["google", "google/gemini-4-argon", true, false],
  ] as const) {
    const message = { provider, model, content: [
      { type: "text", text: "commentary" },
      { type: "thinking", thinking: "", thinkingSignature: "preserve" },
      ...(toolCall ? [{ type: "toolCall", id: "call" }] : []),
    ] };
    const snapshot = JSON.stringify(message);
    for (const streaming of [true, false]) {
      const component = new AssistantMessageComponent();
      component.updateContent(message, streaming);
      assert.equal(component.render(80).length, hidden ? 0 : 1);
      assert.equal(component.lastMessage, message);
      assert.equal(component.isStreaming, streaming);
      assert.equal(JSON.stringify(message), snapshot);
      assert.equal(component.render(80).length, hidden ? 0 : 1);
    }
  }
  const component = new AssistantMessageComponent();
  assert.deepEqual(component.render(80), []);
  const message = { provider: "openrouter", model: "google/gemini-4-argon", content: [
    { type: "text", text: "streaming commentary" },
  ] };
  component.updateContent(message, true);
  assert.equal(component.render(80).length, 1);
  message.content.push({ type: "toolCall", id: "call" } as never);
  component.updateContent(message, true);
  assert.equal(component.render(80).length, 0);
  component.updateContent({ ...message, content: [{ type: "text", text: "final answer" }] }, false);
  assert.equal(component.render(80).length, 1);
});
