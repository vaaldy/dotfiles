; Override for nvim-treesitter's markdown injections query.
;
; NOTE: there is deliberately no `;; extends` line here. Without it this file
; REPLACES the plugin's query rather than appending to it, because replacing is
; the entire point. ~/.config/nvim comes before the plugin on 'runtimepath'.
;
; Why: nvim-treesitter's own queries/markdown/injections.scm resolves the code
; fence language through its custom directive `#set-lang-from-info-string!`,
; implemented in nvim-treesitter/lua/nvim-treesitter/query_predicates.lua:135:
;
;     local node = match[capture_id]
;     if not node then return end
;     local injection_alias = vim.treesitter.get_node_text(node, bufnr):lower()
;
; On Neovim 0.12 `match[capture_id]` is a TSNode[] list, not a single TSNode.
; A table is truthy, so the nil-guard passes, and get_node_text() then calls
; vim.treesitter.get_range() -> `node:range(true)` on a plain table:
;
;     .../lua/vim/treesitter.lua:197: attempt to call method 'range' (a nil value)
;
; It fires from the async parse coroutine, so it surfaces as a vim.schedule
; callback error on every cursor move in a markdown buffer with ``` blocks.
;
; Upstream declined it on both sides — neovim/neovim#39032 and
; nvim-treesitter/nvim-treesitter#8618 are both closed "not planned", and
; nvim-treesitter's master branch is in maintenance (main is the rewrite).
; See also nvim-treesitter#8636 for the underlying match[id] API change.
;
; This is Neovim 0.12.4's own $VIMRUNTIME/queries/markdown/injections.scm,
; which needs no custom directive: it captures @injection.language directly.
;
; TO REVERT: delete this file. If a future nvim-treesitter release fixes the
; directive, that is all that is required.

(fenced_code_block
  (info_string
    (language) @injection.language)
  (code_fence_content) @injection.content)

((html_block) @injection.content
  (#set! injection.language "html")
  (#set! injection.combined)
  (#set! injection.include-children))

((minus_metadata) @injection.content
  (#set! injection.language "yaml")
  (#offset! @injection.content 1 0 -1 0)
  (#set! injection.include-children))

((plus_metadata) @injection.content
  (#set! injection.language "toml")
  (#offset! @injection.content 1 0 -1 0)
  (#set! injection.include-children))

([
  (inline)
  (pipe_table_cell)
] @injection.content
  (#set! injection.language "markdown_inline"))
