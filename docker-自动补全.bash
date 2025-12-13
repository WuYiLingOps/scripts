#!/bin/bash
#
#********************************************************************
#Author:           YiLing Wu (hj)
#email:            huangjing510@126.com
#Date:             2023-12-23
#FileName:         docker-自动补全.bash
#URL:              http://42.194.242.109:510/
#Description:      配置Docker自动补全
#Copyright (C):    2024 All rights reserved
#********************************************************************
#

yum install -y bash-completion
source /usr/share/bash-completion/bash_completion
source /usr/share/bash-completion/completions/docker
