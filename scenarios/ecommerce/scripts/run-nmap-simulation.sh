#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
source_file=${SOURCE_IP_FILE:-"$repo_root/data/ecommerce/export_data-malicious_web_20240114-IPs_only_clean_gateways_v2.csv"}
target=${TARGET_IP:-10.24.44.5}
interface=${SOURCE_INTERFACE:-eth0}
execute=false
[[ ${1:-} == --execute ]] && execute=true
source_ip=$(awk 'BEGIN{srand()} {if (rand()*NR < 1) line=$0} END{print line}' "$source_file" | tr -d '\r' | cut -d, -f1)
[[ $source_ip =~ ^[0-9]+(\.[0-9]+){3}$ ]] || { echo "Invalid source IP: $source_ip" >&2; exit 1; }
commands=(
  "sudo ip address add ${source_ip}/32 dev ${interface}"
  "sudo nmap -Pn -sS -sV -O --source-ip ${source_ip} -e ${interface} ${target}"
  "sudo ip address del ${source_ip}/32 dev ${interface}"
)
printf '%s\n' "Selected synthetic scanner identity: $source_ip" "Target: $target"
if $execute; then
  cleanup() { sudo ip address del "$source_ip/32" dev "$interface" 2>/dev/null || true; }
  trap cleanup EXIT
  sudo ip address add "$source_ip/32" dev "$interface"
  sudo nmap -Pn -sS -sV -O --source-ip "$source_ip" -e "$interface" "$target"
else
  printf '[dry-run] %s\n' "${commands[@]}"
fi
