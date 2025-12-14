#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2023-12-23
#FileName:         install_redis_cluster.bash
#URL:              http://huangjingblog.cn:510/
#Description:      CentOS环境下安装Redis集群
#Copyright (C):    2024 All rights reserved
#********************************************************************
#

grep "redis001" /etc/hosts >/dev/null
if [ $? -eq 1 ];then
#配置hosts文件，将ip和主机名改成自己的（分发公钥部分改成自己的主机名）
cat >>/etc/hosts<<EOF
192.168.42.140  redis001
192.168.42.141  redis002
192.168.42.142  redis003
EOF
fi

#获取主机名(循环条件)
hostname=`awk '!/^#/ && NF==2 {print $2}' /etc/hosts`
#ip
redis1_ip=`awk '!/^#/ && NF==2 {print $1}' /etc/hosts | awk 'NR==1{print $0}'`
redis2_ip=`awk '!/^#/ && NF==2 {print $1}' /etc/hosts | awk 'NR==2{print $0}'`
redis3_ip=`awk '!/^#/ && NF==2 {print $1}' /etc/hosts | awk 'NR==3{print $0}'`

#分发免密公钥
if [ -f "/root/.ssh/id_rsa" ];then
  echo -e "\033[32m密钥已存在 \033[0m" 
else
  echo -e "\033[32m>>开始创建密钥 \033[0m" 
  ssh-keygen -t rsa
  echo -e "\033[32m>>开始分发公钥: \033[0m" 
  ssh-copy-id redis001
  ssh-copy-id redis002
  ssh-copy-id redis003
  echo -e "\033[32m>>分发完成: \033[0m" 
fi

#检查redis环境变量是否配置，下面需要用到
grep '$REDIS_HOME' /etc/profile >/dev/null
if [ $? -eq 0 ];then
 echo -e '\033[32m>>$REDIS_HOME 环境变量已存在 \033[0m'
else
 cat >>/etc/profile<<EOF
#redis
export REDIS_HOME=/usr/local/redis
EOF
  echo 'export PATH=$PATH:$REDIS_HOME/bin'>>/etc/profile
  source /etc/profile
  echo -e '\033[32m>>$REDIS_HOME 环境变量已创建 \033[0m'
fi

mkdir -p /data/redis_cluster/900{0..5}
#配置模板
#拷贝redis.conf配置文件(一般在$REDIS_HOME的conf目录下，但我自己的是在$REDIS_HOME根目录下，所以多加了个判断)
if [ -f "$REDIS_HOME/redis.conf" ];then
  cp $REDIS_HOME/redis.conf /data/redis_cluster/9000
else
  cp $REDIS_HOME/conf/redis.conf /data/redis_cluster/9000
fi

