#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2023-12-23
#FileName:         del_user.bash
#URL:              http://huangjingblog.cn:510/
#Description:      删除指定用户，并选择是否清除用户数据
#Copyright (C):    2024 All rights reserved
#********************************************************************
#

read -p "输入要删除的用户:" username
read -p "是否同时删除用户目录(y/n):" yn

if [ $yn == "y" ]; then
  userdel -r $username
  if [ $? -eq 0 ]; then
    rm -rf /var/spool/mail/$username
    echo "===已同时删除$username 用户目录==="
  fi
else
  userdel $username
  if [ $? -eq 0 ]; then
    rm -rf /var/spool/mail/$username
    echo "===未选择删除$username 用户目录==="
  fi
fi
