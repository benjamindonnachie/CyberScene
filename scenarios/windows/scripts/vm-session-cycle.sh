#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
credentials_file=${WINDOWS_CREDENTIALS_FILE:-"$repo_root/data/windows/activeDirectory_user_pass_only.csv"}
server_vm=${WINDOWS_SERVER_VM:-Windows Server 2022 Standard (Updated July 2023)}
gateway_vm=${WINDOWS_GATEWAY_VM:-kali-linux-2023.3-virtualbox-amd64-gateway}
client_prefix=${WINDOWS_CLIENT_PREFIX:-Win10-Ghosts-}
client_ids=${WINDOWS_CLIENT_IDS:-"0 1 2 3 4 5"}
delay_min=${LOGIN_DELAY_MIN:-180}
delay_max=${LOGIN_DELAY_MAX:-539}

usage() { echo "Usage: $0 start|stop [--execute]"; }
[[ $# -ge 1 ]] || { usage; exit 2; }
action=$1
execute=false
[[ ${2:-} == --execute ]] && execute=true

run() {
  printf '+ '; printf '%q ' "$@"; printf '\n'
  if $execute; then "$@"; fi
}

is_running() { VBoxManage list runningvms | grep -Fq "\"$1\""; }
start_if_needed() {
  if $execute; then is_running "$1" || run VBoxManage startvm "$1" --type headless
  else run VBoxManage startvm "$1" --type headless
  fi
}
random_line() {
  count=$(wc -l < "$1")
  pick=$((1 + RANDOM % count))
  awk -v pick="$pick" 'NR == pick {print; exit}' "$1"
}

case "$action" in
  start)
    [[ -r "$credentials_file" ]] || { echo "Credentials file not readable: $credentials_file" >&2; exit 1; }
    start_if_needed "$server_vm"
    start_if_needed "$gateway_vm"
    shuffled=$(printf '%s\n' $client_ids | awk 'BEGIN{srand()} {print rand(), $0}' | sort -n | cut -d' ' -f2-)
    while IFS= read -r id; do
      vm="${client_prefix}${id}"
      start_if_needed "$vm"
      if $execute; then sleep $((delay_min + RANDOM % (delay_max - delay_min + 1))); fi
      if [[ "$id" == "${ADMIN_CLIENT_ID:-0}" ]]; then
        run VBoxManage controlvm "$vm" setcredentials \
          "${ADMIN_USERNAME:-vboxuser}" "${ADMIN_PASSWORD:-Password2}" "${ADMIN_DOMAIN:-Admin-wfh}"
      else
        IFS=' ' read -r username password domain < <(random_line "$credentials_file")
        run VBoxManage controlvm "$vm" setcredentials "$username" "$password" "$domain"
      fi
    done <<< "$shuffled"
    ;;
  stop)
    for id in $client_ids; do
      vm="${client_prefix}${id}"
      if $execute; then is_running "$vm" && run VBoxManage controlvm "$vm" acpipowerbutton
      else run VBoxManage controlvm "$vm" acpipowerbutton
      fi
    done
    if $execute; then sleep 60; fi
    for id in $client_ids; do
      vm="${client_prefix}${id}"
      if $execute; then is_running "$vm" && run VBoxManage controlvm "$vm" poweroff
      else run VBoxManage controlvm "$vm" poweroff
      fi
    done
    ;;
  *) usage; exit 2 ;;
esac
