#!/bin/bash
# author YiLing Wu (hj)
# date 2023-12-23 15:21
# description: 编写集群配置模板

grep "elk" /etc/hosts >/dev/null
if [ $? -eq 1 ];then
#配置hosts文件，将ip和主机名改成自己的（分发公钥部分改成自己的主机名）
cat >>/etc/hosts<<EOF
192.168.88.170  elk1
192.168.88.171  elk2
192.168.88.172  elk3
192.168.88.173  elk4
EOF
fi

#获取主机名(循环条件)
hostname=`awk '!/^#/ && NF==2 {print $2}' /etc/hosts`

#分发免密公钥
if [ -f "/root/.ssh/id_rsa" ];then
  echo -e "\033[32m密钥已存在 \033[0m" 
else
  echo -e "\033[32m>>开始创建密钥 \033[0m" 
  ssh-keygen -t rsa
  echo -e "\033[32m>>开始分发公钥: \033[0m" 
  ssh-copy-id elk1
  ssh-copy-id elk2
  ssh-copy-id elk3
  #ssh-copy-id elk4
  echo -e "\033[32m>>分发完成: \033[0m" 
fi

grep "JAVA_HOME" /etc/profile >/dev/null
if [ $? -eq 1 ];then
cat >>/etc/profile<<EOF
#JAVA_HOME
export JAVA_HOME=/opt/jdk
export PATH=\$PATH:\$JAVA_HOME/bin
export PATH=\$PATH:\$JAVA_HOME/jre/bin
EOF
fi

scp_jdk () {
 tar_jdk=`ls | grep "jdk-8"`
 jdk=`ls /opt/ | grep "jdk1.8"`
 for hostname in $hostname
 do
  if [[ $hostname != `awk '!/^#/ && NF==2 {print $2}' /etc/hosts | awk 'NR==1'` ]];then
    scp /etc/hosts root@$hostname:/etc/hosts
    scp /etc/profile root@$hostname:/etc/profile
    #scp /root/$tar_jdk root@$hostname:/root
    #ssh $hostname "source /etc/profile;
    #tar -zxvf /root/$tar_jdk -C /opt;
    #mv /opt/$jdk /opt/jdk"
   fi
done 
}

scp_jdk 
