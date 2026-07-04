#!/usr/bin/env bash
# Runs INSIDE the zmkfirmware/zmk-build-arm container (invoked by build-firmware.ps1).
# Builds both halves of the eyelash_corne with the nice_view_gem shield.
#   /workspace        -> persistent "zmk-ws" docker volume (ZMK + Zephyr + modules)
#   /workspace/config -> this repo's config/ (keymap, conf, west.yml)
#   /repo             -> this repo root (provides boards/arm/eyelash_corne via BOARD_ROOT)
#   the hummingbird crystal.c is bind-mounted over nice-view-gem's asset
set -uo pipefail
cd /workspace
west zephyr-export >/dev/null 2>&1
mkdir -p /out
rc=0
for side in left right; do
  echo "======== building eyelash_corne_${side} ========"
  west build -p -s zmk/app -d /workspace/build/${side} \
    -b eyelash_corne_${side} \
    -- -DSHIELD=nice_view_gem \
       -DZMK_CONFIG=/workspace/config \
       -DBOARD_ROOT=/repo || rc=1
  uf2=/workspace/build/${side}/zephyr/zmk.uf2
  if [ -f "$uf2" ]; then
    cp "$uf2" /out/eyelash_corne_${side}.uf2
    echo "  -> eyelash_corne_${side}.uf2 ($(stat -c%s "$uf2") bytes)"
  else
    echo "  !! FAILED: no uf2 for ${side}"; rc=1
  fi
done
echo "======== done (rc=${rc}) ========"
ls -la /out
exit $rc
