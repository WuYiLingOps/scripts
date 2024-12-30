#!/bin/bash
# author YiLing Wu (hj)
# date 2023-12-23 15:21
# description: nginx自签证书(仅限于测试环境)

#自签证书
openssl genrsa -out server.key 1024
openssl req -new -out server.csr -key server.key
openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
#openssl pkcs12 -export -clcerts -in server.crt -inkey server.key -out server.p12
