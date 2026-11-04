#!/bin/sh
# Builds the Ultimate Installer ISO from the Devuan netinstall ISO (installer and
# Devuan base) plus the Genuen netinstall ISO, copied as is to /genuen.iso and
# loop-mounted when Genuen is chosen (inside an image, apt-cdrom does not pick
# it up as a second archive on Devuan installs).
# Usage: ./build-iso.sh devuan_..._netinstall.iso genuen-..._netinstall.iso out/ultimate-installer.iso
set -eu
BASE=$1; GENUEN=$2; OUT=$3
HERE=$(cd "$(dirname "$0")" && pwd)
W=$(mktemp -d)
trap 'chmod -R u+w "$W"; rm -rf "$W"' EXIT

echo "== extracting $BASE"
xorriso -osirrox on -indev "$BASE" -extract / "$W/iso" >/dev/null 2>&1
chmod -R u+w "$W/iso"
B=$W/iso/boot/isolinux

echo "== initrd overlay"
# The boot initrd (preamble.gz) only mounts the disc and unpacks the real
# installer initrd, initrd.gz, with busybox cpio, which stops at the first
# TRAILER!!! record. So the overlay is spliced in before that record.
mkdir -p "$W/ov"
cp -a "$HERE/overlay/." "$W/ov/"
# bin, lib, lib64 and sbin are symlinks into usr/ in the installer: a real
# directory with that name in the overlay replaces the symlink when the kernel
# unpacks the initrd, and the installer no longer boots.
for d in bin lib lib64 sbin; do
	[ ! -e "$W/ov/$d" ] || { echo "overlay/$d: use overlay/usr/$d"; exit 1; }
done
zcat "$B/initrd.gz" > "$W/initrd.cpio"
# Offset of the trailer record: a 110-byte newc header followed by its name.
CUT=$(grep -abo '070701[0-9A-Fa-f]\{104\}TRAILER!!!' "$W/initrd.cpio" | tail -1 | cut -d: -f1)
[ -n "$CUT" ] || { echo "cpio trailer not found"; exit 1; }
head -c "$CUT" "$W/initrd.cpio" > "$W/new.cpio"
(cd "$W/ov" && find . | cpio -o -H newc --owner=0:0 --quiet) >> "$W/new.cpio"
gzip -9 < "$W/new.cpio" > "$B/initrd.gz"
rm -f "$W/initrd.cpio" "$W/new.cpio"

echo "== disc files and boot menu"
cp -a "$HERE/cdrom/ultimate" "$W/iso/"
sed -i -e 's/^menu title .*/menu title Ultimate Installer/' \
       -e '/^label install$/,/append/ s|--- quiet|preseed/file=/cdrom/ultimate/preseed.cfg --- quiet|' \
       "$B/menu.cfg"
(cd "$W/iso" && find . -type f ! -name md5sum.txt ! -path './boot/isolinux/*' -exec md5sum {} + > md5sum.txt)

echo "== writing $OUT"
mkdir -p "$(dirname "$OUT")"; rm -f "$OUT"
xorriso -indev "$BASE" -outdev "$OUT" \
	-map "$B/initrd.gz" /boot/isolinux/initrd.gz \
	-map "$B/menu.cfg" /boot/isolinux/menu.cfg \
	-map "$W/iso/md5sum.txt" /md5sum.txt \
	-map "$W/iso/ultimate" /ultimate \
	-map "$GENUEN" /genuen.iso \
	-boot_image any replay 2>&1 | grep -E "FAILURE|SORRY|WARNING" || true
ls -la "$OUT"
