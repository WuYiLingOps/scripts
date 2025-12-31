#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2023-12-23
#FileName:         install_nginx.bash
#URL:              http://huangjingblog.cn:510/
#Description:      CentOS下编译安装Nginx
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

#使用source运行脚本
#默认安装在/usr/local/nginx

#编译
compile() {
./configure \
--prefix=/usr/local/nginx \
--user=nginx \
--group=nginx \
--sbin-path=/usr/local/nginx/nginx \
--conf-path=/usr/local/nginx/conf/nginx.conf \
--error-log-path=/var/log/nginx/nginx.log \
--http-log-path=/var/log/nginx/access.log \
--modules-path=/usr/local/nginx/modules \
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
--with-stream \
--with-http_addition_module
}

#加入systemd管理
nginx.service() {
cat >/usr/lib/systemd/system/nginx.service<<EOF
[Unit]
Description=nginx
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/nginx/nginx
ExecReload=/usr/local/nginx/nginx -s reload
ExecStop=/usr/local/nginx/nginx -s reload
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
}

#环境变量
grep "nginx" /etc/profile >/dev/null
if [ $? -ne 0 ];then
log_step "配置环境变量"
cat >>/etc/profile<<EOF
#nginx
export NGINX_HOME=/usr/local/nginx
EOF
echo 'export PATH=$PATH:$NGINX_HOME/' >>/etc/profile
source /etc/profile
fi
#安装依赖
log_step "安装依赖包"
yum install -y gcc gcc-c++ automake openssl openssl-devel make pcre-devel gd-devel

#创建用户
id nginx 2>/dev/null
if [ $? -ne 0 ];then
  log_step "创建 nginx 用户"
  useradd nginx -s /sbin/nologin
fi

tar=`ls | grep 'nginx-'`
if [ $? -eq 0 ];then
  log_step "检测到本地 nginx 源码包，开始编译安装"
  tar -xvf $tar -C /opt/
  tar=`ls /opt/ | grep 'nginx'`
  cd /opt/$tar
  #调用方法
  nginx.service
  compile
  #编译
  make && make install
  #启动
  nginx
  #查看是否启动成功
  log_info "Nginx 已启动，进程列表："
  ps -ef |grep nginx
else
  log_step "未检测到本地源码包，下载官方源码后编译安装"
  wget http://nginx.org/download/nginx-1.24.0.tar.gz
  tar -xvf nginx-1.24.0.tar.gz -C /opt/
  cd /opt/nginx-1.24.0/
  #调用方法
  nginx.service
  compile
  #编译
  make && make install
  #启动
  nginx
  #查看是否启动成功
  log_info "Nginx 已启动，进程列表："
  ps -ef |grep nginx
fi
