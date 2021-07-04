#!/bin/bash

export LANG=C.UTF-8
export DEBIAN_FRONTEND=noninteractive

ROOT=build
IMAGE=debian.img

KERNEL_ARGS_FAST="noibrs noibpb nopti nospectre_v2 nospectre_v1 l1tf=off nospec_store_bypass_disable no_stf_barrier mds=off tsx=on tsx_async_abort=off mitigations=off"
KERNEL_ARGS_LIVE="boot=live forcefsck ignore_uuid live-media-path=/system swap=true noeject ip=frommedia" 
KERNEL_ARGS_MISC="console=ttyS0,9600 console=tty1"
KERNEL_ARGS_NORM="panic=5"
KERNEL_ARGS_PERSISTENT="persistence persistence-label=userdata persistence-storage=filesystem"
KERNEL_ARGS_NOPERSISTENT="nopersistence"
GRUB_MODULES="biosdisk disk part_gpt fat file configfile search search_fs_file echo ls reboot usb_keyboard at_keyboard minicmd"
ADD_PACKAGES="sudo curl wget lynx w3m gnupg2 frr vim mtr-tiny tcpdump bmon htop ssh telnet netcat-openbsd socat nmap zmap hping3 arping arp-scan iperf3 dnsutils traceroute ndisc6 sipcalc charon-systemd libcharon-extra-plugins libstrongswan-extra-plugins tshark openvpn qemu-guest-agent open-vm-tools nftables iptables-persistent shadowsocks-libev snmpd watchdog tuned tuned-utils tuned-utils-systemtap tmux screen byobu software-properties-common nload pciutils chrony resolvconf build-essential git man-db wireguard bird2 numactl"
ADD_PACKAGES_UNSTABLE=""
APT_OPTIONS="-o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold"
APT_BACKPORT_RELEASE="buster-backports"
TUNED_PROFILE="virtual-guest"
