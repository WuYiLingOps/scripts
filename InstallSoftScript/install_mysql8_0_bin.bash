#!/bin/bash
# author YiLing Wu (hj)
# date 2023-12-23 15:21
# description: centos下二进制安装MySQL8.0

#删除旧版本
old(){
for i in $(rpm -qa|grep mysql);
do 
  rpm -e $i --nodeps;
done
}

download_and_install(){
#安装所需依赖
yum -y install libaio
yum -y install net-tools
#查看是否有所需包
mysql8=`ls | grep "mysql.*gz"`
if [ $? -ne 0 ];then
  #拉取mysql8.0
  wget https://downloads.mysql.com/archives/get/p/23/file/mysql-8.0.11-linux-glibc2.12-x86_64.tar.gz
  mysql8=`ls | grep "mysql.*gz"`
  tar -zxvf $mysql8 -C /usr/local/
else
  tar -zxvf $mysql8 -C /usr/local/
fi

mysq_pack=`ls /usr/local/ | grep "mysql-8"`
mv /usr/local/$mysq_pack /usr/local/mysql
}

# 设置密码
password(){
read -p "请设置MySQL密码：" -s pwd_mysql
echo
read -p "请再次输入密码：" -s pwd
echo
}

determine1(){
if [ $pwd == $pwd_mysql ];then
   end_pwd=$pwd
#   echo password read, is "\"$pwd\""
   return 0
else
   echo "两次密码不相同,请重新输入...."
   return 1
fi
}

if [ $? -eq 1 ];then
  password
fi

# 最终密码调用函数
new_password(){
while true
do
password
determine1
if [ $? -eq 1 ];then
  password
  determine1
else
  break
fi
done
}

add_user_and_data_log_conf(){
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
}

initialize_AddService(){
#初始化
mysqld --initialize-insecure  --user=mysql --basedir=/usr/local/mysql --datadir=/data/mysql

# 将mysql添加至systemctl进行管理
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
}

update_pwd(){
#更新密码
echo "skip-grant-tables" >> /etc/my.cnf
systemctl restart mysqld
echo "======提示输入免密直接回车======"
mysql -u root -p <<EOF
flush privileges;
ALTER USER 'root'@'localhost' IDENTIFIED BY '$end_pwd';
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
}

main(){
  old
  download_and_install
  new_password
  add_user_and_data_log_conf
  initialize_AddService
  update_pwd
}

#调用安装
main