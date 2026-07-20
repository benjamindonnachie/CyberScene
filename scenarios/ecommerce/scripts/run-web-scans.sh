#!/usr/bin/env bash
set -euo pipefail
target_url=${TARGET_URL:-http://shop.example.org}
execute=false
[[ ${1:-} == --execute ]] && execute=true
commands=(
  "nikto -host $target_url"
  "skipfish -o results/skipfish $target_url"
  "whatweb -a 3 $target_url"
)
printf '%s\n' "Web scan target: $target_url"
if $execute; then
  mkdir -p results
  command -v nikto >/dev/null && nikto -host "$target_url"
  command -v skipfish >/dev/null && skipfish -o results/skipfish "$target_url"
  command -v whatweb >/dev/null && whatweb -a 3 "$target_url"
else
  printf '[dry-run] %s\n' "${commands[@]}"
fi

