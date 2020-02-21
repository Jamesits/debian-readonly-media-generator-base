#!/bin/bash
set -Eeuo pipefail
set -x

source ./config.sh

rm -rf --one-file-system "$ROOT"
mkdir -p "$ROOT"
