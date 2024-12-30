#!/bin/bash

# author YiLing Wu (hj)
# date 2023-12-23 15:21
# description: ubuntu环境下简易二进制安装docker

# 生产环境采用二进制部署
# 确保环境没有安装docker


# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
  echo "请以 root 或 sudo 权限运行此脚本。"
  exit 1
fi

# 安装包放在gitee仓库, Docker 安装
tar_update_install(){
if [ -f "./docker-20.10.18.tgz" ]; then
  tar -xf docker-20.10.18.tgz
  sudo cp docker/* /usr/bin
else
  sudo apt-get install git -y >/dev/null
  git clone https://gitee.com/master_hj/docker-binary-deployment.git
  tar -xf ./docker-binary-deployment/docker-20.10.18.tgz
  sudo cp docker/* /usr/bin
fi
if [ $? -eq 0 ]; then
  rm -rf ./docker
fi
}

# 添加至systemctl进行管理
docker_system(){
sudo cat >/etc/systemd/system/docker.service<<EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/bin/dockerd
ExecReload=/bin/kill -s HUP \$MAINPID
LimitNOFILE=infinity
LimitNPROC=infinity
TimeoutStartSec=0
Delegate=yes
KillMode=process
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s

[Install]
WantedBy=multi-user.target
EOF
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
}

# 配置镜像加速
aliyun_speed_up(){
sudo mkdir -p /etc/docker
sudo cat >/etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["https://r1238ywt.mirror.aliyuncs.com"]
}
EOF
# 启动服务
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable docker
sudo systemctl restart networking
docker info | grep aliyuncs.com >/dev/null
if [ $? -eq 0 ]; then
  echo -e "\033[32m>>docker配置完成 \033[0m"
fi
}

main(){
tar_update_install
docker_system
aliyun_speed_up
}

# 调用
main