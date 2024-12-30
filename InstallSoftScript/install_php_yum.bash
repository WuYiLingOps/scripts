#!/bin/bash
# author YiLing Wu (hj)
# date 2023-12-23 15:21
# description: centos下yum安装php.8.2版本

yum install epel-release -y
yum -y install https://mirrors.aliyun.com/remi/enterprise/remi-release-7.rpm
yum -y install yum-utils

yum-config-manager --enable remi-php82

#依赖,安装php
yum install -y php-cli php-fpm php-mysqlnd php-zip php-devel php-gd php-mbstring php-curl php-xml php-pear php-bcmath php-json php-redis  --skip-broken


systemctl start php-fpm
systemctl enable php-fpm

php -v