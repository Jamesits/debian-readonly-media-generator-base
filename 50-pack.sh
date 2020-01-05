#!/bin/bash
set -Eeuo pipefail
set -x

tar -cvzf "$ROOT/$IMAGE".tar.gz "$ROOT/$IMAGE"

ls -alh "$ROOT/$IMAGE".tar.gz
