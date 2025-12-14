#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2023-12-23
#FileName:         install_jdk_bin.bash
#URL:              http://huangjingblog.cn:510/
#Description:      CentOS下安装JDK脚本
#Copyright (C):    2024 All rights reserved
#********************************************************************
#

#上传jdk到脚本存放目录,再进行操作
#因为涉及到环境变量,建议source运行脚本同时刷新环境变量
java_install() {
jdk_pack=`find ./ -name 'jdk*gz'`
if [ $? -eq 0 ];then
  tar -zxf $jdk_pack -C /usr/local/
else
 echo -e "\033[31m>>请上传相关tag.gz包至脚本同目录！！ \033[0m" 
fi
}

java_profile() {
if [ -d "/usr/local/$java_home" ];then
  grep 'JAVA_HOME' /etc/profile >/dev/null
  if [ $? -ne 0 ];then
  java_home=`ls /usr/local | grep "jdk"`
  cat >>/etc/profile<<EOF
#JAVA_HOME
export JAVA_HOME=/usr/local/$java_home
export PATH=\$PATH:\$JAVA_HOME/bin
EOF
  source /etc/profile
fi
if [ $? -eq 0 ];then
  echo -e "\033[32m>>部署完成: \033[0m"
fi
else
  echo -e "\033[31m>>部署失败,请检查配置和脚本！！ \033[0m" 
fi
}

main() {
#安装
java_install
#环境变量
java_profile
}
#调用
main
