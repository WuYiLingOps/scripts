#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2025-12-15
#FileName:         ubuntu_install_nginx_bin.bash
#URL:              http://huangjingblog.cn:510/
#Description:      Ubuntu下二进制编译安装Nginx（源码编译方式）
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

#==================== 基础检查 ====================
# 需要 root 权限
if [ "$EUID" -ne 0 ]; then
    log_error "请以 root 或 sudo 权限执行此脚本"
    exit 1
fi

NGINX_VERSION="${NGINX_VERSION:-1.24.0}"
NGINX_PREFIX="/usr/local/nginx"
NGINX_TAR="nginx-${NGINX_VERSION}.tar.gz"
NGINX_SRC_DIR="/opt/nginx-${NGINX_VERSION}"

#==================== 安装依赖 ====================
log_step "安装依赖包 (build-essential/PCRE/OpenSSL/Zlib/GD)"
apt-get update -y
apt-get install -y \
  build-essential \
  libpcre3 libpcre3-dev \
  zlib1g-dev \
  libssl-dev \
  libgd-dev libpng-dev libjpeg-dev libfreetype6-dev \
  wget curl > /dev/null
if [ $? -ne 0 ]; then
    log_error "依赖安装失败"
    exit 1
fi

#==================== 创建 nginx 用户 ====================
if id nginx >/dev/null 2>&1; then
    log_warn "用户 nginx 已存在，跳过创建"
else
    log_step "创建 nginx 用户"
    useradd -s /usr/sbin/nologin -M nginx
fi

#==================== 下载并解压源码 ====================
log_step "准备 Nginx 源码包版本 ${NGINX_VERSION}"
if [ -f "${NGINX_TAR}" ]; then
    log_warn "检测到本地源码包 ${NGINX_TAR}，跳过下载"
else
    wget "https://nginx.org/download/${NGINX_TAR}"
    if [ $? -ne 0 ]; then
        log_error "下载 Nginx 源码失败，请检查网络或版本号"
        exit 1
    fi
fi

tar -xzf "${NGINX_TAR}" -C /opt/
if [ $? -ne 0 ]; then
    log_error "解压 Nginx 源码失败"
    exit 1
fi

#==================== 编译安装 ====================
cd "${NGINX_SRC_DIR}" || { log_error "源码目录不存在：${NGINX_SRC_DIR}"; exit 1; }
log_step "开始编译安装 Nginx 到 ${NGINX_PREFIX}"
./configure \
    --prefix=${NGINX_PREFIX} \
    --user=nginx \
    --group=nginx \
    --sbin-path=${NGINX_PREFIX}/nginx \
    --conf-path=${NGINX_PREFIX}/conf/nginx.conf \
    --error-log-path=/var/log/nginx/nginx.log \
    --http-log-path=/var/log/nginx/access.log \
    --modules-path=${NGINX_PREFIX}/modules \
    --with-select_module \
    --with-poll_module \
    --with-threads \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_realip_module \
    --with-http_image_filter_module \
    --with-http_sub_module \
    --with-http_flv_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_stub_status_module \
    --with-stream

if [ $? -ne 0 ]; then
    log_error "configure 失败，请检查依赖是否齐全"
    exit 1
fi

make && make install
if [ $? -ne 0 ]; then
    log_error "编译或安装失败"
    exit 1
fi

#==================== 环境变量 ====================
log_step "配置环境变量到 /etc/profile"
if ! grep -q "NGINX_HOME=${NGINX_PREFIX}" /etc/profile; then
cat >>/etc/profile <<EOF
# nginx
export NGINX_HOME=${NGINX_PREFIX}
export PATH=\$PATH:\$NGINX_HOME
EOF
fi
source /etc/profile

#==================== 启动并验证 ====================
log_step "启动 Nginx 服务"
nginx
if [ $? -eq 0 ]; then
    log_info "Nginx 启动成功"
    log_info "版本：$( ${NGINX_PREFIX}/nginx -v 2>&1 )"
    log_info "访问测试：http://<你的服务器IP>"
    log_info "Nginx 已启动，进程列表："
    ps -ef |grep nginx
else
    log_error "Nginx 启动失败，请查看日志 /var/log/nginx/nginx.log"
    exit 1
fi

