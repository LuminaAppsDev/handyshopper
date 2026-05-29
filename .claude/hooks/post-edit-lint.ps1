# .claude/hooks/post-edit-lint.ps1
# Automatically runs the appropriate linter after Claude edits a file.
# Triggered by the PostToolUse hook in settings.json.
#
# Covered: Python (.py), C/C++ (.c .h .cpp .hpp), Bash (.sh),
#          Go (.go), Rust (.rs), JavaScript/TypeScript (.js .jsx .ts .tsx),
#          Dart/Flutter (.dart), GDScript (.gd), C# (.cs)

param(
    [string]$File = ""
)

# Bail out early if no file or file doesn't exist
if ([string]::IsNullOrEmpty($File) -or -not (Test-Path $File -PathType Leaf)) {
    exit 0
}

$ext = [System.IO.Path]::GetExtension($File).TrimStart('.').ToLower()

function Test-Command {
    param([string]$cmd)
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        return $true
    }
    Write-Host "  (skipped: $cmd not found in PATH)"
    return $false
}

function Get-ModuleRoot {
    $root = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($root)) {
        return (Get-Location).Path
    }
    return $root.Trim()
}

switch ($ext) {
    "py" {
        Write-Host "-> Linting $File (Python)"
        if (Test-Command "flake8") {
            flake8 --max-line-length=88 --extend-ignore=E203,W503 $File
        }
        if (Test-Command "pylint") {
            pylint $File --fail-under=9.5
        }
    }

    { $_ -in "c","h" } {
        Write-Host "-> Checking $File (C)"
        if (Test-Command "gcc") {
            gcc -Wall -Wextra -Wpedantic -Wformat=2 -Wshadow -fsyntax-only $File 2>&1
        }
        if (Test-Command "cppcheck") {
            cppcheck --enable=all $File 2>&1
        }
    }

    { $_ -in "cpp","hpp","cxx","cc" } {
        Write-Host "-> Checking $File (C++)"
        if (Test-Command "g++") {
            g++ -Wall -Wextra -Wpedantic -std=c++17 -fsyntax-only $File 2>&1
        }
        if (Test-Command "cppcheck") {
            cppcheck --enable=all $File 2>&1
        }
    }

    { $_ -in "sh","bash" } {
        Write-Host "-> Linting $File (shellcheck)"
        if (Test-Command "shellcheck") {
            shellcheck -x $File
        }
        if (Test-Command "bash") {
            bash -n $File
        }
    }

    "go" {
        Write-Host "-> Linting $File (Go)"
        if (Test-Command "gofmt") {
            $gofmtOut = gofmt -l $File
            if (-not [string]::IsNullOrEmpty($gofmtOut)) {
                Write-Host "  gofmt: $File needs formatting (run: gofmt -w `"$File`")"
            }
        }
        if (Test-Command "go") {
            $moduleRoot = Get-ModuleRoot
            Push-Location $moduleRoot
            try { go vet ./... 2>&1 } finally { Pop-Location }
        }
    }

    "rs" {
        Write-Host "-> Linting $File (Rust/Clippy)"
        if (Test-Command "cargo") {
            $moduleRoot = Get-ModuleRoot
            Push-Location $moduleRoot
            try { cargo clippy -- -D warnings 2>&1 } finally { Pop-Location }
        }
    }

    { $_ -in "js","jsx","mjs","cjs" } {
        Write-Host "-> Linting $File (ESLint / JavaScript)"
        if (Test-Command "npx") {
            npx eslint $File --max-warnings=0 2>&1
        }
    }

    { $_ -in "ts","tsx" } {
        Write-Host "-> Linting $File (ESLint + tsc / TypeScript)"
        if (Test-Command "npx") {
            npx eslint $File --max-warnings=0 2>&1
        }
        $moduleRoot = Get-ModuleRoot
        $tsconfig = Join-Path $moduleRoot "tsconfig.json"
        if ((Test-Path $tsconfig) -and (Test-Command "npx")) {
            Push-Location $moduleRoot
            try { npx tsc --noEmit 2>&1 } finally { Pop-Location }
        }
    }

    "css" {
        Write-Host "-> Linting $File (stylelint)"
        if (Test-Command "stylelint") {
            stylelint $File 2>&1
        }
    }

    "dart" {
        Write-Host "-> Linting $File (Dart/Flutter)"
        if (Test-Command "dart") {
            dart analyze $File 2>&1
            dart format --set-exit-if-changed --output=none $File 2>&1
        }
    }

    "gd" {
        Write-Host "-> Linting $File (GDScript)"
        if (Test-Command "gdlint")   { gdlint $File 2>&1 }
        if (Test-Command "gdformat") { gdformat --check $File 2>&1 }
    }

    "cs" {
        Write-Host "-> Linting $File (C#)"
        if (Test-Command "dotnet") {
            $moduleRoot = Get-ModuleRoot
            Push-Location $moduleRoot
            try { dotnet build --no-restore -warnaserror 2>&1 } finally { Pop-Location }
        }
    }

    default {
        # Unknown file type — skip silently
    }
}