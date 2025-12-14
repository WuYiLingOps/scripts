#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2023-12-23
#FileName:         install_mysql5_7_bin.bash
#URL:              http://huangjingblog.cn:510/
#Description:      CentOS下二进制安装MySQL5.7
#Copyright (C):    2024 All rights reserved
#********************************************************************
#

#使用sourc类运行脚本！！！
#二进制安装:使用本地包进行安装,或者拉去官网包进行安装
# 默认版本:5.7
clean_mysql(){
#清除旧版本
yum -y remove mariadb* 2>/dev/null
rm -rf /usr/lib64/mysql
rm -rf /usr/share/mysql
yum install -y libaio
}

install_mysql_yilai(){
read -p "请设置MySQL密码：" passwd_mysql
yum -y install gcc-c++  ncurses   ncurses-devel cmake
yum install openssl openssl-devel -y
yum install bison* -y
}

pull_mysql(){
wget https://downloads.mysql.com/archives/get/p/23/file/mysql-5.7.40-linux-glibc2.12-x86_64.tar.gz
}

tar_mysql(){
MySQL_tar=`ls | grep "mysql-"`
tar -zxvf $MySQL_tar -C /usr/local/
MySQL_name=`ls /usr/local/ | grep "mysql-"`
mv /usr/local/$MySQL_name /usr/local/mysql
}

mysql_data(){
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
}

mysql_profile(){
grep MYSQL /etc/profile >/dev/null
if [ $? -ne 0 ];then
cat >>/etc/profile <<EOF
#MYSQL
export MYSQL=/usr/local/mysql
export PATH=\$PATH:\$MYSQL/bin
EOF
fi
source /etc/profile
}

mysql_conf(){
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
}

mysql_systemd(){
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
systemctl status mysqld.service
}

mysql_install(){
mysqld --initialize-insecure  --user=mysql --basedir=/usr/local/mysql --datadir=/data/mysql
echo "skip-grant-tables" >> /etc/my.cnf
systemctl restart mysqld
echo "======提示输入免密直接回车======"
mysql -u root -p <<EOF
flush privileges;
ALTER USER 'root'@'localhost' IDENTIFIED BY '$passwd_mysql';
flush privileges; 
show databases;
EOF
sed -i 's/skip-grant-tables//g' /etc/my.cnf
systemctl restart mysqld
}

main_network(){
clean_mysql
install_mysql_yilai
pull_mysql
tar_mysql
mysql_data
mysql_profile
mysql_conf
mysql_systemd
mysql_install
}

main_local(){
clean_mysql
install_mysql_yilai
tar_mysql
mysql_data
mysql_profile
mysql_conf
mysql_systemd
mysql_install
}

#开始安装
cat <<EOF
*****************************************
**    注意事项：
**    1.利用source 运行脚本   
**    2.检查自己的网络是否能连接外网   
*****************************************
EOF
cat <<EOF
*****************************
**    支持以下方式进行安装：
**    1.官网二进制安装     
**    2.本地二进制安装
*****************************
EOF
read -p "Input a choose:" OP
case $OP in
1)
cat <<EOF
********************************
**    开始进行二进制安装      **
********************************
EOF
#调用
main_network
if [ $? -eq 0 ];then
cat <<EOF
********************************
**    二进制安装已完成         **
**    mysql密码已更新       **
********************************
EOF
fi
  ;;
2)
cat <<EOF
********************************
**  开始进行本地二进制安装    **
********************************
EOF
main_local
   ;;
   *)
echo error
esac
