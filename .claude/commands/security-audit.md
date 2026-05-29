# /security-audit — Security Vulnerability Scan

Invoke the security-auditor subagent to scan the specified file or diff for vulnerabilities.

Usage:
  /security-audit src/module.py   → audit a specific file
  /security-audit                 → audit all files changed since last commit
  /security-audit all             → audit all tracked source files in the repo

## Behavior

1. If $ARGUMENTS is `all`, get all tracked source files:
   `git ls-files -- '*.py' '*.c' '*.h' '*.cpp' '*.hpp' '*.go' '*.rs' '*.js' '*.ts' '*.jsx' '*.tsx' '*.php' '*.dart' '*.gd' '*.cs' '*.sh' '*.bash'`
   Exclude vendored/generated directories (e.g. `vendor/`, `node_modules/`, `build/`, `.dart_tool/`).
2. If $ARGUMENTS is a file path, audit that specific file.
3. If no arguments, get changed files: `git diff --name-only HEAD`

4. For each file, delegate to security-auditor:

```sh
Task(
  subagent_type="security-auditor",
  description="Security audit <filename> for vulnerabilities",
  prompt="Audit the file at <filepath> and return the full Security Audit report."
)
```

1. Present all audit reports.
2. If any report has a VULNERABLE verdict, fix the critical/high findings immediately.
3. After fixes, re-run `/security-audit` on the affected files to confirm SECURE.