```
███████╗███╗   ███╗ █████╗  ██████╗███████╗     ███████╗███████╗██╗  ██╗
██╔════╝████╗ ████║██╔══██╗██╔════╝██╔════╝     ╚══███╔╝██╔════╝██║  ██║
█████╗  ██╔████╔██║███████║██║     ███████╗█████╗ ███╔╝ ███████╗███████║
██╔══╝  ██║╚██╔╝██║██╔══██║██║     ╚════██║╚════╝███╔╝  ╚════██║██╔══██║
███████╗██║ ╚═╝ ██║██║  ██║╚██████╗███████║     ███████╗███████║██║  ██║
╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝     ╚══════╝╚══════╝╚═╝  ╚═╝
```

[![CI](https://github.com/MenkeTechnologies/emacs-zsh/actions/workflows/ci.yml/badge.svg)](https://github.com/MenkeTechnologies/emacs-zsh/actions/workflows/ci.yml)
[![Docs](https://img.shields.io/badge/docs-online-blue.svg)](https://menketechnologies.github.io/emacs-zsh/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

### `[EMACS MAJOR MODE // NEON FONT-LOCK // REFLECTION-DRIVEN // LSP]`

> *"Open a `.zshrc`. The whole shell lights up — builtins, zshrs extensions, special vars, all from the binary's own reflection."*

Emacs major mode (`zshrs-mode`) for **[zshrs](https://github.com/MenkeTechnologies/zshrs)** — the first-ever Rust rewrite of the zsh shell. Font-lock driven by the binary's own reflection tables, filetype detection for zsh dotfiles and shebangs, shell-block-aware indentation, lint via `zshrs -n`, and LSP via `zshrs --lsp` (eglot + lsp-mode).

### [`Read the Docs`](https://menketechnologies.github.io/emacs-zsh/) &middot; [`Engineering Report`](https://menketechnologies.github.io/emacs-zsh/report.html) · [`zshrs`](https://github.com/MenkeTechnologies/zshrs) · [`emacs-stryke`](https://github.com/MenkeTechnologies/emacs-stryke)

---

## [0x00] OVERVIEW

**emacs-zsh** is the Emacs major mode for **zshrs**. It provides:

- **Filetype detection** — zsh dotfiles + `*.zsh` / theme files (`auto-mode-alist`) and `zsh` / `zshrs` shebangs (`interpreter-mode-alist`).
- **Syntax highlighting** — font-lock for the builtin surface, the zshrs-specific extension builtins (their own bold face), special variables, and keywords.
- **Indentation** — shell-block + brace-aware `indent-line-function` (`do`/`done`, `then`/`fi`, `case`/`esac`, `if`/`fi`).
- **Lint** — `M-x zshrs-lint-buffer` runs `zshrs -n` on the buffer.
- **Language server** — `zshrs --lsp` via **eglot** (built in since Emacs 29) and **lsp-mode**.

`zshrs-mode` is a separate mode you opt into; it does **not** clobber the built-in `sh-mode`.

The token tables in `zshrs-stdlib.el` are **generated** (`scripts/gen-stdlib.sh`) directly from the zshrs binary's own reflection tables (`zshrs --dump-reflection`), so they carry the real surface and never drift:

- **138 builtins** — `.builtins | keys[]` (word identifiers, minus keyword + extension names)
- **112 extensions** — `.extensions | keys[]` (the zshrs-specific additions)
- **245 special vars** — `.special_vars | keys[]` (word-identifier names)

Unlike emacs-stryke (10,450 builtins, hash tables to dodge the regexp-size limit), the zshrs surface is small enough that each category is a single precomputed `regexp-opt` alternation — no hash tables, no `"Regular expression too big"`.

Created by **[MenkeTechnologies](https://github.com/MenkeTechnologies)**.

---

## [0x01] FEATURE MATRIX

| Capability | Status |
|---|---|
| Filetype detection — dotfiles + `*.zsh` | **Implemented** — `auto-mode-alist` |
| Filetype detection — shebang | **Implemented** — `interpreter-mode-alist` (`zsh`, `zshrs`) |
| Syntax highlighting — builtins (137) | **Implemented** — `regexp-opt` from reflection |
| Syntax highlighting — extensions (113) | **Implemented** — own `zshrs-extension-face` (bold) |
| Syntax highlighting — special vars (245) | **Implemented** — `$NAME` + bare |
| Comments | **Implemented** — `#` line comments via syntax table |
| Indentation | **Implemented** — shell-block + brace-aware `zshrs-indent-line` |
| Lint | **Implemented** — `zshrs-lint-buffer` runs `zshrs -n` |
| Language server (eglot) | **Implemented** — `zshrs --lsp` |
| Language server (lsp-mode) | **Implemented** — registered client |
| Config | `zshrs-executable`, `zshrs-indent-offset` |

> The `zshrs` binary must be on `$PATH` for the language server and linter. Build **[zshrs](https://github.com/MenkeTechnologies/zshrs)**.

---

## [0x02] INSTALL

### Manual

```elisp
;; clone, then:
(add-to-list 'load-path "/path/to/emacs-zsh")
(require 'zshrs-mode)
```

### use-package + built-in VC

```elisp
(use-package zshrs-mode
  :mode ("\\.zsh\\'" "\\.zsh-theme\\'")
  :vc (:url "https://github.com/MenkeTechnologies/emacs-zsh"))
```

Open any zsh file — it lights up. With eglot, run `M-x eglot` to start the language server (or `(add-hook 'zshrs-mode-hook #'eglot-ensure)`).

---

## [0x03] SYNTAX // FACES

| Token group | Face |
|---|---|
| Control flow (`if` `for` `while` `case` `do` `done`) | `font-lock-keyword-face` |
| Declarations (`typeset` `local` `export` `readonly` `integer`) | `font-lock-keyword-face` |
| Extensions (113 zshrs-specific) | `zshrs-extension-face` (bold) |
| Builtins (137) | `font-lock-builtin-face` |
| Special variables (245) | `font-lock-variable-name-face` |
| Sigil variables (`$foo` `${...}` `$1`) | `font-lock-variable-name-face` |
| Punctuation sigils (`$?` `$@` `$#` `$$` `$!` `$*`) | `font-lock-constant-face` |
| Strings / comments | via syntax table |

---

## [0x04] LANGUAGE SERVER & LINT

`zshrs-mode` registers `zshrs --lsp` (stdio) for both clients (lazily, so neither is a hard dependency):

- **eglot** (Emacs 29+): `M-x eglot` in a zsh buffer.
- **lsp-mode**: `M-x lsp`.

`M-x zshrs-lint-buffer` pipes the buffer to `zshrs -n` and shows the diagnostics (exit 0 = clean). The executable is `zshrs-executable` (default `"zshrs"`); change it for a custom path.

---

## [0x05] REGENERATING THE TOKEN TABLES

After a zshrs upgrade, refresh the generated tables from the live binary:

```bash
./scripts/gen-stdlib.sh        # rewrites zshrs-stdlib.el
```

Verify the mode still fontifies correctly (byte-compile + face assertions):

```bash
emacs --batch -L . -l scripts/face-test.el
```

---

## [0x06] LAYOUT

```
emacs-zsh/
├── zshrs-mode.el           # major mode: syntax table, font-lock, indent, lint, LSP
├── zshrs-stdlib.el         # generated: builtin / extension / special-var regexps
├── scripts/gen-stdlib.sh   # regenerates zshrs-stdlib.el from `zshrs --dump-reflection`
├── scripts/gen-stdlib.el   # the Elisp generator (regexp-opt building)
└── scripts/face-test.el    # fontifies a sample and asserts faces
```

---

## [0x07] LICENSE

MIT © **[MenkeTechnologies](https://github.com/MenkeTechnologies)**
