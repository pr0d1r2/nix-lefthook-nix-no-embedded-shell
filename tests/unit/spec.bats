#!/usr/bin/env bats

@test "documents the flake self-linting bootstrap exception" {
    run grep -F '### Self-linting exception' SPEC.md
    [ "$status" -eq 0 ]

    run grep -F 'SCANNER="${./scan-nix-no-embedded-shell.sh}"' SPEC.md
    [ "$status" -eq 0 ]

    run grep -F '`flake.nix` is intentionally listed in `.nix-embedded-shell-allowlist`' SPEC.md
    [ "$status" -eq 0 ]

    run grep -Fx 'flake.nix' .nix-embedded-shell-allowlist
    [ "$status" -eq 0 ]

    run grep -F 'SCANNER="${./scan-nix-no-embedded-shell.sh}"' flake.nix
    [ "$status" -eq 0 ]
}
