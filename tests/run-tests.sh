#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"

if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
	echo "Godot executable not found: $GODOT_BIN" >&2
	exit 127
fi

test_files="$(find "$PROJECT_ROOT/tests" -maxdepth 1 -type f -name 'test_*.gd' -print | sort)"
if [[ -z "$test_files" ]]; then
	echo "No Godot tests found under $PROJECT_ROOT/tests" >&2
	exit 1
fi

echo "=== importing project resources ==="
"$GODOT_BIN" --headless --path "$PROJECT_ROOT" --editor --quit

while IFS= read -r test_file; do
	[[ -n "$test_file" ]] || continue
	script_path="${test_file#"$PROJECT_ROOT"/}"
	echo "=== $script_path ==="
"$GODOT_BIN" --headless --path "$PROJECT_ROOT" --script "res://$script_path"
done <<< "$test_files"

echo "All Godot tests passed."
