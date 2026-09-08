# Monarchy dev VM

Monarchy is developed and verified inside a libvirt VM running stock Omarchy 4.0.2 with this checkout dev-linked into it. This document is the complete runbook for standing that up on a fresh Omarchy host. Run it top to bottom on a new machine; every step is idempotent or says what it replaces.

The pieces:

| File | Runs on | Purpose |
|---|---|---|
| `create.sh` | host | Define and boot the `monarchy-dev` VM from the ISO |
| `guest-bootstrap.sh` | guest | One-time guest setup: share mount at boot, power button, sshd + key |
| `snapshot.sh` | host | Save / restore / list disk restore points via libvirt volume clones |
| `ssh.sh` | host | SSH into the guest by its DHCP lease (`--ip` prints just the address) |
| `destroy.sh` | host | Remove the VM and its disk, keeping the ISO and restore points |
| `local/` | host | Git-ignored machine-local material: the VM SSH public key |

## 1. Host prerequisites (once per machine)

The host is assumed to be Omarchy 4.x itself. Any Arch with libvirt works the same, minus the Omarchy-specific notes.

1. Install the virtualisation stack and enable libvirt:

   ```bash
   omarchy-pkg-add qemu-desktop libvirt virt-manager edk2-ovmf swtpm dnsmasq virtiofsd
   sudo systemctl enable --now libvirtd
   sudo usermod -aG libvirt "$USER"
   ```

   Log out and back in for the group. In practice `virsh` on `qemu:///system` works before that, because libvirt's polkit rule checks group membership in the user database rather than the running process.

2. Let guests reach libvirt's DHCP and DNS. Omarchy's ufw denies inbound by default and libvirt uses the nftables backend, so both firewalls judge the guest's DHCP request and ufw drops it. Without this rule the guest never gets an address:

   ```bash
   sudo ufw allow in on virbr0 comment 'libvirt guests'
   ```

3. Clone this repo and wire the upstream remote:

   ```bash
   git clone https://github.com/richardjr/monarchy ~/Work/monarchy
   cd ~/Work/monarchy
   git remote add upstream https://github.com/omacom/omarchy.git
   git fetch upstream --tags
   git config --local credential.helper '!gh auth git-credential'   # if pushing over HTTPS with gh logged in
   ```

4. Fetch the Omarchy ISO into the libvirt images pool. It must not live under your home directory: the home is mode 700 and QEMU runs as `libvirt-qemu`, which cannot traverse it. Turn off copy-on-write on the pool directory before any disk image exists there; it only affects files created afterwards.

   ```bash
   sudo chattr +C /var/lib/libvirt/images
   sudo curl -fL -o /var/lib/libvirt/images/omarchy-4.0.2.iso https://iso.omarchy.org/omarchy-4.0.2.iso
   sudo curl -fL -o /var/lib/libvirt/images/omarchy-4.0.2.iso.sha256 https://iso.omarchy.org/omarchy-4.0.2.iso.sha256
   (cd /var/lib/libvirt/images && sha256sum -c omarchy-4.0.2.iso.sha256)
   ```

   The ISO is 6.2 GB. Newer releases follow the same URL pattern; the version must match the tag `main` is based on (see `monarchy/DECISIONS.md` D004).

5. Create the SSH key the host uses to reach the guest and stage its public half where the guest bootstrap reads it. `local/` is git-ignored.

   ```bash
   ssh-keygen -t ed25519 -N "" -C "$USER@$(hostname) monarchy-dev-vm" -f ~/.ssh/monarchy-dev
   mkdir -p monarchy/vm/local && cp ~/.ssh/monarchy-dev.pub monarchy/vm/local/authorized_keys
   ```

## 2. Create the VM and install stock Omarchy

```bash
monarchy/vm/create.sh                  # or: create.sh /path/to/other.iso
virt-manager                           # open monarchy-dev to get the console
```

`create.sh` defines `monarchy-dev`: UEFI without secure boot, 8 GB RAM, 6 vCPUs, a 64 GB virtio qcow2 disk, the ISO on SATA, NAT networking on `default`, SPICE with GL on the host GPU, and a virtiofs share of this checkout tagged `monarchy`. It starts the network if needed and exits cleanly when the domain already exists.

Drive the Omarchy configurator in the console:

| Prompt | Value | Why |
|---|---|---|
| Hostname | `monarchy` | keep it the same on every rebuild |
| Username | your host user name | the first user gets uid 1000, which is what the virtiofs share maps to; only the uid matters |
| Password | short, throwaway | dev VM; it lands hashed in installer logs, so never reuse a real one |
| Disk encryption | no | a passphrase prompt on every boot breaks unattended restores |
| Timezone / keyboard | match the host | |
| Disk | the single 64 GB virtio disk | |

Let it install, reboot into SDDM, and log in once so first-boot user setup completes. Do not customise anything.

## 3. Bootstrap the guest

In the guest, open a terminal (Super+Return) and run one line:

