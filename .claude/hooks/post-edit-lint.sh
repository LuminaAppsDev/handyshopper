#!/usr/bin/env bash
# .claude/hooks/post-edit-lint.sh
# Automatically runs the appropriate linter after Claude edits a file.
# Triggered by the PostToolUse hook in settings.json.
#
# Covered: Python (.py), C/C++ (.c .h .cpp .hpp), Bash (.sh),
#          Go (.go), Rust (.rs), JavaScript/TypeScript (.js .jsx .ts .tsx),
#          Dart/Flutter (.dart), GDScript (.gd), C# (.cs)

set -euo pipefail

FILE="${1:-}"

if [[ -z "$FILE" || ! -f "$FILE" ]]; then
    exit 0
fi

EXT="${FILE##*.}"

run_if_available() {
    local cmd="$1"
    if command -v "$cmd" &>/dev/null; then
        return 0
    else
        echo "  (skipped: $cmd not found in PATH)"
        return 1
    fi
}

case "$EXT" in
    py)
        echo "→ Linting $FILE (Python)"
        run_if_available flake8 && flake8 --max-line-length=88 --extend-ignore=E203,W503 "$FILE" || true
        run_if_available pylint && pylint "$FILE" --fail-under=9.5 || true
        ;;

    c|h)
        echo "→ Checking $FILE (C)"
        run_if_available gcc && gcc -Wall -Wextra -Wpedantic -Wformat=2 -Wshadow -fsyntax-only "$FILE" 2>&1 || true
        run_if_available cppcheck && cppcheck --enable=all "$FILE" 2>&1 || true
        ;;

    cpp|hpp|cxx|cc)
        echo "→ Checking $FILE (C++)"
        run_if_available g++ && g++ -Wall -Wextra -Wpedantic -std=c++17 -fsyntax-only "$FILE" 2>&1 || true
        run_if_available cppcheck && cppcheck --enable=all "$FILE" 2>&1 || true
        ;;

    sh|bash)
        echo "→ Linting $FILE (shellcheck)"
        run_if_available shellcheck && shellcheck -x "$FILE" || true
        bash -n "$FILE" || true
        ;;

    go)
        echo "→ Linting $FILE (Go)"
        # gofmt reports files that differ from canonical format
        run_if_available gofmt && {
            GOFMT_OUT=$(gofmt -l "$FILE")
            if [[ -n "$GOFMT_OUT" ]]; then
                echo "  gofmt: $FILE needs formatting (run: gofmt -w $FILE)"
            fi
        } || true
        # go vet needs the whole package, so run from the module root
        MODULE_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
        run_if_available go && (cd "$MODULE_ROOT" && go vet ./... 2>&1) || true
        ;;

    rs)
        echo "→ Linting $FILE (Rust/Clippy)"
        MODULE_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
        run_if_available cargo && (
            cd "$MODULE_ROOT"
            cargo clippy -- -D warnings 2>&1
        ) || true
        ;;

    js|jsx|mjs|cjs)
        echo "→ Linting $FILE (ESLint / JavaScript)"
        run_if_available npx && npx eslint "$FILE" --max-warnings=0 2>&1 || true
        ;;

    ts|tsx)
        echo "→ Linting $FILE (ESLint + tsc / TypeScript)"
        run_if_available npx && npx eslint "$FILE" --max-warnings=0 2>&1 || true
        # Full type-check needs the whole project
        MODULE_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
        [[ -f "$MODULE_ROOT/tsconfig.json" ]] && \
            (cd "$MODULE_ROOT" && npx tsc --noEmit 2>&1) || true
        ;;

    css)
        echo "→ Linting $FILE (stylelint)"
        run_if_available stylelint && stylelint "$FILE" 2>&1 || true
        ;;

    dart)
        echo "→ Linting $FILE (Dart/Flutter)"
        run_if_available dart && dart analyze "$FILE" 2>&1 || true
        run_if_available dart && dart format --set-exit-if-changed --output=none "$FILE" 2>&1 || true
        ;;

    gd)
        echo "→ Linting $FILE (GDScript)"
        run_if_available gdlint && gdlint "$FILE" 2>&1 || true
        run_if_available gdformat && gdformat --check "$FILE" 2>&1 || true
        ;;

    cs)
        echo "→ Linting $FILE (C#)"
        MODULE_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
        run_if_available dotnet && (
            cd "$MODULE_ROOT"
            dotnet build --no-restore -warnaserror 2>&1
        ) || true
        ;;

    *)
        # Unknown file type — skip silently
        ;;
esac
