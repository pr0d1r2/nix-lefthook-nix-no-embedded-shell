#!/usr/bin/env bats

setup() {
    load "$BATS_LIB_PATH/bats-support/load"
    load "$BATS_LIB_PATH/bats-assert/load"
    load "$BATS_LIB_PATH/bats-file/load"

    TEST_TEMP="$(mktemp -d)"
    export NIX_NO_EMBEDDED_SHELL_ROOT="$TEST_TEMP"
}

teardown() {
    rm -rf "$TEST_TEMP"
}

@test "exits 0 with no arguments" {
    run lefthook-nix-no-embedded-shell
    assert_success
}

@test "exits 0 when no .nix files in arguments" {
    touch "$TEST_TEMP/file.txt"
    run lefthook-nix-no-embedded-shell "$TEST_TEMP/file.txt"
    assert_success
}

@test "skips missing files silently" {
    run lefthook-nix-no-embedded-shell "/nonexistent/file.nix"
    assert_success
}

@test "accepts nix file without embedded shell" {
    cat > "$TEST_TEMP/good.nix" << 'NIXEOF'
{ pkgs }:
pkgs.writeShellApplication {
  name = "hello";
  text = builtins.readFile ./hello.sh;
}
NIXEOF
    run lefthook-nix-no-embedded-shell "$TEST_TEMP/good.nix"
    assert_success
}

@test "detects embedded shell in multi-line string" {
    cat > "$TEST_TEMP/bad.nix" << 'NIXEOF'
{ pkgs }:
pkgs.writeShellApplication {
  name = "hello";
  text = ''
    export FOO=bar
    echo "hello"
  '';
}
NIXEOF
    run lefthook-nix-no-embedded-shell "$TEST_TEMP/bad.nix"
    assert_failure
    assert_output --partial "embedded shell"
}

@test "respects allowlist" {
    cat > "$TEST_TEMP/bad.nix" << 'NIXEOF'
{ pkgs }:
pkgs.writeShellApplication {
  name = "hello";
  text = ''
    export FOO=bar
    echo "hello"
  '';
}
NIXEOF
    echo "bad.nix" > "$TEST_TEMP/.nix-embedded-shell-allowlist"
    run lefthook-nix-no-embedded-shell "$TEST_TEMP/bad.nix"
    assert_success
}

@test "allowlist ignores comments and blank lines" {
    cat > "$TEST_TEMP/bad.nix" << 'NIXEOF'
{ pkgs }:
pkgs.writeShellApplication {
  name = "hello";
  text = ''
    export FOO=bar
  '';
}
NIXEOF
    printf '# comment\n\nbad.nix\n' > "$TEST_TEMP/.nix-embedded-shell-allowlist"
    run lefthook-nix-no-embedded-shell "$TEST_TEMP/bad.nix"
    assert_success
}

@test "accepts nix file with simple string literals" {
    cat > "$TEST_TEMP/simple.nix" << 'NIXEOF'
{
  name = "test";
  version = "1.0";
}
NIXEOF
    run lefthook-nix-no-embedded-shell "$TEST_TEMP/simple.nix"
    assert_success
}

@test "filters non-.nix files from mixed input" {
    cat > "$TEST_TEMP/good.nix" << 'NIXEOF'
{ pkgs }:
pkgs.hello
NIXEOF
    touch "$TEST_TEMP/file.txt"
    run lefthook-nix-no-embedded-shell "$TEST_TEMP/good.nix" "$TEST_TEMP/file.txt"
    assert_success
}
