# Reproduce the ZMK GitHub Actions build locally with Docker (Windows).
# Usage:  .\docker\run-ci.ps1
#
# Builds every entry in ..\build.yaml and drops named .uf2 files in ..\firmware\.
# Requires Docker Desktop running.
#
# Note: no `$ErrorActionPreference = "Stop"` on purpose — native tools (docker)
# write progress to stderr, which Stop would misread as a fatal error. We check
# $LASTEXITCODE explicitly and `throw` on real failures instead.

$Here = $PSScriptRoot
$Repo = Split-Path $Here -Parent
$Img  = "zmk-eyelash-ci"
$Out  = Join-Path $Repo "firmware"

# 1) build the local image if missing (pulls the ZMK toolchain base + adds yq).
#    `docker images -q` prints the id if present, nothing if not — no stderr.
$imgId = docker images -q $Img
if (-not $imgId) {
    Write-Host "Building local CI image ($Img)..." -ForegroundColor Yellow
    docker build -t $Img $Here
    if ($LASTEXITCODE -ne 0) { throw "docker build failed" }
}

New-Item -ItemType Directory -Force $Out | Out-Null

# 2) run the pipeline (init/update the cached workspace, build all of build.yaml)
Write-Host "Running CI pipeline (building every entry in build.yaml)..." -ForegroundColor Cyan
docker run --rm `
    -v zmk-ws:/workspace `
    -v "${Repo}\config:/workspace/config" `
    -v "${Repo}:/repo" `
    -v "${Here}:/docker" `
    -v "${Out}:/out" `
    -w /workspace $Img `
    bash -c "tr -d '\r' < /docker/ci-pipeline.sh | bash"
if ($LASTEXITCODE -ne 0) { throw "CI pipeline failed" }

Write-Host "`nArtifacts -> $Out" -ForegroundColor Green
Get-ChildItem $Out -Filter *.uf2 | Format-Table Name, Length, LastWriteTime
