#!/usr/bin/env bats

setup() {
    load "$BATS_LIB_PATH/bats-support/load"
    load "$BATS_LIB_PATH/bats-assert/load"

    TEST_TEMP="$(mktemp -d)"
    SCANNER="$BATS_TEST_DIRNAME/../../scan-nix-no-embedded-shell.sh"
}

teardown() {
    rm -rf "$TEST_TEMP"
}

@test "exits 0 on file with no multi-line strings" {
    cat > "$TEST_TEMP/simple.nix" << 'NIXEOF'
{
  name = "test";
  version = "1.0";
}
NIXEOF
    run bash "$SCANNER" "$TEST_TEMP/simple.nix"
    assert_success
    assert_output ""
}

@test "exits 0 on file with empty multi-line string" {
    cat > "$TEST_TEMP/empty.nix" << 'NIXEOF'
{
  text = ''
  '';
}
NIXEOF
    run bash "$SCANNER" "$TEST_TEMP/empty.nix"
    assert_success
    assert_output ""
}

@test "exits 0 on multi-line string with non-shell content" {
    cat > "$TEST_TEMP/noShell.nix" << 'NIXEOF'
{
  text = ''
    some plain text
    another line
  '';
}
NIXEOF
    run bash "$SCANNER" "$TEST_TEMP/noShell.nix"
    assert_success
    assert_output ""
}

@test "detects export inside multi-line string" {
    cat > "$TEST_TEMP/export.nix" << 'NIXEOF'
{
  text = ''
    export FOO=bar
  '';
}
NIXEOF
    run bash "$SCANNER" "$TEST_TEMP/export.nix"
    assert_success
    assert_output --partial "export FOO=bar"
}

@test "detects echo inside multi-line string" {
    cat > "$TEST_TEMP/echo.nix" << 'NIXEOF'
{
  text = ''
    echo "hello world"
  '';
}
NIXEOF
    run bash "$SCANNER" "$TEST_TEMP/echo.nix"
    assert_success
    assert_output --partial "echo"
}

@test "detects set -euo pipefail inside multi-line string" {
    cat > "$TEST_TEMP/set.nix" << 'NIXEOF'
{
  text = ''
    set -euo pipefail
    echo "hello"
  '';
}
NIXEOF
    run bash "$SCANNER" "$TEST_TEMP/set.nix"
    assert_success
    assert_output --partial "set -euo pipefail"
    assert_output --partial "echo"
}

@test "detects function definition inside multi-line string" {
    cat > "$TEST_TEMP/func.nix" << 'NIXEOF'
{
  text = ''
    my_func() {
      true
    }
  '';
}
NIXEOF
    run bash "$SCANNER" "$TEST_TEMP/func.nix"
    assert_success
    assert_output --partial "my_func()"
}

@test "does not flag lines outside multi-line string" {
    cat > "$TEST_TEMP/outside.nix" << 'NIXEOF'
{
  # export FOO=bar
  name = "test";
}
NIXEOF
    run bash "$SCANNER" "$TEST_TEMP/outside.nix"
    assert_success
    assert_output ""
}

@test "prints line numbers in output" {
    cat > "$TEST_TEMP/lines.nix" << 'NIXEOF'
{
  text = ''
    export FOO=bar
  '';
}
NIXEOF
    run bash "$SCANNER" "$TEST_TEMP/lines.nix"
    assert_success
    # Line 3 has the export statement
    assert_output --partial "3:"
}

@test "detects if statement inside multi-line string" {
    cat > "$TEST_TEMP/ifstmt.nix" << 'NIXEOF'
{
  text = ''
    if [ -f /tmp/foo ]; then
      true
    fi
  '';
}
NIXEOF
    run bash "$SCANNER" "$TEST_TEMP/ifstmt.nix"
    assert_success
    assert_output --partial "if "
}

@test "detects for loop inside multi-line string" {
    cat > "$TEST_TEMP/forloop.nix" << 'NIXEOF'
{
  text = ''
    for x in 1 2 3; do
      true
    done
  '';
}
NIXEOF
    run bash "$SCANNER" "$TEST_TEMP/forloop.nix"
    assert_success
    assert_output --partial "for "
}

@test "detects multiple shell patterns" {
    cat > "$TEST_TEMP/multi.nix" << 'NIXEOF'
{
  text = ''
    export PATH="/usr/bin"
    echo "setting up"
    printf "done\n"
  '';
}
NIXEOF
    run bash "$SCANNER" "$TEST_TEMP/multi.nix"
    assert_success
    assert_output --partial "export"
    assert_output --partial "echo"
    assert_output --partial "printf"
}

@test "handles multiple multi-line string blocks" {
    cat > "$TEST_TEMP/twoBlocks.nix" << 'NIXEOF'
{
  text1 = ''
    plain text only
  '';
  text2 = ''
    export BAR=baz
  '';
}
NIXEOF
    run bash "$SCANNER" "$TEST_TEMP/twoBlocks.nix"
    assert_success
    assert_output --partial "export BAR=baz"
}

@test "does not flag first line of multi-line string block" {
    cat > "$TEST_TEMP/firstline.nix" << 'NIXEOF'
{
  text = ''
    plain content
  '';
}
NIXEOF
    run bash "$SCANNER" "$TEST_TEMP/firstline.nix"
    assert_success
    assert_output ""
}
