#!/bin/bash
set -e

mkdir -p output tmp

# Set up multi-architecture support using Docker's buildx
docker run --rm --privileged tonistiigi/binfmt --install all

# Alternative approach: use the official multiarch setup
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes || true

docker run --rm --privileged \
    -v "$PWD:/workspace" \
    -v /lib/modules:/lib/modules:ro \
    ubuntu:22.04 \
    bash /workspace/build-script.sh

echo "Build complete: output/octoprint-orangepi4.img.xz"