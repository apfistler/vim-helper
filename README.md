# Vim Editing Helpers

A collection of small, focused Vim helpers for working with **functions, blocks, indentation, comments, and explicit line ranges**.

The helpers are deliberately separated by responsibility:

* `function.vim` — function/method/subroutine operations
* `block.vim` — generic block operations
* `indent.vim` — indentation and reindentation
* `line.vim` — explicit line-oriented operations
* `style.vim` — comment-style detection

The design goal is to keep these operations independent. For example, changing Python function detection should not change how `Cb` determines a Python block.

---

# Command Summary

| Command |          Arguments | Purpose                                                |
| ------- | -----------------: | ------------------------------------------------------ |
| `:Cf`   |               none | Comment the entire function containing the cursor      |
| `:Uf`   |               none | Uncomment the commented function containing the cursor |
| `:Cb`   |               none | Comment the entire block containing the cursor         |
| `:Ub`   |               none | Uncomment the commented block containing the cursor    |
| `:Sf`   |         `[spaces]` | Reindent the current function                          |
| `:Sb`   |         `[spaces]` | Reindent the current block                             |
| `:Sd`   |         `[spaces]` | Reindent the entire document                           |
| `:Iss`  | `<spaces> <lines>` | Insert spaces at the beginning of explicit lines       |
| `:Cl`   |          `<lines>` | Comment an explicit number of lines                    |
| `:Ul`   |          `<lines>` | Uncomment an explicit number of lines                  |

---

# What Each Helper Does

## `function.vim`

Function-aware operations.

### `:Cf`

**Comment Function**

Finds the programming-language function surrounding the cursor and comments the **entire function**.

Example:

def calculate_metrics(data):
    total = sum(data)
    average = total / len(data)
    return average

With the cursor anywhere inside the function:

:Cf

becomes:

# def calculate_metrics(data):
#     total = sum(data)
#     average = total / len(data)
#     return average

The function detector is language-aware.

Supported detection includes:

* Python
* Shell
* Perl
* Vimscript
* C
* C++
* Java
* JavaScript
* TypeScript
* CSS
* PHP
* Go
* Rust
* Kotlin
* Swift
* Scala

Python functions are detected using indentation rather than braces.

---

### `:Uf`

**Uncomment Function**

Finds a previously commented function and removes the comments from the function.

:Uf

`Uf` intentionally does **not** simply call the normal function detector.

Once a function has been commented, its original syntax may no longer be visible to the normal language parser. Therefore `Uf` has a separate commented-function detection path.

This is particularly important for Python.

---

## `block.vim`

Generic programming-language block operations.

### `:Cb`

**Comment Block**

Finds the block containing the cursor and comments the **whole block**.

For Python, blocks are determined from indentation.

For brace-based languages, blocks are determined from `{ ... }`.

For shell, keyword blocks such as:

if ...
fi

for ...
done

while ...
done

case ...
esac

are supported.

Example Python:

if enabled:
    initialize()
    process()
    cleanup()

With the cursor inside the block:

:Cb

produces:

# if enabled:
#     initialize()
#     process()
#     cleanup()

---

### `:Ub`

**Uncomment Block**

Recovers a block that has previously been commented with `Cb`.

Like `Uf`, this uses a separate detection path because the original programming-language structure may no longer be visible after commenting.

For line-comment languages it searches for contiguous comment lines.

For C-style languages it searches for:

/*
...
*/

---

## `indent.vim`

Indentation and reindentation operations.

### `:Sf`

**Shift Function / Reindent Function**

Reindents the entire function containing the cursor.

:Sf

If an explicit indentation size is supplied:

:Sf 4

the function is reindented using four spaces per indentation level.

The indentation implementation temporarily changes the Vim indentation settings needed for the operation and restores the original Vim state afterward.

This means the helper should not permanently alter settings such as:

shiftwidth
softtabstop
tabstop
expandtab
autoindent
smartindent
cindent
indentexpr

---

### `:Sb`

**Shift Block / Reindent Block**

Reindents the block containing the cursor.

:Sb

or:

:Sb 4

Python blocks are determined using indentation.

Brace-based blocks use brace detection.

---

### `:Sd`

**Shift Document / Reindent Document**

Reindents the entire document.

:Sd

or:

:Sd 4

The original Vim indentation state is saved before the operation and restored afterward.

---

## `line.vim`

Explicit line-oriented operations.

These commands do **not** attempt to determine functions or blocks.

### `:Iss`

**Insert Spaces**

Syntax:

:Iss <spaces> <lines>

Example:

:Iss 4 3

Starting with:

one
two
three

produces:

    one
    two
    three

The operation starts at the current cursor line.

---

### `:Cl`

**Comment Lines**

Syntax:

:Cl <lines>

For example:

:Cl 5

comments the current line and the following four lines.

The comment style comes from `style.vim`.

Python:

# code

Vimscript:

" code

C-style languages use block comments.

---

### `:Ul`

**Uncomment Lines**

Syntax:

:Ul <lines>

For example:

:Ul 5

uncomments the current line and the following four lines.

---

# Function Reference

The public commands above are backed by smaller detection and implementation functions.

## `function.vim`

### Function detection

FindFunctionRange()
FindPythonFunction()
FindShellFunction()
FindPerlFunction()
FindVimFunction()
FindBraceFunction()
FindBraceRange()

### Comment operations

CommentFunction()
UncommentFunction()
FindCommentedFunctionRange()
FindCommentedPythonFunction()
FindCommentedShellFunction()
FindCommentedPerlFunction()
FindCommentedVimFunction()
FindCommentedCStyleFunction()
FindCommentedLineFunction()
FindCommentedBraceRange()

