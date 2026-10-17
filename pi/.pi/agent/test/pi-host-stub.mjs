/**
 * Test-only stub for the host packages an extension imports.
 *
 * Pi supplies `@earendil-works/pi-coding-agent`, `@earendil-works/pi-ai`, `@earendil-works/pi-tui`
 * and `typebox` at runtime through its extension loader. Plain `node --test` resolves bare
 * specifiers from this directory, so the test maps those four to this stub instead of
 * duplicating a node_modules tree inside the tracked Pi configuration. Only module-load-time
 * surface is stubbed; tests exercise the extension's pure helpers and never call the tool.
 */
export const Type = new Proxy(
  {},
  { get: () => (...args) => ({ "~kind": "typebox-stub", args }) }
);

export const StringEnum = (values) => ({ "~kind": "string-enum-stub", values });

export class Text {
  constructor(...args) {
    this.args = args;
  }
}

export function truncateHead(value) {
  return { content: String(value), truncated: false };
}
