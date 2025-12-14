#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2023-12-23
#FileName:         k8s-自动补全脚本.bash
#URL:              http://huangjingblog.cn:510/
#Description:      K8s指令自动补全配置脚本
#Copyright (C):    2024 All rights reserved
#********************************************************************
#
# Usage: source k8s-自动补全脚本.bash
echo "source <(kubectl completion bash)" >> ~/.bashrc
source ~/.bashrc
