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

# 确保 nvm 已加载
load_nvm() {
    if ! command -v nvm > /dev/null 2>&1; then
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$HOME/.bashrc" ] && source "$HOME/.bashrc"
    fi
}

# 检查 nvm 是否已安装
load_nvm
if ! command -v nvm > /dev/null 2>&1; then
    # 下载并安装 nvm
    log_step "下载并安装 nvm"
    wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
    if [ $? -eq 0 ]; then
        log_info "nvm 安装成功"
        load_nvm
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
    # 询问用户是否要安装指定版本
    echo -e "${YELLOW}是否要安装指定版本的 Node.js？${RESET}"
    echo -e "${CYAN}  默认将安装 Node.js 18${RESET}"
    read -p "请输入 y 安装指定版本，直接回车使用默认版本 18: " install_custom
    
    NODE_VERSION="18"
    
    if [ "${install_custom}" = "y" ] || [ "${install_custom}" = "Y" ]; then
        log_step "获取可安装的 Node.js 版本列表"
        load_nvm
        echo -e "${CYAN}正在获取版本列表，请稍候...${RESET}"
        # 列出可安装的版本（LTS 和最新版本）
        echo -e "${BOLD}=== LTS 版本（长期支持版本）===${RESET}"
        nvm ls-remote --lts | tail -20
        echo ""
        echo -e "${BOLD}=== 最新版本 ===${RESET}"
        nvm ls-remote | tail -10
        echo ""
        read -p "请输入要安装的 Node.js 版本号（例如: 20.11.0 或 18.19.0）: " NODE_VERSION
        
        if [ -z "${NODE_VERSION}" ]; then
            log_warn "未输入版本号，使用默认版本 18"
            NODE_VERSION="18"
        fi
    fi
    
    log_step "安装 Node.js 版本 ${NODE_VERSION}"
    load_nvm
    nvm install "${NODE_VERSION}"
    if [ $? -eq 0 ]; then
        nvm use "${NODE_VERSION}"
        nvm alias default "${NODE_VERSION}"
        nvm ls
        log_info "Node.js 版本: ${PURPLE}$(node -v)${RESET}"
    else
        log_error "Node.js ${NODE_VERSION} 安装失败"
        exit 1
    fi

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
