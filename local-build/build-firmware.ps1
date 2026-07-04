# Build eyelash_corne firmware (both halves) locally with Docker.
# Run from anywhere:  .\local-build\build-firmware.ps1
#
# Self-contained: the board and the nice_view_gem shield (with the hummingbird
# animation) are vendored in this repo, so only ZMK itself is downloaded.
# Requirements: Docker Desktop running. First run downloads ZMK + Zephyr into a
# persistent docker volume ("zmk-ws"); later runs reuse it and are fast.
#
# Output: firmware\eyelash_corne_left.uf2 and firmware\eyelash_corne_right.uf2

$ErrorActionPreference = "Stop"

# --- paths (edit $Repo if you move it) ---
$Repo    = "C:\Users\Tien\Documents\local_coding_projects\zmk-new_corne"
$Img     = "zmkfirmware/zmk-build-arm:stable"
$Scripts = "$Repo\local-build"
$Out     = "$Repo\firmware"

New-Item -ItemType Directory -Force $Out | Out-Null

# 1) one-time workspace setup (ZMK v0.3 + Zephyr 3.5 + modules) into the zmk-ws volume
$hasWest = (docker run --rm -v zmk-ws:/workspace $Img bash -c "test -d /workspace/.west && echo YES" | Out-String).Trim()
if ($hasWest -ne "YES") {
    Write-Host "First run: initializing west workspace (downloads ZMK + Zephyr, a few minutes)..." -ForegroundColor Yellow
    docker run --rm -v zmk-ws:/workspace -v "${Repo}\config:/workspace/config" $Img `
        bash -c "cd /workspace && west init -l config && west update"
    if ($LASTEXITCODE -ne 0) { throw "west setup failed" }
}

# 2) build both halves; board + shield come from this repo via ZMK_EXTRA_MODULES
Write-Host "Building both halves (nice_view_gem + hummingbird)..." -ForegroundColor Cyan
docker run --rm `
    -v zmk-ws:/workspace `
    -v "${Repo}\config:/workspace/config" `
    -v "${Repo}:/repo" `
    -v "${Scripts}:/scripts" `
    -v "${Out}:/out" `
    -w /workspace $Img `
    bash -c "tr -d '\r' < /scripts/build_firmware.sh | bash"

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nOK -> $Out" -ForegroundColor Green
    Get-ChildItem $Out -Filter *.uf2 | Format-Table Name, Length, LastWriteTime
} else {
    throw "firmware build failed"
}
