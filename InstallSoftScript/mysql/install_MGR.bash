#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2023-12-23
#FileName:         install_MGR.bash
#URL:              http://huangjingblog.cn:510/
#Description:      CentOS下安装MGR单组集群
#Copyright (C):    2024 All rights reserved
#********************************************************************
#

#MGR单组集群
grep "db01" /etc/hosts >/dev/null
if [ $? -eq 1 ];then
#配置hosts文件，将ip和主机名改成自己的（分发公钥部分改成自己的主机名）
cat >>/etc/hosts<<EOF
192.168.42.10	db01
192.168.42.20	db02
192.168.42.30	db03
EOF
fi

#获取主机名(循环条件)
hostname=`awk '!/^#/ && NF==2 {print $2}' /etc/hosts`
node1=`awk '!/^#/ && NF==2 {print $2}' /etc/hosts | awk 'NR==1{print $1}'`
node2=`awk '!/^#/ && NF==2 {print $2}' /etc/hosts | awk 'NR==2{print $1}'`
node3=`awk '!/^#/ && NF==2 {print $2}' /etc/hosts | awk 'NR==3{print $1}'`
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
  ssh-copy-id $node1
  ssh-copy-id $node2
  ssh-copy-id $node3
  echo -e "\033[32m>>分发完成: \033[0m" 
fi

#my.cnf配置文件
mycnf() {
cat >/etc/my.cnf<<EOF
[mysqld]
user=mysql
basedir=/usr/local/mysql
datadir=/data/mysql
server_id=1
port=3306
socket=/data/mysql/mysql.sock

#开启gtid
gtid-mode=on
enforce-gtid-consistency=on

#将master.info元数据保存在系统表中
master-info-repository=TABLE

#将relay.info元数据保存中系统表中
relay-log-info-repository=TABLE

# 禁用二进制日志事件校验
binlog-checksum=none

#级联复制
log-slave-updates=on

#binlog日志
log_bin=/data/binlog/mysql-bin  
sync_binlog=1
binlog_format=row
expire_logs_days=30
max_binlog_size=100M

# 使用哈希算法将其编码为散列
transaction-write-set-extraction=XXHASH64 
# 加入的组名，可以修改
loose-group_replication_group_name='ce9be252-2b71-11e6-b8f4-00212844f856'
# 不启用组复制集群
loose-group_replication_start_on_boot=off 
# 以本机端口33061接受来自组中成员的传入连接
loose-group_replication_local_address='db01:33061'
# 组中成员的访问列表
loose-group_replication_group_seeds='db01:33061,db02:33062,db03:33063'
# 不启用引导组
loose-group_replication_bootstrap_group=off 

[mysql]
socket=/data/mysql/mysql.sock

[mysqld_safe]
log-error=/var/log/mysql/mysql.log
pid-file=/data/mysql/mysql.pid
EOF
}

#创建复制用户
mgr_user() {
  ssh $1 'source /etc/profile;mysql -uroot -p123456 -e 'grant replication slave on *.* to "repl"@"192.168.42.%" identified by "123456";''
}

mgr_change() {
  ssh $1 'source /etc/profile;mysql -uroot -p123456 -e 'change master to master_user="repl",master_password="123456" for channel "group_replication_recovery";install PLUGIN group_replication SONAME "group_replication.so";''
}

mgr_start() {
  ssh $1 'source /etc/profile;mysql -uroot -p123456 -e 'set global group_replication_bootstrap_group=on;start group_replication;start group_replication;''
}

mgr_select() {
  ssh $1 'source /etc/profile;mysql -uroot -p123456 -e 'select * from performance_schema.replication_group_members;''
}

#在主服务器上创建复制用户(node1)：
for hostname in $hostname
do
  #在主服务器上创建复制用户(node1)
  if [[ $hostname == `awk '!/^#/ && NF==2 {print $2}' /etc/hosts | awk 'NR==1{print $1}'` ]];then
    source /etc/profile
	echo -e "\033[32m开始配置:$hostname \033[0m"
	#配置文件
	mycnf
	#重启服务
    systemctl restart mysqld
	
	mgr_user $hostname
	mgr_change $hostname
	mgr_start $hostname
  #主机2
  elif [[ $hostname == `awk '!/^#/ && NF==2 {print $2}' /etc/hosts | awk 'NR==2{print $1}'` ]];then
    source /etc/profile
    echo -e "\033[32m开始配置:$hostname \033[0m"
    #分发配置
    scp /etc/my.cnf root@$hostname:/etc/my.cnf
	#修改配置
    ssh $hostname "sed -i 's/server_id=1/server_id=2/g' /etc/my.cnf; "
	#重启服务
    systemctl restart mysqld
    
	mgr_user $hostname
	mgr_change $hostname
	mgr_start $hostname
  #主机3
  elif [[ $hostname == `awk '!/^#/ && NF==2 {print $2}' /etc/hosts | awk 'NR==3{print $1}'` ]];then
    source /etc/profile
    echo -e "\033[32m开始配置:$hostname \033[0m"
    #分发配置
    scp /etc/my.cnf root@$hostname:/etc/my.cnf
	#修改配置
    ssh $hostname "sed -i 's/server_id=1/server_id=3/g' /etc/my.cnf; "
	#重启服务
    systemctl restart mysqld
    
	mgr_user $hostname
	mgr_change $hostname
	mgr_start $hostname
  fi
done
