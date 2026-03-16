---
name: code-quality
description: |
  Load this skill when running quality checks, reviewing code before commit,
  or setting up a new project's linting pipeline. Enforces strict standards
  for Python (PEP8), C/C++ (zero GCC/Clang warnings), Bash (shellcheck),
  Go (go vet + staticcheck), Rust (clippy), JavaScript/TypeScript (eslint),
  Flutter/Dart (dart analyze + very_good_analysis), and Godot (gdlint/dotnet).
---

# Skill: Code Quality Enforcer

---

## Python Quality Pipeline
Run these in order. All must pass with zero output before code is acceptable.

```bash
# 1. Format (auto-fix)
black .
isort .

# 2. Style check (PEP8 — must be zero warnings)
flake8 --max-line-length=88 --extend-ignore=E203,W503 .

# 3. Static analysis (must score >= 9.5/10)
pylint **/*.py --fail-under=9.5

# 4. Type checking
mypy . --strict
```

### Key PEP8 Rules
- Max line length: 88 (black default)
- Two blank lines before/after top-level functions and classes
- Imports grouped: stdlib → third-party → local, separated by blank lines
- No trailing whitespace; files end with a single newline
- All functions: type hints + docstrings

---

## C / C++ Quality Pipeline

```bash
# 1. Compile with strict warnings — must produce ZERO warnings
gcc -Wall -Wextra -Wpedantic -Wformat=2 -Wshadow -o /dev/null file.c
g++ -Wall -Wextra -Wpedantic -std=c++17 -o /dev/null file.cpp

# 2. Static analysis
cppcheck --enable=all --error-exitcode=1 .

# 3. Clang-tidy (if available)
clang-tidy file.c -- -Wall -Wextra
```

### Zero-Warning Rules for C
- Always check return values of malloc, fopen, etc.
- Initialize all variables at declaration
- No implicit int or implicit function declarations
- Unused parameters: `__attribute__((unused))` or cast to `(void)`
- Explicit casts when mixing signed/unsigned arithmetic
- Switch statements always have a `default:` case

---

## Bash Quality Pipeline

```bash
shellcheck -x script.sh
bash -n script.sh   # syntax check
```

Every script must begin with:
```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
```

### Bash Standards
- Always quote variables: `"$var"` not `$var`
- Never use `ls` programmatically — use `find` or globs
- Check exit codes where relevant
- Prefer `[[ ]]` over `[ ]` for conditionals

---

## Go Quality Pipeline

```bash
# 1. Format (auto-fix — Go is strict about formatting)
gofmt -w .
goimports -w .        # also fixes imports

# 2. Vet (built-in static analysis — must be clean)
go vet ./...

# 3. Staticcheck (must be clean)
# Install: go install honnef.co/go/tools/cmd/staticcheck@latest
staticcheck ./...

# 4. Tests
go test ./... -race   # always run with race detector

# 5. Build check
go build ./...
```

Preferred: use `golangci-lint` when available — it bundles all of the above:
```bash
golangci-lint run ./...
```

### Go Standards
- All exported functions, types, and variables must have doc comments
- Error values must be handled — never `_` an error silently
- Use `errors.Is` / `errors.As` for error comparison, not string matching
- Goroutines must have a clear owner responsible for their lifecycle
- Avoid `init()` unless absolutely necessary
- Package names: lowercase, single word, no underscores

---

## Rust Quality Pipeline

```bash
# 1. Format (auto-fix)
cargo fmt

# 2. Clippy — treat warnings as errors, no exceptions
cargo clippy -- -D warnings -D clippy::pedantic -D clippy::nursery

# 3. Tests
cargo test

# 4. Build both profiles (release can surface different warnings)
cargo build
cargo build --release

# 5. Dependency audit
# Install: cargo install cargo-audit
cargo audit
```

### Rust Standards
- All public items must have doc comments (`///`)
- Prefer `?` operator over `.unwrap()` or `.expect()` in library code
- `.unwrap()` only acceptable in tests, or with a comment proving it can't fail
- `unsafe` blocks require a comment explaining the invariants being upheld
- Suppress a clippy lint only with `#[allow(...)]` + an explanatory comment
- Error types should implement `std::error::Error`

---

## JavaScript / TypeScript Quality Pipeline

