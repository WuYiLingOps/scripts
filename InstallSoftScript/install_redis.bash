#!/bin/bash
# author YiLing Wu (hj)
# date 2023-12-23 15:21
# description: centos下编译安装redis,并完成基础配置

#354  logfile /xxxx/redis.log #指定日志生成路径和文件名字 （自行修改配置文件）
#504  dir /usr/local/redis/data          #指定应用持久化路径（自行修改配置文件）
#AOF启动 	自行在配置文件中修改
#脚本安装默认安装，所有配置在/usr/local/目录下

redis_home() {
cat >>/etc/profile<<EOF
#redis
export REDIS_HOME=/usr/local/redis
EOF
echo 'export PATH=$PATH:$REDIS_HOME/bin' >>/etc/profile
source /etc/profile
}

update_conf() {
  #开启后台运行模式
  read -p "是否开启后台运行(y/n):" a
   
  if [ $a == "y" ];then
    sed -i "s/daemonize no/daemonize yes/g" $REDIS_HOME/redis.conf
	if [ $? -eq 0 ];then
	  echo ">>后台运行打开成功"
	fi
  fi
  #是否开启密码验证
  read -p "是否开启密码验证(y/n):" b
  
  if [ $b == "y" ];then
    read -p "设置redis密码验证:" redis_password
    sed -i "s/# requirepass foobared/requirepass $redis_password/p" $REDIS_HOME/redis.conf
	if [ $? -eq 0 ];then
	  echo ">>密码验证开启成功"
	fi
  fi
}

#添加至system进行管理
redis_system() {
cat >/usr/lib/systemd/system/redis.service<<EOF
[Unit]
Description=Redis
After=network.target
 
[Service]
Type=forking
ExecStart=/usr/local/redis/bin/redis-server /usr/local/redis/redis.conf
ExecReload=/usr/local/redis/bin/redis-cli -p 6379 CONFIG REWRITE
ExecStop=pkill -9 redis
PrivateTmp=true
 
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
}

#添加依赖
yum install gcc gcc-c++ -y
yum install make -y

tar=`ls | grep 'redis-'`
if [ $? -eq 0 ];then
  tar -zxvf $tar -C /usr/local/
  tar=`ls /usr/local/ | grep 'redis'`
  mv /usr/local/$tar /usr/local/redis
  cd /usr/local/redis
  make && make install PREFIX=/usr/local/redis
  #解决warning问题
  echo "echo 511 >/proc/sys/net/core/somaxconn" >>/etc/rc.d/rc.local
  echo 511 >/proc/sys/net/core/somaxconn
  #添加环境变量
  if [ $? -eq 0 ];then
    grep "redis" /etc/profile
    if [ $? -eq 1 ];then
    #调用函数
	redis_home
	echo ">>版本号："
	redis-server --version
    fi
  fi
  if [ $? -eq 0 ];then
    #函数调用
	redis_system
    update_conf
  fi
else
  wget https://download.redis.io/releases/redis-7.0.12.tar.gz
  tar -zxvf redis-7.0.12.tar.gz -C /usr/local/
  mv /usr/local/redis-7.0.12 /usr/local/redis
  cd /usr/local/redis
  make && make install PREFIX=/usr/local/redis/
  #解决warning问题
  echo "echo 511 >/proc/sys/net/core/somaxconn" >>/etc/rc.d/rc.local
  echo 511 >/proc/sys/net/core/somaxconn
  #添加环境变量
  if [ $? -eq 0 ];then
    grep "redis" /etc/profile
    if [ $? -eq 1 ];then
    #调用函数
    redis_home
	echo ">>版本号："
	redis-server --version
    fi
  fi
  if [ $? -eq 0 ];then
    #函数调用
	redis_system
    update_conf
  fi
fi

#启动服务
#redis-server $REDIS_HOME/redis.conf
if [ $? -eq 0 ];then
  systemctl start redis
  netstat -nlpa | grep redis
  if [ $? -eq 0 ];then
    systemctl status redis
    echo "redis服务启动成功（已加入systemtcl进行管理）！"
  fi
fi

