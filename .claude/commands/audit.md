# /audit — Full Quality Audit

Run a complete quality audit on the changed or specified files.

If $ARGUMENTS is provided, audit only those files.
If no arguments are given, audit all files changed since the last git commit.

## Steps

1. Determine scope:
   - With args: audit the files listed in $ARGUMENTS
   - Without args: run `git diff --name-only HEAD` to get changed files

2. For each file, apply the appropriate linter:
   - `.py` → `flake8`, `pylint`, `mypy`
   - `.c` / `.h` → `gcc -Wall -Wextra -Wpedantic` (compile check), `cppcheck`
   - `.sh` / `.bash` → `shellcheck`

3. Collect all output. Report in this format:

```sh
## Audit Report

### Python
<flake8 output or "✅ Clean">
<pylint score or "✅ Clean">

### C/C++
<gcc warnings or "✅ No warnings">

### Shell
<shellcheck output or "✅ Clean">

### Summary
- Files audited: N
- Issues found: N blockers, N warnings
- Status: ✅ READY TO COMMIT / ❌ FIX REQUIRED
```

4. If any blockers exist, fix them immediately and re-run the audit to confirm clean.
