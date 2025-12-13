#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2023-7-24
#FileName:         centos_initialization.bash
#URL:              http://42.194.242.109:510/
#Description:      CentOS虚拟机初始化脚本
#Copyright (C):    2024 All rights reserved
#********************************************************************
#

#echo "网卡配置默认ens33"
#安装格式化工具
#yum install dos2unix -y

#配置命令行显示颜色
grep PS1 /etc/profile >/dev/null
if [ $? -ne 0 ];then
cat >>/etc/profile <<EOF
export PS1='[\[\e[34;1m\]\u@\[\e[0m\]\[\e[32;1m\]\H\[\e[0m\]\[\e[31;1m\] \w\[\e[0m\]]\$ '
EOF
fi

yum_local() {
#挂载镜像,配置本地仓库
mount /dev/sr0 /mnt
mkdir /etc/yum.repos.d/bak
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak
touch /etc/yum.repos.d/local.repo
cat << EOF > /etc/yum.repos.d/local.repo
[local]
name=local
baseurl=file:///mnt
enable=1
gpgcheck=0
gpgkey=file:///mnt/RPM-GPG-KEY-CentOS-7
EOF

#配置开机自动挂载磁盘
fstab=`cat /etc/fstab | grep "/dev/cdrom /mnt iso9660 defaults" | wc -l`
if [ $fstab -eq 0 ];then
cat << EOF >> /etc/fstab 
/dev/cdrom /mnt iso9660 defaults        0 0
EOF
fi
yum clean all >/dev/null 2>&1
yum repolist >/dev/null 2>&1

#安装日常所需工具
yum install lrzsz -y
yum install vim -y
yum install wget -y
}

cat <<EOF
********************************
**    网卡配置默认ens33      **
********************************
EOF
read -p "Please input the hostname:" hostname
read -p "Please input an IP address:" ip
read -p "Please input the gateway:" gateway
#网络配置
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-ens33
TYPE=Ethernet
DEVICE=ens33
NAME=ens33
BOOTPROTO=static
ONBOOT=yes
IPADDR=$ip
GATEWAY=$gateway
PREFIX=24
EOF
systemctl restart network
resolv=`grep "$gateway" /etc/resolv.conf | wc -l`
if [ $resolv -eq 0 ];then
   echo "nameserver $gateway" >> /etc/resolv.conf
fi

#修改主机名
hostnamectl set-hostname $hostname

#检查防火墙
firewalld_status=`systemctl status firewalld | grep "running" | wc -l`
if [ $firewalld_status -eq 1 ]; then
   systemctl stop firewalld
   systemctl disable firewalld >/dev/null 2>&1
   echo -e '\033[32mfirewalld is stop \033[0m'
else
    echo -e '\033[32mfirewalld is stop \033[0m'
fi

#检查selinux
selinux_status=`awk 'BEGIN{FS="="}NR=="7"{print $2}' /etc/selinux/config`
if [[ $selinux_status == "enforcing" ]]; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
	echo -e '\033[32mselinux is stop \033[0m'
else
	echo -e '\033[32mselinux is stop \033[0m'
fi

#开始配置yum源
cat <<EOF
*****************************     
**    1.配置阿里源     
**    2.仅配置本地源
*****************************
EOF
read -p "Input a choose:" OP
case $OP in
1|"配置阿里源")
cat <<EOF
********************************
**    开始配置阿里源     **
********************************
EOF
#函数调用
yum_local
#添加网络仓库，额外源
wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo >/dev/null 2>&1
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo >/dev/null 2>&1

yum clean all
yum repolist

cat <<EOF
********************************
**    阿里源配置完成     **
********************************
EOF
#刷新
bash
   ;;
2|"配置本地源")
cat <<EOF
********************************
**    开始配置本地源     **
********************************
EOF
#挂载镜像,配置本地仓库
#调用函数
yum_local
yum repolist | grep repolist
cat <<EOF
********************************
**    本地源配置完成     **
********************************
EOF
#刷新
bash
   ;;
   *)
echo "请输入有效选项...."
esac
