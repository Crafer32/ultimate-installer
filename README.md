# Debian Ultimate

Not a distro: one netinstall ISO that installs "the Debian of always" (Devuan,
no systemd) or "the new Debian" (Debian + systemd), with the kernel you choose.
It is the stock Devuan installer (text mode) with a few touches.

| Init | Kernel | Desktop |
|---|---|---|
| SysV (Default) | linux-libre (Default) | MATE (Default) |
| OpenRC (Recommended) | linux (Recommended) | Xfce (Recommended) |
| runit | linux-xanmod | Cinnamon, GNOME, GNOME Flashback, KDE, LXDE, LXQt |
| systemd -> Debian base | linux-liquorix | none |

## How it works
- `overlay/` is appended to the installer initrd (`preamble.gz`) as a second cpio.
  - `ultimate-choose` (menu item 6400, right before the base system) asks the
    three questions, answers Devuan's `choose-init` and `tasksel`, and for
    systemd points debootstrap at deb.debian.org instead of the disc.
    It also lists hardware that needs closed firmware (won't work with linux-libre).
  - `pre-pkgsel.d/20ultimate` installs the chosen kernel (freesh / XanMod /
    Liquorix repos); the stock kernel stays as a fallback GRUB entry.
  - `finish-install.d/35ultimate` installs `ultimate-firmware`; with linux-libre
    it purges non-free firmware/microcode and leaves only `main`.
- Closed firmware is opt-in: `ultimate-firmware` lists the hardware that needs
  it, `ultimate-firmware install` adds only those packages, `remove` undoes it.
- The menu step is registered by `lib/debian-installer-startup.d/S99ultimate`,
  and the overlay is spliced into `initrd.gz` before its cpio trailer
  (the preamble unpacks it with busybox cpio, which stops at the first one).

## Tested (QEMU, 30-10-2026)
- systemd + linux-libre -> Debian 13.7, boots 6.18.59-gnu.
- SysV + linux-libre + MATE / none -> Devuan, no firmware, main only.
- `cdrom/ultimate/preseed.cfg` skips boring questions (domain, root password,
  mirror, proxy, more discs, popcon). Only the "Install" entry uses it;
  "Expert install" asks everything.

## Build
    ./build-iso.sh devuan_excalibur_6.1.1_amd64_netinstall.iso out/debian-ultimate.iso
