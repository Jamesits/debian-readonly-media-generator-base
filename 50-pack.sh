#!/bin/bash
set -Eeuo pipefail
set -x

ROOT=build
IMAGE=debian.img

cd "$ROOT"
tar -cvzf "$IMAGE".tar.gz "$IMAGE"

ls -alh 
