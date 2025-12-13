#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2023-12-23
#FileName:         install_kafka_zookeeper_bin.bash
#URL:              http://42.194.242.109:510/
#Description:      CentOS下部署Zookeeper和Kafka集群
#Copyright (C):    2024 All rights reserved
#********************************************************************
#

#使用sourc运行脚本

#方法定义部分
#========环境变量模板=============
KAFKA_HOME() {
cat >>/etc/profile<<EOF
#KAFKA_HOME
export KAFKA_HOME=/module/kafka
export PATH=\$PATH:\$KAFKA_HOME/bin
EOF
source /etc/profile
}

ZK_HOME() {
cat >>/etc/profile<<EOF
#ZK_HOME
export ZK_HOME=/module/zookeeper
export PATH=\$PATH:\$ZK_HOME/bin
EOF
source /etc/profile
}

JAVA_HOME() {
cat >>/etc/profile<<EOF
#JAVA_HOME
export JAVA_HOME=/module/jdk
export PATH=\$PATH:\$JAVA_HOME/bin
EOF
}


#=======解压安装模块=========
install_module() {
#安装目录
mkdir /module > /dev/null 2>&1

#组件1(kafka)
kafka=`ls | grep "kafka.*gz"`
if [ $? -eq 1 ];then
  #拉取安装包
  wget https://downloads.mysql.com/archives/get/p/23/file/mysql-8.0.11-linux-glibc2.12-x86_64.tar.gz
else
  tar -zxvf $kafka -C /module
  kafka_pack=`ls /module | grep "kafka_"`
  if [ $? -eq 0 ];then
    mv /module/$kafka_pack /module/kafka
  fi
fi

#组件2(zookeeper)
zk=`ls | grep "zookeeper.*gz"`
if [ $? -eq 1 ];then
  #拉取安装包
  wget https://downloads.mysql.com/archives/get/p/23/file/mysql-8.0.11-linux-glibc2.12-x86_64.tar.gz
else
  tar -zxvf $zk -C /module
  zk_pack=`ls /module | grep "zookeeper-"`
  if [ $? -eq 0 ];then
    mv /module/$zk_pack /module/zookeeper
  fi
fi

#组件3(jdk)
java=`ls | grep "jdk.*gz"`
if [ $? -eq 1 ];then
  #拉取安装包
  wget https://downloads.mysql.com/archives/get/p/23/file/mysql-8.0.11-linux-glibc2.12-x86_64.tar.gz
else
  tar -zxvf $java -C /module
  java_pack=`ls /module | grep "jdk1."`
  if [ $? -eq 0 ];then
    mv /module/$java_pack /module/jdk
  fi
fi
}


#============代码主要流程==============
grep "kafka" /etc/hosts >/dev/null
if [ $? -eq 1 ];then
#配置hosts文件，将ip和主机名改成自己的（分发公钥部分改成自己的主机名）
cat >>/etc/hosts<<EOF
192.168.88.140  kafka1
192.168.88.141  kafka2
192.168.88.142  kafka3
EOF
fi

#获取主机名(循环条件)
hostname=`awk '!/^#/ && NF==2 {print $2}' /etc/hosts`
#ip all
hostname_ip1=`awk '!/^#/ && NF==2 {print $1}' /etc/hosts | awk 'NR==1{print $0}'`
hostname_ip2=`awk '!/^#/ && NF==2 {print $1}' /etc/hosts | awk 'NR==2{print $0}'`
hostname_ip3=`awk '!/^#/ && NF==2 {print $1}' /etc/hosts | awk 'NR==3{print $0}'`

#hostname all
hostname1=`awk '!/^#/ && NF==2 {print $2}' /etc/hosts | awk 'NR==1{print $0}'`
hostname2=`awk '!/^#/ && NF==2 {print $2}' /etc/hosts | awk 'NR==2{print $0}'`
hostname3=`awk '!/^#/ && NF==2 {print $2}' /etc/hosts | awk 'NR==3{print $0}'`

#分发免密公钥
if [ -f "/root/.ssh/id_rsa" ];then
  echo -e "\033[32m密钥已存在 \033[0m" 
