#!/bin/bash
# author YiLing Wu (hj)
# date 2023-12-23 15:21
# description: k8s指令自动补全
#使用source运行
echo "source <(kubectl completion bash)" >> ~/.bashrc
source ~/.bashrc
