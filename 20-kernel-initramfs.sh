#!/bin/bash
set -Eeuo pipefail
set -x

ROOT=build

mkdir -p "$ROOT"/boot
docker run --rm -i \
	-v $(realpath docker):/mnt/builder:ro \
	-v $(realpath "$ROOT"/boot):/mnt/build \
	-v $(realpath rootfs_overrides/etc/apt/sources.list):/etc/apt/sources.list:ro \
	debian:buster-slim /mnt/builder/00-initramfs.sh
ls -alh "$ROOT"/boot
