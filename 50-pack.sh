#!/bin/bash
set -Eeuo pipefail
set -x

source ./config.sh

cd "$ROOT"
tar -cvzf "$IMAGE".tar.gz "$IMAGE"
qemu-img convert -f raw -O qcow2 "$IMAGE" "$IMAGE".qcow2
qemu-img convert -f raw -O vmdk -o adapter_type=lsilogic,subformat=streamOptimized,compat6 "$IMAGE" "$IMAGE".vmdk
qemu-img convert -f raw -O vhdx "$IMAGE" "$IMAGE".vhdx
ls -alh 
