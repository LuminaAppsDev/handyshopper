# /review — Code Review Before Commit

Invoke the code-reviewer subagent to review the specified file or diff.

Usage:
  /review src/module.py       → review a specific file
  /review                     → review all files changed since last commit

## Behavior

1. If $ARGUMENTS is given, review that specific file.
2. If no arguments, get changed files: `git diff --name-only HEAD`

3. For each file, delegate to code-reviewer:

```sh
Task(
  subagent_type="code-reviewer",
  description="Review <filename> for quality issues",
  prompt="Review the file at <filepath> and return the full Code Review report."
)
```

4. Present all review reports.
5. If any report has a FAIL verdict, fix the blockers immediately.
6. After fixes, re-run `/review` on the affected files to confirm PASS.
