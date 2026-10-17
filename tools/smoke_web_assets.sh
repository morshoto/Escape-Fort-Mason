#!/usr/bin/env bash
set -euo pipefail

base_url="${1:-https://morshoto.github.io/Escape-Fort-Mason}"
base_url="${base_url%/}"

for asset in index.html index.js index.wasm index.pck; do
	curl \
		--connect-timeout 10 \
		--max-time 120 \
		--fail \
		--silent \
		--show-error \
		--location \
		--output /dev/null \
		"${base_url}/${asset}"
done

printf 'Web entry point and engine assets are reachable at %s\n' "$base_url"
