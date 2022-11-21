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
5. do a sys install on the NVME
6. mkdir /mnt/newroot
7. mount /dev/nvme0n1p2 /mnt/newroot/
8. mount /dev/nvme0n1p1 /mnt/newroot/boot
9. cp /media/mmcblk0p1/usercfg.txt /mnt/newboot/boot
10. chroot /mnt/newroot
11. 
