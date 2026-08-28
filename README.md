# Vim Editing Helpers

Small custom Vim commands for quickly inserting indentation, commenting, and uncommenting consecutive lines.

The helpers are designed for simple, repetitive editing tasks where using Vim's more elaborate range and substitution syntax would be unnecessary overhead.

## Features

The plugin provides three commands:

| Command | Purpose                                 |
| ------- | --------------------------------------- |
| `:Iss`  | Insert spaces at the beginning of lines |
| `:Cl`   | Comment out lines                       |
| `:Uc`   | Uncomment lines                         |

The commands operate starting at the **current line** and accept a number of lines to process.

---

# Installation

The helper can be installed using the included installer:

```bash
./place-helper.sh
```

The installer:

* Checks that Vim or a compatible Vim implementation is installed.
* Detects supported Vim implementations.
* Creates the user's Vim plugin directory if necessary.
* Installs the helper as:

```text
~/.vim/helper.vim
```

After installation, restart Vim.

The helper can also be loaded manually:

```vim
source ~/.vim/helper.vim
```

---

# Commands

## `:Iss` — Insert Spaces

```text
:Iss <number_of_spaces> <number_of_lines>
```

Inserts the specified number of spaces at the beginning of the current line and the following lines.

### Example

```vim
:Iss 4 3
```

Before:

```text
one
two
three
four
```

After:

```text
    one
    two
    three
four
```

The second argument specifies the **total number of lines affected**, including the current line.

### One line

```vim
:Iss 4 1
```

Only the current line is modified.

---

# `:Cl` — Comment Out

```text
:Cl <number_of_lines>
```

Comments out the current line and the following lines.

The helper uses `// ` as the comment prefix.

### Example

```vim
:Cl 3
```

Before:

```text
first line
second line
third line
fourth line
```

After:

```text
// first line
// second line
// third line
fourth line
```

The argument specifies the **total number of lines affected**.

### One line

```vim
:Cl 1
```

Comments out only the current line.

---

# `:Uc` — Uncomment

```text
:Uc <number_of_lines>
```

Removes a `//` comment from the beginning of the current line and the following lines.

### Example

```vim
:Uc 3
```

Before:

```text
// first line
// second line
// third line
fourth line
```

After:

```text
first line
second line
third line
fourth line
```

Existing indentation is preserved.

For example:

```text
    // some code
```

becomes:

```text
    some code
```

---

# Line Counting

All three commands interpret the line count as the **total number of lines affected**.

For example:

```vim
:Iss 2 5
```

means:

```text
current line
+ 4 following lines
= 5 lines total
```

Likewise:

```vim
:Cl 10
```

means:

```text
current line
+ 9 following lines
= 10 lines total
```

This makes the commands easy to use while moving through a file: put the cursor on the first line of the block and specify how many lines should be affected.

---

# Typical Workflow

## Indent a block

Place the cursor on the first line and run:

```vim
:Iss 2 5
```

This inserts two spaces on five consecutive lines.

## Comment a block

```vim
:Cl 5
```

This comments the current line and the next four lines.

## Uncomment a block

```vim
:Uc 5
```

This removes the `//` comment prefix from five consecutive lines.

---

# Why the Commands Use Uppercase Internally

Vim has a restriction on user-defined command names: custom `:command` definitions must begin with an uppercase letter.

Therefore the helper internally defines commands using uppercase names:

```text
Iss
Cl
Uc
```

The plugin then provides lowercase command abbreviations so the convenient commands can still be used:

```text
:Iss
:Cl
:Uc
```

This allows the short, natural lowercase interface without violating Vim's user-command naming rules.

---

# Helper Source

The installed helper is:

```text
~/.vim/helper.vim
```

The basic implementation is:

```vim
" ~/.vim/helper.vim
"
" Small editing helpers


" ------------------------------------------------------------
" :Iss <spaces> <lines>
"
" Insert <spaces> spaces at the beginning of the current line
" and the following <lines>-1 lines.
" ------------------------------------------------------------

command! -nargs=+ Iss call InsertSpaces(<f-args>)

function! InsertSpaces(spaces, lines)
  let indent = repeat(' ', a:spaces)
  execute '.,+' . (a:lines - 1) . 's/^/' . escape(indent, '\') . '/'
endfunction

command! -nargs=+ iss Iss


" ------------------------------------------------------------
" :Cl <lines>
"
" Comment out the current line and the following <lines>-1
" lines using //.
" ------------------------------------------------------------

command! -nargs=1 Cl execute '.,+' . (<args> - 1) . 'normal! I// '

command! -nargs=1 cl Cl


" ------------------------------------------------------------
" :Uc <lines>
"
" Uncomment the current line and the following <lines>-1
" lines by removing a leading // comment.
" ------------------------------------------------------------

command! -nargs=1 Uc execute '.,+' . (<args> - 1) . 's/^\(\s*\)\/\/\s\?/\1/'

command! -nargs=1 uc Uc
```

---

# File Location

The repository contains the helper and installer:

```text
vim-helper/
├── helper.vim
├── place-helper.sh
├── README.md
└── LICENSE
```

The installer places the helper at:

```text
~/.vim/helper.vim
```

---

# Compatibility

The helper is intended for Vim-compatible editors that support Vimscript user commands.

The installer checks for available Vim implementations before installing the helper.

---

# Future Improvements

Possible future additions include:

* Filetype-aware comment characters
* `:Iss` support for Vim's existing indentation settings
* Support for `#` comments in Bash, Python, and YAML
* Support for HTML comments
* Support for CSS comments
* Support for block comments
* Visual-selection support
* Additional small editing helpers

The goal is to keep the commands **small, predictable, and fast** while eliminating repetitive editing operations.

---

# License

Vim Editing Helpers is licensed under the Apache License, Version 2.0.

Copyright 2026 Adam Fistler

[adam@adamfistler.com](mailto:adam@adamfistler.com)

[www.adamfistler.com](https://www.adamfistler.com)

