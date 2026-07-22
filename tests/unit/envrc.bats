#!/usr/bin/env bats

setup() {
    load "$BATS_LIB_PATH/bats-support/load"
    load "$BATS_LIB_PATH/bats-assert/load"

    TEST_TEMP="$(mktemp -d)"
    cp "$BATS_TEST_DIRNAME/../../.envrc" "$TEST_TEMP/.envrc"
    mkdir -p "$TEST_TEMP/nix/dev"
    touch "$TEST_TEMP/flake.nix"
    touch "$TEST_TEMP/dev.sh"
    touch "$TEST_TEMP/nix/packages.nix"
    touch "$TEST_TEMP/nix/dev/shell.nix"
}

teardown() {
    rm -rf "$TEST_TEMP"
}

@test "watches flake, dev hook, and recursive nix modules before using flake" {
    cd "$TEST_TEMP"

    watch_file() {
        printf 'watch %s\n' "$1"
    }
    use() {
        printf 'use %s\n' "$*"
    }
    export -f watch_file use

    run bash .envrc

    assert_success
    assert_line --index 0 "watch flake.nix"
    assert_line --index 1 "watch dev.sh"
    assert_line --index 2 "watch nix"
    assert_line "watch nix/packages.nix"
    assert_line "watch nix/dev/shell.nix"
    assert_line --index 5 "use flake"
}
