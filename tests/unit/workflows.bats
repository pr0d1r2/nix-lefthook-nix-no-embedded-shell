#!/usr/bin/env bats

@test "pin update workflow uses the current checkout action" {
    workflow=".github/workflows/update-pins.yml"

    run grep -F 'uses: actions/checkout@v6' "$workflow"
    [ "$status" -eq 0 ]

    run grep -F 'uses: actions/checkout@v4' "$workflow"
    [ "$status" -eq 1 ]
}
