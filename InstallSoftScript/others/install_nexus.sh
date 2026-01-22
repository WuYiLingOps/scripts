#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2026-01-22
#FileName:         install_nexus.sh
#URL:              https://script.huangjingblog.cn
#Description:      自动化安装Nexus（适配CentOS/Rocky/Ubuntu）
#Copyright (C):    2026 All rights reserved
#********************************************************************

# 定义Nexus安装包下载地址
NEXUS_URL="https://download.sonatype.com/nexus/3/nexus-3.88.0-08-linux-x86_64.tar.gz"

# 定义安装目录
INSTALL_DIR="/usr/local/nexus"

# 定义颜色输出变量
GREEN="echo -e \E[32;1m"
END="\E[0m"

# 获取本机第一个IP地址（用于拼接访问链接）
HOST=`hostname -I|awk '{print $1}'`

# 加载系统版本信息（区分CentOS/Rocky/Ubuntu）
. /etc/os-release

# 定义自定义安装路径和相关配置
DOWNLOAD_DIR="/tmp"
NEXUS_PACKAGE=$(basename $NEXUS_URL)
PACKAGE_PATH="$DOWNLOAD_DIR/$NEXUS_PACKAGE"
NEXUS_VERSION="3.88.0-08"
NEXUS_HOME="$INSTALL_DIR/nexus-$NEXUS_VERSION"
SYSTEMD_SERVICE="/lib/systemd/system/nexus.service"

