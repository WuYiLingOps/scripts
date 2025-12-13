#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2023-12-23
#FileName:         anolisOS_change-hostname-ip.bash
#URL:              http://42.194.242.109:510/
#Description:      AnolisOS模板机下快速修改主机名和IP地址
#Copyright (C):    2024 All rights reserved
#********************************************************************
#
# Usage: bash anolisOS_change-hostname-ip.bash <主机名> <IP地址> 

#模板机ip地址
ip=`hostname -I |awk '{print $1}'|sed 's#.*\.##g'`
#新的ip
ip_new=`echo $2 |sed 's#^.*\.##g'`
#新的主机名
hostname=$1
#修改ip
sed -i "s#192.168.10.$ip#192.168.10.$ip_new#g" /etc/sysconfig/network-scripts/ifcfg-ens33

#龙溪重启网络服务
#nmcli device show                   # 查看获取的IP地址
nmcli c reload                       # 重新加载配置文件
nmcli c up ens33                     # 重启ens32网卡

#修改主机名
hostnamectl set-hostname $hostname && bash
