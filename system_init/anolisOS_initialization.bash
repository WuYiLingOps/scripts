#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2023-7-23
#FileName:         anolisOS_initialization.bash
#URL:              http://huangjingblog.cn:510/
#Description:      AnolisOS虚拟机初始化脚本
#Copyright (C):    2024 All rights reserved
#********************************************************************
#

# echo "网卡配置默认ens33"
# 安装格式化工具
# yum install dos2unix -y



#配置命令行显示颜色
grep PS1 /etc/profile >/dev/null
if [ $? -ne 0 ];then
cat >>/etc/profile <<EOF
export PS1='[\[\e[34;1m\]\u\[\e[0m\]@\[\e[32;1m\]\H\[\e[0m\]\[\e[31;1m\] \w\[\e[0m\]]\$ '
EOF
fi

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

#龙溪重启网络服务
#nmcli device show		     # 查看获取的IP地址
nmcli c reload                       # 重新加载配置文件
nmcli c up ens33                     # 重启ens32网卡

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

#安装日常所需工具
yum install lrzsz -y
yum install vim -y
yum install wget -y
yum install git -y


#刷新
bash
