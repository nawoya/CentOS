#!/bin/bash

### これは以下のHPのコマンドをそのまま引用しただけのものです。
### https://www.server-world.info/query?os=CentOS_7&p=oracle12c&f=1

#----------------------------------------------
# 実行時のユーザを確認
#----------------------------------------------
if [[ `whoami` != "root" ]]
then
    echo "rootユーザで実行してください。"
    exit 1
fi

#----------------------------------------------
# 必要なライブラリを持ってくる
#----------------------------------------------
echo "Download and install necessary libs"
yum -y install binutils compat-libcap1 gcc gcc-c++ glibc glibc.i686 glibc-devel glibc.i686 ksh libaio libaio.i686 libaio-devel libaio-devel.i686 libgcc libgcc.i686 libstdc++ libstdc++l7.i686 libstdc++-devel libstdc++-devel.i686 compat-libstdc++-33 compat-libstdc++-33.i686 libXi libXi.i686 libXtst libXtst.i686 make sysstat 


#----------------------------------------------
# カーネルパラメータの変更
#----------------------------------------------
MEMTOTAL=$(free -b | sed -n '2p' | awk '{print $2}')
SHMMAX=$(expr $MEMTOTAL / 2)
SHMMNI=4096
PAGESIZE=$(getconf PAGE_SIZE)
cat >> /etc/sysctl.conf << EOF
fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.shmmax = $SHMMAX
kernel.shmall = $(expr \( $SHMMAX / $PAGESIZE \) \* \( $SHMMNI / 16 \))
kernel.shmmni = $SHMMNI
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
EOF

sysctl -p 

#----------------------------------------------
# Oracle用のユーザ、グループの作成
#----------------------------------------------
i=54321; for group in oinstall dba backupdba oper dgdba kmdba; do
groupadd -g $i $group; i=$(expr $i + 1)
done

useradd -u 1200 -g oinstall -G dba,oper,backupdba,dgdba,kmdba -d /home/oracle oracle
passwd oracle 

mkdir -p /u01/app/oracle 
chown -R oracle:oinstall /u01/app 
chmod -R 775 /u01 

vi /etc/pam.d/login
# 14行目あたりに追記
#session    required     pam_selinux.so open
#session    required     pam_namespace.so
#session    required     pam_limits.so
#session    optional     pam_keyinit.so force revoke
#session    include      system-auth
#-session   optional     pam_ck_connector.so

vi /etc/security/limits.conf
# 最終行に追記
# oracle  soft  nproc   2047
#oracle  hard  nproc   16384
#oracle  soft  nofile  1024
#oracle  hard  nofile  65536
#oracle  soft  stack   10240
#oracle  hard  stack   32768

#この後は以下のホームページにある手順で勧める
# https://www.server-world.info/query?os=CentOS_7&p=oracle12c&f=2
