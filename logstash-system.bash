#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2023-12-23
#FileName:         logstash-system.bash
#URL:              http://42.194.242.109:510/
#Description:      Logstash启动脚本
#Copyright (C):    2024 All rights reserved
#********************************************************************
#
# Usage: bash logstash-system.bash [start|stop|status] <配置文件.conf>
#传参(start stop restart status)
a=$1
#选择需要启动的配置文件
conf=$2
#进程号
logstash_id=`netstat -lntp | grep 9600 | awk '{print $7}' |  awk -F'/' '{print $1}'`
if [[ $a == "start" ]];then
  nohup logstash -f /etc/logstash/conf.d/$conf &
elif [[ $a == "stop" ]];then
  kill -9 $logstash_id
elif [[ $a == "restart" ]];then
  netstat -lntp | grep 9600 >/dev/null
  if [ $? -eq 0 ];then
    kill -9 $logstash_id
  fi
  nohup logstash -f /etc/logstash/conf.d/$conf &
elif [[ $a == "status" ]];then
  netstat -lntp | grep 9600 >/dev/null
  if [ $? -eq 0 ];then
     sleep 2
    echo -e "\033[32mlogstash is running !! \033[0m"
  fi
else
  echo "请输入正确参数"
fi