```bash
# 1. Format (auto-fix)
npx prettier --write .

# 2. Lint — zero errors AND zero warnings
npx eslint . --ext .js,.jsx,.ts,.tsx --max-warnings=0

# 3. Type check (TypeScript projects)
npx tsc --noEmit

# 4. Tests
npm test
```

### Recommended ESLint Config (`.eslintrc.json`)
```json
{
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/strict",
    "plugin:@typescript-eslint/stylistic"
  ],
  "rules": {
    "no-console": "warn",
    "no-unused-vars": "error",
    "eqeqeq": ["error", "always"],
    "prefer-const": "error",
    "no-var": "error"
  }
}
```

### JavaScript/TypeScript Standards
- `const` by default; `let` only when reassignment is needed; never `var`
- Always use `===` / `!==`, never `==` / `!=`
- No `console.log` in committed code — use a structured logger
- Async functions: always `await` or explicitly chain `.catch()`
- TypeScript: `strict: true` in `tsconfig.json`; no `any` without a justifying comment

---

## Flutter / Dart Quality Pipeline

```bash
# 1. Format (auto-fix — canonical style, non-negotiable)
dart format .

# 2. Static analysis — must be zero issues
dart analyze .

# 3. Tests
flutter test
```

### Recommended `analysis_options.yaml`

```yaml
include: package:very_good_analysis/analysis_options.yaml
# or at minimum: package:flutter_lints/flutter.yaml

analyzer:
  strict-casts: true
  strict-inference: true
  strict-raw-types: true
  errors:
    missing_return: error
    dead_code: warning

linter:
  rules:
    - always_declare_return_types
    - prefer_final_locals
    - avoid_dynamic_calls
    - unawaited_futures
    - prefer_const_constructors
    - prefer_const_declarations
```

### Flutter/Dart Standards

- No implicit `dynamic` — all public APIs have explicit type annotations
- `const` constructors wherever possible
- All `Future`s are `await`ed or explicitly handled — no fire-and-forget
- No `print()` in committed code — use a logging framework
- `dispose()` called for all controllers, streams, and animation controllers
- Widget `build()` methods stay focused — extract sub-widgets for readability

---

## Godot (GDScript) Quality Pipeline

```bash
# 1. Format (auto-fix)
# Install: pip install gdtoolkit
gdformat .

# 2. Lint — must be zero warnings
gdlint .
```

### Recommended `.gdlintrc`

```ini
[general]
max-line-length = 100
tab-size = 4

[rules]
function-name = snake_case
class-name = PascalCase
max-function-lines = 40
```

### GDScript Standards

- Naming: `snake_case` for functions/variables, `PascalCase` for classes/nodes
- All editor warnings enabled in Project Settings > Debug > GDScript
- No `@warning_ignore` without a justifying comment
- Use `@onready` or `@export` for node references — no hardcoded paths
- Signals connected and disconnected properly (no dangling connections)
- Keep `_ready()`, `_process()`, `_physics_process()` short — delegate to focused functions

---

## Godot (C#) Quality Pipeline

```bash
# 1. Format (auto-fix)
dotnet format

# 2. Build with warnings as errors
dotnet build -warnaserror

# 3. Tests
dotnet test
```

### Godot C# Standards

- `TreatWarningsAsErrors` enabled in `.csproj` — zero warnings
- Roslyn analyzers and/or StyleCop enabled
- Naming: `PascalCase` for public members, `_camelCase` for private fields
- No `GD.Print()` in committed code
- All `IDisposable` resources properly disposed
- Signal connections use typed delegates, not string-based wiring

---

## Universal Pre-Commit Checklist

Before marking any task as done:
- [ ] Formatter passed (black / gofmt / cargo fmt / prettier / dart format / gdformat / dotnet format)
- [ ] Linter clean with zero warnings (flake8+pylint / go vet+staticcheck / clippy -D warnings / eslint --max-warnings=0 / dart analyze / gdlint / dotnet build -warnaserror)
- [ ] Compiler/type-checker clean (mypy --strict / tsc --noEmit / cargo build / gcc -Wall -Wextra -Wpedantic)
- [ ] Tests pass (pytest / go test -race / cargo test / npm test / flutter test / dotnet test)
- [ ] No debug prints left in code
- [ ] No hardcoded paths, IPs, or credentials
- [ ] All new public functions/types have documentation comments
