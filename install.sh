#!/bin/sh
# POSIX entry point for curl ... | sh; the actual installer requires Bash.
set -eu

# A checked-out copy can install directly without downloading again.
case "$0" in
    */install.sh|install.sh)
        source_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
        if [ -f "$source_dir/scripts/install.sh" ] && [ -f "$source_dir/omazed" ]; then
            exec bash "$source_dir/scripts/install.sh" "$@"
        fi
        ;;
esac

for cmd in curl bash mktemp; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        printf '[ERROR] Required command not found: %s\n' "$cmd" >&2
        exit 1
    fi
done

download_dir=$(mktemp -d "${TMPDIR:-/tmp}/omazed-install.XXXXXXXX")
trap 'rm -rf -- "$download_dir"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

base_url=https://raw.githubusercontent.com/huacnlee/omazed/main
printf '[INFO] Downloading Omazed...\n'
mkdir -p "$download_dir/scripts"
for file in scripts/install.sh omazed omazed-generator.sh omazed-font.sh omazed-theme.tpl; do
    curl --fail --silent --show-error --location --retry 3 \
        "$base_url/$file" --output "$download_dir/$file"
done

bash "$download_dir/scripts/install.sh" "$@"
