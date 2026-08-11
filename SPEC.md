# SPEC — nix-lefthook-nix-no-embedded-shell

## §D — Description

A lefthook-compatible linter that detects embedded shell code inside Nix multi-line string blocks (`''...''`) in `.nix` files, enforcing the practice of extracting shell scripts into separate files and referencing them via `builtins.readFile`.

Packaged as a Nix flake with cross-platform support (Linux and macOS, amd64 and arm64), it integrates into pre-commit and pre-push hooks through lefthook, either as a remote config or a flake input.

Target users are Nix developers who want to maintain clean separation between Nix expressions and shell logic in their projects.

## §V — Invariants

1. The scanner (`scan-nix-no-embedded-shell.sh`) always exits 0 regardless of findings; it reports hits on stdout.
2. The wrapper (`lefthook-nix-no-embedded-shell`) exits 0 with no arguments.
3. The wrapper exits 0 when no `.nix` files appear in its arguments; non-`.nix` files are silently ignored.
4. Missing files are silently skipped (no error).
5. The wrapper exits 1 when any scanned `.nix` file contains embedded shell and is not in the allowlist.
6. The allowlist (`.nix-embedded-shell-allowlist`) supports blank lines and `#`-prefixed comments; both are ignored.
7. Allowlist paths are relative to the project root (git toplevel or `$NIX_NO_EMBEDDED_SHELL_ROOT`).
8. Every lefthook command has a `timeout` with a configurable environment variable and a default fallback.
9. All checks run in both `pre-commit` (on `{staged_files}`) and `pre-push` (on `{push_files}`).
10. The flake builds on all four supported systems: `aarch64-darwin`, `x86_64-darwin`, `x86_64-linux`, `aarch64-linux`.
11. Every shell script has a 1-to-1 bats unit test file under `tests/unit/`.
12. CI runs on both `ubuntu-latest` and `macos-latest`.
13. Shell scripts must not define functions; logic is split into separate scripts.
14. Scripts are invoked via `bash script.sh`, never `./script.sh`.
15. The `dev.sh` shell hook installs lefthook only when `.git/hooks/pre-commit` is absent.
16. The flake delegates outputs to `set-and-setting.lib.mkConsumerFlake`.

## §I — Interfaces

### CLI

| command | arguments | exit code | description |
|---|---|---|---|
| `lefthook-nix-no-embedded-shell` | `[file ...]` | 0 on pass, 1 on violation | Scan `.nix` files for embedded shell in `''` blocks |
| `bash scan-nix-no-embedded-shell.sh` | `<file>` | always 0 | Low-level scanner; prints four spaces followed by `<line>: <content>` per hit |

### Nix flake outputs

| output | type | description |
|---|---|---|
| `packages.<system>.default` | `writeShellApplication` | The `lefthook-nix-no-embedded-shell` wrapper binary |
| `packages.<system>.setting` | materialized setting | Sync-setting binary for config materialization |
| `devShells.<system>.default` | `mkShell` | Dev shell with all tools, lefthook wrappers, and bats |
| `devShells.<system>.agentic` | `mkShell` | Agentic dev shell (extends default) |
| `devShells.<system>.ruby` | `mkShell` | Ruby dev shell (extends default) |

### Config files

| file | format | purpose |
|---|---|---|
| `.nix-embedded-shell-allowlist` | plain text, one relative path per line | Grandfathered files to skip |
| `lefthook-remote.yml` | YAML (lefthook remote config) | Drop-in remote config for consumers |
| `lefthook.yml` | YAML (lefthook config) | Local hooks including remotes for 15 external check repos |
| `config/lefthook/file_size_limits.yml` | YAML | Per-extension file size limits (bytes) |
| `.yamllint.yml` | YAML | yamllint configuration |
| `.markdownlint.yml` | YAML | markdownlint configuration |
| `.editorconfig` | INI | Editor formatting rules (2-space indent, UTF-8, LF) |

### Environment variables

| variable | default | scope | description |
|---|---|---|---|
| `NIX_NO_EMBEDDED_SHELL_ROOT` | `git rev-parse --show-toplevel` or `pwd` | wrapper | Override project root for allowlist lookup |
| `LEFTHOOK_NIX_NO_EMBEDDED_SHELL_TIMEOUT` | `30` | lefthook | Timeout in seconds for the check |
| `LEFTHOOK_NIX_FLAKE_CHECK_TIMEOUT` | `60` | lefthook | Timeout for `nix flake check` |
| `SCANNER` | set by flake to nix store path | wrapper internals | Path to `scan-nix-no-embedded-shell.sh` |
| `BATS_LIB_PATH` | set by `dev.sh` shell hook | dev shell | Path to bats helper libraries |

### Shell patterns detected

The scanner flags lines in `''` blocks:

- `set -[eux]+`, `export`, `unset`, `echo`, `printf`, `exec`, `source`, `.`
- `if`, `elif`, `for`, `while`, `until`, `case`, `exit`, `return`, `local`
- Function definitions: `name() {`
- `#!/bin/bash`, `#!/usr/bin/env bash`

### Self-linting exception

`flake.nix` is intentionally listed in `.nix-embedded-shell-allowlist`. The
package wrapper is otherwise sourced from `lefthook-nix-no-embedded-shell.sh`,
but `pkgs.writeShellApplication` must first bootstrap its `SCANNER` environment
variable with the Nix store path of `scan-nix-no-embedded-shell.sh`:

```nix
text = ''
  SCANNER="${./scan-nix-no-embedded-shell.sh}"
''
+ builtins.readFile ./lefthook-nix-no-embedded-shell.sh;
```

