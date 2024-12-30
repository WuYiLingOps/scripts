#!/bin/bash
# user: huangjing 2023.11.08-18.16
# author YiLing Wu (hj)
# date 2023-12-23 15:21
# description: 一键自动化创建和分发公钥

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
