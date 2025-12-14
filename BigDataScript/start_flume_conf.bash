#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2024-12-23
#FileName:         start_flume_conf.bash
#URL:              http://huangjingblog.cn:510/
#Description:      传参以配置文件启动flume
#Copyright (C):    2024 All rights reserved
#********************************************************************
#
# Usage: bash start_flume_conf.bash <agent_name> <config_file>
flume-ng agent -n $1 -c $FLUME_HOME/conf -f $2 -Dflume.root.logger=INFO,console
