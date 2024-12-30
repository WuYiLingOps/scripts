#!/bin/bash
# author YiLing Wu (hj)
# date 2023-12-23 15:21
# description: centos模板机下,快速修改主机名和ip地址

#脚本用法
#sh   /server/scripts/change.sh 主机名  192.168.10.7 

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
