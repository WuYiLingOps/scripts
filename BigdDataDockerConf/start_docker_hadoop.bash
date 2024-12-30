#!/bin/bash
sudo docker run -d --privileged --name bigdata_v1 --hostname bigdata1 -p 9870:9870 -p 8088:8088 -v /sys/fs/cgroup:/sys/fs/cgroup hadoopnoinit:guet
sudo docker run -d --privileged --name bigdata_v2 --hostname bigdata2 -v /sys/fs/cgroup:/sys/fs/cgroup hadoopnoinit:guet
sudo docker run -d --privileged --name bigdata_v3 --hostname bigdata3 -v /sys/fs/cgroup:/sys/fs/cgroup hadoopnoinit:guet
