#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2023-12-23
#FileName:         ssh7.4_update_ssh8.9.bash
#URL:              http://42.194.242.109:510/
#Description:      CentOS下更新SSH 7.4到SSH 8.9
#Copyright (C):    2024 All rights reserved
#********************************************************************
#

#本脚本在root目录下运行
#检查防火墙
firewalld_status=`systemctl status firewalld | grep "running" | wc -l`
if [ $firewalld_status -eq 1 ]; then
   systemctl stop firewalld
   echo "firewalld is stop"
else
    echo"防火墙已关闭"
    systemctl status firewalld
fi

#检查selinux
selinux_status=`awk 'BEGIN{FS="="}NR=="7"{print $2}' /etc/selinux/config`
if [[ $selinux_status == "enforcing" ]]; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
    echo "selinux is stop"
else
    echo "selinux已关闭"
fi

#安装telnet
yum -y install telnet*
systemctl enable telnet.socket
systemctl start telnet.socket

#安装依赖包
yum -y install zlib*
yum -y install pam-*
yum -y install gcc
yum -y install openssl-devel

#备份原有ssh服务版本
cp -r /etc/ssh /etc/ssh.bak
mv /usr/bin/ssh /usr/bin/ssh.bak
mv /usr/sbin/sshd /usr/sbin/sshd.bak

#下载openssh8.9
wget https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-8.9p1.tar.gz
tar -zxvf openssh-8.9p1.tar.gz
cd openssh-8.9p1
echo "开始编译"
./configure --prefix=/usr/local/openssh --with-zlib=/usr/local/zlib --with-ssl-dir=/usr/local/ssl
make && make install

#卸载由yum安装的openssh
yum remove openssh -y

cat >>/usr/local/openssh/etc/sshd_config <<EOF
PermitRootLogin yes
PubkeyAuthentication yes
PasswordAuthentication yes
EOF

cp /root/openssh-8.9p1/contrib/redhat/sshd.init /etc/init.d/sshd
chkconfig --add sshd
cp /usr/local/openssh/etc/sshd_config /etc/ssh/sshd_config
cp /usr/local/openssh/sbin/sshd /usr/sbin/sshd
cp /usr/local/openssh/bin/ssh /usr/bin/ssh
cp /usr/local/openssh/bin/ssh-keygen /usr/bin/ssh-keygen
cp /usr/local/openssh/etc/ssh_host_ecdsa_key.pub /etc/ssh/ssh_host_ecdsa_key.pub

echo "================启动服务================"
systemctl restart sshd.service
echo "================服务状态================"
systemctl status sshd.service

echo "================ssh版本验证================"
ssh -V
