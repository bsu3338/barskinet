# BarskiNet
This is an experiment to learn Alpine, ARM, Containers, Security, and Enterprise Infrastruicture

Use any of this at your own risk!!

Tools used, but may be swapped out with preffered container technology

## Hardware
- 4x 8GB Raspberry Pi 4 
- 4x 500GB SSDs

## Software
- [Alpine](https://www.alpinelinux.org)
&ndash; Minimal based Linux Distribution 
- [NerdCtl](https://github.com/containerd/nerdctl)
&ndash; Command line utility to administer containerd
- [Container Network Interface](https://github.com/containernetworking/cni)
- [SmallStep-CA]
- [Authelia]
- [Vaultwarden]
- [Dashy]
- [Uptime Kuma]
- [Netbox]
- [Minio]
- [Keepalived]
- [DRBD]

## Setup Alpine on Raspberry Pi
[Alpine Pi Instructions](https://wiki.alpinelinux.org/wiki/Raspberry_Pi)

For Cm4
1. Install RPIBoot in Windows
2. Jumper J2
3. Create usercfg.txt
4. Add `otg_mode=1` for the USB ports to work 
5. remove jumper
6. Unplug NVME Drive before install to install on emmc
7. do a sys install on the mmcblk0
8. poweroff 
9. plug in NVME
10. boot
11. fdisk /dev/nvme0n1
12. Create new partition
13. mkfs.ext4 /dev/nvme0n1p1
14. Note UUID
15. edit fstab
16. UUID=14886657-84eb-4cec-85a7-de78cdfd1724       /       ext4    rw,relatime 0 1

