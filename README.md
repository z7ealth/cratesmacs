# hexmacs

`hexmacs` is a small Emacs package that automatically checks for outdated Hex dependencies in your Elixir project's `mix.exs` file. It runs `mix hex.outdated` when you open `mix.exs` and annotates each dependency line with a green check mark (✓) if up to date or a red cross (✗) if an update is available.

---

## Features

- Runs `mix hex.outdated` automatically on opening `mix.exs`.
- Inline annotation of dependencies showing their update status.
- Simple and lightweight with no external dependencies.
- Works in any Elixir project with a `mix.exs` file.

---

## Installation

Clone or download this repository and add it to your Emacs `load-path`.

---

## Usage

Add the following to your Emacs config (`init.el`, `config.el`, or equivalent):

```elisp
;; hexmacs
(use-package hexmacs
  :load-path "/my/cloned/path/hexmacs"
  :config
  (hexmacs-mode 1))
