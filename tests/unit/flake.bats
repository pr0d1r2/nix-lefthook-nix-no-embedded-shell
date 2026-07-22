#!/usr/bin/env bats

@test "flake unit check runs the complete bats unit suite" {
    run grep -F 'pkgs.runCommand "unit-tests"' flake.nix
    [ "$status" -eq 0 ]

    run grep -F 'bats tests/unit/' flake.nix
    [ "$status" -eq 0 ]
}
