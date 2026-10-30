# Debian Ultimate

Not a distro: one netinstall ISO that installs "the Debian of always" (Devuan,
no systemd) or "the new Debian" (Debian + systemd), with the kernel you choose.
It is the stock Devuan installer (text mode) with a few touches.

| Init | Kernel | Desktop |
|---|---|---|
| SysV (Default) | linux-libre (Default) | MATE (Default) |
| OpenRC (Recommended) | linux (Recommended) | Xfce (Recommended) |
| runit | linux-xanmod | LXDE, LXQt, Cinnamon, KDE |
| systemd -> Debian base | linux-liquorix | none |

## How it works
- `overlay/` is appended to the installer initrd (`preamble.gz`) as a second cpio.
  - `ultimate-choose` (menu item 6400, right before the base system) asks the
    three questions, answers Devuan's `choose-init` and `tasksel`, and for
    systemd points debootstrap at deb.debian.org instead of the disc.
    It also lists hardware that needs closed firmware (won't work with linux-libre).
  - `pre-pkgsel.d/20ultimate` installs the chosen kernel (freesh / XanMod /
    Liquorix repos) and removes the stock one.
  - `finish-install.d/35ultimate` with linux-libre purges non-free packages and
    leaves only `main`.
- `cdrom/ultimate/preseed.cfg` skips boring questions (domain, root password,
  mirror, proxy, more discs, popcon). Only the "Install" entry uses it;
  "Expert install" asks everything.

## Build
    ./build-iso.sh devuan_excalibur_6.1.1_amd64_netinstall.iso out/debian-ultimate.iso
