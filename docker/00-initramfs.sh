#!/bin/bash
set -Eeuo pipefail
set -x

# build kernel and initramfs

ROOT=/mnt/build

apt-get update -y
apt-get upgrade -y
apt-get install -y linux-image-amd64 initramfs-tools live-boot intel-microcode amd64-microcode

cp -r /boot/* "$ROOT"

