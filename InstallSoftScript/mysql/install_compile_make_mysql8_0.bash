#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2023-12-23
#FileName:         install_compile_make_mysql8_0.bash
#URL:              http://huangjingblog.cn:510/
#Description:      源码编译安装MySQL8.0，编译时间过久，谨慎选择
#Copyright (C):    2024 All rights reserved
#********************************************************************
#

#cmake官网:https://cmake.org/download/
#默认端口设置为3380

#清理残余
rm -rf /etc/my.cnf
yum remove cmake -y
yum -y remove mariadb* 2>/dev/null
yum install -y libaio
find / -name "*mysql*" -exec rm -rf {} \; 2>/dev/null

#提前上传cmake包至脚本同目录
cmake_version=`ls | grep cmake-3*`
tar -zxf $cmake_version -C /opt/
cmake_install=`ls /opt/ | grep "cmake-3*"`
mv /opt/$cmake_install /opt/cmake


if [ $? -eq 0 ];then
  grep "CMAKE" /etc/profile >/dev/null
  if [ $? -eq 1 ];then
cat >>/etc/profile <<EOF
#CMAKE
export CMAKE_HOME=/opt/cmake
EOF
  echo 'export PATH=$PATH:$CMAKE_HOME/bin' >> /etc/profile
  fi
  source /etc/profile
  echo "======cmake版本号======"
  cmake --version
fi

#gcc 升级9.0
yum install -y gcc gcc-c++ gcc-g77
yum -y install centos-release-scl
yum -y install devtoolset-9-gcc devtoolset-9-gcc-c++ devtoolset-9-binutils

mv /usr/bin/gcc /usr/bin/gcc.bak
cp /opt/rh/devtoolset-9/root/usr/bin/gcc /usr/bin/
if [ $? -eq 0 ];then
  echo "======gcc版本号======"
fi
gcc -v


#其他依赖安装
yum install -y make
yum install -y openssl openssl-libs openssl-devel
yum install -y ncurses ncurses-devel
yum install -y bison bison-devel


#获取8.x安装包
wget https://cdn.mysql.com/archives/mysql-8.0/mysql-boost-8.0.30.tar.gz

tar -zxvf mysql-boost-8.0.30.tar.gz -C /opt/
cd /opt/mysql-8.0.30
#开始编译
mkdir cbuild
cd cbuild/
yum install devtoolset-11-gcc devtoolset-11-gcc-c++ devtoolset-11-binutils -y

cmake .. \
-DCMAKE_INSTALL_PREFIX=/usr/local/mysql80/ \
-DDEFAULT_CHARSET=utf8mb4 \
-DDEFAULT_COLLATION=utf8mb4_0900_ai_ci \
-DENABLED_LOCAL_INFILE=ON \
-DMYSQL_DATADIR=/data/mysql80/ \
-DMYSQL_TCP_PORT=3380 \
-DMYSQL_UNIX_ADDR=/data/mysql80/mysql.sock \
-DSYSCONFDIR=/etc/mysql80/my.cnf \
-DWITH_ARCHIVE_STORAGE_ENGINE=1 \
-DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
-DWITHOUT_EXAMPLE_STORAGE_ENGINE=1 \
-DWITH_FEDERATED_STORAGE_ENGINE=1 \
-DWITH_NDB_STORAGE_ENGINE=1 \
-DWITH_BOOST=/opt/mysql-8.0.30/boost/boost_1_77_0 \
-DWITH_INNODB_MEMCACHED=ON \
-DWITH_SSL=system

make && make install

useradd mysql -s /sbin/nologin
mkdir -p /data/mysql80
mkdir -p /var/log/mysql80/
chown -R mysql:mysql /usr/local/mysql80/ /data/mysql80/ /var/log/mysql80/

#添加环境变量
cat >>/etc/profile <<EOF
#MYSQL80
export MYSQL80=/usr/local/mysql80
EOF
echo 'export PATH=$PATH:$MYSQL80/bin'>> /etc/profile
source /etc/profile


#修改基本配置
mkdir  /etc/mysql80/
cat > /etc/mysql80/my.cnf <<EOF
[mysqld]
user=mysql80
basedir=/usr/local/mysql80
datadir=/data/mysql80
server_id=2
port=3380
socket=/data/mysql80/mysql.sock

[mysql]
socket=/data/mysql80/mysql.sock

[mysqld_safe]
log-error=/var/log/mysql80/mysql.log
pid-file=/data/mysql80/mysql.pid
EOF
#初始化
/usr/local/mysql80/bin/mysqld --initialize-insecure  --user=mysql --basedir=/usr/local/mysql80 --datadir=/data/mysql80

#添加至system进行管理
touch /usr/lib/systemd/system/mysqld80.service
cat >/usr/lib/systemd/system/mysqld80.service <<EOF
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
ExecStart=/usr/local/mysql80/bin/mysqld --defaults-file=/etc/mysql80/my.cnf
LimitNOFILE = 5000
EOF
#重新加载system配置
systemctl daemon-reload
systemctl start  mysqld80.service
systemctl status mysqld80.service

#更新密码
echo "======提示输入免密直接回车======"
echo "skip-grant-tables" >> /etc/mysql57/my.cnf
systemctl restart mysqld80.service
mysql -u root -p <<EOF
flush privileges;
ALTER USER 'root'@'localhost' IDENTIFIED BY '$passwd_mysql';
flush privileges; 
show databases;
EOF
sed -i 's/skip-grant-tables//g' /etc/mysql80/my.cnf
systemctl restart mysqld
if [ $? -eq 0 ];then
  echo "======源码安装完成======"
  echo "======mysql密码已更新======"
fi
