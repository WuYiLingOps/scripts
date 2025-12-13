#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2023-12-23
#FileName:         docker-push-aliyun.bash
#URL:              http://42.194.242.109:510/
#Description:      将本地Docker镜像上传至阿里云镜像仓库
#Copyright (C):    2024 All rights reserved
#********************************************************************
#
# 登录: docker login --username=2794998160@qq.com registry.cn-hangzhou.aliyuncs.com

aliyun() {
Registry="registry.cn-hangzhou.aliyuncs.com/$Registry_id/"
read -p "输入要上传的镜像id:" image_id
read -p "上传后的名字:" image_name
read -p "设置标签:" image_tag
aliyun_image="$Registry$image_name:$image_tag"
docker tag $image_id $aliyun_image
docker push $aliyun_image
}

cat <<EOF
######现有仓库########
# 1.	k8s-hj       #
# 2.	shangguan-hj #
# 3.	510_repo     #
######################
EOF
read -p "请输入仓库id:" Registry_choose
if [[ $Registry_choose == "1" ]];then
  Registry_id="k8s-hj"
  aliyun
elif [[ $Registry_choose == "2" ]];then 
  Registry_id="shangguan-hj"
  aliyun
elif [[ $Registry_choose == "3" ]];then 
  Registry_id="510_repo"
  aliyun
else
 echo -e "\033[31m>>请重新选择现有的仓库！！： \033[0m" 
fi
