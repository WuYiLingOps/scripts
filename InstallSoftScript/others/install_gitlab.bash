#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2023-12-23
#FileName:         install_gitlab.bash
#URL:              http://huangjingblog.cn:510/
#Description:      CentOS下安装GitLab脚本
#Copyright (C):    2024 All rights reserved
#********************************************************************
#

#服务检测
detection(){
which git >/dev/null
if [ $? -ne 0 ];then
  yum install git -y
fi
firewalld_status=`systemctl status firewalld | grep "running" | wc -l`
if [ $firewalld_status -eq 1 ]; then
   systemctl stop firewalld
   systemctl disable firewalld >/dev/null 2>&1
   echo -e '\033[32mfirewalld is stop \033[0m'
else
    echo -e '\033[32mfirewalld is stop \033[0m'
fi
selinux_status=`awk 'BEGIN{FS="="}NR=="7"{print $2}' /etc/selinux/config`
if [[ $selinux_status == "enforcing" ]]; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
	echo -e '\033[32mselinux is stop \033[0m'
else
	echo -e '\033[32mselinux is stop \033[0m'
fi
}

#开始安装
install_gitlad(){
read -p "请输入本机ip:" IP
read -p "请输入要设置的域名:" YUMING
yum install -y  curl openssh-server  postfix wget
#下载安装 gitlab-ce-12.0.3 
yum install -y https://mirror.tuna.tsinghua.edu.cn/gitlab-ce/yum/el7/gitlab-ce-12.0.3-ce.0.el7.x86_64.rpm
#已默认配置邮箱,如果有更改请及时调整
cat >/etc/gitlab/gitlab.rb<<EOF
external_url 'http://$YUMING'
gitlab_rails['gitlab_email_enabled'] = true
gitlab_rails['gitlab_email_from'] = 'xxxxxxx@qq.com'
gitlab_rails['gitlab_email_display_name'] = 'shangguan_gitlab_tongzhi'
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.qq.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "xxxxx@qq.com"
gitlab_rails['smtp_password'] = "juifzceweyujdhcc"
gitlab_rails['smtp_domain'] = "qq.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = true
prometheus['enable'] = false
prometheus['monitor_kubernetes'] = false
alertmanager['enable'] = false
node_exporter['enable'] = false
redis_exporter['enable'] = false
postgres_exporter['enable'] = false
gitlab_monitor['enable'] = false
prometheus_monitoring['enable'] = false
grafana['enable'] = false
EOF
cat >>/etc/hosts<<EOF
$IP  $YUMING
EOF
gitlab-ctl reconfigure
}

#汉化
China(){
wget https://gitlab.com/xhang/gitlab/-/archive/12-0-stable-zh/gitlab-12-0-stable-zh.tar.gz
tar -zxf gitlab-12-0-stable-zh.tar.gz
\cp -r gitlab-12-0-stable-zh/* /opt/gitlab/embedded/service/gitlab-rails/
}

start_gitlab(){
gitlab-ctl reconfigure
gitlab-rake db:migrate
gitlab-ctl reconfigure
gitlab-ctl restart
if [ $? -eq 0 ];then
  gitlab-ctl status
fi
}

main(){
detection
install_gitlad
China
start_gitlab
}

main