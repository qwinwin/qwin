#!/bin/bash

_red() {
    printf '\033[1;31;31m%b\033[0m' "$1"
}

_green() {
    printf '\033[1;31;32m%b\033[0m' "$1"
}

_yellow() {
    printf '\033[1;31;33m%b\033[0m' "$1"
}

_info() {
    _green "[Info] "
    printf -- "%s" "$1"
    printf "\n"
}

_warn() {
    _yellow "[Warning] "
    printf -- "%s" "$1"
    printf "\n"
}

_error() {
    _red "[Error] "
    printf -- "%s" "$1"
    printf "\n"
    exit 1
}

Check_OS() {
    if [ -f /etc/redhat-release ]; then
        release="centos"
    elif cat /etc/issue | grep -Eqi "debian"; then
        release="debian"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        release="ubuntu"
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
    elif cat /proc/version | grep -Eqi "debian"; then
        release="debian"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        release="ubuntu"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
    else
        release="Unknown"
    fi
}
Get_IP() {
    ip=$(wget -qO- -t1 -T2 ipinfo.io/ip)
    if [[ -z "${ip}" ]]; then
        ip=$(wget -qO- -t1 -T2 api.ip.sb/ip)
        if [[ -z "${ip}" ]]; then
            ip=$(wget -qO- -t1 -T2 members.3322.org/dyndns/getip)
            if [[ -z "${ip}" ]]; then
                ip="VPS_IP"
            fi
        fi
    fi
}
get_opsy() {
    [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

reboot_os() {
    echo
    _info "The system needs to reboot."
    read -p "Do you want to restart system? [y/n]" is_reboot
    if [[ ${is_reboot} == "y" || ${is_reboot} == "Y" ]]; then
        reboot
    else
        _info "Reboot has been canceled..."
        exit 0
    fi
}

opsy=$(get_opsy)
arch=$(uname -m)
lbit=$(getconf LONG_BIT)
kern=$(uname -r)

Check_Docker() {
    docker -v &>/dev/null
    if [ $? -eq 0 ]; then
        echo "Docker already installed"
    else
        echo "Docker has not been installed,please intall docker first"
        exit 0
    fi

}

Reinstall_OS() {
    Check_OS
    case "$release" in
    ubuntu | debian)
        apt-get install -y xz-utils openssl gawk file
        ;;
    centos)
        yum install -y xz openssl gawk file
        ;;
    *)
        echo "Only support Ubuntu/Debian and Centos"
        exit 1
        ;;
    esac
    wget -N https://raw.githubusercontent.com/qwinwin/qwin/dev/reins2.sh && chmod +x reins2.sh
    clear
    echo -n "
--------------------
Default passwd:Vicer
Option[3][5]passwd:
cxthhhhh.com
--------------------
[1] Ubuntu 18.04 x64
[2] Debian 10 x64
[3] CentOS 7.X x64
[4] CentOS 6.9 x64
[5] Windows Server 2019
[6] Debian 9 x64
--------------------
Enter the number:"
    read System_ID
    read -p "(Option)Set passwd or Press 'Enter' to skip:" Set_pass
    if [ -z "$Set_pass" ]; then
        echo "Default password:Vicer"
    fi

    case "$System_ID" in
    1)
        bash reins2.sh -u 18.04 -v 64 -a -p "$Set_pass"
        ;;
    2)
        bash reins2.sh -d 10 -v 64 -a -p "$Set_pass" --mirror 'http://cdn-aws.deb.debian.org/debian'
        ;;
    3)
        bash reins2.sh -dd 'https://dr.kwin.win/down/Image/CentOS_7.X_NetInstallation.vhd.gz' --mirror 'http://deb.debian.org/debian'
        ;;
    4)
        bash reins2.sh -c 6.9 -v 64 -a -p "$Set_pass"
        ;;
    5)
        bash reins2.sh -dd 'https://dr.kwin.win/down/Image/Disk_Windows_Server_2019_DataCenter_CN.vhd.gz' --mirror 'http://deb.debian.org/debian'
        ;;
    6)
        bash reins2.sh -d 9 -v 64 -a -p "$Set_pass"
        ;;
    *)
        echo "Wrong option"
        exit 1
        ;;
    esac

}

Install_BBR() {
    wget -N --no-check-certificate https://raw.githubusercontent.com/qwinwin/qwin/dev/bbr.sh && chmod +x bbr.sh && ./bbr.sh
}

Install_Docker() {
    Check_OS
    case "$release" in
    ubuntu | debian)
        apt-get install -y curl sudo
        ;;
    centos)
        yum install -y curl
        ;;
    esac
    curl -fsSL get.docker.com -o get-docker.sh && sudo sh get-docker.sh
    systemctl enable docker
    systemctl start docker
}

Reboot_OS() {
    echo -e " The system needs to reboot."
    read -p "Do you want to restart system? [y/n]" is_reboot
    if [[ ${is_reboot} == "y" || ${is_reboot} == "Y" ]]; then
        reboot
    else
        echo -e "${green}Info:${plain} Reboot has been canceled..."
        exit 0
    fi
}

