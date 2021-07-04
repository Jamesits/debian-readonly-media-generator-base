# debian-readonly-media-generator-base

Minimal Debian disk image for network experiments.

[![Build Status](https://dev.azure.com/nekomimiswitch/General/_apis/build/status/debian-readonly-media-generator-base?branchName=master)](https://dev.azure.com/nekomimiswitch/General/_build/latest?definitionId=73&branchName=master)

## Features

This image is mainly built for eve-ng, but it can run on most PCs, servers or in hypervisors. Features we intended to support is listed below; unchecked means not being actively tested currently.

Hypervisor support:
- [x] QEMU
- [x] VMware Workstation
- [ ] VMware ESXi
- [ ] Hyper-V
- [ ] Xen

Firmware types:
- [x] Legacy / CSM
- [x] UEFI

Security features:
- [x] Kernel lockdown mode
- [ ] Secure Boot

Networking features:
- [x] bird 2
- [x] FRRouting
- [x] Kernel MPLS/L3VPN support
- [x] Kernel SR-MPLS/SRv6 support + srext module
- [x] StrongSwan
- [x] OpenVPN
- [x] Wireguard
- [x] DHCP client
- [ ] DHCP server

Network Automation Options:
- [x] Python 3
- [x] SNMP server
- [x] SNMP client

## Usage

### eve-ng

```shell
mkdir /opt/unetlab/addons/qemu/linux-debian
# transfer debian.img.qcow2 to `/opt/unetlab/addons/qemu/linux-debian/virtioa.qcow2`
/opt/unetlab/wrappers/unl_wrapper -a fixpermissions
```

### QEMU

Legacy boot:
```shell
qemu-system-x86_64 -smp 4 -m 4096M -drive file=debian.img.qcow2
```

UEFI boot: TBD

UEFI boot with Secure Boot ([download the required files](https://packages.debian.org/sid/all/ovmf/download)):
```shell
qemu-system-x86_64
    --machine pc-q35-2.5 -smp 4 -m 4096M -boot menu=on \
    -drive if=pflash,format=raw,readonly=on,file=OVMF_CODE_4M.secboot.fd \
    -drive if=pflash,format=raw,file=OVMF_VARS_4M.ms.fd \
    -drive file=debian.img.qcow2
```

## Building

To build the image yourself, please refer to the procedures described in `azure-pipelines.yaml`.

**WARNING:**
- This script might destory your boot config -- only run it from a dedicated CI virtual machine!
