---
name: codebase-navigator
description: |
  Load this skill when starting work on an unfamiliar codebase, or when you need
  to understand the structure of a project before making changes. It teaches
  efficient, token-minimal exploration: understand the shape of a project first,
  then read only what you need.
---

# Skill: Codebase Navigator

## Goal
Understand a codebase's structure and purpose with the minimum number of tokens.
Never speculatively read files hoping to find something. Always have a reason before opening a file.

## Exploration Order (follow this sequence)

### Step 1 — Orientation (always do this first)
```bash
# Get directory shape without reading any file content
tree -L 3 --dirsfirst -I '__pycache__|node_modules|.git|*.pyc|build|dist'
```
Read only these files if they exist, in this order:
- `README.md` or `README.rst`
- `CLAUDE.md` or `AGENTS.md`
- Build/project descriptor: `pyproject.toml`, `setup.py`, `Makefile`, `CMakeLists.txt`, `package.json`, `Cargo.toml`

**After Step 1:** You should know: language(s), build system, rough module layout. Stop and report this before going further.

### Step 2 — Entry Points Only
Find the main entry points — don't read the whole file yet:
```bash
# Python: find main entry points
grep -rn "if __name__" --include="*.py" -l
grep -rn "def main" --include="*.py" -l

# C: find main()
grep -rn "^int main\|^void main" --include="*.c" -l

# Read only the top 40 lines of each entry point to understand its purpose
head -40 <entrypoint_file>
```

### Step 3 — Targeted Reading
Only read a full file when you have a specific reason:
- You're modifying it
- It's directly called by something you're working on
- You need to understand an interface

Use grep/ripgrep to find specific symbols before opening files:
```bash
# Find where a function is defined
grep -rn "def function_name\|function_name(" --include="*.py"

# Find all callers of a function
grep -rn "function_name(" --include="*.c" --include="*.h"

# Find a class definition
grep -rn "^class ClassName" --include="*.py"
```

### Step 4 — Interface Before Implementation
When understanding a module, read headers/interfaces before implementations:
- Read `.h` files before `.c` files
- Read `__init__.py` before submodules
- Read type stubs (`.pyi`) before `.py` implementations

## What NOT to Do
- Do NOT run `cat` on every file in a directory
- Do NOT read test files to understand production code (read production code directly)
- Do NOT read `__pycache__`, `build/`, `dist/`, `.git/` contents
- Do NOT re-read a file you've already read in the same session unless it changed

## Reporting Back
After navigation, always produce a brief summary:
```
## Codebase Summary
- **Language(s):** Python 3.11
- **Build:** Make + setuptools
- **Entry point:** src/main.py
- **Key modules:** [list with one-line purpose each]
- **Test framework:** pytest (tests/ directory)
- **Files read:** [count] — [total estimated tokens used]
```
