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
### Learning Objectives
- Raspberry Pi CM4 emmc configuration
- Alpine Installation
- Disk Partitioning
- File System Formating
- fstab file format

### Lab
[Alpine Pi Instructions](https://wiki.alpinelinux.org/wiki/Raspberry_Pi)

For Cm4
1. Install RPIBoot in Windows
2. Jumper J2
3. Create usercfg.txt
4. Add `otg_mode=1` for the USB ports to work 
5. remove jumper
6. Unplug NVME Drive before install to install on emmc
7. If you own a dns name us it or home.arpa [RFC Reference](https://datatracker.ietf.org/doc/html/rfc8375)
8. do a sys install on the mmcblk0
9. poweroff 
10. plug in NVME
11. boot
12. fdisk /dev/nvme0n1
13. Create new partition
14. mkfs.ext4 /dev/nvme0n1p1
15. Note UUID
16. apk add nano
17. edit fstab
18. UUID=14886657-84eb-4cec-85a7-de78cdfd1724       /       ext4    defaults 0 2
19. mount -a
20. date 
21. chronyc -a sources
22. chronyc -a tracking
23. chronyc -a 'burst 4/4'
24. chronyc -a makestep


## Setup Containerd, CNI, and NerdCtl
### Learning Objectives
- Alpine Packages
- Containerd Installation
- Container Network Interface (CNI) Installation
- NerdCTL Installation

### Lab
1. nano /etc/apk/repositories
2. uncomment community in addition to main
3. apk update
4. apk add containerd iptables ip6tables
5. rc-service containerd start
6. rc-update add containerd
7. cd /home/thor/
8. wget https://github.com/containernetworking/plugins/releases/download/v1.1.1/cni-plugins-linux-arm64-v1.1.1.tgz
9. wget https://github.com/containerd/nerdctl/releases/download/v1.0.0/nerdctl-1.0.0-linux-arm64.tar.gz
10. cp nerdctl-1.0.0-linux-arm64.tar.gz /usr/local/bin/
11. cd /usr/local/bin/
12. tar -xzf nerdctl-1.0.0-linux-arm64.tar.gz
13. rm nerdctl-1.0.0-linux-arm64.tar.gz
14. cd /home/thor/
15. mkdir -p /opt/cni/bin
16. cp cni-plugins-linux-arm64-v1.1.1.tgz /opt/cni/bin/
17. tar -xzf cni-plugins-linux-arm64-v1.1.1.tgz
18. rm cni-plugins-linux-arm64-v1.1.1.tgz

## Pi-Hole
### Learning Objectives
- Basic Dcoker Compose File Layout
- DNS
- DHCP
- DNS/DHCP Security Best Practices
- Docker User Group
- Docker Environment file


### Lab
Use the Instructions from [Pi-Hole Quickstart](https://github.com/pi-hole/docker-pi-hole/#quick-start)

1. Place the docker-compose.yml file in the /srv folder to keep all container files on the NVME or external storage
2. Create the below folder structure under srv
  - config &ndash; Used to store configutaion files for all containers 
  - data &ndash; Used to store data files for all containers
3. In future labs, we will be able to backup all of our configurations or data quickly by just grabbing one folder
4. `cd /srv/config/pihole`
5. `mkdir vol`
6. `mkdir env`
7. For every container, we will create the same three folders: vol for persistent volumes, env for environment variables, and secrets to store passwords
8. cd /srv/config/pihole/vol/
9. `mkdir etc-pihole`
10. `mkdir etc-dnsmasq.d`
11. Update docker-compose to use the recently created folders
12. Try processing the docker compose file. First change directory to /srv. My most often used commands:
  - `nerdctl compose up --detach`
  - `nerdctl compose ps`
  - `nerdctl compose down`
  - `nerdctl compose logs`
  - `nerdctl compose logs --follow`
  - `nerdctl compose config`
  - `nerdctl compose pull`
 13. Use the logs option to find the auto generated admin password
 14. Move variables to use an environment file
 15. Do not need secrets because random password is stored encrypted in pihole volume
   - Sometimes environment variables are used just to set the initial password when spinning up a container. Once the password is stored in an encrypted format within the data or configuration file, remove all references to password environment variables and store passwords in a password database
 16. `nerdctl exec -it pihole pihole -a -p`
 17. Run `ps aux`  

## Setup Private Registry to Host Docker Containers


