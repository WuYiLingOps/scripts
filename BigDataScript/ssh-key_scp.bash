#!/bin/bash
# author YiLing Wu (hj)
# date 2024-12-23 15:21
# description: 在所有节点运行此脚本,实现免密登陆

# 获取所有主机名
nodes=$(awk '!/^#/ && NF==2 {print $2}' /etc/hosts)

echo "create key..."
    if [ ! -f ~/.ssh/id_rsa ]; then
        echo "Generating SSH key pair..."
        ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa
    fi
echo "scp nodes ...."
    for hostname in $nodes
    do
        ssh-copy-id $hostname
    done
echo "SSH key distribution completed successfully."
