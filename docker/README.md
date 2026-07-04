# docker/ — local ZMK "CI" build

Reproduces the GitHub Actions build (`build-user-config`) on your own machine with
Docker: builds **every** entry in [`../build.yaml`](../build.yaml) and writes named
`.uf2` files to `../firmware/`.

Because the board and the `nice_view_gem` shield (with the hummingbird animation)
are vendored in this repo, the build pulls only ZMK itself — nothing external.

## Use

```powershell
# Windows (PowerShell)
.\docker\run-ci.ps1
```

```bash
# Linux / macOS / WSL
./docker/run-ci.sh
```

Requires Docker Desktop / Docker running. Flash the results (`firmware\*.uf2`) by
double-tapping reset on a half and dragging its `.uf2` onto the `NICENANO` drive.

## What the scripts do

1. **Build the image if needed** — `zmk-eyelash-ci`, a thin tag over
   `zmkfirmware/zmk-build-arm:stable` (which already has python3 + pyyaml, used to
   read `build.yaml`). Built once; reused after.
2. **Mount a cached volume** — `zmk-ws` holds ZMK + Zephyr + modules so only the
   first run downloads them.
3. **Run the pipeline** (`ci-pipeline.sh`, inside the container): `west init` /
   `update` / `zephyr-export`, then `west build` for each `build.yaml` entry with
   `-DZMK_EXTRA_MODULES=<repo>` (how ZMK CI discovers this repo's board + shield).

## Handy

- Rebuild the image after editing the `Dockerfile`: `docker build -t zmk-eyelash-ci docker`
- Start from a clean workspace (re-download ZMK/Zephyr): `docker volume rm zmk-ws`

## Files

| File | Runs on | Purpose |
| --- | --- | --- |
| `Dockerfile` | — | thin tag over the ZMK build image |
| `parse-build-matrix.py` | container | read `build.yaml` (python3 + pyyaml) |
| `ci-pipeline.sh` | container | build every `build.yaml` entry |
| `run-ci.ps1` | Windows host | wrapper |
| `run-ci.sh` | Linux/macOS/WSL host | wrapper |
