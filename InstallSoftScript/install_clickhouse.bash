#!/bin/bash
# author YiLing Wu (hj)
# date 2023-12-23 15:21
# description: 安装clickhouse

#脚本放再tgz包目录执行
mkdir /opt/clickhouse
client_tgz=`ls | grep "client"`
commondbg_tgz=`ls | grep 'common' | awk "NR==2{print $1}"`
common_tgz=`ls | grep 'common' | awk "NR==1{print $1}"`
server_tgz=`ls | grep "server"`

cat <<EOF
************************
** 开始安装clickhouse **
************************
EOF
echo ">>开始解压client"
tar -zxf $client_tgz -C /opt/clickhouse
echo ">>开始解压common-dbg"
tar -zxf $commondbg_tgz -C /opt/clickhouse
echo ">>开始解压common"
tar -zxf $common_tgz -C /opt/clickhouse
echo ">>开始解压server"
tar -zxf $server_tgz -C /opt/clickhouse

client=`ls /opt/clickhouse| grep "client"`
commondbg=`ls /opt/clickhouse | grep "common-static-dbg"`
common=`ls /opt/clickhouse | grep "common" | awk "NR==1{print $1}"`
server=`ls /opt/clickhouse | grep "server"`

sh /opt/clickhouse/$common/install/doinst.sh
sh /opt/clickhouse/$commondbg/install/doinst.sh
# 执行 clickhouse-server 会创建一个用户 default 并让你设置密码，直接回车密码设置为空
echo  "=====设置default用户密码(回车设置密码为空)======" 
cat <<EOF
*******************************************
** 设置default用户密码(回车设置密码为空) **
** 是否设置ClickHouse服务器的网络连接权限**
*******************************************
EOF
sh /opt/clickhouse/$server/install/doinst.sh 2>1 /dev/null
sh /opt/clickhouse/$client/install/doinst.sh

read -p "是否修改clickhouse默认端口(y/n):" yn
if [ $yn == 'y' ];then
  read -p "修改的端口为:" port
  sed -i "s/9000/$port/g" /etc/clickhouse-server/config.xml
  if [ $? -eq 0 ];then
   echo ">clickhouse端口已更改成:$port"
  else 
   echo "修改失败！！"
  fi
else
  echo ">clickhouse默认端口为: 9000 "
fi

#启动
echo "=====启动====="
clickhouse start
echo "=====状态====="
clickhouse status

if [ $? -eq 0 ];then
  read -p "是否查看登录帮助(y/n)" help
  if [ $help == 'y' ];then
cat <<EOF
语法：clickhouse-client --host=主机地址 --port 端口 --user=用户 --password=密码 
参数:
	--host：指定要连接的ClickHouse服务器的主机名或IP地址。
	--port：指定要连接的ClickHouse服务器的端口号，默认为9000。
	--user：指定要使用的用户名进行身份验证，默认为"default"。
	--password：指定要使用的密码进行身份验证。
	--database：指定要使用的默认数据库。
	--query：指定要在连接后立即执行的查询。
EOF
fi

cat <<EOF
************************
** clickhouse安装完成 **
************************
EOF
else
cat <<EOF
**************************************
** clickhouse安装失败（请检查配置） **
**************************************
EOF
fi
