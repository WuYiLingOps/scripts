#!/bin/bash
# author YiLing Wu (hj)
# date 2023-12-23 15:21
# description: centos环境yum源配置(清华园已放弃)

yum_local() {
#挂载镜像,配置本地仓库
mount /dev/sr0 /mnt
mkdir /etc/yum.repos.d/bak
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak
touch /etc/yum.repos.d/local.repo
cat << EOF > /etc/yum.repos.d/local.repo
[local]
name=local
baseurl=file:///mnt
enable=1
gpgcheck=0
gpgkey=file:///mnt/RPM-GPG-KEY-CentOS-7
EOF

fstab=`cat /etc/fstab | grep "/dev/cdrom /mnt iso9660 defaults" | wc -l`
if [ $fstab -eq 0 ];then
cat << EOF >> /etc/fstab 
/dev/cdrom /mnt iso9660 defaults        0 0
EOF
fi
}

#检查防火墙
firewalld_status=`systemctl status firewalld | grep "running" | wc -l`
if [ $firewalld_status -eq 1 ]; then
   systemctl stop firewalld
   systemctl disable firewalld >/dev/null 2>&1
   echo -e '\033[32mfirewalld is stop \033[0m'
else
    echo -e '\033[32mfirewalld is stop \033[0m'
fi

#检查selinux
selinux_status=`awk 'BEGIN{FS="="}NR=="7"{print $2}' /etc/selinux/config`
if [[ $selinux_status == "enforcing" ]]; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
	echo -e '\033[32mselinux is stop \033[0m'
else
	echo -e '\033[32mselinux is stop \033[0m'
fi

#开始配置yum源
cat <<EOF
*****************************     
**    1.配置阿里源     
**    2.配置清华源    
**    3.仅配置本地源
*****************************
EOF
read -p "Input a choose:" OP
case $OP in
1|"配置阿里源")
cat <<EOF
********************************
**    开始配置阿里源     **
********************************
EOF
#函数调用
yum_local
#添加网络仓库，额外源
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo >/dev/null 2>&1
curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo >/dev/null 2>&1

yum clean all
yum repolist | grep repolist

cat <<EOF
********************************
**    阿里源配置完成     **
********************************
EOF
#刷新
bash
   ;;
2|"配置清华源")
cat <<EOF
********************************
**    开始配置清华源      **
********************************
EOF
#函数调用
yum_local
#恢复,配置清华源
mv /etc/yum.repos.d/bak/* /etc/yum.repos.d/ && rm -rf /etc/yum.repos.d/bak

#修改本地源为清华源
sed -e 's|^mirrorlist=|#mirrorlist=|g' \
         -e 's|^#baseurl=http://mirror.centos.org/centos|baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos|g' \
         -i.bak \
         /etc/yum.repos.d/CentOS-*.repo
#额外源
curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo >/dev/null 2>&1

yum clean all
yum repolist | grep repolist

cat <<EOF
********************************
**    清华源配置完成     **
********************************
EOF
bash
   ;;
3|"配置本地源")
cat <<EOF
********************************
**    开始配置本地源     **
********************************
EOF
#挂载镜像,配置本地仓库
#调用函数
yum_local
yum repolist | grep repolist
cat <<EOF
********************************
**    本地源配置完成     **
********************************
EOF
#刷新
bash
   ;;
   *)
echo error
esac
