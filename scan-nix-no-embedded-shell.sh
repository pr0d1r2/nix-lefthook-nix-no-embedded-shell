#!/usr/bin/env bash
# Scan a single .nix file for embedded shell inside '' blocks.
# Prints one line per hit to stdout. Exits 0 always.
set -euo pipefail

file="$1"

shell_pattern='^[[:space:]]*(set -[eux]+|export |unset |echo |printf |exec |if |elif |for |while |until |case |exit |return |local )'
func_pattern='^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\(\)[[:space:]]*\{'

mapfile -t lines <"$file"
n=${#lines[@]}
in_block=0
block_start=0
i=0
while [ "$i" -lt "$n" ]; do
    line="${lines[$i]}"
    rest="$line"
    while [[ "$rest" == *"''"* ]]; do
        rest="${rest#*\'\'}"
        if [ "$in_block" -eq 0 ]; then
            in_block=1
            block_start=$((i + 1))
        else
            in_block=0
        fi
    done
    if [ "$in_block" -eq 1 ] && [ $((i + 1)) -ne "$block_start" ]; then
        if [[ $line =~ $shell_pattern ]] ||
            [[ $line =~ $func_pattern ]]; then
            printf '    %s: %s\n' "$((i + 1))" "$line"
        fi
    fi
    i=$((i + 1))
done
