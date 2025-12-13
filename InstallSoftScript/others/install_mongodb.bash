#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2023-12-23
#FileName:         install_mongodb.bash
#URL:              http://42.194.242.109:510/
#Description:      CentOS下安装MongoDB
#Copyright (C):    2024 All rights reserved
#********************************************************************
#

#环境变量
mongodb_home() {
cat >>/etc/profile<<EOF
#mongodb
export MONGODB_HOME=/usr/local/mongodb
EOF
echo 'export PATH=$PATH:$MONGODB_HOME/bin' >>/etc/profile
source /etc/profile
}

#添加至system进行管理
mongodb_system() {
cat >/usr/lib/systemd/system/mongod.service<<EOF
[Unit]
Description=mongod
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/mongodb/bin/mongod -f /usr/local/mongodb/conf/mongodb.yaml
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/usr/local/mongodb/bin/mongod -f /usr/local/mongodb/conf/mongodb.yaml --shutdown
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
}

mongodb_yaml() {
cat >/usr/local/mongodb/conf/mongodb.yaml<<EOF
systemLog:
  destination: file
  path: "/usr/local/mongodb/logs/mongodb.log"
  logAppend: true
storage:
  journal:
     enabled: true
  dbPath: "/usr/local/mongodb/data"
processManagement:
  fork: true
net:
  port: 27017
  bindIp: 127.0.0.1
EOF
}

#集群



#关闭waring
grep "transparent_hugepage" /etc/rc.local >/dev/null
if [ $? -eq 1 ];then
  cat >>/etc/rc.local<<EOF
if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
  echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi
if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
   echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi
EOF
  chmod a+x /etc/rc.d/rc.local
fi

useradd mongod -s /sbin/nologin
tar=`ls | grep 'mongodb-'`
if [ $? -eq 0 ];then
  tar -xvf $tar -C /usr/local/
  tar=`ls /usr/local/ | grep 'mongodb'`
  mv /usr/local/$tar /usr/local/mongodb
  cd /usr/local/mongodb
  mkdir {conf,data,logs}
  #函数调用
  mongodb_yaml
  chown -R mongod:mongod /usr/local/mongodb/
  #添加环境变量
  if [ -d "/usr/local/mongodb/bin/" ];then
    grep "mongodb" /etc/profile >/dev/null
    if [ $? -eq 1 ];then
    #调用函数
      mongodb_home
    fi
  fi
  if [ $? -eq 0 ];then
    #添加system管理函数调用
    mongodb_system   
  fi
else
  wget https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel70-5.0.20.tgz
  tar -xvf mongodb-linux-x86_64-rhel70-5.0.20.tgz -C /usr/local/
  mv /usr/local/mongodb-linux-x86_64-rhel70-5.0.20 /usr/local/mongodb
  cd /usr/local/mongodb
  mkdir {conf,data,logs}
  #函数调用
  mongodb_yaml
  chown -R mongod:mongod /usr/local/mongodb/
  #添加环境变量
  if [ -d "/usr/local/mongodb/bin/" ];then
    grep "mongodb" /etc/profile >/dev/null
    if [ $? -eq 1 ];then
    #调用函数
      mongodb_home
    fi
  fi
  if [ $? -eq 0 ];then
    #添加system管理函数调用
    mongodb_system
  fi
fi
#启动服务
if [ $? -eq 0 ];then
  systemctl start mongod
  if [ $? -eq 0 ];then
    systemctl status mongod
	systemctl enable mongod
	netstat -ntpl | grep mongo
	echo -e "\033[32m mongodb服务启动成功（已加入systemtcl进行管理）！！ \033[0m"
  fi
fi