#!/bin/bash
# author YiLing Wu (hj)
# date 2023-12-23 15:21
# description: 同步本地仓库到云端

#huanjging<2794998160@qq.com> git 上传至远程仓库
git_add() {
git add .
read -p "请输入一个标签:" git_tag
git commit -m "$git_tag"
}

git_push(){
echo "=========开始同步本地origin仓库至gitee远程仓库================"
git remote | grep origin > /dev/null
if [ $? -eq 0 ];then
  git push origin master
  if [ $? -ne 0 ];then
    echo -e "\033[31m>>origin同步至gitee失败！！！没有origin这个仓库别名！！\033[0m"
    git_push_gitee_github
  else
    echo -e "\033[32m>>origin仓库同步完成 \033[0m"
  fi
else
  echo -e "\033[31m>>本地没有origin这个仓库\033[0m"
fi
}

main() {
  git_add
  git_push
}

#调用
main
