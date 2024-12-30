#!/bin/bash
# author YiLing Wu (hj)
# date 2023-12-23 15:21
# description: anolisOS模板机下,快速修改主机名和ip地址
# 脚本用法:
# bash /server/scripts/change.sh 主机名  192.168.10.7 

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
