#/bin/bash

read -p "配置静态ip：" local_ip
UUID=`uuidgen`
# 配置静态ip地址
echo """
TYPE="Ethernet"
PROXY_METHOD="none"
BROWSER_ONLY="no"
BOOTPROTO="static"
IPADDR="${local_ip}"
NETMASK="255.255.255.0"
GATEWAY="192.168.48.2"
DNS1="192.168.0.58"
DNS2="8.8.8.8"
DEFROUTE="yes"
IPV4_FAILURE_FATAL="no"
IPV6INIT="yes"
IPV6_AUTOCONF="yes"
IPV6_DEFROUTE="yes"
IPV6_FAILURE_FATAL="no"
IPV6_ADDR_GEN_MODE="stable-privacy"
NAME="ens33"
UUID="${UUID}"
DEVICE="ens33"
ONBOOT="yes"
""" > /etc/sysconfig/network-scripts/ifcfg-ens33

echo "关闭防火墙、swap、selinux"
systemctl stop firewalld #关闭防火墙
systemctl disable firewalld #关闭开机自启
swapoff -a #临时关闭
sed -ri 's/.*swap.*/#&/' /etc/fstab
sed -i 's/enforcing/disabled/' /etc/selinux/config

# 基本软件
echo "下载wget"
yum install -y wget

echo "腾讯云同步"
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.cloud.tencent.com/repo/centos7_base.repo

wget -O /etc/yum.repos.d/epel.repo http://mirrors.cloud.tencent.com/repo/epel-7.repo
#清空原有缓存, 生成新的yum缓存，加速下载
yum clean all
yum makecache

echo "常用软件下载"
yum install -y epel-release.noarch vim net-tools wget bash-completion lrzsz expect nc nmap tree dos2unix htop iftop iotop unzip telnet sl psmisc nethogs glances bc ntpdate openssl openssl-devel git

echo "时间同步"
ntpdate ntp1.aliyun.com
date
hwclock --show
hwclock -w