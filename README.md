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
 17. Run `ps aux` Notice the user the pi processes are running. We want to create users for the pi container to runas 
 18. Enter the container with `nerdctl exec -it pihole /bin/bash` and then do `cat /etc/passwd` Note the pihole userid and www-data userid 
   - `exit` to leave container back to the host
 19.Create a pihole user and piwww user
   - `adduser pihole --disabled-password`
   - `adduser pihole_www-data --disabled-password`
   - `cat /etc/passwd`
   - Note the userid of each, example 1001 and 1002
  20. Edit environment variables
    - PIHOLE_UID: 1001
    - PIHOLE_GID: 1001
    - WEB_UID: 1002
    - WEB_GID: 1002
  21. Down and up the compose file or just up it again   

## Rootless
### Learning Objectives
- Rootless Containers

### Lab
[nerdctl rootless](https://github.com/containerd/nerdctl/blob/main/docs/rootless.md)
[Upgrade Alpine to New Release](https://wiki.alpinelinux.org/wiki/Upgrading_Alpine)

1. Required rootlesskit and slirp4netns can only be found in the edge repositories
2. edit /etc/apk/repositories
3. Comment out current version and uncomment edge main and community
4. `apk update`
5. `apk add --upgrade apk-tools`
6. `apk upgrade --available` 
7. `apk install rootlesskit` needed by containerd-rootless.sh
8. `apk install slirp4netns` needed by containerd-rootless.sh
9. `apk add iproute2-minimal` needed by containerd-rootless.sh
10. `modprobe tun` Need to add instructions to include on startup
11. `mkdir /run/user`
12. `chmod 1777 /run/user`  Sticky bit is important
13. create file /etc/profile.d/xdg_runtime_dir.sh
```
if test -z "${XDG_RUNTIME_DIR}"; then
  export XDG_RUNTIME_DIR=/run/user/$(id -u)
  if ! test -d "${XDG_RUNTIME_DIR}"; then
    mkdir "${XDG_RUNTIME_DIR}"
    chmod 0700 "${XDG_RUNTIME_DIR}"
  fi
fi
```
10. Set password to the pihole user to login and out, then disable
- passwd pihole temppass
- login pihole
- exit
- passwd -l pihole
12. Switch to the pihole user `su - pihole` the dash is important to set the XDG_RUNTIME_VARIABLE
13. edit /etc/subuid  
 - pihole:231072:65536
15. edit /etc/subgid
 - pihole:231072:65536
17. `containerd-rootless.sh`
18. 

### Lab Full Containerd Install
[nerdctl rootless](https://github.com/containerd/nerdctl/blob/main/docs/rootless.md)
[Upgrade Alpine to New Release](https://wiki.alpinelinux.org/wiki/Upgrading_Alpine)

1. Required rootlesskit and slirp4netns can only be found in the edge repositories
2. edit /etc/apk/repositories
3. Comment out current version and uncomment edge main and community
4. `apk update`
5. `apk add --upgrade apk-tools`
6. `apk upgrade --available` 
9. `apk add iproute2-minimal` needed by containerd-rootless.sh
10. `apk add curl` need to check github for most recent version
11. `modprobe tun` Need to add instructions to include on startup
12. `modprobe ip_tables`
13. `modprobe ip6_tables`
14. sysctl net.ipv4.ip_unprivileged_port_start=0  #needed to bind to lower ports
15. create file /etc/profile.d/xdg_runtime_dir.sh
```
if test -z "${XDG_RUNTIME_DIR}"; then
  export XDG_RUNTIME_DIR=/tmp/$(id -u)
  if ! test -d "${XDG_RUNTIME_DIR}"; then
    mkdir "${XDG_RUNTIME_DIR}"
    chmod 0700 "${XDG_RUNTIME_DIR}"
  fi
fi
```
12. Switch to the pihole user `su - pihole` the dash is important to set the XDG_RUNTIME_VARIABLE
13. edit /etc/subuid  
 - pihole:100100000:65536
15. edit /etc/subgid
 - pihole:100100000:65536
17. apk add shadow-subids
- apk add util-linux-misc
- # Needed to prevent error The host root filesystem is mounted as "". Setting child propagation to "rslave" is not supported.
- cd /etc/local.d/
- touch mount.start
- echo ???mount --make-rshared /??? > mount.start
- chmod +x mount.start
- rc-update add local
- Enable cgroups 
- set rc.conf rc_cgroup_mode="unified"
- rc-service cgroups start
- rc-update add cgroups 

- `containerd-rootless.sh`
18. 

## Setup Private Registry to Host Docker Containers

## Side Project
- apk add libc6-compat
- download full version of containerd
- Enable cgroups 
- set rc.conf rc_cgroup_mode="unified"
- rc-service cgroups start
- rc-update add cgroups

