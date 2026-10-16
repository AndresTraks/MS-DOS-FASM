#!/bin/sh
set -e
cd "$(dirname "$0")"
QEMU=${QEMU:-qemu-system-i386}

./create_image.sh

if ! command -v "$QEMU" >/dev/null 2>&1; then
    echo "$QEMU not found. Please install QEMU." >&2
    exit 1
fi

exec "$QEMU" -rtc base=localtime -drive file=msdos.img,format=raw,if=floppy \
    -audiodev "${AUDIODEV:-pa}",id=snd0 -machine pc,pcspk-audiodev=snd0
