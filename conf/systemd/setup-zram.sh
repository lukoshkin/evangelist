#!/usr/bin/env bash
# Enables zram-based compressed RAM swap. This is the single biggest anti-hang
# fix on laptops where the current swap lives on a slow disk: zram compresses
# cold pages in RAM (~2-3x) and avoids disk I/O thrashing entirely.
#
# Run with: sudo bash setup-zram.sh

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "must run as root (sudo bash setup-zram.sh)" >&2
  exit 1
fi

apt update
apt install -y zram-tools

# Defaults in /etc/default/zramswap are usually fine (PERCENT=50, ALGO=lz4).
# Bump size a bit and use zstd for better compression if you want:
sed -i 's/^#\?PERCENT=.*/PERCENT=75/'     /etc/default/zramswap
sed -i 's/^#\?ALGO=.*/ALGO=zstd/'         /etc/default/zramswap
sed -i 's/^#\?PRIORITY=.*/PRIORITY=100/'  /etc/default/zramswap

systemctl enable --now zramswap.service
systemctl restart zramswap.service

echo "--- current swap devices ---"
swapon --show
echo
echo "zram should appear with higher PRIO than /swap.img."
echo "To drop the disk swapfile entirely (optional):"
echo "  sudo swapoff /swap.img && sudo rm /swap.img"
echo "  then remove its line from /etc/fstab"