else
  echo -e "\033[32m>>开始创建密钥 \033[0m" 
  ssh-keygen -t RSA -N '' -f ~/.ssh/id_rsa
  echo -e "\033[32m>>开始分发公钥: \033[0m" 
  ssh-copy-id $hostname1
  ssh-copy-id $hostname2
  ssh-copy-id $hostname3
  echo -e "\033[32m>>分发完成: \033[0m" 
fi

#环境变量
grep 'KAFKA_HOME' /etc/profile >/dev/null
if [ $? -eq 0 ];then
 echo -e '\033[32m>>$KAFKA_HOME 环境变量已存在 \033[0m'
else
  #函数调用
  KAFKA_HOME
  echo -e '\033[32m>>$KAFKA_HOME 环境变量已创建 \033[0m'
fi

grep 'ZK_HOME' /etc/profile >/dev/null
if [ $? -eq 0 ];then
 echo -e '\033[32m>>$ZK_HOME 环境变量已存在 \033[0m'
else
  #函数调用
  ZK_HOME
  echo -e '\033[32m>>$ZK_HOME 环境变量已创建 \033[0m'
fi

grep 'JAVA_HOME' /etc/profile >/dev/null
if [ $? -eq 0 ];then
 echo -e '\033[32m>>$JAVA_HOME 环境变量已存在 \033[0m'
else
  #函数调用
  JAVA_HOME
  echo -e '\033[32m>>$JAVA_HOME 环境变量已创建 \033[0m'
fi

#解压安装模块
install_module

#配置模块zookeeper
if [ -d "/module/zookeeper" ];then
mkdir /module/zookeeper/data > /dev/null
cp /module/zookeeper/conf/zoo_sample.cfg /module/zookeeper/conf/zoo.cfg
sed -i "s#dataDir=/tmp/zookeeper#dataDir=/module/zookeeper/data#g" /module/zookeeper/conf/zoo.cfg
cat >>/module/zookeeper/conf/zoo.cfg<<EOF
server.1=$hostname1:2888:3888
server.2=$hostname2:2888:3888
server.3=$hostname3:3888:3888
EOF
cat >/module/zookeeper/data/myid<<EOF
1
EOF
fi

#配置模块kafka
if [ -d "/module/kafka" ];then
  mkdir /module/kafka/kafka-logs >/dev/null
  sed -i "s%#listeners=PLAINTEXT://:9092%listeners=PLAINTEXT://$hostname1:9092%g" /module/kafka/config/server.properties
  sed -i "s%log.dirs=/tmp/kafka-logs%log.dirs=/module/kafka/kafka-logs%g" /module/kafka/config/server.properties
  sed -i "s%zookeeper.connect=localhost:2181%zookeeper.connect=$hostname1:2181,$hostname2:2181,$hostname3:2181%g" /module/kafka/config/server.properties
  cat >>/module/kafka/config/server.properties<<EOF
num.partitions=1
auto.create.topics.enable=true
delete.topic.enable=true
EOF
fi


#配置集群(主机将主机名改成自己的,函数无法调用)
for hostname in $hostname
do
 echo "当前主机名：$hostname"
 sleep 1
 if [[ $hostname != $hostname1 ]];then
   scp -r /module root@$hostname:/
   scp /etc/hosts root@$hostname:/etc/hosts
   scp /etc/profile root@$hostname:/etc/profile
   if [[ $hostname == $hostname2 ]];then
     ssh $hostname 'source /etc/profile;echo "2" > /module/zookeeper/data/myid;sed -i "s%broker.id=0%broker.id=1%g" /module/kafka/config/server.properties;
     sed -i "s%listeners=PLAINTEXT://kafka1:9092%listeners=PLAINTEXT://kafka2:9092%g" /module/kafka/config/server.properties'
   elif [[ $hostname == $hostname3 ]];then
      ssh $hostname 'source /etc/profile;echo "3" > /module/zookeeper/data/myid;sed -i "s%broker.id=0%broker.id=2%g" /module/kafka/config/server.properties;
      sed -i "s%listeners=PLAINTEXT://kafka1:9092%listeners=PLAINTEXT://kafka2:9092%g" /module/kafka/config/server.properties'
   fi
 fi
done
