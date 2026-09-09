#!/bin/bash

# Create the monarchy-dev libvirt VM that boots the stock Omarchy ISO.
#
# Idempotent: exits cleanly when the domain already exists. Needs the caller in
# the libvirt group (or polkit access to qemu:///system); no sudo.
#
# Usage: monarchy/vm/create.sh [path-to-omarchy.iso]
#
# The ISO must live somewhere the libvirt-qemu user can read, such as
# /var/lib/libvirt/images/. A home directory with mode 700 will not do.
#
# The VM gets a virtiofs share of this checkout under the tag "monarchy" so the
# guest can `omarchy dev link` the live working tree. SPICE runs with GL so
# Hyprland renders on the host GPU; a side effect is that `virsh screenshot`
# has no surface to dump, so take screenshots inside the guest instead.
#
# GL is skipped on hosts running the proprietary NVIDIA driver: QEMU's EGL
# render-node init fails there (EGL_NOT_INITIALIZED) and the driver has no
# dmabuf export for SPICE anyway. The guest then renders in software on a 2D
# virtio-gpu, which upstream's own ISO harness targets. Override the detection
# with MONARCHY_VM_GL=1 or MONARCHY_VM_GL=0.
#
# NVRAM is raw because Arch's edk2-ovmf ships only raw firmware descriptors,
# which rules out libvirt internal snapshots. Use `virsh vol-clone --reflink`
# in the images pool for stock/restore points instead (see README.md).

set -euo pipefail

CONNECT="qemu:///system"
NAME="monarchy-dev"
POOL_DIR="/var/lib/libvirt/images"
ISO="${1:-$POOL_DIR/omarchy-4.0.2.iso}"
DISK="$POOL_DIR/$NAME.qcow2"
DISK_SIZE_GB=64
MEMORY_MB=8192
VCPUS=6
REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)

if [[ -z ${MONARCHY_VM_GL:-} ]]; then
  if grep -qE '^nvidia ' /proc/modules; then MONARCHY_VM_GL=0; else MONARCHY_VM_GL=1; fi
fi
if (( MONARCHY_VM_GL )); then
  GRAPHICS="spice,listen=none,gl.enable=yes"
  VIDEO="model.type=virtio,model.acceleration.accel3d=yes"
else
  echo "Host GL unavailable to QEMU (NVIDIA driver or MONARCHY_VM_GL=0); guest will render in software."
  GRAPHICS="spice,listen=none"
  VIDEO="model.type=virtio"
fi

if virsh -c "$CONNECT" dominfo "$NAME" >/dev/null 2>&1; then
  echo "$NAME already exists; nothing to do."
  echo "  start:   virsh -c $CONNECT start $NAME"
  echo "  console: virt-manager"
  exit 0
fi

if [[ ! -r $ISO ]]; then
  echo "Error: ISO not found or unreadable: $ISO" >&2
  exit 1
fi

if [[ $(virsh -c "$CONNECT" net-info default 2>/dev/null | awk '/^Active:/ {print $2}') != "yes" ]]; then
  virsh -c "$CONNECT" net-start default
  virsh -c "$CONNECT" net-autostart default
fi

virt-install --connect "$CONNECT" \
  --name "$NAME" --os-variant archlinux \
  --memory "$MEMORY_MB" --vcpus "$VCPUS" --cpu host-passthrough --machine q35 \
  --boot uefi,firmware.feature0.name=enrolled-keys,firmware.feature0.enabled=no,firmware.feature1.name=secure-boot,firmware.feature1.enabled=no \
  --disk "path=$DISK,size=$DISK_SIZE_GB,format=qcow2,bus=virtio,discard=unmap" \
  --cdrom "$ISO" \
  --network network=default,model=virtio \
  --graphics "$GRAPHICS" \
  --video "$VIDEO" \
  --sound none --channel spicevmc --rng /dev/urandom \
  --memorybacking source.type=memfd,access.mode=shared \
  --filesystem "source.dir=$REPO_ROOT,target.dir=monarchy,driver.type=virtiofs" \
  --noautoconsole

echo
echo "$NAME is booting the installer. Open it in virt-manager to run the configurator."
