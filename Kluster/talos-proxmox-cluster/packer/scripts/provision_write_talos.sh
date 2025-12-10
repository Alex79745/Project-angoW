#!/usr/bin/env bash
set -euo pipefail
IMAGE_URL="$1"
TMP=/tmp/talos.raw.xz

# wait for network
for i in {1..30}; do
  if ping -c1 -W1 8.8.8.8 >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

# download
curl -L "$IMAGE_URL" -o "$TMP"

# write to disk
xz -d -c "$TMP" | dd of=/dev/sda bs=4M status=progress conv=fsync
sync

# ensure disk written; poweroff (Packer will convert to template)
poweroff -f