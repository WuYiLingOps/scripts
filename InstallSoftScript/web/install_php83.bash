#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2023-12-23
#FileName:         install_php83.bash
#URL:              http://huangjingblog.cn:510/
#Description:      安装PHP 8.3版本
#Copyright (C):    2024 All rights reserved
#********************************************************************
#

# 定义颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # 无颜色

# 安装相关依赖
install_dependencies() {
    echo -e "${YELLOW}开始安装相关依赖...${NC}"
    yum -y install cmake gcc g++ ncurses-devel libtirpc-devel rpcgen libxml2-devel sqlite-devel libpng-devel oniguruma-devel libcurl-devel --skip-broken
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}依赖安装成功！${NC}"
    else
        echo -e "${RED}依赖安装失败！${NC}"
        exit 1
    fi
}

# 下载PHP包
download_php_package() {
    echo -e "${YELLOW}检查/opt目录下是否存在php-8.3.0.tar.gz包...${NC}"
    if [ ! -f /opt/php-8.3.0.tar.gz ]; then
        echo -e "${YELLOW}未找到包，开始下载...${NC}"
        cd /opt
        wget https://www.php.net/distributions/php-8.3.0.tar.gz
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}PHP包下载成功！${NC}"
        else
            echo -e "${RED}PHP包下载失败！${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}/opt目录下已存在php-8.3.0.tar.gz包，无需下载。${NC}"
    fi
}

# 解压并编译安装PHP
compile_and_install_php() {
    echo -e "${YELLOW}开始解压并编译安装PHP...${NC}"
    mkdir -p /usr/local/php/etc
    cd /opt
    tar -zxvf php-8.3.0.tar.gz -C /usr/local
    cd /usr/local/php-8.3.0
    ./configure \
    --prefix=/usr/local/php \
    --with-config-file-path=/usr/local/php/etc \
    --enable-fpm \
    --enable-gd \
    --enable-gd-jis-conv \
    --enable-mysqlnd \
    --enable-mbstring \
    --with-openssl \
    --with-curl \
    --with-zlib \
    --with-pdo-mysql \
    --with-fpm-user=nginx \
    --with-fpm-group=nginx \
    --with-mysqli \
    CFLAGS="-fPIE" LDFLAGS="-pie"
    if [ $? -eq 0 ]; then
        make && make install
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}PHP编译安装成功！${NC}"
        else
            echo -e "${RED}PHP编译安装失败！${NC}"
            exit 1
        fi
    else
        echo -e "${RED}PHP配置失败！${NC}"
        exit 1
    fi
}

# 添加环境变量
add_environment_variable() {
    echo -e "${YELLOW}开始添加环境变量...${NC}"
    echo '# php env' >> /etc/profile
    echo 'export PHP_HOME=/usr/local/php' >> /etc/profile
    echo 'export PATH=$PATH:$PHP_HOME/bin:$PHP_HOME/sbin' >> /etc/profile
    source /etc/profile
    php_version=$(php -v | head -n 1)
    echo -e "${GREEN}环境变量添加成功，当前PHP版本为：${php_version}${NC}"
}

# 主函数
main() {
    install_dependencies
    download_php_package
    compile_and_install_php
    add_environment_variable
    echo -e "${GREEN}PHP安装完成！${NC}"
}

# 执行主函数
main
