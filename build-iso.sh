#!/bin/sh
# Builds the Debian Ultimate ISO from a Devuan netinstall ISO.
# Usage: ./build-iso.sh devuan_..._netinstall.iso out/debian-ultimate.iso
set -eu
BASE=$1; OUT=$2
HERE=$(cd "$(dirname "$0")" && pwd)
W=$(mktemp -d)
trap 'chmod -R u+w "$W"; rm -rf "$W"' EXIT

echo "== extracting $BASE"
xorriso -osirrox on -indev "$BASE" -extract / "$W/iso" >/dev/null 2>&1
chmod -R u+w "$W/iso"
B=$W/iso/boot/isolinux

echo "== initrd overlay"
mkdir -p "$W/ov"
cp -a "$HERE/overlay/." "$W/ov/"
mkdir -p "$W/ov/var/lib/dpkg"
zcat "$B/preamble.gz" | (cd "$W" && cpio -id --quiet var/lib/dpkg/status)
cp "$W/var/lib/dpkg/status" "$W/ov/var/lib/dpkg/status"
cat >> "$W/ov/var/lib/dpkg/status" <<STANZA

Package: ultimate-choose
Status: install ok unpacked
Version: 1.0
Depends: cdebconf-udeb
Description: Debian Ultimate: choose init, kernel and desktop
Installer-Menu-Item: 6400
STANZA
# A second cpio appended to the initrd overrides files of the first one.
(cd "$W/ov" && find . | cpio -o -H newc --owner=0:0 --quiet | gzip -9) >> "$B/preamble.gz"

echo "== disc files and boot menu"
cp -a "$HERE/cdrom/ultimate" "$W/iso/"
sed -i -e 's/^menu title Devuan GNU\/Linux/menu title Debian Ultimate (Devuan GNU\/Linux/' \
       -e 's/installation menu$/installation menu)/' \
       -e '/^label install$/,/append/ s|--- quiet|preseed/file=/cdrom/ultimate/preseed.cfg --- quiet|' \
       "$B/menu.cfg"
(cd "$W/iso" && find . -type f ! -name md5sum.txt ! -path './boot/isolinux/*' -exec md5sum {} + > md5sum.txt)

echo "== writing $OUT"
mkdir -p "$(dirname "$OUT")"; rm -f "$OUT"
xorriso -indev "$BASE" -outdev "$OUT" \
	-map "$B/preamble.gz" /boot/isolinux/preamble.gz \
	-map "$B/menu.cfg" /boot/isolinux/menu.cfg \
	-map "$W/iso/md5sum.txt" /md5sum.txt \
	-map "$W/iso/ultimate" /ultimate \
	-boot_image any replay 2>&1 | grep -E "FAILURE|SORRY|WARNING" || true
ls -la "$OUT"
