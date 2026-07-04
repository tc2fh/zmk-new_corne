# Local build image for the Eyelash Corne firmware.
#
# The stock ZMK toolchain image already includes python3 + pyyaml, which
# ci-pipeline.sh uses to read build.yaml (the image ships no curl/wget/yq).
# Kept as a thin, named layer ("zmk-eyelash-ci") so it's a stable target and
# easy to extend later.
FROM zmkfirmware/zmk-build-arm:stable
