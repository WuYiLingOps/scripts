#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2023-12-23
#FileName:         centos_change-hostname-ip.bash
#URL:              http://huangjingblog.cn:510/
#Description:      CentOS模板机下快速修改主机名和IP地址
#Copyright (C):    2024 All rights reserved
#********************************************************************
#
# Usage: bash centos_change-hostname-ip.bash <主机名> <IP地址> 

#获取第一个IP地址的前三段（用于第一个网卡，如：192.168.10.）
ip_prefix_eth0=`hostname -I | awk '{print $1}' | awk -F '.' '{print $1"."$2"."$3"."}'`
#获取第二个IP地址的前三段（用于第二个网卡，如：10.0.0.），如果不存在则使用第一个IP的前三段
ip_prefix_eth1=`hostname -I | awk '{if(NF>1) print $2; else print $1}' | awk -F '.' '{print $1"."$2"."$3"."}'`
#模板机ip地址的最后一段（使用第一个IP）
ip=`hostname -I |awk '{print $1}'|sed 's#.*\.##g'`
#新的ip地址的最后一段
ip_new=`echo $2 |sed 's#^.*\.##g'`
#新的主机名
hostname=$1

#检测第一个网卡配置文件（优先使用eth0，如果不存在则使用ens33）
if [ -f /etc/sysconfig/network-scripts/ifcfg-eth0 ]; then
    netcard1="eth0"
elif [ -f /etc/sysconfig/network-scripts/ifcfg-ens33 ]; then
    netcard1="ens33"
else
    echo "未找到网卡配置文件 ifcfg-eth0 或 ifcfg-ens33"
    exit 1
fi

#检测第二个网卡配置文件（优先使用eth1，如果不存在则使用ens34）
if [ -f /etc/sysconfig/network-scripts/ifcfg-eth1 ]; then
    netcard2="eth1"
elif [ -f /etc/sysconfig/network-scripts/ifcfg-ens34 ]; then
    netcard2="ens34"
else
    #如果第二个网卡不存在，只修改第一个网卡
    netcard2=""
fi

#修改ip
sed -i "s#$ip_prefix_eth0$ip#$ip_prefix_eth0$ip_new#g" /etc/sysconfig/network-scripts/ifcfg-$netcard1
if [ -n "$netcard2" ]; then
    sed -i "s#$ip_prefix_eth1$ip#$ip_prefix_eth1$ip_new#g" /etc/sysconfig/network-scripts/ifcfg-$netcard2
fi
systemctl restart network 
#修改主机名
hostnamectl set-hostname $hostname && bash
