# cratesmacs

`cratesmacs` is a small Emacs package that automatically checks for outdated Rust dependencies in your project's `Cargo.toml` file. It runs `cargo outdated` when you open `Cargo.toml` and annotates each dependency line with a green check mark (✓) if up to date, or a red ✗ if an update is available.

---

## Requirements

- Requires cargo-outdated subcommand: https://github.com/kbknapp/cargo-outdated

## Features

- Runs `cargo outdated` automatically on opening `Cargo.toml`.
- Inline annotation of dependencies showing their update status.
- Simple and lightweight with no Emacs package dependencies.
- Works in any Rust project with a `Cargo.toml` file.

---

## Installation

Clone or download this repository and add it to your Emacs `load-path`.

---

## Usage

Add the following to your Emacs config (`init.el`, `config.el`, or equivalent):

```elisp
;; cratesmacs
(use-package cratesmacs
  :load-path "/my/cloned/path/cratesmacs"
  :config
  (cratesmacs-mode 1))
```
