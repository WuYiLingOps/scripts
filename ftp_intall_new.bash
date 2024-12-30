#!/bin/bash
# author YiLing Wu (hj)
# date 2023-12-23 15:21
# description: 此脚本为一键安装ftp并修改用户上传文件目录脚本

read -p " 请输入用户名字:" name
read -p "请输入所指定账户文件绝对路径:" dir
mkdir $dir
useradd -d $dir $name
read -p "请输入密码：" pawd
echo $pawd | passwd --stdin $name
cp /etc/skel/.bash* $dir
chown $name:$name -R $dir
if [ $? -eq 0 ];
then
    echo "更改家目录成功"
else
    echo "请输入正确的地址"
fi
#上面为修改用户以及其家目录，下面为安装ftp过程
yum repolist > /dev/null
if [ $? -eq 0 ];
then
    echo "yum源正常"
else
    echo "请检查yum源"
fi
echo "安装ftp "
yum install -y vsftpd > /dev/null
yum install -y ftp > /dev/null
if [ $? -eq 0 ];
then
    echo "ftp服务器已经安装或者安装完毕"
fi
sed -i 's/anonymous_enable=YES/anonymous_enable=NO/g' /etc/vsftpd/vsftpd.conf
sed -i 's/userlist_enable=NO/userlist_enable=YES/g' /etc/vsftpd/vsftpd.conf
echo "userlist_deny=NO" >> /etc/vsftpd/vsftpd.conf
echo $name > /etc/vsftpd/user_list
service vsftpd restart
chkconfig vsftpd on
if [ $? -eq 0 ];
then
    echo "ftp启动成功"
else
    echo "请检查ftp配置"
fi
