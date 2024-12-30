#!/bin/bash
# author YiLing Wu (hj)
# date 2023-12-23 15:21
# description: centos下编译安装nginx

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
--with-stream
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
cat >>/etc/profile<<EOF
#nginx
export NGINX_HOME=/usr/local/nginx
EOF
echo 'export PATH=$PATH:$NGINX_HOME/' >>/etc/profile
source /etc/profile
fi
#安装依赖
yum install -y gcc gcc-c++ automake openssl openssl-devel make pcre-devel gd-devel

#创建用户
id nginx 2>/dev/null
if [ $? -ne 0 ];then
  useradd nginx -s /sbin/nologin
fi

tar=`ls | grep 'nginx-'`
if [ $? -eq 0 ];then
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
  ps -ef |grep nginx
else
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
  ps -ef |grep nginx
fi
