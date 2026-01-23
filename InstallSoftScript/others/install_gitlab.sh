#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2026-01-23
#FileName:         install_gitlab.sh
#URL:              https://script.huangjingblog.cn
#Description:      自动化安装GitLab（适配CentOS/Rocky/Ubuntu）
#Copyright (C):    2026 All rights reserved
#********************************************************************

# 说明:安装GitLab 服务器内存建议至少4G,root密码至少8位
# 当前URL是针对ubuntu22.04安装gitlab，如果需要安装别的版本请改成正确的url指向（jammy）
GITLAB_VERSION="17.3.1"
GITLAB_URL="https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/ubuntu/pool/jammy/main/g/gitlab-ce/gitlab-ce_${GITLAB_VERSION}-ce.0_amd64.deb"
# GITLAB_URL="https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/ubuntu/pool/jammy/main/g/gitlab-ce/gitlab-ce_15.10.0-ce.0_amd64.deb" # 2026.1.3 当前清华源已经没有gitlab-ce_15之前的版本
# GITLAB_URL="https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/ubuntu/pool/jammy/main/g/gitlab-ce/gitlab-ce_17.3.1-ce.0_amd64.deb"
# GITLAB_URL="https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/yum/el8/gitlab-ce-14.1.5-ce.0.el8.x86_64.rpm" # 2026.1.3 # 当前清华源已经没有el8
# GITLAB_URL="https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/yum/el7/gitlab-ce-14.1.5-ce.0.el7.x86_64.rpm"

# 配置信息
GITLAB_ROOT_PASSWORD="huang@123456"  # 新版密码必须符合复杂性要求且至少8位
SMTP_PASSWORD="xxxxxxxxxxxxxx"
SMTP_USER="2794998160@qq.com"  # SMTP邮箱账号
SMTP_DOMAIN="qq.com"  # SMTP域名
GITLAB_EMAIL="2794998160@qq.com"  # GitLab发件邮箱
HOST="gitlab.huang.org"
# HOST=`hostname -I|awk '{print $1}'`

# 加载系统版本信息（区分CentOS/Rocky/Ubuntu）
. /etc/os-release

# 定义颜色输出变量
GREEN="echo -e \E[32;1m"
END="\E[0m"

# 定义自定义安装路径和相关配置
DOWNLOAD_DIR="/opt/software"
GITLAB_PACKAGE=$(basename $GITLAB_URL)
PACKAGE_PATH="$DOWNLOAD_DIR/$GITLAB_PACKAGE"

# 定义颜色输出函数（用于操作结果提示）
color () {
    RES_COL=60
    MOVE_TO_COL="echo -en \033[${RES_COL}G"
    SETCOLOR_SUCCESS="echo -en \033[1;32m"
    SETCOLOR_FAILURE="echo -en \033[1;31m"
    SETCOLOR_WARNING="echo -en \033[1;33m"
    SETCOLOR_NORMAL="echo -en \E[0m"
    echo -n "$1" && $MOVE_TO_COL
    echo -n "["
    if [ $2 = "success" -o $2 = "0" ] ;then
        ${SETCOLOR_SUCCESS}
        echo -n $" OK "    
    elif [ $2 = "failure" -o $2 = "1" ] ;then
        ${SETCOLOR_FAILURE}
        echo -n $"FAILED"
    else
        ${SETCOLOR_WARNING}
        echo -n $"WARNING"
    fi
    ${SETCOLOR_NORMAL}
    echo -n "]"
    echo
}

# 检查并创建下载目录
prepare_directory() {
    if [ ! -d "$DOWNLOAD_DIR" ]; then
        mkdir -p "$DOWNLOAD_DIR"
        if [ $? -eq 0 ]; then
            color "创建下载目录成功!" 0
        else
            color "创建下载目录失败!" 1
            exit
        fi
    else
        color "下载目录已存在，跳过创建!" 0
    fi
}

# 下载GitLab安装包
download_gitlab() {
    # 检查安装包是否已存在
    if [ -f "$PACKAGE_PATH" ]; then
        color "安装包 $GITLAB_PACKAGE 已存在，跳过下载!" 0
    else
        color "开始下载GitLab安装包..." 0
        wget -P "$DOWNLOAD_DIR" "$GITLAB_URL" || { color "下载失败!" 1 ;exit ; }
        if [ $? -eq 0 ]; then
            color "下载GitLab安装包成功!" 0
        else
            color "下载GitLab安装包失败!" 1
            exit
        fi
    fi
}

