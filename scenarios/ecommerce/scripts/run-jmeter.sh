#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
plan="$repo_root/scenarios/ecommerce/jmeter/user-journeys.jmx"
mkdir -p "$repo_root/results"
cd "$repo_root"
exec jmeter -n -t "$plan" \
  -Jtarget_host="${TARGET_HOST:-shop.example.org}" \
  -Jtarget_ip="${TARGET_IP:-10.24.44.5}" \
  -Jtarget_port="${TARGET_PORT:-80}" \
  -l "$repo_root/results/jmeter.jtl" "$@"
