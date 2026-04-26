#!/usr/bin/env bash
# Installs systemd-oomd drop-ins + sysctl tuning to make the kernel + oomd
# react to memory pressure before the machine thrashes to a hang.
#
# Run with: sudo bash apply.sh
# Source of truth for the files lives in ./files/ next to this script.

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "must run as root (sudo bash apply.sh)" >&2
  exit 1
fi

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
SRC="$SCRIPT_DIR/files"

install -D -m 0644 "$SRC/etc/systemd/oomd.conf.d/override.conf"          /etc/systemd/oomd.conf.d/override.conf
install -D -m 0644 "$SRC/etc/systemd/system/-.slice.d/10-oomd.conf"       /etc/systemd/system/-.slice.d/10-oomd.conf
install -D -m 0644 "$SRC/etc/systemd/system/user@.service.d/10-oomd.conf" /etc/systemd/system/user@.service.d/10-oomd.conf
install -D -m 0644 "$SRC/etc/systemd/system/system.slice.d/10-oomd.conf"  /etc/systemd/system/system.slice.d/10-oomd.conf
install -D -m 0644 "$SRC/etc/sysctl.d/99-swap.conf"                       /etc/sysctl.d/99-swap.conf

systemctl daemon-reload
systemctl restart systemd-oomd
sysctl --system | tail -n 5

echo "--- applied. verify with: oomctl ---"
