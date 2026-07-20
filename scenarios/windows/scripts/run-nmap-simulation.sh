#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
hosts_file=${WINDOWS_SCAN_HOSTS_FILE:-data/windows/export_data-benign_rdp_20240114-IPs_only_clean_hosts.csv}
gateways_file=${WINDOWS_SCAN_GATEWAYS_FILE:-data/windows/export_data-benign_rdp_20240114-IPs_only_clean_gateways.csv}
target=${WINDOWS_TARGET_IP:-10.44.0.12}
interface=${WINDOWS_SCAN_INTERFACE:-eth0}
execute=false

[[ $hosts_file = /* ]] || hosts_file="$repo_root/$hosts_file"
[[ $gateways_file = /* ]] || gateways_file="$repo_root/$gateways_file"
[[ ${1:-} == --execute ]] && execute=true

[[ -s $hosts_file ]] || { echo "Missing scanner-host CSV: $hosts_file" >&2; exit 1; }
[[ -s $gateways_file ]] || { echo "Missing scanner-gateway CSV: $gateways_file" >&2; exit 1; }

host_count=$(wc -l < "$hosts_file" | tr -d ' ')
gateway_count=$(wc -l < "$gateways_file" | tr -d ' ')
[[ $host_count -eq $gateway_count && $host_count -gt 0 ]] || {
  echo "Scanner host/gateway CSVs must contain the same non-zero number of rows." >&2
  exit 1
}

row=$(awk -v count="$host_count" 'BEGIN { srand(); print 1 + int(rand() * count) }')
source_ip=$(sed -n "${row}p" "$hosts_file" | tr -d '\r\357\273\277' | cut -d, -f1)
source_gateway=$(sed -n "${row}p" "$gateways_file" | tr -d '\r\357\273\277' | cut -d, -f1)

ipv4_re='^[0-9]+(\.[0-9]+){3}$'
[[ $source_ip =~ $ipv4_re ]] || { echo "Invalid source IP on row $row: $source_ip" >&2; exit 1; }
[[ $source_gateway =~ $ipv4_re ]] || { echo "Invalid gateway IP on row $row: $source_gateway" >&2; exit 1; }
[[ $target =~ $ipv4_re ]] || { echo "Invalid Windows target IP: $target" >&2; exit 1; }

printf '%s\n' \
  "Selected GreyNoise-derived scanner identity: $source_ip" \
  "Paired simulated gateway: $source_gateway" \
  "Windows Server target: $target (RDP/3389)" \
  "Interface: $interface"

if $execute; then
  if ! ip -4 address show dev "$interface" | grep -Fq " $source_ip/"; then
    echo "The selected identity is not configured on $interface." >&2
    echo "Load the retained host aliases on the isolated scanner VM before executing." >&2
    exit 1
  fi
  sudo nmap -Pn -sS -sV -O -p 3389 --source-ip "$source_ip" -e "$interface" "$target"
else
  printf '[dry-run] sudo nmap -Pn -sS -sV -O -p 3389 --source-ip %q -e %q %q\n' \
    "$source_ip" "$interface" "$target"
fi
