#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2023-12-23
#FileName:         centos_change-hostname-ip.bash
#URL:              http://42.194.242.109:510/
#Description:      CentOS模板机下快速修改主机名和IP地址
#Copyright (C):    2024 All rights reserved
#********************************************************************
#
# Usage: bash centos_change-hostname-ip.bash <主机名> <IP地址> 

#模板机ip地址
ip=`hostname -I |awk '{print $1}'|sed 's#.*\.##g'`
#新的ip
ip_new=`echo $2 |sed 's#^.*\.##g'`
#新的主机名
hostname=$1
#修改ip
sed -i "s#192.168.10.$ip#192.168.10.$ip_new#g" /etc/sysconfig/network-scripts/ifcfg-eth0
sed -i "s#10.0.0.$ip#10.0.0.$ip_new#g" /etc/sysconfig/network-scripts/ifcfg-eth1
systemctl restart network 
#修改主机名
hostnamectl set-hostname $hostname && bash
