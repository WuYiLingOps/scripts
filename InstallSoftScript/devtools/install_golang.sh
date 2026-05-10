#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2025-12-14
#FileName:         install_golang.sh
#URL:              https://script.huangjingblog.cn
#Description:      自动化安装Go语言环境，支持下载、解压、配置环境变量并验证安装
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

# 检查命令执行结果
check_result() {
    if [ $? -eq 0 ]; then
        log_info "$1 成功"
    else
        log_error "$1 失败，脚本退出"
        exit 1
    fi
}

# ==================== 主流程 ====================
# 1. 检查是否为root用户
if [ $EUID -ne 0 ]; then
    log_error "请使用root用户执行该脚本（sudo ./install_go.sh）"
    exit 1
fi

# 2. 下载Go安装包
log_step "1. 开始下载Go 1.25.5安装包"
GO_TAR="go1.25.5.linux-amd64.tar.gz"
GO_URL="https://golang.google.cn/dl/${GO_TAR}"

if [ -f "${GO_TAR}" ]; then
    log_warn "安装包 ${GO_TAR} 已存在，跳过下载"
else
    wget "${GO_URL}" -O "${GO_TAR}" --quiet
    check_result "下载Go安装包"
fi

# 3. 解压Go安装包到/usr/local
log_step "2. 解压Go安装包到/usr/local"
if [ -d "/usr/local/go" ]; then
    log_warn "/usr/local/go 目录已存在，是否覆盖解压？(y/n)"
    read -r confirm
    if [ "${confirm}" != "y" ] && [ "${confirm}" != "Y" ]; then
        log_info "用户取消覆盖，跳过解压步骤"
    else
        rm -rf /usr/local/go
        tar -zxf "${GO_TAR}" -C /usr/local > /dev/null 2>&1
        check_result "解压Go安装包"
    fi
else
    tar -zxf "${GO_TAR}" -C /usr/local > /dev/null 2>&1
    check_result "解压Go安装包"
fi

# 4. 配置Go环境变量（/etc/profile）
log_step "3. 配置Go环境变量到/etc/profile"
PROFILE_FILE="/etc/profile"
GO_ENV_CONTENT=$(cat <<EOF

# Golang 环境变量设置
export GOROOT=/usr/local/go
export GOPATH=\$HOME/go
export PATH=\$PATH:\$GOROOT/bin:\$GOPATH/bin
EOF
)

# 检查环境变量是否已存在
if grep -q "# Golang 环境变量设置" "${PROFILE_FILE}"; then
    log_warn "Go环境变量已存在于 ${PROFILE_FILE}，跳过添加"
else
    echo "${GO_ENV_CONTENT}" >> "${PROFILE_FILE}"
    check_result "添加Go环境变量"
fi

# 5. 生效环境变量
log_step "4. 生效环境变量"
source "${PROFILE_FILE}"

# 6. 配置 Go 代理（GOPROXY）
log_step "5. 配置 Go 代理（GOPROXY）"
go env -w GO111MODULE=on
go env -w GOPROXY=https://goproxy.io,direct
log_info "已设置 GO111MODULE: $(go env GO111MODULE)"
log_info "已设置 GOPROXY: $(go env GOPROXY)"

# 7. 验证Go版本
log_step "6. 生效环境变量并验证Go版本"
GO_VERSION=$(go version 2>/dev/null)
if echo "${GO_VERSION}" | grep -q "go1.25.5"; then
    log_info "Go版本验证成功：${PURPLE}${GO_VERSION}${RESET}"
else
    log_error "Go版本验证失败，当前版本：${GO_VERSION:-未检测到}"
    exit 1
fi

# 8. 最终提示
log_step "Go 1.25.5 安装配置完成！"
echo -e "${CYAN}使用说明：${RESET}"
echo -e "  1. 立即生效环境变量：source /etc/profile"
echo -e "  2. 验证Go版本：go version"
echo -e "  3. GOPATH目录：\$HOME/go（会在首次使用时自动创建）"
echo -e "  4. 当前 GOPROXY：$(go env GOPROXY)"
