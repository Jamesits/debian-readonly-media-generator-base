#!/bin/bash
set -Eeuo pipefail
set -x

ROOT=build

mkdir -p "$ROOT"/boot
docker run --rm -it -v $(realpath docker):/mnt/builder:ro -v $(realpath "$ROOT"/boot):/mnt/build debian:buster-slim /mnt/builder/00-initramfs.sh
ls -alh "$ROOT"/boot