The scanner does not currently flag a bare variable assignment such as this
one. Because allowlisting is file-granular, the narrow, repository-local entry
covers the `SCANNER` injection. It does not change scanner or wrapper behavior
for consumers.

## §T — Tasks

| status | id | goal |
|---|---|---|
| `x` | T1 | Expand `.envrc` to watch `flake.nix`, `dev.sh`, and nix modules per project direnv conventions |
| `x` | T2 | Add bats test for wrapper behavior when multiple files have violations (verify all are reported) |
| `x` | T3 | Add bats test for scanner handling of Nix string interpolation `''${}` inside multi-line blocks |
| `x` | T4 | Add `checks` flake output that runs `bats tests/unit/` so `nix flake check` validates tests |
| `x` | T5 | Align `actions/checkout` version in `update-pins.yml` (v4) with `ci.yml` (v6) |
| `x` | T6 | Add scanner detection of `source` and `.` (dot-source) commands as shell patterns |
| `x` | T7 | Add test for allowlist with entry that does not match the scanned file (non-matching allowlist entry) |
| `x` | T8 | Add detection of `#!/bin/bash` or `#!/usr/bin/env bash` shebang lines inside `''` blocks |
| `x` | T9 | Document the self-linting exception in SPEC (flake.nix bootstraps `SCANNER=` via a small embedded snippet) |

## §B — Bugs / Known Issues

1. **Scanner requires bash 4+**: `mapfile` and `declare -A` work in the Nix dev shell (bash 5), but not in stock macOS bash 3.2.

2. **Greedy `''` token matching**: Escapes (`''${`, `'''`) and multiple tokens per line can desynchronize `in_block`, producing false results.

3. **`.envrc` does not watch dependencies**: The `.envrc` contains only `use flake` and does not `watch_file` on `flake.nix`, `dev.sh`, or other nix modules. Changes to these files require manual `direnv reload`.

4. **Self-referential embedded shell**: `flake.nix` contains a small embedded shell snippet needed to inject the scanner path, as documented in [Self-linting exception](#self-linting-exception).

    This would trigger the check itself, but the flake is in the allowlist by convention (the check runs on staged files that are `.nix`).

5. **No `source`/`.` detection**: The scanner does not flag `source` or `.` (dot-source) commands, which are common shell patterns that would indicate embedded shell code.

6. **`actions/checkout` version skew**: `ci.yml` uses `actions/checkout@v6` while `update-pins.yml` uses `actions/checkout@v4`. This is a maintenance inconsistency, not a functional bug.

7. **`nix flake check` runs without `checks` output**: The lefthook config runs `nix flake check` but the flake only defines `packages` and `devShells` — no `checks` attribute. The command still validates derivation evaluation but does not run tests.

8. **Duplicate `default` attribute in `packages`**: Migration left a stale `default = pkgs.mkShell { … }` block inside `packages`, colliding with the real `default = pkgs.writeShellApplication { … }`. Also left `scannerScript` undefined.

    Fixed by removing the leftover `mkShell` block and adding a `let` binding for `scannerScript`.

9. **Unpinned flake inputs broke hook/package coherence**: `flake.lock` was ignored, so CI resolved a moving `set-and-setting` revision whose generated `lefthook.yml` referenced markdown and YAML wrappers absent from the dev-shell `PATH`; the dependency-graph check also had no lockfile to inspect.

    Fixed by tracking `flake.lock` and pinning a coherent dependency graph.

10. **Duplicated nixpkgs lock nodes**: `flake.lock` contained a second `nixpkgs-lock`/`nixpkgs` pair for `set-and-setting`, causing the lock-graph guardrail to fail.

    Fixed by reusing the root `nixpkgs-lock` node from `set-and-setting` and removing the duplicate nodes.

10. **Confirm app omitted fragment tools from `PATH`**: The confirmation app checked generated lefthook commands using only its core utility runtime, so markdown and YAML wrappers were reported missing even though the dev shell contained them.

    Fixed by adding the materialized fragment packages to the app runtime.

11. **2026-07-22 — Invalid SPEC indentation**: Three continuations used three spaces.

    Fixed by using four spaces.

12. **2026-07-22 — SC2016**: Single-quoted `${` match; fixed with escaped `$`.

13. **2026-07-25 — Stale workflow test**: `tests/unit/workflows.bats` still referenced `.github/workflows/update-pins.yml` after the workflow was dropped in the pin-refresh commit.

    Fixed by removing the obsolete test file.

14. **2026-07-28 — Flake lock exceeded its file-size budget**: The generated `flake.lock` grew to 120,413 bytes after the pin refresh, exceeding the 65,536-byte `.lock` limit.

    Fixed by raising only the `.lock` file-size budget to 131,072 bytes.

15. **2026-07-29 — `set-and-setting` pinned to version without `lib` output**: `nix flake update` bumped `set-and-setting` to rev `d2fa92cc` which temporarily removed its `lib` flake output, breaking all `set-and-setting.lib.*` calls in `flake.nix`. The resulting lock file also exceeded the 131,072-byte `.lock` limit.

    Fixed by updating `set-and-setting` to rev `92febe03` (which restored `lib`) and raising the `.lock` file-size budget to 524,288 bytes.

16. **2026-08-04 — `flake-manifest-check` failed: hand-rolled outputs body**: The `flake.nix` used a top-level `let` block with `supportedSystems`, `forAllSystems`, and `fragments` bindings, and constructed the outputs attrset inline. The `set-and-setting` `flake-manifest` check (strict mode) disallows top-level `let` expressions and non-manifest attributes in the outputs body.

    Fixed by delegating outputs to `set-and-setting.lib.mkConsumerFlake` with `extraPackages` and `extraChecks` for project-specific additions, and inlining `let` bindings that would trigger the `: let` pattern.
