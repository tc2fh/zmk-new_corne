# Build eyelash_corne firmware (both halves) locally with Docker + the nice_view_gem
# hummingbird display. Run from anywhere:  .\local-build\build-firmware.ps1
#
# Requirements: Docker Desktop running. First run downloads ZMK + Zephyr into a
# persistent docker volume ("zmk-ws"); later runs reuse it and are fast.
#
# Output: firmware\eyelash_corne_left.uf2 and firmware\eyelash_corne_right.uf2

$ErrorActionPreference = "Stop"

# --- paths (edit if you move these repos) ---
$Repo    = "C:\Users\Tien\Documents\local_coding_projects\zmk-new_corne"
$Gem     = "C:\Users\Tien\Documents\local_coding_projects\nice-view-gem"   # branch: hummingbird (v0.3.0 + LVGL-8 art)
$Img     = "zmkfirmware/zmk-build-arm:stable"
$Scripts = "$Repo\local-build"
$Out     = "$Repo\firmware"
$Crystal = "$Gem\boards\shields\nice_view_gem\assets\crystal.c"

New-Item -ItemType Directory -Force $Out | Out-Null

# 1) one-time workspace setup (ZMK v0.3 + Zephyr 3.5 + modules) into the zmk-ws volume
$hasWest = (docker run --rm -v zmk-ws:/workspace $Img bash -c "test -d /workspace/.west && echo YES" | Out-String).Trim()
if ($hasWest -ne "YES") {
    Write-Host "First run: initializing west workspace (downloads ZMK + Zephyr, a few minutes)..." -ForegroundColor Yellow
    docker run --rm -v zmk-ws:/workspace -v "${Repo}\config:/workspace/config" $Img `
        bash -c "cd /workspace && west init -l config && west update"
    if ($LASTEXITCODE -ne 0) { throw "west setup failed" }
}

# 2) build both halves; the hummingbird crystal.c is bind-mounted over v0.3.0's asset
Write-Host "Building both halves with the hummingbird animation..." -ForegroundColor Cyan
docker run --rm `
    -v zmk-ws:/workspace `
    -v "${Repo}\config:/workspace/config" `
    -v "${Repo}:/repo" `
    -v "${Crystal}:/workspace/nice-view-gem/boards/shields/nice_view_gem/assets/crystal.c" `
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