### Utility

FunctionUncommentedText()
GetCommentMarker()

---

# `block.vim` Function Reference

### Block detection

FindBlock()
FindPythonBlock()
FindShellBlock()
FindPerlBlock()
FindVimBlock()
FindBraceBlock()
FindOpeningBrace()
FindBraceRangeFromStart()
FindShellKeywordBlock()
FindCommentedBlock()
FindLineCommentedBlock()
FindCStyleCommentedBlock()

### Comment operations

CommentBlock()
UncommentBlock()
BlockCommentLines()
BlockUncommentLines()
BlockCommentCStyle()
BlockUncommentCStyle()

### Utility

BlockCommentStyle()
BlockStripStrings()

---

# `indent.vim` Function Reference

### Commands

ShiftFunction()
ShiftBlock()
ShiftDocument()

### Reindent engine

ReindentRange()
ParseSpaceArg()

### Python detection

FindIndentPythonFunction()
FindIndentPythonBlock()

### Brace detection

FindBraceRange()

---

# `line.vim` Function Reference

InsertSpaces()
CommentLines()
UncommentLines()

CommentLineRange()
UncommentLineRange()

CommentBlockRange()
UncommentBlockRange()

---

# `style.vim` Function Reference

GetCommentStyle()

This returns:

[comment_marker, comment_type]

Examples:

Python       -> ['#',  'line']
Shell        -> ['#',  'line']
Perl         -> ['#',  'line']
YAML         -> ['#',  'line']
Vimscript    -> ['"',  'line']
C            -> ['/*', 'block']
JavaScript   -> ['/*', 'block']
CSS          -> ['/*', 'block']

Unknown filetypes default to:

['#', 'line']

---

# Design Principles

## 1. Function and block detection are separate

A function is not necessarily the same thing as a generic block.

For example:

def process():
    if enabled:
        work()

The function is:

def process():
    if enabled:
        work()

while the inner block is:

if enabled:
    work()

Therefore:

:Cf

and:

:Cb

are intentionally different operations.

---

## 2. Commenting and uncommenting use different detection paths

Commenting can inspect the original programming-language structure.

After commenting, however, that structure may be hidden behind comment markers.

Therefore:

Cf -> FindFunctionRange()
Uf -> FindCommentedFunctionRange()

Cb -> FindBlock()
Ub -> FindCommentedBlock()

This separation is intentional.

---

## 3. Python is indentation-based

Python does not have `{}` delimiters.

Python function and block detection therefore uses indentation rather than brace matching.

For example:

def outer():
    if condition:
        do_something()
    do_something_else()

The indentation hierarchy itself defines the structure.

---

## 4. Vim state should be preserved

Operations that temporarily change Vim indentation settings should save the original values first.

For example:

shiftwidth
softtabstop
tabstop
expandtab
autoindent
smartindent
cindent
indentexpr

After the operation finishes, the previous state is restored.

The helpers should behave like temporary tools rather than permanently modifying the user's Vim configuration.

---

## 5. Explicit spacing versus implicit spacing

Indent commands accept an optional number of spaces.

For example:

:Sf

means:

> Reindent this function using the helper's normal indentation behavior.

Whereas:

:Sf 4

means:

> Explicitly use four spaces for indentation.

This distinction allows the helper to preserve the user's existing indentation structure when no explicit spacing was requested, while still allowing commands such as `:Sf 2` or `:Sf 4` to impose a specific indentation width.

---

# Typical Workflow

A common workflow is:

:Sf 4

Reindent the current function.

Then:

:Cf

Comment the function if it needs to be temporarily disabled.

Later:

:Uf

restore it.

For a smaller nested structure:

:Sb 4

followed by:

:Cb

can operate on the current block without affecting the surrounding function.

For explicit line operations:

:Iss 4 5
:Cl 5
:Ul 5

operate directly on the requested number of lines.

---

# Installation

Place the helper files in:

~/.vim/helper/

Expected structure:

~/.vim/
└── helper/
    ├── block.vim
    ├── function.vim
    ├── indent.vim
    ├── line.vim
    └── style.vim

Load them from your `.vimrc`:

source ~/.vim/helper/style.vim
source ~/.vim/helper/line.vim
source ~/.vim/helper/block.vim
source ~/.vim/helper/function.vim
source ~/.vim/helper/indent.vim

---

# Debugging

`indent.vim` contains a debug flag:

let g:indent_helper_debug = get(g:, 'indent_helper_debug', 0)

To enable debugging:

let g:indent_helper_debug = 1

To disable it:

let g:indent_helper_debug = 0

When enabled, indentation commands report information such as:

Cursor
Filetype
Target range
Requested spaces
Original Vim indentation settings
Range before reindent
Temporary indentation settings
Range after reindent
Vim state restoration

This is particularly useful when a language's indentation structure is not being detected as expected.

---

# Current Scope

The helpers are intentionally implemented as small Vimscript modules rather than one large monolithic script.

The major separation is:

                 Vim Editing Helpers
                         |
        +----------------+----------------+
        |                |                |
     Function          Block            Line
        |                |                |
      Cf/Uf            Cb/Ub          Cl/Ul/Iss
        |
     detection
        |
   Python / Shell /
   Perl / Vim / Brace

                    Indentation
                         |
                    Sf / Sb / Sd
                         |
              language-aware detection

The architecture is designed so that language-specific detection can be improved independently without changing the basic command interface.

