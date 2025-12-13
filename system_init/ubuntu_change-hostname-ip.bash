###
 # @Author: 無以菱 2794998160@qq.com
 # @Date: 2025-12-13 15:41:11
 # @LastEditors: 無以菱 2794998160@qq.com
 # @LastEditTime: 2025-12-14 00:13:33
 # @FilePath: \wylblog_scripts\system_init\ubuntu_change-hostname-ip.bash
 # @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
### 
#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2023-12-23
#FileName:         ubuntu_change-hostname-ip.bash
#URL:              http://42.194.242.109:510/
#Description:      Ubuntu模板机下快速修改主机名和IP地址
#Copyright (C):    2024 All rights reserved
#********************************************************************
#
# Usage: bash ubuntu_change-hostname-ip.bash <主机名> <IP地址> 

#获取当前IP地址的前三段（如：192.168.10.）
ip_prefix=`hostname -I | awk -F '.' '{print $1"."$2"."$3"."}'`
#模板机ip地址的最后一段
ip=`hostname -I |awk '{print $1}'|sed 's#.*\.##g'`
#新的ip地址的最后一段
ip_new=`echo $2 |sed 's#^.*\.##g'`
#新的主机名
hostname=$1
#修改ip
sudo sed -i "s#$ip_prefix$ip#$ip_prefix$ip_new#g" /etc/netplan/01-netcfg.yaml

#ubuntu重启网络服务,应用 Netplan 配置
sudo netplan apply

#修改主机名
sudo hostnamectl set-hostname $hostname && bash
