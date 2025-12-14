#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2023-12-23
#FileName:         fenfa.bash
#URL:              http://huangjingblog.cn:510/
#Description:      一键自动化创建和分发SSH公钥
#Copyright (C):    2024 All rights reserved
#********************************************************************
#

ip_list="192.168.10.7 192.168.10.31 192.168.10.41 192.168.10.51"
echo '--------------------------------------------'
echo '1. 创建 key'
echo '--------------------------------------------'
ssh-keygen -f ~/.ssh/id_rsa -P ''
echo '--------------------------------------------'
echo '2. 分发 pub key'
echo '--------------------------------------------'
for ip in $ip_list
do
  sshpass -p1 ssh-copy-id -i ~/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@$ip
done