#开始配置
if [ $? -eq 0 ];then
  sed -i 's/port 6379/port 9000/g' /data/redis_cluster/9000/redis.conf
  sed -i "s/bind 127.0.0.1 -::1/bind $redis1_ip/g" /data/redis_cluster/9000/redis.conf
  sed -i 's/daemonize no/daemonize yes/g' /data/redis_cluster/9000/redis.conf
  sed -i 's/protected-mode yes/protected-mode no/g' /data/redis_cluster/9000/redis.conf
  sed -i 's#pidfile /var/run/redis_6379.pid#pidfile /data/redis_cluster/redis_9000.pid#g' /data/redis_cluster/9000/redis.conf
  sed -i 's#logfile \"\"#logfile /data/redis_cluster/redis_9000.log#g' /data/redis_cluster/9000/redis.conf
  sed -i 's/# cluster-enabled yes/cluster-enabled yes/g' /data/redis_cluster/9000/redis.conf
  sed -i 's/# cluster-config-file nodes-6379.conf/cluster-config-file nodes-9000.conf/g' /data/redis_cluster/9000/redis.conf
  sed -i 's/# cluster-node-timeout 15000/cluster-node-timeout 15000/g' /data/redis_cluster/9000/redis.conf
  sed -i 's#dir ./#dir /data/redis_cluster/9000#g' /data/redis_cluster/9000/redis.conf
  sed -i 's/appendonly no/appendonly yes/g' /data/redis_cluster/9000/redis.conf
  sed -i 's/requirepass 123456/#requirepass 123456/g' /data/redis_cluster/9000/redis.conf
  cp /data/redis_cluster/9000/redis.conf /data/redis_cluster/9001
  sed -i 's/9000/9001/g' /data/redis_cluster/9001/redis.conf
  
  cp /data/redis_cluster/9000/redis.conf /data/redis_cluster/9002
  cp /data/redis_cluster/9000/redis.conf /data/redis_cluster/9003
  cp /data/redis_cluster/9000/redis.conf /data/redis_cluster/9004
  cp /data/redis_cluster/9000/redis.conf /data/redis_cluster/9005
  
  sed -i "s/bind $redis1_ip/bind $redis2_ip/g" /data/redis_cluster/9002/redis.conf
  sed -i "s/bind $redis1_ip/bind $redis2_ip/g" /data/redis_cluster/9003/redis.conf
  sed -i 's/9000/9002/g' /data/redis_cluster/9002/redis.conf
  sed -i 's/9000/9003/g' /data/redis_cluster/9003/redis.conf
  
  sed -i "s/bind $redis1_ip/bind $redis3_ip/g" /data/redis_cluster/9004/redis.conf
  sed -i "s/bind $redis1_ip/bind $redis3_ip/g" /data/redis_cluster/9005/redis.conf
  sed -i 's/9000/9004/g' /data/redis_cluster/9004/redis.conf
  sed -i 's/9000/9005/g' /data/redis_cluster/9005/redis.conf

  #分发
  for hostname in $hostname
  do
    #主机1
    if [[ $hostname == `awk '!/^#/ && NF==2 {print $2}' /etc/hosts | awk 'NR==1{print $1}'` ]];then
      echo -e "\033[32m开始配置:$hostname \033[0m"
      #启动服务
      $REDIS_HOME/bin/redis-server /data/redis_cluster/9000/redis.conf
      $REDIS_HOME/bin/redis-server /data/redis_cluster/9001/redis.conf
    
      if [ $? -eq 0 ];then
        echo -e "\033[32m$hostname 配置完成！！ \033[0m"
      fi
    #主机2
    elif [[ $hostname == `awk '!/^#/ && NF==2 {print $2}' /etc/hosts | awk 'NR==2{print $1}'` ]];then
    echo -e "\033[32m开始配置:$hostname \033[0m"
    #创建数据目录，分发配置
    ssh $hostname "
    mkdir -p /data/redis_cluster/9002
    mkdir -p /data/redis_cluster/9003"
    
    scp -r /data/redis_cluster/9002/redis.conf root@$hostname:/data/redis_cluster/9002
    scp -r /data/redis_cluster/9003/redis.conf root@$hostname:/data/redis_cluster/9003
    
    #启动服务
    ssh $hostname "
    $REDIS_HOME/bin/redis-server /data/redis_cluster/9002/redis.conf
    $REDIS_HOME/bin/redis-server /data/redis_cluster/9003/redis.conf"
    
    if [ $? -eq 0 ];then
      rm -rf /data/redis_cluster/9002/ /data/redis_cluster/9003/
  	echo -e "\033[32m$hostname配置完成！！ \033[0m"
    fi
    #主机3
    elif [[ $hostname == `awk '!/^#/ && NF==2 {print $2}' /etc/hosts | awk 'NR==3{print $1}'` ]];then
    echo -e "\033[32m开始配置:$hostname \033[0m"
    #创建数据目录，分发配置
    ssh $hostname "
    mkdir -p /data/redis_cluster/9004
    mkdir -p /data/redis_cluster/9005"
    
    scp -r /data/redis_cluster/9004/redis.conf root@$hostname:/data/redis_cluster/9004
    scp -r /data/redis_cluster/9005/redis.conf root@$hostname:/data/redis_cluster/9005
  
    #启动服务
    ssh $hostname "
    $REDIS_HOME/bin/redis-server /data/redis_cluster/9004/redis.conf
    $REDIS_HOME/bin/redis-server /data/redis_cluster/9005/redis.conf"
    
    if [ $? -eq 0 ];then
      rm -rf /data/redis_cluster/9004/ /data/redis_cluster/9005/
  	  echo -e "\033[32m$hostname配置完成！！ \033[0m"
    fi
    fi
  done
else
  echo -e "\033[31m>>拷贝redis.conf配置文件失败，请检查自己的redis配置！！ \033[0m"
fi
#创建集群
if [ -f "/data/redis_cluster/9000/redis.conf" ];then
  echo -e "\033[32m>>开始创建redis集群(yes确定集群创建)： \033[0m"
  redis-cli --cluster create --cluster-replicas 1 $redis1_ip:9000 $redis1_ip:9001 $redis2_ip:9002 $redis2_ip:9003 $redis3_ip:9004 $redis3_ip:9005
  if [ $? -eq 0 ];then
    echo -e "\033[32m>>redis集群创建成功！！！ \033[0m"
  else
    echo -e "\033[31m>>创建redis集群失败！！！请检查redis.conf配置！！： \033[0m"
  fi
else
  echo -e "\033[31m>>创建redis集群失败！！！请检查redis配置！！： \033[0m"
fi
