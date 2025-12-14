#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2024-12-23
#FileName:         create_bigdatamaster_and_bigdataSlave.bash
#URL:              http://huangjingblog.cn:510/
#Description:      根据创建的基础镜像创建容器
#Copyright (C):    2024 All rights reserved
#********************************************************************
#
# Usage: bash create_bigdatamaster_and_bigdataSlave.bash [bigdata1|master|bigdata2|slave1|bigdata3|slave2]

# Docker镜像地址
images="bigdatamaster:guet"
imagesSlave="bigdataslave:guet"

# 网络名称
network_name="bigdata"
# 子网
subnet="192.168.1.0/24"

# 检查并创建网络
if ! sudo docker network ls | grep -q $network_name; then
    sudo docker network create --subnet=$subnet $network_name
fi

# 容器创建函数
create_container() {
    name=$1
    hostname=$2
    ip=$3
    image=$4
    ports=("${!5}")

    port_args=""
    for port in "${ports[@]}"; do
        port_args="$port_args -p $port"
    done

    sudo docker run -d --privileged --name $name --hostname $hostname --network $network_name --ip $ip \
        $port_args \
        -v /sys/fs/cgroup:/sys/fs/cgroup \
        $image /bin/bash
}

# 根据传参创建相应容器
# 3306:3306 mysql 未映射
case "$1" in
    "bigdata1"|"master")
        ports=(16010:16010 3306:3306 2181:2181 6379:6379 8031:8031 8032:8032 8033:8033 8080:8080 8081:8081
               8020:8020 8088:8088 8123:8123 9000:9000 9083:9083 9092:9092 9866:9866 9870:9870 10000:10000
               1022:22 60010:60010 12321:12321 4040:4040 12345:12345)
        create_container "$1" "$1" "192.168.1.10" "$images" ports[@]
        ;;
    "bigdata2"|"slave1")
        ports=(1023:22)
        create_container "$1" "$1" "192.168.1.11" "$imagesSlave" ports[@]
        ;;
    "bigdata3"|"slave2")
        ports=(1024:22)
        create_container "$1" "$1" "192.168.1.12" "$imagesSlave" ports[@]
        ;;
    *)
        echo "请注意传参参数信息！！"
        ;;
esac