# 定义颜色输出函数（用于操作结果提示）
color () {
    RES_COL=60
    MOVE_TO_COL="echo -en \\033[${RES_COL}G"
    SETCOLOR_SUCCESS="echo -en \\033[1;32m"
    SETCOLOR_FAILURE="echo -en \\033[1;31m"
    SETCOLOR_WARNING="echo -en \\033[1;33m"
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

# 检查并创建安装目录
prepare_directory() {
    if [ ! -d "$INSTALL_DIR" ]; then
        mkdir -p "$INSTALL_DIR"
        if [ $? -eq 0 ]; then
            color "创建安装目录成功!" 0
        else
            color "创建安装目录失败!" 1
            exit
        fi
    else
        color "安装目录已存在，跳过创建!" 0
    fi
}

# 下载Nexus安装包
download_nexus() {
    # 检查安装包是否已存在
    if [ -f "$PACKAGE_PATH" ]; then
        color "安装包 $NEXUS_PACKAGE 已存在，跳过下载!" 0
    else
        color "开始下载Nexus安装包..." 0
        wget -P "$DOWNLOAD_DIR" "$NEXUS_URL" || { color "下载失败!" 1 ;exit ; }
        if [ $? -eq 0 ]; then
            color "下载Nexus安装包成功!" 0
        else
            color "下载Nexus安装包失败!" 1
            exit
        fi
    fi
}

# 解压安装包
install_nexus() {
    color "开始解压Nexus安装包..." 0
    tar -zxf "$PACKAGE_PATH" -C "$INSTALL_DIR" || { color "解压失败!" 1 ;exit ; }
    if [ $? -eq 0 ]; then
        color "解压Nexus安装包成功!" 0
    else
        color "解压Nexus安装包失败!" 1
        exit
    fi
}

# 添加环境变量
add_environment() {
    color "添加Nexus环境变量..." 0
    if grep -q "NEXUS_HOME" /etc/profile; then
        color "环境变量已存在，跳过添加!" 0
    else
        cat >> /etc/profile << EOF

# NEXUS_HOME
export NEXUS_HOME=$NEXUS_HOME
export PATH=\$PATH:\$NEXUS_HOME/bin
EOF
        if [ $? -eq 0 ]; then
            color "添加环境变量成功!" 0
            # 立即加载环境变量
            source /etc/profile
        else
            color "添加环境变量失败!" 1
            exit
        fi
    fi
}

# 配置JDK路径
configure_jdk() {
    color "配置JDK路径..." 0
    JDK_PATH="$NEXUS_HOME/jdk/temurin_21.0.9_10_linux_x86_64/jdk-21.0.9+10"
    cat > "$NEXUS_HOME/bin/nexus.rc" << EOF
INSTALL4J_JAVA_HOME_OVERRIDE="$JDK_PATH"
EOF
    if [ $? -eq 0 ]; then
        color "配置JDK路径成功!" 0
    else
        color "配置JDK路径失败!" 1
        exit
    fi
}

# 创建nexus用户并授权
create_nexus_user() {
    color "创建nexus用户..." 0
    if id -u nexus > /dev/null 2>&1; then
        color "nexus用户已存在，跳过创建!" 0
    else
        useradd -m nexus
        if [ $? -eq 0 ]; then
            color "创建nexus用户成功!" 0
        else
            color "创建nexus用户失败!" 1
            exit
        fi
    fi
    
    color "授权nexus用户..." 0
    chown -R nexus:nexus "$INSTALL_DIR"
    if [ $? -eq 0 ]; then
        color "授权nexus用户成功!" 0
    else
        color "授权nexus用户失败!" 1
        exit
    fi
}

# 创建systemd服务
create_systemd_service() {
    color "创建systemd服务..." 0
    cat > "$SYSTEMD_SERVICE" << EOF
[Unit]
Description=nexus service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
User=nexus
Group=nexus
ExecStart=$NEXUS_HOME/bin/nexus start
ExecStop=$NEXUS_HOME/bin/nexus stop
Restart=on-failure
TimeoutStopSec=120

[Install]
WantedBy=multi-user.target
EOF
    if [ $? -eq 0 ]; then
        color "创建systemd服务成功!" 0
        # 重新加载systemd配置
        systemctl daemon-reload
        color "重新加载systemd配置成功!" 0
    else
        color "创建systemd服务失败!" 1
        exit
    fi
}

# 启动服务并设置开机自启
start_nexus() {
    color "设置Nexus开机自启..." 0
    systemctl enable nexus
    if [ $? -eq 0 ]; then
        color "设置开机自启成功!" 0
    else
        color "设置开机自启失败!" 1
        exit
    fi
    
    color "启动Nexus服务..." 0
    systemctl start nexus
    if [ $? -eq 0 ]; then
        color "启动Nexus服务成功!" 0
    else
        color "启动Nexus服务失败!" 1
        exit
    fi
}

# 验证Nexus启动状态
verify_nexus() {
    color "验证Nexus启动状态..." 0
    
    # 等待服务启动并检查状态
    MAX_WAIT=120
    WAIT_COUNT=0
    
    while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
        systemctl is-active nexus
        if [ $? -eq 0 ]; then
            break
        fi
        sleep 5
        WAIT_COUNT=$((WAIT_COUNT + 5))
        color "等待Nexus服务启动... ($WAIT_COUNT/$MAX_WAIT秒)" 0
    done
    
    # 检查服务状态
    systemctl is-active nexus
    if [ $? -eq 0 ]; then
        echo
        color "Nexus安装完成!" 0
        
        # 读取实际使用的端口
        PROPERTIES_FILE="$NEXUS_HOME/etc/nexus-default.properties"
        if [ -f "$PROPERTIES_FILE" ]; then
            ACTUAL_PORT=$(grep "application-port=" "$PROPERTIES_FILE" | cut -d= -f2)
        else
            ACTUAL_PORT="8081"
        fi
        
        echo "-------------------------------------------------------------------"
        echo -e "访问链接: \c"
        ${GREEN}"http://$HOST:$ACTUAL_PORT/"${END}
        echo "-------------------------------------------------------------------"
        echo -e "默认账号: admin"
        echo -e "默认密码: 请查看密码文件"
        echo -e "密码文件: $INSTALL_DIR/sonatype-work/nexus3/admin.password"
        echo "-------------------------------------------------------------------"
    else
        color "Nexus启动失败!" 1
        exit
    fi
}

# 执行安装流程
prepare_directory
download_nexus
install_nexus
add_environment
configure_jdk
create_nexus_user
create_systemd_service
start_nexus
verify_nexus

# 清理临时文件
color "清理临时文件..." 0
rm -f "$PACKAGE_PATH"
if [ $? -eq 0 ]; then
    color "清理临时文件成功!" 0
else
    color "清理临时文件失败!" 1
fi

echo
color "Nexus自动化安装脚本执行完成!" 0
# 读取实际使用的端口
PROPERTIES_FILE="$NEXUS_HOME/etc/nexus-default.properties"
if [ -f "$PROPERTIES_FILE" ]; then
    ACTUAL_PORT=$(grep "application-port=" "$PROPERTIES_FILE" | cut -d= -f2)
else
    ACTUAL_PORT="8081"
fi

echo "-------------------------------------------------------------------"
echo "安装目录: $INSTALL_DIR"
echo "应用目录: $NEXUS_HOME"
echo "工作目录: $INSTALL_DIR/sonatype-work"
echo "访问地址: http://$HOST:$ACTUAL_PORT/"
echo "-------------------------------------------------------------------"
echo "注意事项:"
echo "1. Nexus服务启动可能需要几分钟时间，请耐心等待"
echo "2. 首次登录需使用admin账号和初始密码文件中的密码"
echo "3. 登录后请立即修改默认密码以确保安全"
echo "4. 如需修改Nexus配置，请编辑 $NEXUS_HOME/etc/nexus-default.properties"
echo "-------------------------------------------------------------------"