Update_Kernel() {
    Check_OS
    case "$release" in
    debian)
        export DEBIAN_FRONTEND=noninteractive
        read main_ver sub_ver <<<$(uname -r | awk -F '.' '{print $1,$2}')
        [[ "$main_ver" > 4 && "$sub_ver" > 5 ]] && exit 1
        apt-get update && apt-get upgrade -y -f
        apt-get install -y curl vim wget unzip apt-transport-https lsb-release ca-certificates gnupg2
        cat >/etc/apt/sources.list <<EOF
deb http://cdn-aws.deb.debian.org/debian $(lsb_release -sc) main contrib non-free
deb http://cdn-aws.deb.debian.org/debian-security $(lsb_release -sc)/updates main contrib non-free
deb http://cdn-aws.deb.debian.org/debian $(lsb_release -sc)-updates main contrib non-free
deb http://cdn-aws.deb.debian.org/debian $(lsb_release -sc)-backports main contrib non-free
deb http://cdn-aws.deb.debian.org/debian $(lsb_release -sc)-proposed-updates main contrib non-free
# deb http://cdn-aws.deb.debian.org/debian $(lsb_release -sc)-backports-sloppy main contrib non-free
EOF
        apt-get -t $(lsb_release -sc)-backports update
        apt-get -y -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" -t $(lsb_release -sc)-backports upgrade
        update-grub
        ;;
    centos)
        rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
        rpm -Uvh https://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
        yum --enablerepo=elrepo-kernel install kernel-ml-devel kernel-ml -y
        grub2-set-default 0
        ;;

    *)
        echo "Only support Debian and Centos"
        exit 1
        ;;
    esac
}

Install_Nginx() {
    wget -O /etc/apt/trusted.gpg.d/nginx-mainline.gpg https://packages.sury.org/nginx-mainline/apt.gpg
    sh -c 'echo "deb https://packages.sury.org/nginx-mainline/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/nginx.list'
    cat >>/etc/apt/preferences <<EOF
Package: nginx*
Pin: release a=buster-backports
Pin-Priority: 499
EOF
    apt-get update
    apt-get install -y nginx-extras
    systemctl enable nginx
}

Install_Percona() {
    wget -O /tmp/percona.deb https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb
    dpkg -i /tmp/percona.deb
    percona-release setup ps80
    apt-get install -y percona-server-server
}

Install_PHP() {
    wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
    sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
    apt-get update
    apt-get install -y php7.4-fpm php7.4-mysql php7.4-curl php7.4-gd php7.4-mbstring php7.4-xml php7.4-xmlrpc php7.4-opcache php7.4-zip php7.4 php7.4-json php7.4-bz2 php7.4-bcmath
    apt-get upgrade -y
}

Download_Xmrig() {
    cd /home
    Check_OS
    case "$release" in
    debian)
        wget -O /tmp/xmr.tgz https://raw.githubusercontent.com/qwinwin/qwin/dev/xmr.tgz && tar -xzvf /tmp/xmr.tgz -C .
        ;;
    centos)
        yum install libdnet-devel hwloc-devel openssl-devel zlib-devel pkgconfig -y
        wget -O /tmp/xmr.tgz https://raw.githubusercontent.com/qwinwin/qwin/dev/xmr_centos.tgz && tar -xzvf /tmp/xmr.tgz -C .
        ;;
    esac
    [ "$?" = 0 ] && sed -i "s/test/$(hostname)/" config.json && echo 'cd /home;nohup ./xmrig >>/dev/null 2>&1 &'

}

Init_System() {
    Check_OS
    case "$release" in
    debian)
        Install_Nginx
        ;;
    centos)
        yum install epel-release python3 wget glibc-devel -y
        # yum install make gcc gcc-c++ zlib-devel pcre-devel openssl-devel -y
        sed -i '/^SELINUX=/d' /etc/selinux/config && echo 'SELINUX=disabled' >>/etc/selinux/config
        sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
        systemctl stop firewalld
        systemctl disable firewalld
        ;;
    esac
    Update_Kernel
}

Get_IP
echo "-------- System Information --------
OS      : $opsy
Arch    : $arch ($lbit Bit)
Kernel  : $kern
IP      : $ip
------------------------------------
[  1  ] : Reinstall OS
[  2  ] : Update Kernel
[  3  ] : Install BBR
[  4  ] : Install Docker
[  5  ] : Install Nginx
[  6  ] : Install Php
[  7  ] : Install Percona
[  8  ] : Download Xmrig
[  9  ] : Init System
------------------------------------"
OPTION=$1
[ -z "$OPTION" ] && read -p "PLEASE SELECT YOUR OPTION:" OPTION
clear
case "${OPTION}" in
1)
    Reinstall_OS
    ;;
2)
    Update_Kernel
    ;;
3)
    Install_BBR
    ;;
4)
    Install_Docker
    ;;
5)
    Install_Nginx
    ;;
6)
    Install_PHP
    ;;
7)
    Install_Percona
    ;;
8)
    Download_Xmrig
    ;;
9)
    Init_System
    ;;
*)
    echo "Worong option"
    ;;
esac
