#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2023-12-23
#FileName:         nginx_create_local_SSL.bash
#URL:              http://huangjingblog.cn:510/
#Description:      Nginx自签证书生成（仅限于测试环境）
#Copyright (C):    2024 All rights reserved
#********************************************************************
#

#自签证书
openssl genrsa -out server.key 1024
openssl req -new -out server.csr -key server.key
openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
#openssl pkcs12 -export -clcerts -in server.crt -inkey server.key -out server.p12
