#!/bin/bash

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
        release="Doesn't know"
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
Reinstall_OS() {
    Check_OS
    case "$release" in
    ubuntu | debian)
        apt install -y xz-utils openssl gawk file
        ;;
    centos)
        yum install -y xz openssl gawk file
        ;;
    *)
        echo "Only support Ubuntu/Debian and Centos"
        exit 1
        ;;
    esac
    wget https://raw.githubusercontent.com/qwinwin/qwin/master/reins.sh && chmod +x reins.sh
    clear
    echo -n "Select the system to reinstall:
    --------------------
    Default passwd:Vicer
    --------------------
    [1] Ubuntu 18.04 x64
    [2] Ubuntu 16.04 x64     
    [3] CentOS 6.9
    --------------------
    Enter the number:"
    read System_ID
    case "$System_ID" in
    1)
        bash reins.sh -u 18.04 -v 64 -a -p
        ;;
    2)
        bash reins.sh -u 16.04 -v 64 -a
        ;;
    3)
        bash reins.sh -c 6.9 -v 64 -a
        ;;
    *)
        echo "Wrong option"
        exit 1
        ;;
    esac

}

Install_BBR() {
    wget https://raw.githubusercontent.com/qwinwin/qwin/master/bbr.sh && chmod +x bbr.sh && ./bbr.sh
    #    cd $(dirname $0) && ;
}

Install_Docker() {
    Check_OS
    case "$release" in
    ubuntu)
        apt update && apt install -y docker.io && echo "Install Dokcer Successfully!"
        systemctl enable docker
        ;;
    centos)
        yum update -y && yum install -y yum-utils device-mapper-persistent-data lvm2
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        yum install -y docker-ce && echo "Install Dokcer Successfully!"
        systemctl start docker
        systemctl enable docker
        ;;
    *)
        echo "Only support Ubuntu and Centos"
        exit 1
        ;;
    esac

}
Install_SSRMU() {
    docker pull shirolin1997/ssrmu
    echo -n "Enter information:"
    read -p "Enter NODE_ID:" NODE_ID
    read -p "Enter MYSQL_HOST:" MYSQL_HOST
    read -p "Enter MYSQL_DB:" MYSQL_DB
    read -p "Enter MYSQL_USER:" MYSQL_USER
    read -p "Enter MYSQL_PASS:" MYSQL_PASS
    docker run -d --name=ss -e NODE_ID=${NODE_ID} -e SPEEDTEST=6 -e CLOUDSAFE=0 -e AUTOEXEC=0 -e ANTISSATTACK=0 -e API_INTERFACE=glzjinmod -e MYSQL_HOST=${MYSQL_HOST} -e MYSQL_USER=${MYSQL_USER} -e MYSQL_PASS=${MYSQL_PASS} -e MYSQL_DB=${MYSQL_DB} --network=host --restart=always shirolin1997/ssrmu
}
Get_IP
echo "====================================================================
IP adress:${ip}
====================================================================
[1] [Reinstall OS]
[2] [Install] - [BBR]
[3] [Install] - [Docker]
[4] [Install] - [SSRMU]
===================================================================="
read -p "PLEASE SELECT YOUR OPTION:" OPTION

clear
case "${OPTION}" in
1)
    Reinstall_OS
    ;;
2)
    Install_BBR
    ;;
3)
    Install_Docker
    ;;
4)
    Install_SSRMU
    ;;
*)
    echo "Worong option"
    ;;
esac
