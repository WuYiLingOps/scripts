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

# ==================== 颜色定义 ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
BOLD='\033[1m'
RESET='\033[0m'

# ==================== 函数定义 ====================
# 带颜色的日志输出
log_info() {
    echo -e "${GREEN}[INFO]${RESET} $1"
}
log_warn() {
    echo -e "${YELLOW}[WARN]${RESET} $1"
}
log_error() {
    echo -e "${RED}[ERROR]${RESET} $1"
}
log_step() {
    echo -e "${BLUE}[STEP]${RESET} ${BOLD}$1${RESET}"
}

# 检查 nvm 是否已安装
command -v nvm > /dev/null
if [ $? -ne 0 ]; then
    # 下载并安装 nvm
    log_step "下载并安装 nvm"
    wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
    if [ $? -eq 0 ]; then
        log_info "nvm 安装成功"
        source ~/.bashrc
        log_info "nvm 版本号: ${PURPLE}$(nvm --version)${RESET}"
    else
        log_error "nvm 安装失败"
        exit 1
    fi
else
    log_warn "nvm 已存在，版本号为: ${PURPLE}$(nvm --version)${RESET}"
fi

# 检查 node 是否已安装
log_step "检查 Node.js 安装状态"
command -v node > /dev/null
if [ $? -ne 0 ]; then
    log_step "安装 Node.js 版本 18"
    nvm install 18
    nvm use 18
    nvm alias default 18
    nvm ls
    log_info "Node.js 版本: ${PURPLE}$(node -v)${RESET}"

    # 备份当前 npm 源
    log_step "配置 npm 镜像源"
    npm_registry_backup=$(npm get registry)
    log_info "备份当前 npm 源: ${CYAN}$npm_registry_backup${RESET}"

    # 设置 npm 镜像源
    npm config set registry https://registry.npmmirror.com
    log_info "当前 npm 源为: ${CYAN}$(npm get registry)${RESET}"
else
    log_warn "本地 Node.js 已存在，版本为: ${PURPLE}$(node -v)${RESET}"
fi
