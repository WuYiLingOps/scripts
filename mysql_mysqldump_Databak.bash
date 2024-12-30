#!/bin/bash
# author YiLing Wu (hj)
# date 2023-12-23 15:21
# description: mysql 数据备份

#分库备分是为了解决上面多库备份在同一个备份文件造成的问题, 一般做法是使用脚本，然后将脚本加入定时任务定期执行
MYSQL_CMD="/usr/local/mysql/bin/mysqldump"
MYSQL_USER="root"
MYSQL_PWD="123456"
MYSQL_SOCK="/data/mysql/mysql.sock"
DATA=`date +%F`
MYSQLDUMP_DIR="/data/mysqlbackup/"
DBname=`mysql -u$MYSQL_USER -p$MYSQL_PWD -S$MYSQL_SOCK -e "show databases;" |egrep -v  'Database|schema$|sys|mysql'`
if [ ! -d "$MYSQLDUMP_DIR" ];then
  echo "Directory does not exist. Creating..."
  mkdir -p $MYSQLDUMP_DIR
  echo "Directory: $MYSQLDUMP_DIR  created."
fi
for i in $DBname
do
  $MYSQL_CMD -u$MYSQL_USER -p$MYSQL_PWD -S$MYSQL_SOCK -B $i >$MYSQLDUMP_DIR$DBname\_$DATA.Sql
done