# 安装GitLab
install_gitlab() {
    color "开始安装GitLab..." 0
    
    if [ $ID = "centos" -o $ID = "rocky" ]; then
        yum -y install "$PACKAGE_PATH"
    else
        dpkg -i "$PACKAGE_PATH"
    fi
    
    if [ $? -eq 0 ]; then
        color "安装GitLab完成!" 0
    else
        color "安装GitLab失败!" 1
        exit
    fi
}

# 配置GitLab
config_gitlab() {
    color "配置GitLab..." 0
    
    # 备份原配置文件
    cp /etc/gitlab/gitlab.rb /etc/gitlab/gitlab.rb.bak
    
    # 修改外部URL
    sed -i "/^external_url.*/c external_url 'http://$HOST'" /etc/gitlab/gitlab.rb
    
    # 添加SMTP和初始密码配置
    cat >> /etc/gitlab/gitlab.rb << EOF
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.qq.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "$SMTP_USER"
gitlab_rails['smtp_password'] = "$SMTP_PASSWORD"
gitlab_rails['smtp_domain'] = "$SMTP_DOMAIN"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = false
gitlab_rails['smtp_tls'] = true
gitlab_rails['gitlab_email_from'] = "$GITLAB_EMAIL"
gitlab_rails['initial_root_password'] = "$GITLAB_ROOT_PASSWORD"

# 禁用Prometheus相关组件
prometheus['enable'] = false
prometheus['monitor_kubernetes'] = false
alertmanager['enable'] = false
node_exporter['enable'] = false
redis_exporter['enable'] = false
postgres_exporter['enable'] = false
gitlab_exporter['enable'] = false
prometheus_monitoring['enable'] = false
EOF
    
    color "重新配置GitLab..." 0
    gitlab-ctl reconfigure
    
    if [ $? -eq 0 ]; then
        color "GitLab重新配置成功!" 0
    else
        color "GitLab重新配置失败!" 1
        exit
    fi
}

# 验证GitLab状态
verify_gitlab() {
    color "验证GitLab状态..." 0
    
    # 等待服务启动
    MAX_WAIT=180
    WAIT_COUNT=0
    
    while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
        gitlab-ctl status | grep -q "run"
        if [ $? -eq 0 ]; then
            break
        fi
        sleep 10
        WAIT_COUNT=$((WAIT_COUNT + 10))
        color "等待GitLab服务启动... ($WAIT_COUNT/$MAX_WAIT秒)" 0
    done
    
    # 检查服务状态
    gitlab-ctl status
    if [ $? -eq 0 ]; then
        echo
        color "GitLab安装完成!" 0
        echo "-------------------------------------------------------------------"
        echo -e "访问链接: \c"
        ${GREEN}"http://$HOST/"${END}
        echo "-------------------------------------------------------------------"
        echo -e "默认账号: root"
        echo -e "默认密码: \c"
        ${GREEN}$GITLAB_ROOT_PASSWORD${END}
        echo "-------------------------------------------------------------------"
    else
        color "GitLab启动失败!" 1
        exit
    fi
}

# 清理临时文件
cleanup() {
    color "清理临时文件..." 0
    rm -f "$PACKAGE_PATH"
    if [ $? -eq 0 ]; then
        color "清理临时文件成功!" 0
    else
        color "清理临时文件失败!" 1
    fi
}

# 执行安装流程
prepare_directory
download_gitlab
install_gitlab
config_gitlab
verify_gitlab
cleanup

echo
echo "-------------------------------------------------------------------"
echo "GitLab安装信息:"
echo "安装版本: $GITLAB_VERSION"
echo "访问地址: http://$HOST/"
echo "默认账号: root"
echo "默认密码: $GITLAB_ROOT_PASSWORD"
echo "-------------------------------------------------------------------"
echo "注意事项:"
echo "1. GitLab服务启动可能需要几分钟时间，请耐心等待"
echo "2. 首次登录后请立即修改默认密码以确保安全"
echo "3. 如需修改GitLab配置，请编辑 /etc/gitlab/gitlab.rb"
echo "4. 修改配置后需执行: gitlab-ctl reconfigure"
echo "-------------------------------------------------------------------"
color "GitLab自动化安装脚本执行完成!" 0