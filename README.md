# Ultimate Installer

Not a distro: one Debian/Devuan netinstall ISO that installs the existing
Devuan/Debian-family distro that your choices add up to, with that distro's own
packages and repositories. It is the stock Debian/Devuan installer
(debian-installer, text mode, as Devuan ships it) plus one extra step and a
few hooks.

## Choices (one screen, right after partitioning)

| Branch | Init | Kernel | Installs |
|---|---|---|---|
| stable (Default) | SysV (Default), runit | linux-libre (Default) | **Devuan** + linux-libre 6.12 from FSFLA (freesh) |
| stable | OpenRC (Recommended) | linux-libre | **Genuen** (libre Devuan), from the disc |
| stable | s6 | linux-libre only | **Genuen** + its s6 packages |
| stable | SysV, OpenRC, runit | linux (Recommended) | **Devuan**, from the disc |
| stable | systemd | linux | **Debian** stable (**LMDE** with Cinnamon) |
| stable | systemd | linux-libre | **Debian Libre** (Debian main + linux-libre 6.12) |
| testing | systemd | linux-libre / linux | **Debian testing** |

- Kernel screen warns about hardware that needs closed firmware
  ("Hardware not compatible with linux-libre: ..."). With s6 it only lists
  linux-libre: s6 comes from Genuen, which has no plain SysV either (its
  sysvinit-core needs openrc or s6 as rc), hence Devuan for SysV/runit.
- Repositories: with linux-libre, `main` only. With any other kernel, `main`
  is always included and `non-free-firmware` (checked), `contrib` and
  `non-free` are offered.
- Desktop: MATE (Default), Xfce (Recommended), Cinnamon, GNOME,
  GNOME Flashback, KDE Plasma, LXDE, LXQt or none; downloaded from the net.
  Cinnamon on Debian stable with linux installs LMDE 7 (Linux Mint's
  repository on top of Debian, preferred as LMDE does, and mint-meta-cinnamon).
- X server, asked after the desktop only for X11 desktops (MATE, Xfce,
  Cinnamon, LXDE, LXQt, GNOME Flashback): X11 (Xorg, preselected) or XLibre.
  Plasma and GNOME keep Wayland, their official session; experimental
  Wayland sessions are not offered. XLibre comes from
  [xlibre-debian](https://xlibre-debian.github.io) (`debian` or `devuan`,
  `stable` or `testing`; stable also needs the Debian/Devuan backports). It is
  installed before the desktop, so it takes the place of Xorg (it provides
  `xorg` and `xserver-xorg`), and Xorg's server is pinned out.
- One kernel in the installed system. Closed firmware is opt-in:
  `ultimate-firmware` lists, installs or removes it.

The "Install" entry skips the boring questions (domain, mirror, proxy, more
discs, popularity-contest, tasksel, console-data's keymap, GRUB: it goes to
the disk chosen when partitioning) and preselects "Yes" when writing the
partitions; "Expert install" asks everything. A "Use the same password for
the administrator (root)" checkbox, ticked by default, comes before the user:
unticked, the root password is asked too.

## How it works
- `build-iso.sh` remasters the Devuan netinstall ISO and adds the Genuen
  netinstall ISO as `/genuen.iso` (inside an image, apt-cdrom does not pick it
  up as a second archive on Devuan installs).
- `overlay/` is spliced into the installer initrd (`initrd.gz`) before its cpio
  trailer (the boot preamble unpacks it with busybox cpio, which stops at the
  first one); `S99ultimate` registers the extra step in the installer menu.
- `ultimate-rootpw` (menu item 2390, just before user-setup): the root
  checkbox; `finish-install.d/35ultimate` copies the user's password to root.
- `ultimate-choose` (menu item 6400, before the base system) asks the
  questions and answers the stock ones underneath (choose-init, tasksel,
  apt-setup, mirror) with debconf-set-selections:
  - Genuen: `/genuen.iso` is loop-mounted over `/cdrom`; Devuan's debootstrap
    script with opensysusers instead of systemd-standalone-sysusers.
  - Debian / LMDE: `.disk/base_installable` is hidden so the base comes from
    the mirror.
- `apt-setup/generators/39ultimate`: Genuen's disc as apt source.
- `pre-pkgsel.d/20ultimate`: Debian sources, the kernel when it does not
  come with the distro (linux-libre from freesh), and s6.
- `pre-pkgsel.d/25ultimate-xlibre`: XLibre's repository and packages.
- `pre-pkgsel.d/30ultimate-lmde`: Linux Mint's repository and Cinnamon.
- `finish-install.d/36ultimate-session`: the login screen starts the X11
  session.
- `finish-install.d/35ultimate`: `ultimate-firmware`, and no blobs with libre.

## Build
    ./build-iso.sh devuan_excalibur_6.1.1_amd64_netinstall.iso \
        genuen-6.0.1-netinstall-2026.10.11-amd64.iso out/ultimate-installer.iso

## Credits
Ultimate Installer only puts together the work of these Debian/Devuan projects:
- [Genuen](https://genuen.org) — libre spin of Devuan
- [Devuan](https://devuan.org) — Debian without systemd, and its installer
- [Debian](https://www.debian.org) — the base of everything, and debian-installer
- [Debian Libre](https://libre.debian.net) — the idea of Debian without non-free
- [Linux Mint / LMDE](https://linuxmint.com)
- [XLibre](https://github.com/X11Libre/xserver) and its Debian packages,
  [xlibre-debian](https://xlibre-debian.github.io) (NexusSfan)
- [GNU Linux-libre / FSFLA freesh](https://www.fsfla.org/ikiwiki/selibre/linux-libre/freesh)

## License
GPL-3.0-or-later (see `LICENSE`). debian-installer, which this builds on, is
GPL-2.0-or-later.
