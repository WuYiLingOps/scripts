#!/bin/bash
# author YiLing Wu (hj)
# date 2023-12-23 15:21
# description: centos环境下安装zabbix-agent客户端


#安装客户端
yum install  https://mirrors.tuna.tsinghua.edu.cn/zabbix/zabbix/6.0/rhel/7/x86_64/zabbix-agent2-6.0.5-1.el7.x86_64.rpm -y

#配置客户端
if [ -f "/etc/zabbix/zabbix_agent2.conf" ];then
  read -p "请输入zabbix服务端地址:" zabbixserver
  read -p "请输入你设置代理的主机:" zabbixhostname
cat >/etc/zabbix/zabbix_agent2.conf<<EOF
PidFile=/run/zabbix/zabbix_agent2.pid
LogFile=/var/log/zabbix/zabbix_agent2.log
LogFileSize=0
Server=$zabbixserver
ServerActive=$zabbixserver
Hostname=$zabbixhostname
Include=/etc/zabbix/zabbix_agent2.d/*.conf
PluginSocket=/run/zabbix/agent.plugin.sock
ControlSocket=/run/zabbix/agent.sock
Include=./zabbix_agent2.d/plugins.d/*.conf
EOF
fi
#启动服务
if [ $? -eq 0 ];then
  systemctl start zabbix-agent2 && systemctl enable zabbix-agent2 >/dev/null 2>&1
  if [ $? -eq 0 ];then
    netstat -ntpl |grep 10050 >/dev/null
    if [ $? -eq 0 ];then
      echo -e "\033[32m zabbix-agent2 配置完成！！ \033[0m"
    else
       echo -e "\033[31m>> zabbix-agent2 配置失败,请检查配置！！ \033[0m"
    fi
  fi
fi
