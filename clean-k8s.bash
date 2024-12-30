#!/bin/bash
# author YiLing Wu (hj)
# date 2023-12-23 15:21
# description: 清除k8s初始化数据

kubeadm reset <<EOF
y
EOF
rm -rf /etc/kubernetes
rm -rf /var/lib/etcd
rm -rf /etc/kubernetes