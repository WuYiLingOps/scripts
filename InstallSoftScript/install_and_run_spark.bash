#!/bin/bash

# author: YiLing Wu (hj)
# date: 2023-12-23
# description: 自动化安装和配置 Spark，支持添加环境变量、配置 YARN 提交任务等。

# 定义变量
JDK_HOME="/opt/jdk"
SPARK_HOME="/opt/module/spark_on_yarn"
HADOOP_HOME="/opt/hadoop"  # 假设 Hadoop 安装目录为此路径

# 拉取 Spark 安装包
download_spark_package() {
  echo "--------------------------------------------"
  echo "1. 拉取 Spark 安装包"
  echo "--------------------------------------------"
  wget -P /tmp/ http://10.33.210.121/bigdata/spark-3.1.1-bin-hadoop3.2.tgz
  if [ $? -eq 0 ]; then
    echo "Spark 安装包下载成功！"
  else
    echo "Spark 安装包下载失败，请检查 URL 或网络连接。"
    exit 1
  fi
}

# 解压并重命名文件
extract_and_rename() {
  echo "--------------------------------------------"
  echo "2. 解压 Spark 安装包至 /opt/module 并改名为 spark_on_yarn"
  echo "--------------------------------------------"
  sudo mkdir -p /opt/module
  sudo tar -zxvf /tmp/spark-3.1.1-bin-hadoop3.2.tgz -C /opt/module/
  sudo rm -rf /tmp/spark-3.1.1-bin-hadoop3.2.tgz
  sudo mv /opt/module/spark-3.1.1-bin-hadoop3.2 /opt/module/spark_on_yarn
  if [ $? -eq 0 ]; then
    echo "解压并重命名成功！"
  else
    echo "解压或重命名失败，请检查路径或文件。"
    exit 1
  fi
}

# 追加环境变量
add_environment_variables() {
  echo "--------------------------------------------"
  echo "3. 追加环境变量"
  echo "--------------------------------------------"
  # 检查是否已存在 SPARK_HOME
  if ! grep -q "SPARK_HOME" /etc/profile.d/bigdata.sh; then
    echo "export SPARK_HOME=$SPARK_HOME" | sudo tee -a /etc/profile.d/bigdata.sh > /dev/null
    echo "export PATH=\$PATH:\$SPARK_HOME/bin:\$SPARK_HOME/sbin" | sudo tee -a /etc/profile.d/bigdata.sh > /dev/null
    echo "环境变量已追加！"
  else
    echo "环境变量已存在，无需重复添加。"
  fi

  # 使配置生效
  source /etc/profile.d/bigdata.sh
}

# 直接覆盖写入 spark-env.sh 配置
configure_spark_env() {
  echo "--------------------------------------------"
  echo "4. 直接覆盖写入 spark-env.sh 配置"
  echo "--------------------------------------------"
  SPARK_ENV_FILE="$SPARK_HOME/conf/spark-env.sh"

  if [ ! -f "$SPARK_ENV_FILE" ]; then
    sudo cp $SPARK_HOME/conf/spark-env.sh.template $SPARK_ENV_FILE
  fi

  # 直接覆盖写入配置
  echo "export JAVA_HOME=$JDK_HOME" | sudo tee $SPARK_ENV_FILE > /dev/null
  echo "export YARN_CONF_DIR=\$HADOOP_HOME/etc/hadoop" | sudo tee -a $SPARK_ENV_FILE > /dev/null
  
  echo "spark-env.sh 配置已成功覆盖！"
}

# 提交 Spark 任务测试
submit_spark_job() {
  echo "--------------------------------------------"
  echo "5. 提交 Spark 任务进行测试"
  echo "--------------------------------------------"
  spark-submit --class org.apache.spark.examples.SparkPi \
               --master yarn \
               $SPARK_HOME/examples/jars/spark-examples_2.12-3.1.1.jar
  if [ $? -eq 0 ]; then
    echo "Spark 任务提交成功！"
  else
    echo "Spark 任务提交失败，请检查配置和环境。"
    exit 1
  fi
}

# 主函数
main() {
  download_spark_package
  extract_and_rename
  add_environment_variables
  configure_spark_env
  submit_spark_job
}

# 执行主函数
main
