#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2023-12-23
#FileName:         clean-k8s.bash
#URL:              http://huangjingblog.cn:510/
#Description:      清除K8s初始化数据
#Copyright (C):    2024 All rights reserved
#********************************************************************
#

kubeadm reset <<EOF
y
EOF
rm -rf /etc/kubernetes
rm -rf /var/lib/etcd
rm -rf /etc/kubernetes