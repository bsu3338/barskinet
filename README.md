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
- Install RPIBoot in Windows
- Jumper J2
- Create usercfg.txt
- Add `otg_mode=1` for the USB ports to work 

