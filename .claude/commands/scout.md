# /scout — Map the Codebase

Invoke the project-scout subagent to get a token-efficient orientation of this project.

Use this at the start of a session when you need to understand a codebase you haven't
worked on recently, or when diving into a new repository.

## Behavior

Delegate to the `project-scout` agent:

```sh
Task(
  subagent_type="project-scout",
  description="Map the project structure and return a concise orientation summary",
  prompt="Scout the current working directory and return the Project Scout Report."
)
```

Present the returned summary to me directly.
Do not read additional files before or after — the scout report tells us what to read next.

## Optional: /scout $ARGUMENTS

If a subdirectory is specified (e.g., `/scout src/network`), pass it to the scout agent
to focus exploration on that subdirectory only.
