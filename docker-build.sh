#!/bin/bash
set -e

mkdir -p output tmp

docker run --rm --privileged \
    -v "$PWD:/workspace" \
    ubuntu:22.04 \
    bash /workspace/build-script.sh

echo "Build complete: output/octoprint-orangepi4.img.xz"