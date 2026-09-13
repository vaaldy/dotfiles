# Handoff: Highlight Tool Actions in Compact Transcript

## Repository

- Upstream: **[`avhagedorn/pi-compact-transcript`](https://github.com/avhagedorn/pi-compact-transcript)**
- Upstream HEAD inspected: `58b619ad26924f0253edcd9c1cf9fa06bfaa1928`
- Published package inspected: `pi-compact-transcript@0.9.0`
- Local target: `/Users/rda001/Documents/pi-compact-transcript-highlighted`
- Intended destination: a new private GitHub repository preserving upstream history; it will be a private copy, not a GitHub fork of the public repository.

Do not substitute `pi-tool-display` or layer another tool-rendering extension over this package.

## Goal

Keep all current Compact Transcript behavior while making the action in each compact tool row visually distinct.

Desired shape:

```text
◆ 4× read src/foo.ts {12 lines · 8s}
     ^^^^ highlighted with the theme's tool-title style
```

Actions include `read`, `grep`, `find`, `ls`, `edit`, `write`, the bash `$`, and the displayed name of custom tools.

## Current behavior

The implementation is in:

```text
extensions/compact-transcript.ts
```

`compactToolLine()` currently renders almost the complete compact row with one color:

```ts
const color = info.isError ? "muted" : "dim";
// ...
return marker + theme.fg(color, plainLine);
```

Diff statistics already receive separate `toolDiffAdded`, `toolDiffRemoved`, and `toolDiffContext` colors through `colorDiffStats()`. The status diamond already uses success/error/dim colors through `statusMarker()`.

## Required change

Make the smallest change in `compactToolLine()` or a tiny nearby helper:

- Keep the status marker unchanged.
- Keep burst prefixes such as `4× ` dim/muted.
- Render only the action token with `theme.fg("toolTitle", theme.bold(action))`.
- Keep paths, arguments, counts, durations, and other details dim/muted as today.
- Preserve the existing colored diff statistics.
- Use theme tokens; do not hardcode ANSI colors.
- Preserve ANSI-safe width truncation and narrow-terminal behavior.
- Preserve custom-tool previews and failed-tool visibility.
- Do not change tool execution, model context, transcript persistence, expansion, or coalescing behavior.

Do not add a general styling framework or new dependency. A small renderer helper is acceptable only if it prevents duplicated slicing logic.

## Theme integration

The fork should use Pi's existing `toolTitle` token. Color selection remains outside this package.

The current tracked theme is:

```text
/Users/rda001/Documents/term-agentic/pi/themes/tokyo-night.json
```

It currently maps `toolTitle` to `text`. After the fork works, the term-agentic repository can independently change that mapping to `purple`, `blue`, or another existing theme variable. Do not edit the user's theme from this repository.

## Acceptance checks

Run the local extension in isolation so the globally installed npm copy does not also patch the transcript:

```bash
cd /Users/rda001/Documents/pi-compact-transcript-highlighted
pi --no-extensions -e ./extensions/compact-transcript.ts
```

Verify interactively:

1. `read`, `grep`, `find`, `ls`, `edit`, and `write` action tokens use `toolTitle` and bold.
2. Bash highlights `$` without coloring the whole command.
3. Paths and arguments remain dim.
4. Consecutive matching tools still coalesce, and `4× ` remains dim.
5. Edit/write `{+N/-N}` statistics retain green/red coloring.
6. Failed rows remain visible and retain their red failure marker.
7. `Ctrl+O` still shows Pi's original expanded renderer.
8. Long rows remain one line and truncate correctly in a narrow terminal.
9. `/compact-transcript off` and `on` still rerender existing rows correctly.
10. No second renderer package is required.

The upstream repository currently has no test script. Add only a small focused test if the rendering logic can be extracted and tested without introducing a framework; otherwise document the manual checks in the final report.

## Private repository and Pi installation

After committing and pushing the private repository, replace the public npm installation rather than loading both:

```bash
pi remove npm:pi-compact-transcript
pi install git:git@github.com:<github-user>/pi-compact-transcript-highlighted.git
```

Alternatively, test the working tree directly before pushing:

```bash
pi remove npm:pi-compact-transcript
pi install /Users/rda001/Documents/pi-compact-transcript-highlighted
```

Then run `/reload` or restart Pi. Never keep the public package and private copy enabled simultaneously.

## Out of scope

- Hover previews or popup overlays
- Arbitrary assistant Markdown/code-block folding
- Footer/statusline changes
- New configuration UI
- New color settings inside Compact Transcript
- Tool execution or context compaction changes
- Integration with tmux, subagents, or `pi-tool-display`
