#!/bin/bash
set -Eeuo pipefail
set -x

source ./config.sh

apt-get update -y
apt-get install -y qemu-utils grub2-common dosfstools gdisk wget tar debootstrap grub-efi-amd64-signed