```bash
mkdir -p ~/monarchy && sudo mount -t virtiofs monarchy ~/monarchy && ~/monarchy/monarchy/vm/guest-bootstrap.sh && systemctl poweroff
```

The bootstrap adds the share to `/etc/fstab` so it mounts at boot on `~/monarchy`, drops a logind override so the virtual power button powers the guest off (stock Omarchy ships `HandlePowerKey=ignore`, which also swallows `virsh shutdown`), and runs Omarchy's own `omarchy-setup-security-sshd --key=...` with the key from `local/authorized_keys`, which enables sshd, rate-limits port 22 in ufw and disables password logins. It prints the guest's address and does not dev-link anything. The one-liner ends by powering off so the next step can snapshot a clean disk.

## 4. Take the stock restore point

With the guest off:

```bash
monarchy/vm/snapshot.sh save stock-4.0.2
virsh -c qemu:///system start monarchy-dev
```

`stock-4.0.2` is stock Omarchy plus only the bootstrap's access plumbing; nothing of Monarchy is in it. Restoring is `snapshot.sh restore stock-4.0.2` while the VM is off, then start it again. Restore points are whole-volume clones because the domain's UEFI NVRAM is raw (Arch's edk2 ships raw firmware descriptors only), which rules out libvirt internal snapshots. Clones use btrfs reflinks when the pool allows it and fall back to a full copy.

## 5. Dev-link the checkout

```bash
monarchy/vm/ssh.sh 'omarchy dev link ~/monarchy --no-reboot'
monarchy/vm/ssh.sh 'systemctl reboot'
# wait for the login screen, then:
monarchy/vm/ssh.sh 'omarchy version'          # must print: dev (<short sha>)
monarchy/vm/ssh.sh 'cd ~/monarchy && ./test/all'
```

Use `systemctl reboot` over SSH rather than `virsh reboot`: the latter is the same ACPI power-button event, which the bootstrap's override maps to power off.

Phase 0 of the roadmap is complete when the dev-linked guest is indistinguishable from stock and the tests pass.

## 6. Daily loop

Edit on the host; the guest sees the working tree live through the share, so nothing needs committing to try a change.

| Changed | Then, in the guest |
|---|---|
| `shell/` QML | `omarchy-restart-shell` |
| `default/hypr/*.lua` | `hyprctl reload` |
| `themes/<name>/`, `default/themed/` | `omarchy theme set <name>` |
| `bin/` | nothing; commands run from the checkout |

Session commands need the graphical session's environment, which a plain SSH login does not have. Either run them from a terminal inside the guest, or borrow the environment of the running compositor over SSH:

```bash
monarchy/vm/ssh.sh 'export $(tr "\0" "\n" </proc/$(pgrep -x Hyprland)/environ | grep -E "^(WAYLAND_DISPLAY|HYPRLAND_INSTANCE_SIGNATURE|XDG_RUNTIME_DIR|DBUS_SESSION_BUS_ADDRESS)="); omarchy-restart-shell'
```

Screenshots are taken inside the guest and copied back. `virsh screenshot` does not work while SPICE GL is enabled (QEMU reports "no surface"), and GL is worth keeping for a usable Hyprland.

```bash
monarchy/vm/ssh.sh '... ; omarchy capture screenshot fullscreen save'   # prints the guest path
scp -i ~/.ssh/monarchy-dev -o UserKnownHostsFile=~/.ssh/known_hosts.monarchy-dev "$USER@$(monarchy/vm/ssh.sh --ip):Pictures/<file>.png" .
```

Follow upstream's `agents/skills/visual-verification.md` for what to look for.

## 7. Reset or rebuild

```bash
monarchy/vm/destroy.sh                 # stop and remove the VM and its disk; ISO and restore points stay
monarchy/vm/create.sh                  # start again from section 2
```

Never `virsh undefine --remove-all-storage` on this domain: the ISO sits in the same pool and would be deleted with it.

## Notes and gotchas collected while building this

- `omarchy dev link` covers `bin/`, `default/`, `shell/`, `themes/`, `applications/` and `config/`. Fixed system paths (`/etc`, systemd units, plymouth, sddm) still come from the installed package; `omarchy dev pkg-test` builds those from a checkout when needed.
- While linked, `omarchy update` inside the guest runs `git pull --ff-only` on `~/monarchy`, which is the host checkout through the share. Harmless, but be aware of it.
- If the VM ever boots without the share attached, Hyprland's config cannot find `$OMARCHY_PATH` and the session will not start. Log into a TTY and run `omarchy dev unlink`, or restore a snapshot.
- Guest host keys change when the VM is rebuilt or restored, so `ssh.sh` keeps them in `~/.ssh/known_hosts.monarchy-dev`, which `snapshot.sh restore` deletes.
- Firmware autoselection refuses a qcow2 NVRAM request on Arch. Naming the loader and vars template explicitly was also rejected by libvirt 12.6 in a first attempt; if internal snapshots ever matter, that is the thread to pull.
