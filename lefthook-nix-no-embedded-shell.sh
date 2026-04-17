# shellcheck shell=bash
# Lefthook-compatible nix no-embedded-shell check.
# NOTE: sourced by writeShellApplication — no shebang or set needed.
# SCANNER is set by flake.nix to the nix store path of scan-nix-no-embedded-shell.sh.

if [ $# -eq 0 ]; then
    exit 0
fi

ROOT="${NIX_NO_EMBEDDED_SHELL_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
ALLOWLIST_FILE="$ROOT/.nix-embedded-shell-allowlist"

declare -A allow=()
if [ -f "$ALLOWLIST_FILE" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            '' | '#'*) continue ;;
        esac
        allow["$line"]=1
    done <"$ALLOWLIST_FILE"
fi

failed=0
for f in "$@"; do
    [ -f "$f" ] || continue
    case "$f" in
        *.nix) ;;
        *) continue ;;
    esac

    rel="${f#"$ROOT"/}"
    if [ -n "${allow[$rel]:-}" ]; then
        continue
    fi

    hits="$(bash "$SCANNER" "$f")"
    if [ -n "$hits" ]; then
        {
            echo "lefthook-nix-no-embedded-shell: $rel has embedded shell inside '' block:"
            printf '%s\n' "$hits"
        } >&2
        failed=1
    fi
done

if [ "$failed" -ne 0 ]; then
    {
        echo
        echo "Fix: extract the shell into scripts/ and reference via builtins.readFile"
        echo "     or add the path to .nix-embedded-shell-allowlist."
    } >&2
fi
exit "$failed"
