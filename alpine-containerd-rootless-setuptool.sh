#!/bin/sh
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at

#       http://www.apache.org/licenses/LICENSE-2.0

#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

# Description
# Use to setup Alpine linux to use rootless containers

# utility functions
INFO() {
        # https://github.com/koalaman/shellcheck/issues/1593
        # shellcheck disable=SC2039
        /bin/echo -e "\e[104m\e[97m[INFO]\e[49m\e[39m ${*}"
}

WARNING() {
        # shellcheck disable=SC2039
        /bin/echo >&2 -e "\e[101m\e[97m[WARNING]\e[49m\e[39m ${*}"
}

ERROR() {
        # shellcheck disable=SC2039
        /bin/echo >&2 -e "\e[101m\e[97m[ERROR]\e[49m\e[39m ${*}"
}

# constants
CONTAINERD_ROOTLESS_SH="containerd-rootless.sh"

# global vars
ARG0="$0"
REALPATH0="$(realpath "$ARG0")"
BIN=""
NERDCTL_FULL=""
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"


# Read environment variables from file


# If variables are not provided then request input from user


# run checks and also initialize global vars (BIN)
# Many check are specific to Alpine to make rootlesskit work
init() {
        id="$(id -u)"
        # User verification: must be running as root
        if [ ! "$id" = "0" ]; then
                ERROR "Root user is required to setup prerequisites to install rootless containerd for Alpine linux."
                exit 1
        fi

        # Add community repository
        # May need to adjust if using edge
        #sed -i -e 's:^#\(http.*/community\):\1:' /etc/apk/repositories

        #
        PKGLIST=""
        if ! apk list iptables | grep installed  >/dev/null 2>&1; then
                INFO Require iptables
                PKGLIST="$PKGLIST iptables"
        fi

        if ! apk list ip6tables | grep installed  >/dev/null 2>&1; then
                INFO Require ip6tables
                PKGLIST="$PKGLIST ip6tables"
        fi

        if ! apk list shadow-subids | grep installed  >/dev/null 2>&1; then
                INFO Require shadow-subids
                PKGLIST="$PKGLIST shadow-subids"
        fi

        if ! apk list util-linux-misc | grep installed  >/dev/null 2>&1; then
                INFO Require util-linux-misc
                PKGLIST="$PKGLIST util-linux-misc"
        fi

        if ! apk list iproute2-minimal | grep installed  >/dev/null 2>&1; then
                INFO Require iproute2-minimal
                PKGLIST="$PKGLIST iproute2-minimal"
        fi

        if ! apk list curl | grep installed  >/dev/null 2>&1; then
                INFO Require curl
                PKGLIST="$PKGLIST curl"
        fi

        #If PKGLIST is not empty install packages
        if [ -n "$PKGLIST" ]; then
                INFO Installing $PKGLIST
                apk update
                apk add $PKGLIST
        fi


        # set BIN
        if ! BIN="$(command -v "$CONTAINERD_ROOTLESS_SH" 2>/dev/null)"; then
                ERROR "$CONTAINERD_ROOTLESS_SH needs to be present under \$PATH"
                # Install latest version of nerdctl full
                NERDCTL_RELEASE=$(curl --silent "https://api.github.com/repos/containerd/nerdctl/releases/latest" |
                        grep '"tag_name":' |
                        sed -E 's/[^0-9.]//g')
                ARCH=`arch`
                INFO Detected $ARCH
                if [ $ARCH = "aarch64" ]; then
                        NERDCTL_FULL=https://github.com/containerd/nerdctl/releases/download/v1.0.0/nerdctl-full-$NERDCTL_RELEASE-linux-arm64.tar.gz
                elif [ $ARCH = "x86_64" ]; then
                        NERDCTL_FULL=https://github.com/containerd/nerdctl/releases/download/v1.0.0/nerdctl-full-$NERDCTL_RELEASE-linux-amd64.tar.gz
                else
                        ERROR Architecture $ARCH not supported
                        exit 1
                fi
                INFO "Installing $NERDCTL_FULL"
                cd /usr/local/
                wget $NERDCTL_FULL
                tar -xzf nerdctl-full*.tar.gz
                rm nerdctl-full*.tar.gz
                if BIN="$(command -v "$CONTAINERD_ROOTLESS_SH" 2>/dev/null)"; then
                        INFO Nerdctl Full installed
                fi
        fi
        BIN=$(dirname "$BIN")

        # detect systemd
        if systemctl --user show-environment >/dev/null 2>&1; then
                ERROR "Script should only br ran on an Alpine OpenRC system. systemd is not supported"
                exit 1
        fi

        # Enable cgroups2
        if ! grep -x rc_cgroup_mode=\"unified\" /etc/rc.conf >/dev/null 2>&1; then
                INFO Configuring cgroups2
                sed -i '/rc_cgroup_mode=/c\rc_cgroup_mode=\"unified\"' /etc/rc.conf
        fi
        
        if ! rc-update | grep cgroups | grep default >/dev/null 2>&1; then
                rc-update add cgroups
                rc-service cgroups start
        fi


        # Check then install required packages
        # Add community repository

        # Add required kernel modules
        if ! lsmod | grep ip_tables >/dev/null 2>&1; then
                INFO Add module ip_tables to /etc/modules.d/rootless
                modprobe ip_tables
                echo ip_tables >> /etc/modprobe.d/rootless.conf
        fi

        if ! lsmod | grep ip6_tables >/dev/null 2>&1; then
                INFO Add module ip6_tables to /etc/modules.d/rootless
                modprobe ip6_tables
                echo ip6_tables >> /etc/modprobe.d/rootless.conf
        fi

        if ! lsmod | grep tun >/dev/null 2>&1; then
                INFO Add module tun to /etc/modules.d/rootless
                modprobe tun
                echo ip_tables >> /etc/modprobe.d/rootless.conf
        fi


        # Set sysctl

        # Configure mount so rootlesskit can use rslave

        # Validate XDG_RUNTIME_DIR set in /etc/profile.d
        if ! grep XDG_RUNTIME_DIR /etc/profile.d/* >/dev/null 2>&1; then
                INFO installing rootless.sh script to set XDG_RUNTIME_DIR variable in /etc/profile.d
                cat <<-EOF > /etc/profile.d/rootless.sh
                        if test -z "${XDG_RUNTIME_DIR}"; then
                          export XDG_RUNTIME_DIR=/tmp/$(id -u)
                          if ! test -d "${XDG_RUNTIME_DIR}"; then
                            mkdir "${XDG_RUNTIME_DIR}"
                            chmod 0700 "${XDG_RUNTIME_DIR}"
                          fi
                        fi
                      EOF
       fi
}

# CLI subcommand: "check"
cmd_entrypoint_check() {
        init
        INFO "Checking RootlessKit functionality"
#       if ! rootlesskit \
#               --net=slirp4netns \
#               --disable-host-loopback \
#               --copy-up=/etc --copy-up=/run --copy-up=/var/lib \
#               true; then
#               ERROR "RootlessKit failed, see the error messages and https://rootlesscontaine.rs/getting-started/common/ ."
#               exit 1
#       fi

        INFO "Checking cgroup v2"
#       controllers="/sys/fs/cgroup/user.slice/user-${id}.slice/user@${id}.service/cgroup.controllers"
#       if [ ! -f "${controllers}" ]; then
#               WARNING "Enabling cgroup v2 is highly recommended, see https://rootlesscontaine.rs/getting-started/common/cgroup2/ "
#       else
#               for f in cpu memory pids; do
#                       if ! grep -qw "$f" "$controllers"; then
#                               WARNING "The cgroup v2 controller \"$f\" is not delegated for the current user (\"$controllers\"), see https://rootlesscontaine.rs/getting-started/common/cgroup2/"
#                       fi
#               done
#       fi

        INFO "Checking overlayfs"
#       tmp=$(mktemp -d)
#       mkdir -p "${tmp}/l" "${tmp}/u" "${tmp}/w" "${tmp}/m"
#       if ! rootlesskit mount -t overlay -o lowerdir="${tmp}/l,upperdir=${tmp}/u,workdir=${tmp}/w" overlay "${tmp}/m"; then
#               WARNING "Overlayfs is not enabled, consider installing fuse-overlayfs snapshotter (\`$0 install-fuse-overlayfs\`), " \
#                       "or see https://rootlesscontaine.rs/how-it-works/overlayfs/ to enable overlayfs."
#       fi
#       rm -rf "${tmp}"
        INFO "Requirements are satisfied"
}

# Enable cgroups2

# Check then install required packages
# Add community repository

# Check if containerd or rootlesskit are installed and remove them
# Using the binaries from nerdctl full

# Add required modules

# Download nerdctl full

# Set sysctl

# Set subuid and subgid

# Configure mount so rootlesskit can use rslave

# Setup userd

# setup sample compose file with wbitt/network-multitool

# End with instructions for the user to reboot and switch to container user


# text for --help
usage() {
        echo "Usage: ${ARG0} [OPTIONS] COMMAND"
        echo
        echo "A setup tool for an Alpine host running  Rootless containerd (${CONTAINERD_ROOTLESS_SH})."
        echo "Do not confuse this for containerd-rootless-setuptool.sh which is used for systemd based systems"
        echo
        echo "Commands:"
        echo "  check        Check prerequisites"
        echo "  nsenter      Enter into RootlessKit namespaces (mostly for debugging)"
        echo "  install      Install openrc init script and prerequisites"
        echo "  uninstall    Uninstall openrc init script and remove prerequisites"
        echo
        echo "Add-on commands (User Maintenance):"
        echo "  install-user            Install the openrc scripts for user"
        echo "  install-compose-sample  Install sample docker-compose.yaml for user"
        echo "  uninstall-user          Uninstall the openrc scripts for user"
}

# parse CLI args
if ! args="$(getopt -o h --long help -n "$ARG0" -- "$@")"; then
        usage
        exit 1
fi
eval set -- "$args"
while [ "$#" -gt 0 ]; do
        arg="$1"
        shift
        case "$arg" in
        -h | --help)
                usage
                exit 0
                ;;
        --)
                break
                ;;
        *)
                # XXX this means we missed something in our "getopt" arguments above!
                ERROR "Scripting error, unknown argument '$arg' when parsing script arguments."
                exit 1
                ;;
        esac
done

command=$(echo "${1:-}" | sed -e "s/-/_/g")
if [ -z "$command" ]; then
        ERROR "No command was specified. Run with --help to see the usage. Maybe you want to run \`$ARG0 install\`?"
        exit 1
fi

if ! command -v "cmd_entrypoint_${command}" >/dev/null 2>&1; then
        ERROR "Unknown command: ${command}. Run with --help to see the usage."
        exit 1
fi

# main
shift
"cmd_entrypoint_${command}" "$@"
