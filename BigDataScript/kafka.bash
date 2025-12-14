#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2024-12-23
#FileName:         kafka.bash
#URL:              http://huangjingblog.cn:510/
#Description:      Kafka集群管理脚本，支持启动、停止操作
#Copyright (C):    2024 All rights reserved
#********************************************************************
#
# Usage: bash kafka.bash [start|stop]

# 获取所有主机名
hostname=$(awk '!/^#/ && NF==2 {print $2}' /etc/hosts)

case $1 in
"start")
  echo "======= 启动 Kafka 集群 ========"
  for i in $hostname; do
    echo "--------------- 启动 $i -------------"
    ssh "$i" "source /etc/profile; ${KAFKA_HOME}/bin/kafka-server-start.sh -daemon ${KAFKA_HOME}/config/server.properties"
    if [ $? -eq 0 ]; then
      echo -e "\033[32m>> $i Kafka 服务启动成功!! \033[0m"
    else
      echo -e "\033[31m>> $i Kafka 服务启动失败!! \033[0m"
    fi
  done
  ;;
"stop")
  echo "======== 关闭 Kafka 集群 =========="
  for i in $hostname; do
    echo "--------------- 关闭 $i -------------"
    ssh "$i" "source /etc/profile; ${KAFKA_HOME}/bin/kafka-server-stop.sh"
    if [ $? -eq 0 ]; then
      echo -e "\033[32m>> $i Kafka 服务关闭成功!! \033[0m"
    else
      echo -e "\033[31m>> $i Kafka 服务关闭失败!! \033[0m"
    fi
  done
  ;;
*)
  echo "请输入 start 或 stop!!!"
  ;;
esac
