# Vim Editing Helpers

Small custom Vim commands for quickly indenting, commenting, and uncommenting consecutive lines.

## Installation

Place the helper file here:

```text
~/.vim/plugin/helpers.vim
```

Vim automatically loads files from the `~/.vim/plugin/` directory when Vim starts.

After creating or modifying the file, restart Vim.

---

# Commands

The helper provides three commands:

| Command | Purpose                                 |
| ------- | --------------------------------------- |
| `:iss`  | Insert spaces at the beginning of lines |
| `:cl`   | Comment out lines                       |
| `:uc`   | Uncomment lines                         |

All commands operate starting at the **current line**.

---

# `:iss` — Insert Spaces

```text
:iss <number_of_spaces> <number_of_lines>
```

Inserts the specified number of spaces at the beginning of the current line and the following lines.

### Example

```vim
:iss 4 3
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
:iss 4 1
```

Inserts four spaces at the beginning of the current line only.

---

# `:co` — Comment Out

```text
:cl<number_of_lines>
```

Comments out the current line and the following lines.

The current implementation uses:

```text
// 
```

as the comment prefix.

### Example

```vim
:cl3
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
:cl1
```

Comments out only the current line.

---

# `:uc` — Uncomment

```text
:uc <number_of_lines>
```

Removes a `//` comment from the beginning of the current line and the following lines.

### Example

```vim
:uc 3
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

The command preserves existing indentation.

For example:

```text
    // some code
```

becomes:

```text
    some code
```

---

# Typical Workflow

These commands are particularly useful when making quick changes to blocks of code.

## Indent a block

Place the cursor on the first line:

```vim
:iss 2 5
```

This inserts two spaces on the current line and the next four lines.

## Comment a block

```vim
:cl5
```

## Uncomment a block

```vim
:uc 5
```

---

# Important: Current Line + Following Lines

The line count represents the **total number of lines**, not the number of lines after the current line.

For example:

```vim
:iss 2 5
```

means:

```text
current line
+ 4 following lines
= 5 lines total
```

Likewise:

```vim
:cl10
```

means the current line plus the next nine lines.

---

# Helper Source

The current helper is:

```vim
" ~/.vim/plugin/helpers.vim

" ------------------------------------------------------------
" :iss <spaces> <lines>
" ------------------------------------------------------------

command! -nargs=+ iss call InsertSpaces(<f-args>)

function! InsertSpaces(spaces, lines)
  let indent = repeat(' ', a:spaces)
  execute '.,+' . (a:lines - 1) . 's/^/' . escape(indent, '\') . '/'
endfunction


" ------------------------------------------------------------
" :cl<lines>
" ------------------------------------------------------------

command! -nargs=1 clexecute '.,+' . (<args> - 1) . 'normal! I// '


" ------------------------------------------------------------
" :uc <lines>
" ------------------------------------------------------------

command! -nargs=1 uc execute '.,+' . (<args> - 1) . 's/^\(\s*\)\/\/\s\?/\1/'
```

---

# Future Improvements

Possible future additions include:

* Filetype-aware comment characters
* `:co` with no argument to comment one line
* `:uc` with no argument to uncomment one line
* Support for `#` comments in Bash, Python, and YAML
* Support for HTML comments
* Support for CSS comments
* Support for block comments
* Optional indentation using Vim's existing `shiftwidth`
* Support for visual selections

The goal is to keep these commands small and fast while eliminating repetitive editing operations.

---


# License
Vim Editing Helpers is licensed under the Apache License, Version 2.0.

Copyright 2026 Adam Fistler

[adam@adamfistler.com](mailto:adam@adamfistler.com)

[www.adamfistler.com](https://www.adamfistler.com)
