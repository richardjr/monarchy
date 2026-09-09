#!/bin/bash

# One-time guest setup for the monarchy-dev VM. Run INSIDE the guest as the
# desktop user, after mounting the share by hand for the first time:
#
#   mkdir -p ~/monarchy && sudo mount -t virtiofs monarchy ~/monarchy && ~/monarchy/monarchy/vm/guest-bootstrap.sh
#
# What it does, idempotently:
#   1. Makes the virtiofs share of the host checkout mount at boot on ~/monarchy.
#   2. Lets the virtual power button shut the guest down. Omarchy ships
#      HandlePowerKey=ignore for real machines, which also swallows the ACPI
#      event `virsh shutdown` sends; a later logind drop-in overrides it here.
#   3. Enables sshd, opens the firewall and authorizes the host's VM key using
#      Omarchy's own omarchy-setup-security-sshd, reading the public key from
#      monarchy/vm/local/authorized_keys on the share (git-ignored on the host).
#   4. Clones omacom/omarchy-pkgs and omacom/omarchy-iso beside the share when
#      missing; four of the shell tests read them and fail without them.
#   5. Grants the desktop user passwordless sudo. The host drives `omarchy dev
#      link`, reboots and package installs over SSH, where sudo has no terminal
#      to ask on. This is a throwaway VM behind NAT with key-only SSH; do not
#      copy this step to a real machine.
#
# It deliberately does NOT run `omarchy dev link`; take the base snapshot first
# (monarchy/vm/snapshot.sh save base-4.0.2 on the host), then link.

set -euo pipefail

SHARE_TAG="monarchy"
MOUNT="$HOME/monarchy"
KEYS="$MOUNT/monarchy/vm/local/authorized_keys"

if [[ ! -d $MOUNT/bin || ! -d $MOUNT/shell ]]; then
  echo "Error: $MOUNT does not look like the mounted Monarchy checkout." >&2
  echo "Mount it first: mkdir -p $MOUNT && sudo mount -t virtiofs $SHARE_TAG $MOUNT" >&2
  exit 1
fi

if ! grep -qE "^$SHARE_TAG[[:space:]]+$MOUNT[[:space:]]+virtiofs" /etc/fstab; then
  echo "Adding the share to /etc/fstab..."
  echo "$SHARE_TAG $MOUNT virtiofs defaults,nofail 0 0" | sudo tee -a /etc/fstab >/dev/null
  sudo systemctl daemon-reload
else
  echo "Share already in /etc/fstab."
fi

POWER_CONF=/etc/systemd/logind.conf.d/20-monarchy-vm-power-button.conf
if [[ ! -f $POWER_CONF ]]; then
  echo "Letting the virtual power button power off the guest..."
  printf '[Login]\nHandlePowerKey=poweroff\n' | sudo install -Dm644 /dev/stdin "$POWER_CONF"
  sudo systemctl kill -s HUP systemd-logind.service 2>/dev/null || true
else
  echo "Power button override already present."
fi

for repo in omarchy-pkgs omarchy-iso; do
  if [[ ! -d $HOME/$repo/.git ]]; then
    echo "Cloning $repo for the test suite..."
    git clone -q "https://github.com/omacom/$repo" "$HOME/$repo"
  else
    echo "$repo already present."
  fi
done

SUDOERS=/etc/sudoers.d/20-monarchy-vm-nopasswd
if [[ ! -f $SUDOERS ]]; then
  echo "Granting $USER passwordless sudo (dev VM only)..."
  printf '%s ALL=(ALL:ALL) NOPASSWD: ALL\n' "$USER" | sudo install -Dm440 /dev/stdin "$SUDOERS"
  sudo visudo -cf "$SUDOERS" >/dev/null
else
  echo "Passwordless sudo already present."
fi

if [[ ! -s $KEYS ]]; then
  echo "Error: no public keys at $KEYS; on the host, copy ~/.ssh/monarchy-dev.pub there." >&2
  exit 1
fi

while IFS= read -r key; do
  [[ -z $key ]] && continue
  omarchy-setup-security-sshd --key="$key"
done <"$KEYS"

echo
echo "Guest ready. Address(es):"
ip -4 -brief address show | awk '$1 != "lo" { print "  " $1 " " $3 }'
echo "Next, on the host: monarchy/vm/ssh.sh 'omarchy version'"
