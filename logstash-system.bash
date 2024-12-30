#!/bin/bash
# author YiLing Wu (hj)
# date 2023-12-23 15:21
# description: logstash启动脚本

#启动方式: 脚本名 + [start,stop,status] 配置文件[.conf]
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

