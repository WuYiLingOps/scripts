#!/bin/bash
# ser: huangjing 2023.11.08-18.16
# author YiLing Wu (hj)
# date 2023-12-23 15:21
# description: docker镜像清理工具

#用于快捷删除docker镜像/容器脚本
tool(){
cat <<EOF
###########################
###1.查看现有docker镜像  ##
###2.删除指定docker镜像  ##
###3.删除无用docker镜像	 ##
###4.查看所有docker容器  ##
###5.删除指定docker容器  ##
###6.退出操作		 ##
###########################
EOF
read -p "请选择你的操作:" choose
case $choose in
1)
#docker images 
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}"
  ;;
2)
read -p "请输入要删除的镜像id:" imagesid
docker rmi -f $imagesid
  ;;
3)
docker image prune <<EOF
y
EOF
  ;;
4)
docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Names}}"
  ;;
5)
read -p "请输入要删除的容器id:" containerid
docker rm -f $containerid
  ;;
6|q)
break
  ;;
  *)
echo error
esac
}

#调用
while true
do
  tool
done
