## 1.git全局配置

>  个人笔记记录

```sh
$ git config --global user.name 'huangjing'

$ git config --global user.email '2794998160@qq.com'

$ git config --global color.ui true

$ git config --global --list
user.name=17758619389
user.email=2794998160@qq.com
color.ui=true
```



## 2.添加仓库



```sh
#gitee
$ git remote add gitee https://gitee.com/master_hj/openstack_-study_-notes.git

#github
git remote add github git@github.com:wuyiling55kai/openstack_-study_-notes.git

#查看仓库情况
$ git remote -v
gitee   https://gitee.com/master_hj/openstack_-study_-notes.git (fetch)
gitee   https://gitee.com/master_hj/openstack_-study_-notes.git (push)
github  git@github.com:wuyiling55kai/openstack_-study_-notes.git (fetch)
github  git@github.com:wuyiling55kai/openstack_-study_-notes.git (push)
```



## 3.生成公钥私钥

```sh
$ ssh-keygen.exe
Generating public/private rsa key pair.
Enter file in which to save the key (/c/Users/hj/.ssh/id_rsa):
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /c/Users/hj/.ssh/id_rsa
Your public key has been saved in /c/Users/hj/.ssh/id_rsa.pub
The key fingerprint is:
SHA256:e1leq19dfTn+CkbSJ0JHcc5P41SahOQGLReXQruMtFk hj@DESKTOP-TP96LAR
The key's randomart image is:
+---[RSA 3072]----+
|          .+*++..|
|          .+=B.o.|
|          ooE.=o.|
|         o X .oo+|
|        S * B o+=|
|         . B +..=|
|        . o + ..o|
|         . . o ..|
|            ..o..|
+----[SHA256]-----+
```



## 4.查看是否创建成功

```sh
$ ls ~/.ssh/
id_rsa  id_rsa.pub  known_hosts  known_hosts.old
```




## 5.查看公钥

```sh
$ cat ~/.ssh/id_rsa.pub
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDxr8bAvg3vz6CCOfZmbKxwqieAr5LLVgv2RTXw3PNuEotOE0IGcWsJafLA6IFoJzT1KqhpMJbxu6WK4BPX6YSEwvi6NfCi0aEJkinK1igcetlNG9peCTNCNXO2bAGRL2dB/Duu7uXUgHakmmCT4HrbJpUxA84GHKS0eQ66ORQgK+Wokek5A+iGrZ40GidxyKy/+OOXYZ6
```



## 6. shell格式转换

dos2unix [`需要转换的shell`]

```sh
yum install dos2unix -y
dos2unix install_MYSQL.sh
```

![image-20231130110544858](https://hj-typora-images-1319512400.cos.ap-guangzhou.myqcloud.com/images/202311301105997.png)
