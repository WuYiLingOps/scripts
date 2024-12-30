#!/bin/bash
# author YiLing Wu (hj)
# date 2023-12-23 15:21
# description: ubuntu模板机下,快速修改主机名和ip地址
# 脚本用法:
# bash /server/scripts/change.sh 主机名  192.168.10.7 

#模板机ip地址
ip=`hostname -I |awk '{print $1}'|sed 's#.*\.##g'`
#新的ip
ip_new=`echo $2 |sed 's#^.*\.##g'`
#新的主机名
hostname=$1
#修改ip
sudo sed -i "s#192.168.10.$ip#192.168.10.$ip_new#g" /etc/netplan/00-installer-config.yaml 

#ubuntu重启网络服务,应用 Netplan 配置
sudo netplan apply

#修改主机名
sudo hostnamectl set-hostname $hostname && bash
