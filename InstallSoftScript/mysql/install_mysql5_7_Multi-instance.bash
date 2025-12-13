#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2023-12-23
#FileName:         install_mysql5_7_Multi-instance.bash
#URL:              http://42.194.242.109:510/
#Description:      CentOS下二进制安装MySQL5.7并实现多实例
#Copyright (C):    2024 All rights reserved
#********************************************************************
#

read -p "请设置MySQL密码：" passwd_mysql
read -p "请输入版本号5.7.xx:" num

#清除旧版本
yum -y remove mariadb* 2>/dev/null
find / -name "*mysql*" -exec rm -rf {} \; 2>/dev/null 


# 获取mysql二进制压缩包
wget https://downloads.mysql.com/archives/get/p/23/file/mysql-5.7.$num-linux-glibc2.12-x86_64.tar.gz


#解压
tar -zxvf mysql-5.7.$num-linux-glibc2.12-x86_64.tar.gz -C /usr/local/
mv /usr/local/mysql-5.7.$num-linux-glibc2.12-x86_64 /usr/local/mysql

#创建用户
useradd mysql -s /sbin/nologin

#数据存储目录
mkdir -p /data/mysql

#日志存储目录
mkdir -p /var/log/mysql

#创建binlog日志目录
mkdir /data/binlog/

#设置权限
chown mysql:mysql -R /usr/local/mysql  /data/mysql  /var/log/mysql /data/binlog/

#添加环境变量
grep MYSQL /etc/profile >/dev/null
if [ $? -eq 1 ];then
cat >>/etc/profile <<EOF
#MYSQL
export MYSQL=/usr/local/mysql
EOF
echo 'export PATH=$PATH:$MYSQL/bin'>> /etc/profile
fi
source /etc/profile

#修改基本配置
cat > /etc/my.cnf <<EOF
[mysqld]
user=mysql
basedir=/usr/local/mysql
datadir=/data/mysql
server_id=1
port=3306
socket=/data/mysql/mysql.sock

#binlog日志
log_bin=/data/binlog/mysql-bin  
sync_binlog=1
binlog_format=row
expire_logs_days=30
max_binlog_size=100M

[mysql]
socket=/data/mysql/mysql.sock

[mysqld_safe]
log-error=/var/log/mysql/mysql.log
pid-file=/data/mysql/mysql.pid
EOF

#初始化
mysqld --initialize-insecure  --user=mysql --basedir=/usr/local/mysql --datadir=/data/mysql

touch /usr/lib/systemd/system/mysqld57.service
cat >/usr/lib/systemd/system/mysqld.service <<EOF
[Unit]
Description=MySQL Server
Documentation=man:mysqld(8)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target
After=syslog.target
[Install]
WantedBy=multi-user.target
[Service]
User=mysql
Group=mysql
ExecStart=/usr/local/mysql/bin/mysqld --defaults-file=/etc/my.cnf
LimitNOFILE = 5000
EOF
#重新加载system配置
systemctl daemon-reload
systemctl start  mysqld.service
systemctl status mysqld.server

#更新密码
#read -p "请输入新密码:" num
echo "skip-grant-tables" >> /etc/my.cnf
systemctl restart mysqld
cat <<EOF
********************************
** 提示输入免密直接回车  **
********************************
EOF
mysql -u root -p <<EOF
flush privileges;
ALTER USER 'root'@'localhost' IDENTIFIED BY '$passwd_mysql';
flush privileges; 
show databases;
EOF
sed -i 's/skip-grant-tables//g' /etc/my.cnf
systemctl restart mysqld
if [ $? -eq 0 ];then
cat <<EOF
********************************
**    二进制安装已完成      **
**    mysql密码已更新       **
********************************
EOF
fi

#MySQL5.7多实例配置多实例配置
#关闭数据库
systemctl  stop mysqld

#备份my.cnf 
cp /etc/my.cnf /etc/my.cnf.bak

#创建所需目录
mkdir -p /data/33{07..10}/data 

#添加配置
#3307配置
cat > /data/3307/my.cnf << EOF
[mysqld]
basedir=/usr/local/mysql
datadir=/data/3307/data
socket=/data/3307/mysql.sock
port=3307
log-error=/data/3307/mysql.log
log_bin=/data/3307/mysql-bin
binlog_format=row
server-id=7
gtid-mode=on
enforce-gtid-consistency=true
#互为主从必须加下面这一选项
log-slave-updates=1  
EOF

#3308配置
 cat > /data/3308/my.cnf << EOF
[mysqld]
basedir=/usr/local/mysql
datadir=/data/3308/data
port=3308
socket=/data/3308/mysql.sock
log-error=/data/3308/mysql.log
log_bin=/data/3308/mysql-bin
binlog_format=row
server-id=8
gtid-mode=on
enforce-gtid-consistency=true
log-slave-updates=1   
EOF

#3309配置
 cat > /data/3309/my.cnf << EOF
[mysqld]
basedir=/usr/local/mysql
datadir=/data/3309/data
socket=/data/3309/mysql.sock
port=3309
log-error=/data/3309/mysql.log
log_bin=/data/3309/mysql-bin
binlog_format=row
server-id=9
gtid-mode=on
enforce-gtid-consistency=true
log-slave-updates=1  
EOF

