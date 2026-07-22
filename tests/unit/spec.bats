#!/usr/bin/env bats

@test "documents the flake self-linting bootstrap exception" {
    run grep -F '### Self-linting exception' SPEC.md
    [ "$status" -eq 0 ]

    run grep -F 'SCANNER="${scannerScript}"' SPEC.md
    [ "$status" -eq 0 ]

    run grep -F '`flake.nix` is intentionally listed in `.nix-embedded-shell-allowlist`' SPEC.md
    [ "$status" -eq 0 ]
}
