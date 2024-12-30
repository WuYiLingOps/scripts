#!/bin/bash
# author YiLing Wu (hj)
# date 2024-12-23 15:21
# description: 传参以配置文件启动flume
flume-ng agent -n $1 -c $FLUME_HOME/conf -f $2 -Dflume.root.logger=INFO,console
