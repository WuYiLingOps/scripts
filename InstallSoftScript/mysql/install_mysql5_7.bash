#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2023-12-23
#FileName:         install_mysql5_7.bash
#URL:              http://huangjingblog.cn:510/
#Description:      CentOS下安装MySQL5.7，可选择安装方式
#Copyright (C):    2024 All rights reserved
#********************************************************************
#

# 使用sourc类运行脚本！！！
# 默认5.7版本
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
**    1.yum 安装     
**    2.二进制安装     
**    3.源码安装      
**    4.本地安装
*****************************
EOF
read -p "Input a choose:" OP
case $OP in
1|backup)
cat <<EOF
********************************
**    开始进行yum安装      **
********************************
EOF
#清除残留
read -p "请输入新密码:" num
yum -y remove mariadb* 2>/dev/null
yum install -y libaio
find / -name "*mysql*" -exec rm -rf {} \; 2>/dev/null

#安装依赖
yum -y install gcc-c++  ncurses   ncurses-devel cmake
yum install openssl openssl-devel -y
yum install bison* -y

#获取社区版的 Yum 存储库
rpm -ivh https://repo.mysql.com//yum/mysql-5.7-community/el/7/x86_64/mysql57-community-release-el7-10.noarch.rpm
yum list >/dev/null
#关闭全部验证
sed -i 's/gpgcheck=1/gpgcheck=0/g'  /etc/yum.repos.d/mysql-community.repo
yum -y install mysql-community-server
systemctl start mysqld

#修改密码交互验证
#cut_password=`grep 'password' /var/log/mysqld.log | cut -d ":" -f4`
echo "skip-grant-tables" >> /etc/my.cnf
systemctl restart mysqld
echo "======提示输入免密直接回车======"
mysql -u root -p <<EOF
flush privileges;
ALTER USER 'root'@'localhost' IDENTIFIED BY '$num';
flush privileges; 
show databases;
EOF
sed -i 's/skip-grant-tables//g' /etc/my.cnf
systemctl restart mysqld
if [ $? -eq 0 ];then
cat <<EOF
********************************
**    yum安装已完成         **
**    mysql密码已更新       **
********************************
EOF
fi
   ;;
2|"二进制安装")
cat <<EOF
********************************
**    开始进行二进制安装      **
********************************
EOF
read -p "请设置MySQL密码：" passwd_mysql
read -p "请输入版本号5.7.xx:" num

#安装依赖
yum -y install gcc-c++  ncurses   ncurses-devel cmake
yum install openssl openssl-devel -y
yum install bison* -y

#清除旧版本
yum -y remove mariadb* 2>/dev/null
find / -name "*mysql*" -exec rm -rf {} \; 2>/dev/null 
yum install -y libaio

# 获取mysql二进制压缩包
wget https://downloads.mysql.com/archives/get/p/23/file/mysql-5.7.$num-linux-glibc2.12-x86_64.tar.gz


#解压
#read -p "选择安装目录:" install_home
tar -zxvf mysql-5.7.$num-linux-glibc2.12-x86_64.tar.gz -C /usr/local/
mv /usr/local/mysql-5.7.$num-linux-glibc2.12-x86_64 /usr/local/mysql

#创建用户
#read -p "创建mysql用户：" user_mysql
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
systemctl status mysqld.service

#更新密码
#read -p "请输入新密码:" num
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
if [ $? -eq 0 ];then
cat <<EOF
********************************
**    二进制安装已完成      **
**    mysql密码已更新       **
********************************
EOF
fi

   ;;
3|"源码安装")
cat <<EOF
********************************
**    开始进源码安装      **
********************************
EOF
#清除旧版本
yum -y remove mariadb* 2>/dev/null
find / -name "*mysql*" -exec rm -rf {} \; 2>/dev/null 

read -p "请设置MySQL密码：" passwd_mysql
read -p "请输入版本号5.7.xx:" num

#安装依赖
yum -y install gcc-c++  ncurses   ncurses-devel cmake
yum install openssl openssl-devel -y
yum install bison* -y
yum install -y libaio
#获取源码包
wget https://cdn.mysql.com/archives/mysql-5.7/mysql-boost-5.7.$num.tar.gz

tar -xvf mysql-boost-5.7.$num.tar.gz  -C /opt/

mv /opt/mysql-5.7.$num/ /opt/mysql

#编译
cd /opt/mysql/

cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DMYSQL_DATADIR=/data/mysql -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DMYSQL_TCP_PORT=3306 -DMYSQL_UNIX_ADDR=/data/mysql/mysql.sock -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DDOWNLOAD_BOOST=0 -DWITH_BOOST=/opt/mysql/boost -DWITH_INNODB_MEMCACHED=ON 

make  && make install

#创建用户
#read -p "创建mysql用户：" user_mysql
useradd mysql -s /sbin/nologin

#数据存储目录
#datadir=/data/mysql
#read -p "数据目录:" data_home
mkdir -p /data/mysql

#日志存储目录
#/var/log/mysql
#read -p "日志存储目录:" log_home
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
systemctl status mysqld.service


#更新密码
echo "======提示输入免密直接回车======"
echo "skip-grant-tables" >> /etc/my.cnf
systemctl restart mysqld
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
**    源码安装已完成      **
**    mysql密码已更新       **
********************************
EOF
fi

   ;;
4|"本地安装")
cat <<EOF
********************************
**    开始进行本地安装        **
**(请提前将相关包上传至服务器)**
********************************
EOF
read -p "请设置MySQL密码：" passwd_mysql
MySQL_tar=`ls | grep "mysql-"`
#清除旧版本
yum -y remove mariadb* 2>/dev/null
rm -rf /usr/lib64/mysql
rm -rf /usr/share/mysql
yum install -y libaio
#解压
tar -zxvf $MySQL_tar -C /usr/local/

#安装依赖
yum -y install gcc-c++  ncurses   ncurses-devel cmake
yum install openssl openssl-devel -y
yum install bison* -y

MySQL_name=`ls /usr/local/ | grep "mysql-"`
mv /usr/local/$MySQL_name /usr/local/mysql

#创建用户
#read -p "创建mysql用户：" user_mysql
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
echo "======提示输入免密直接回车======"
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
**    本地安装已完成      **
**    mysql密码已更新       **
********************************
EOF
fi
   ;;
   *)
echo error
esac
