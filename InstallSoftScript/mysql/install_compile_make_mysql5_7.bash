#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2023-12-23
#FileName:         install_compile_make_mysql5_7.bash
#URL:              http://42.194.242.109:510/
#Description:      源码编译安装MySQL5.7，编译时间过长，谨慎选择
#Copyright (C):    2024 All rights reserved
#********************************************************************
#

# 清除旧版本
yum -y remove mariadb* 2>/dev/null
find / -name "*mysql*" -exec rm -rf {} \; 2>/dev/null 
rm -rf /etc/my.cnf

read -p "请设置MySQL密码：" passwd_mysql
read -p "请输入版本号5.7.xx:" num

#安装依赖
yum -y install gcc-c++  ncurses   ncurses-devel cmake
yum install openssl openssl-devel -y
yum install bison* -y

#获取源码包
wget https://cdn.mysql.com/archives/mysql-5.7/mysql-boost-5.7.$num.tar.gz

tar -xvf mysql-boost-5.7.$num.tar.gz  -C /opt/

mv /opt/mysql-5.7.$num/ /opt/mysql

#编译
cd /opt/mysql/

cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql57 -DMYSQL_DATADIR=/data/mysql57 -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DMYSQL_TCP_PORT=3306 -DMYSQL_UNIX_ADDR=/data/mysql57/mysql.sock -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DDOWNLOAD_BOOST=0 -DWITH_BOOST=/opt/mysql/boost -DWITH_INNODB_MEMCACHED=ON 

make  && make install

#创建用户
#read -p "创建mysql用户：" user_mysql
useradd mysql -s /sbin/nologin

#数据存储目录
#datadir=/data/mysql
#read -p "数据目录:" data_home
mkdir -p /data/mysql57

#日志存储目录
#/var/log/mysql
#read -p "日志存储目录:" log_home
mkdir -p /var/log/mysql57
#设置权限
chown mysql:mysql -R /usr/local/mysql57  /data/mysql57  /var/log/mysql57

#添加环境变量
grep MYSQL /etc/profile >/dev/null
if [ $? -eq 1 ];then
cat >>/etc/profile <<EOF
#MYSQL
export MYSQL=/usr/local/mysql57
EOF
echo 'export PATH=$PATH:$MYSQL/bin'>> /etc/profile
fi
source /etc/profile

#修改基本配置
mkdir  /etc/mysql57/
cat > /etc/mysql57/my.cnf <<EOF
[mysqld]
user=mysql57
basedir=/usr/local/mysql57
datadir=/data/mysql57
server_id=1
port=3306
socket=/data/mysql57/mysql.sock

[mysql]
socket=/data/mysql57/mysql.sock

[mysqld_safe]
log-error=/var/log/mysql57/mysql.log
pid-file=/data/mysql57/mysql.pid
EOF

#初始化
mysqld --initialize-insecure  --user=mysql --basedir=/usr/local/mysql57 --datadir=/data/mysql57
touch /usr/lib/systemd/system/mysqld57.service
cat >/usr/lib/systemd/system/mysqld57.service <<EOF
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
ExecStart=/usr/local/mysql57/bin/mysqld --defaults-file=/etc/mysql57/my.cnf
LimitNOFILE = 5000
EOF
#重新加载system配置
systemctl daemon-reload
systemctl start  mysqld57.service
systemctl status mysqld57.server

#更新密码
echo "======提示输入免密直接回车======"
echo "skip-grant-tables" >> /etc/mysql57/my.cnf
systemctl restart mysqld57.server
mysql -u root -p <<EOF
flush privileges;
ALTER USER 'root'@'localhost' IDENTIFIED BY '$passwd_mysql';
flush privileges; 
show databases;
EOF
sed -i 's/skip-grant-tables//g' /etc/mysql57/my.cnf
systemctl restart mysqld
if [ $? -eq 0 ];then
  echo "======源码安装完成======"
  echo "======mysql密码已更新======"
fi