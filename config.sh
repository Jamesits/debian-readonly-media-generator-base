#!/bin/bash

ROOT=build
export LANG=C.UTF-8
export DEBIAN_FRONTEND=noninteractive
IMAGE=debian.img
KERNEL_ARGS_FAST="noibrs noibpb nopti nospectre_v2 nospectre_v1 l1tf=off nospec_store_bypass_disable no_stf_barrier mds=off tsx=on tsx_async_abort=off mitigations=off"
KERNEL_ARGS_LIVE="boot=live forcefsck ignore_uuid live-media-path=/system swap=true noeject ip=frommedia" 
KERNEL_ARGS_MISC="console=ttyS0,9600 console=tty1 lockdown"
KERNEL_ARGS_NORM="panic=5"
KERNEL_ARGS_PERSISTENT="persistence persistence-label=userdata persistence-storage=filesystem"
KERNEL_ARGS_NOPERSISTENT="nopersistence"
GRUB_MODULES="biosdisk disk part_gpt fat file configfile search search_fs_file echo ls reboot usb_keyboard at_keyboard minicmd"
ADD_PACKAGES="sudo curl gnupg2 frr vim mtr-tiny tcpdump bmon htop ssh telnet netcat socat nmap zmap hping3 arping arp-scan dnsutils traceroute ndisc6 sipcalc charon-systemd libcharon-extra-plugins libstrongswan-extra-plugins tshark openvpn qemu-guest-agent open-vm-tools iptables-persistent shadowsocks-libev snmpd"
ADD_PACKAGES_UNSTABLE="wireguard bird2"
APT_OPTIONS="-o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold"
declare -a SYSTEMD_ENABLE_UNITS=("acpid.service")
declare -a SYSTEMD_DISABLE_UNITS=("bird.service" "frr.service" "ssh.service" "shadowsocks-libev.service" "snmpd.service")