#3310配置
cat > /data/3310/my.cnf << EOF
[mysqld]
basedir=/usr/local/mysql
datadir=/data/3310/data
socket=/data/3310/mysql.sock
port=3310
log-error=/data/3310/mysql.log
log_bin=/data/3310/mysql-bin
binlog_format=row
server-id=10
gtid-mode=on
enforce-gtid-consistency=true
log-slave-updates=1   
EOF

#初始化
cat <<EOF
********************************
** 多实例数据库初始化开始  **
********************************
EOF
#3307
cat <<EOF
********************************
** 3307数据库初始化开始  **
********************************
EOF
/usr/local/mysql/bin/mysqld --initialize-insecure  --user=mysql --datadir=/data/3307/data --basedir=/usr/local/mysql
#3308
cat <<EOF
********************************
** 3308数据库初始化开始  **
********************************
EOF
/usr/local/mysql/bin/mysqld --initialize-insecure  --user=mysql --datadir=/data/3308/data --basedir=/usr/local/mysql
#3309
cat <<EOF
********************************
** 3309数据库初始化开始  **
********************************
EOF
/usr/local/mysql/bin/mysqld --initialize-insecure  --user=mysql --datadir=/data/3309/data --basedir=/usr/local/mysql
#3310
cat <<EOF
********************************
** 3310数据库初始化开始  **
********************************
EOF
/usr/local/mysql/bin/mysqld --initialize-insecure  --user=mysql --datadir=/data/3310/data --basedir=/usr/local/mysql

chown -R mysql.mysql /data/*

#添加至system管理

cat > /usr/lib/systemd/system/mysqld3307.service <<EOF
[Unit]
Description=MySQL Server
Documentation=man:mysqld(8)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target
After=syslog.target
[Install]
WantedBy=multi-user.target
[Service]
User=mysql
Group=mysql
ExecStart=/usr/local/mysql/bin/mysqld --defaults-file=/data/3307/my.cnf
LimitNOFILE = 5000
EOF

cat > /usr/lib/systemd/system/mysqld3308.service <<EOF
[Unit]
Description=MySQL Server
Documentation=man:mysqld(8)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target
After=syslog.target
[Install]
WantedBy=multi-user.target
[Service]
User=mysql
Group=mysql
ExecStart=/usr/local/mysql/bin/mysqld --defaults-file=/data/3308/my.cnf
LimitNOFILE = 5000
EOF

cat > /usr/lib/systemd/system/mysqld3309.service <<EOF
[Unit]
Description=MySQL Server
Documentation=man:mysqld(8)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target
After=syslog.target
[Install]
WantedBy=multi-user.target
[Service]
User=mysql
Group=mysql
ExecStart=/usr/local/mysql/bin/mysqld --defaults-file=/data/3309/my.cnf
LimitNOFILE = 5000
EOF

cat > /usr/lib/systemd/system/mysqld3310.service <<EOF
[Unit]
Description=MySQL Server
Documentation=man:mysqld(8)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target
After=syslog.target
[Install]
WantedBy=multi-user.target
[Service]
User=mysql
Group=mysql
ExecStart=/usr/local/mysql/bin/mysqld --defaults-file=/data/3310/my.cnf
LimitNOFILE = 5000
EOF

#重新加载system
systemctl daemon-reload

#启动各别实例
systemctl start mysqld3307.service
systemctl start mysqld3308.service
systemctl start mysqld3309.service
systemctl start mysqld3310.service


#配置host
grep "mycat" /etc/hosts >/dev/null
if [ $? -eq 1 ];then
cat >>/etc/hosts << EOF
192.168.42.130 mysql001
192.168.42.131 mysql002
192.168.42.132 mycat
EOF
fi


cat <<EOF
*************************************************
**    多实例安装完成          
**    使用netstat -lnp|grep 330* 查看运行情况
**************************************************
EOF

#针对第二个节点设置
cat <<EOF
***************************************
**    是否更新my.cnf 的server-id?          
***************************************
EOF

read -p "yes/no:" yn
if [ $yn == "y" ];then
  read -p "请输入3307要更新的server-id(17):" a
  read -p "请输入3308要更新的server-id(18):" b
  read -p "请输入3309要更新的server-id(19):" c
  read -p "请输入3310要更新的server-id(20):" d
  
  #开始更新
  sed -i "s/server-id=7/server-id=$a/g" /data/3307/my.cnf
  sed -i "s/server-id=7/server-id=$b/g" /data/3308/my.cnf
  sed -i "s/server-id=7/server-id=$c/g" /data/3309/my.cnf
  sed -i "s/server-id=7/server-id=$d/g" /data/3310/my.cnf
  
  #重启服务
  systemctl start mysqld3307.service
  systemctl start mysqld3308.service
  systemctl start mysqld3309.service
  systemctl start mysqld3310.service
else
  echo "=====未选择更新server-id====="
fi


#查看运行情况
netstat -lnp|grep "330*"
