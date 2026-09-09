#!/bin/bash

# SSH into the monarchy-dev guest, resolving its address from the libvirt DHCP
# lease. Uses the dedicated key generated for the VM and a separate known_hosts
# file, because the guest is re-created and restored often and its host key
# changes each time; `monarchy/vm/snapshot.sh restore` wipes that file.
#
# Usage: monarchy/vm/ssh.sh [ssh options] [command ...]
#        monarchy/vm/ssh.sh --ip          print the guest address only (for scp etc.)
#   MONARCHY_VM_USER overrides the guest user (default: the host user name).
#
# A command is run through a login shell in the guest so /etc/profile sources
# /etc/omarchy.conf, which is where `omarchy dev link` puts OMARCHY_PATH. Over
# a plain ssh command that file is never read and `omarchy version` reports the
# installed package rather than the link.

set -euo pipefail

CONNECT="qemu:///system"
NAME="monarchy-dev"
KEY="$HOME/.ssh/monarchy-dev"
KNOWN_HOSTS="$HOME/.ssh/known_hosts.monarchy-dev"
GUEST_USER="${MONARCHY_VM_USER:-$USER}"

if [[ ! -f $KEY ]]; then
  echo "Error: VM key missing: $KEY (see monarchy/vm/README.md)" >&2
  exit 1
fi

ip=$(virsh -c "$CONNECT" domifaddr "$NAME" --source lease 2>/dev/null | awk '/ipv4/ { sub(/\/.*/, "", $4); print $4; exit }')
if [[ -z $ip ]]; then
  echo "Error: no DHCP lease for $NAME; is it running and past boot?" >&2
  exit 1
fi

if [[ ${1:-} == "--ip" ]]; then
  printf '%s\n' "$ip"
  exit 0
fi

ssh_opts=()
while [[ ${1:-} == -o ]]; do ssh_opts+=("$1" "$2"); shift 2; done

if (( $# == 0 )); then
  exec ssh -i "$KEY" -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile="$KNOWN_HOSTS" -o ConnectTimeout=10 "${ssh_opts[@]}" "$GUEST_USER@$ip"
fi
exec ssh -i "$KEY" -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile="$KNOWN_HOSTS" -o ConnectTimeout=10 "${ssh_opts[@]}" "$GUEST_USER@$ip" bash -lc "$(printf '%q ' "$*")"
