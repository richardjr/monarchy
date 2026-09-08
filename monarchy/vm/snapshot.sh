#!/bin/bash

# Disk restore points for the monarchy-dev VM, done as whole-volume clones in
# the libvirt "images" pool. libvirt internal snapshots are unavailable because
# the domain's UEFI NVRAM is raw (see create.sh), and a clone is instant on
# btrfs via --reflink anyway. The VM must be shut off for save and restore.
#
# Usage:
#   monarchy/vm/snapshot.sh save <name>       clone the current disk as <name>
#   monarchy/vm/snapshot.sh restore <name>    replace the current disk with <name>
#   monarchy/vm/snapshot.sh list              show saved restore points
#   monarchy/vm/snapshot.sh delete <name>     remove a restore point
#
# The NVRAM is left alone: the boot entry it holds points at the same EFI path
# in every restore point, so it stays valid.

set -euo pipefail

CONNECT="qemu:///system"
NAME="monarchy-dev"
POOL="images"
DISK="$NAME.qcow2"
KNOWN_HOSTS="$HOME/.ssh/known_hosts.monarchy-dev"

virsh() { command virsh -c "$CONNECT" "$@"; }

usage() {
  sed -n '3,16p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

require_shut_off() {
  local state
  state=$(virsh domstate "$NAME" 2>/dev/null || true)
  if [[ $state != "shut off" ]]; then
    echo "Error: $NAME must be shut off (currently: ${state:-undefined})." >&2
    echo "  virsh -c $CONNECT shutdown $NAME" >&2
    exit 1
  fi
}

clone() {
  local from="$1" to="$2"
  if ! virsh vol-clone "$from" "$to" --pool "$POOL" --reflink 2>/dev/null; then
    echo "reflink clone unavailable; copying in full..." >&2
    virsh vol-clone "$from" "$to" --pool "$POOL"
  fi
}

snapshot_name() {
  local n="${1:-}"
  if [[ -z $n || $n == *[^A-Za-z0-9._-]* || $n == "$NAME" ]]; then
    echo "Error: give a snapshot name using letters, digits, . _ - (not '$NAME')." >&2
    exit 1
  fi
  printf '%s.qcow2' "$n"
}

case "${1:-}" in
  save)
    vol=$(snapshot_name "${2:-}")
    require_shut_off
    if virsh vol-info "$vol" --pool "$POOL" >/dev/null 2>&1; then
      echo "Error: $vol already exists; delete it first or pick another name." >&2
      exit 1
    fi
    clone "$DISK" "$vol"
    echo "Saved $DISK as $vol"
    ;;
  restore)
    vol=$(snapshot_name "${2:-}")
    require_shut_off
    virsh vol-info "$vol" --pool "$POOL" >/dev/null
    virsh vol-delete "$DISK" --pool "$POOL"
    clone "$vol" "$DISK"
    rm -f "$KNOWN_HOSTS"
    echo "Restored $DISK from $vol. Start with: virsh -c $CONNECT start $NAME"
    ;;
  list)
    virsh vol-list "$POOL" | awk 'NR > 2 && $1 ~ /\.qcow2$/ && $1 != "'"$DISK"'" { print $1 }'
    ;;
  delete)
    vol=$(snapshot_name "${2:-}")
    virsh vol-delete "$vol" --pool "$POOL"
    ;;
  -h|--help|help)
    usage 0
    ;;
  *)
    usage 1 >&2
    ;;
esac
