#!/usr/bin/env bats

setup() {
  CI_YML="$BATS_TEST_DIRNAME/../../.github/workflows/ci.yml"
}

@test "every uses reference is pinned to a full 40-character commit SHA" {
  run grep -E '^\s*(-\s+)?uses:' "$CI_YML"
  [ "$status" -eq 0 ]
  while IFS= read -r line; do
    [[ "$line" =~ @[0-9a-f]{40}$ ]]
  done <<<"$output"
}
