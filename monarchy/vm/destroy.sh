#!/bin/bash

# Remove the monarchy-dev VM and its disk. Keeps the ISO and every restore
# point in the images pool. Never uses `undefine --remove-all-storage`, which
# would delete the ISO along with the disk.
#
# Usage: monarchy/vm/destroy.sh [--yes]

set -euo pipefail

CONNECT="qemu:///system"
NAME="monarchy-dev"
POOL="images"
DISK="$NAME.qcow2"

virsh() { command virsh -c "$CONNECT" "$@"; }

if ! virsh dominfo "$NAME" >/dev/null 2>&1; then
  echo "$NAME is not defined."
  if virsh vol-info "$DISK" --pool "$POOL" >/dev/null 2>&1; then
    echo "Leftover disk $DISK found; removing it."
    virsh vol-delete "$DISK" --pool "$POOL"
  fi
  exit 0
fi

if [[ ${1:-} != "--yes" ]]; then
  read -r -p "Power off and delete $NAME and its disk $DISK? [y/N] " answer
  [[ $answer == [yY] ]] || { echo "Aborted."; exit 1; }
fi

if [[ $(virsh domstate "$NAME") != "shut off" ]]; then
  virsh destroy "$NAME"
fi
virsh undefine "$NAME" --nvram
virsh vol-delete "$DISK" --pool "$POOL"
rm -f "$HOME/.ssh/known_hosts.monarchy-dev"
echo "Removed $NAME. Remaining volumes:"
virsh vol-list "$POOL"
