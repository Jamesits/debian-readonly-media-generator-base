#!/bin/bash

ROOT=build
export LANG=C.UTF-8
export DEBIAN_FRONTEND=noninteractive
IMAGE=debian.img
KERNEL_ARGS_FAST="noibrs noibpb nopti nospectre_v2 nospectre_v1 l1tf=off nospec_store_bypass_disable no_stf_barrier mds=off tsx=on tsx_async_abort=off mitigations=off"
KERNEL_ARGS_LIVE="boot=live forcefsck ignore_uuid live-media-path=/system nopersistence swap=true noeject" 
KERNEL_ARGS_MISC="console=ttyS0,9600 console=tty1 lockdown"
KERNEL_ARGS_NORM="panic=5"
GRUB_MODULES="biosdisk disk part_gpt fat file configfile search search_fs_file echo ls reboot usb_keyboard at_keyboard minicmd"

