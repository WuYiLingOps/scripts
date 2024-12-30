#!/bin/bash
# author YiLing Wu (hj)
# date 2023-12-23 15:21
# description: 删除指定用户,并选择是否清除用户数据

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
