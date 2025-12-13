#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2024-12-23
#FileName:         zk.bash
#URL:              http://42.194.242.109:510/
#Description:      Zookeeper集群管理脚本，支持启动、停止、查看状态
#Copyright (C):    2024 All rights reserved
#********************************************************************
#
# Usage: bash zk.bash [start|stop|status]

# 获取所有主机名
hostname=$(awk '!/^#/ && NF==2 {print $2}' /etc/hosts)

case $1 in
"start")
echo "=======启动zookeeper集群=============="
for i in $hostname;do
	echo "---------------启动$i-------------"
	ssh $i "source /etc/profile;${ZK_HOME}/bin/zkServer.sh start"
done
;;
"stop")
echo "========关闭zookeeper集群============"
for i in $hostname;do
	echo "---------------关闭$i-------------"
	ssh $i "source /etc/profile;${ZK_HOME}/bin/zkServer.sh stop"
done
;;
"status")
echo "=======查看zookeeper集群节点状态========="
for i in $hostname;do
	echo "---------------查看$i-------------"
	ssh $i "source /etc/profile;${ZK_HOME}/bin/zkServer.sh status"
done
;;
*)
echo "请输入start或stop或status!!!"
;;
esac
