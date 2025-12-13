#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2023-12-23
#FileName:         install_nvm_node.bash
#URL:              http://42.194.242.109:510/
#Description:      检查本地是否存在NVM，并使用NVM安装Node18，并配置淘宝源
#Copyright (C):    2024 All rights reserved
#********************************************************************
#

# 检查 nvm 是否已安装
command -v nvm > /dev/null
if [ $? -ne 0 ]; then
    # 下载并安装 nvm
    wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
    if [ $? -eq 0 ]; then
        echo "nvm 安装成功..."
        source ~/.bashrc
        echo "nvm 版本号: $(nvm --version)"
    else
        echo "nvm 安装失败"
        exit 1
    fi
else
    echo "nvm 已存在，版本号为: $(nvm --version)"
fi

# 检查 node 是否已安装
command -v node > /dev/null
if [ $? -ne 0 ]; then
    echo "安装 Node.js 版本 18..."
    nvm install 18
    nvm use 18
    nvm alias default 18
    nvm ls
    echo "Node.js 版本: $(node -v)"

    # 备份当前 npm 源
    npm_registry_backup=$(npm get registry)
    echo "备份当前 npm 源: $npm_registry_backup"

    # 设置 npm 镜像源
    npm config set registry https://registry.npmmirror.com
    echo "当前 npm 源为: $(npm get registry)"
else
    echo "本地 Node.js 已存在，版本为: $(node -v)"
fi
