#!/usr/bin/env bash
# Runs INSIDE the container (invoked by docker/run-ci.ps1 or run-ci.sh).
# Reproduces ZMK's build-user-config CI locally: builds EVERY entry in
# /repo/build.yaml and writes named artifacts to /out.
#
#   /workspace        persistent "zmk-ws" docker volume (ZMK + Zephyr + modules)
#   /workspace/config repo config/ (west.yml, keymap, conf)
#   /repo             repo root (board + shield, added via ZMK_EXTRA_MODULES)
#   /out              firmware output (../firmware on the host)
#   /docker           this docker/ folder (for parse-build-matrix.py)
set -uo pipefail
cd /workspace

# 1) workspace: init once, always update (mirrors CI; fast when up to date)
if [ ! -d /workspace/.west ]; then
  echo "== west init =="
  west init -l config
fi
echo "== west update (a few minutes on first run, cached afterward) =="
west update
echo "== west zephyr-export =="
west zephyr-export

# 2) build every entry in build.yaml (parsed with python3+pyyaml; the image has no yq)
BUILD_YAML=/repo/build.yaml
mapfile -t ENTRIES < <(python3 /docker/parse-build-matrix.py "$BUILD_YAML")
n=${#ENTRIES[@]}
echo "== building ${n} configuration(s) from build.yaml =="
mkdir -p /out
rc=0
for line in "${ENTRIES[@]}"; do
  IFS=$'\x1f' read -r idx board shield snippet cmake_args artifact <<< "$line"
  [ -z "$artifact" ] && artifact="${board}${shield:+-$shield}"

  echo ""
  echo "======== [$((idx + 1))/${n}] ${artifact} ========"
  echo "board=${board}  shield=${shield:-<none>}  snippet=${snippet:-<none>}  cmake-args=${cmake_args:-<none>}"

  westargs=(-p -s zmk/app -d "/workspace/build/$idx" -b "$board")
  [ -n "$snippet" ] && westargs+=(-S "$snippet")
  cmakeargs=(-DZMK_CONFIG=/workspace/config -DZMK_EXTRA_MODULES=/repo)
  [ -n "$shield" ] && cmakeargs+=(-DSHIELD="$shield")
  read -ra extra_cmake <<< "$cmake_args"   # split "-Dx=y -Dz=w" into args (empty -> none)

  if west build "${westargs[@]}" -- "${cmakeargs[@]}" "${extra_cmake[@]}"; then
    copied=""
    for ext in uf2 bin hex; do
      if [ -f "/workspace/build/$idx/zephyr/zmk.$ext" ]; then
        cp "/workspace/build/$idx/zephyr/zmk.$ext" "/out/${artifact}.$ext"
        echo "  -> ${artifact}.$ext"
        copied=1; break
      fi
    done
    [ -z "$copied" ] && { echo "  !! no output binary produced for ${artifact}"; rc=1; }
  else
    echo "  !! BUILD FAILED: ${artifact}"; rc=1
  fi
done

echo ""
echo "======== done (rc=${rc}) ========"
ls -la /out
exit $rc
