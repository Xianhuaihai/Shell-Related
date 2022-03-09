#!/bin/bash
red_echo ()      { [ "$HASTTY" == 0 ] && echo "$@" || echo -e "\033[031;1m$@\033[0m"; }
green_echo ()    { [ "$HASTTY" == 0 ] && echo "$@" || echo -e "\033[032;1m$@\033[0m"; }
yellow_echo ()   { [ "$HASTTY" == 0 ] && echo "$@" || echo -e "\033[033;1m$@\033[0m"; }
blue_echo ()     { [ "$HASTTY" == 0 ] && echo "$@" || echo -e "\033[034;1m$@\033[0m"; }
purple_echo ()   { [ "$HASTTY" == 0 ] && echo "$@" || echo -e "\033[035;1m$@\033[0m"; }
bred_echo ()     { [ "$HASTTY" == 0 ] && echo "$@" || echo -e "\033[041;1m$@\033[0m"; }
bgreen_echo ()   { [ "$HASTTY" == 0 ] && echo "$@" || echo -e "\033[042;1m$@\033[0m"; }
byellow_echo ()  { [ "$HASTTY" == 0 ] && echo "$@" || echo -e "\033[043;1m$@\033[0m"; }
bblue_echo ()    { [ "$HASTTY" == 0 ] && echo "$@" || echo -e "\033[044;1m$@\033[0m"; }
bpurple_echo ()  { [ "$HASTTY" == 0 ] && echo "$@" || echo -e "\033[045;1m$@\033[0m"; }
bgreen_echo ()   { [ "$HASTTY" == 0 ] && echo "$@" || echo -e "\033[042;34;1m$@\033[0m"; }

purple_echo ()   { [ "$HASTTY" == 0 ] && echo "$@" || echo -e "\033[035;1m$@\033[0m"; }
bred_echo ()     { [ "$HASTTY" == 0 ] && echo "$@" || echo -e "\033[041;1m$@\033[0m"; }
bgreen_echo ()   { [ "$HASTTY" == 0 ] && echo "$@" || echo -e "\033[042;1m$@\033[0m"; }
byellow_echo ()  { [ "$HASTTY" == 0 ] && echo "$@" || echo -e "\033[043;1m$@\033[0m"; }
bblue_echo ()    { [ "$HASTTY" == 0 ] && echo "$@" || echo -e "\033[044;1m$@\033[0m"; }
bpurple_echo ()  { [ "$HASTTY" == 0 ] && echo "$@" || echo -e "\033[045;1m$@\033[0m"; }
bgreen_echo ()   { [ "$HASTTY" == 0 ] && echo "$@" || echo -e "\033[042;34;1m$@\033[0m"; }

set -e
SELF_DIR=$(dirname "$(readlink -f "$0")")
usage () {
    echo "usage: zb_install PLATFORM"

    echo "用法: "
    echo "  ./zb_install dk         安装 docker 及依赖环境并启动服务"
    echo "  ./zb_install pk         导入parkedge镜像并且启动服务"
    echo "  ./zb_install up         启动服务"
    echo "  ./zb_install down       停止服务"
    echo "  ./zb_install ps         查看服务状态"
    
}
log () {
   # 打印消息, 并记录到日志, 日志文件由 LOG_FILE 变量定义
   local retval=$?
   local timestamp=$(date +%Y%m%d-%H%M%S)
   local level=INFO
   local func_seq=$(echo ${FUNCNAME[@]} | sed 's/ /-/g')
   local logfile=${LOG_FILE:=${SELF_DIR}/park.log}

   echo "[$(blue_echo $LAN_IP)]$timestamp $BASH_LINENO   $@"
   echo "[$(blue_echo $LAN_IP)]$timestamp $level|$BASH_LINENO|${func_seq} $@" >>$logfile
   return $retval
}
fail () {
   # 打印错误消息,并以非0值退出程序
   # 参数1: 消息内容
   # 参数2: 可选, 返回值, 若不提供默认返回1
   local timestamp=$(date +%Y%m%d-%H%M%S)
   local level=FATAL
   local retval=${2:-1}
   local func_seq=$(echo ${FUNCNAME[@]} | sed 's/ /-/g')
   local logfile=${LOG_FILE:=${SELF_DIR}/park.log}

   echo "[$(red_echo $LAN_IP)]$timestamp $BASH_LINENO   $(red_echo $@)"
   echo "[$(red_echo $LAN_IP)]$timestamp $level|$BASH_LINENO|${func_seq} $@" >> $logfile

   exit $retval
}

ok () {
   # 打印标准输出(绿色消息), 说明某个过程执行成功, 状态码为0
   local timestamp=$(date +%Y%m%d-%H%M%S)
   local level=INFO
   local func_seq=$(echo ${FUNCNAME[@]} | sed 's/ /-/g')
   local logfile=${LOG_FILE:=${SELF_DIR}/park.log}

   echo "[$(green_echo $LAN_IP)]$timestamp $BASH_LINENO   $(green_echo $@)"
   echo "[$(green_echo $LAN_IP)]$timestamp $level|$BASH_LINENO|${func_seq} $@" >> $logfile

   return 0
}
stop_firewalld(){
     bblue_echo "--------------------stop firewalld and selinux--------------------"
     systemctl stop firewalld && ok [关闭防火墙成功] || fail [关闭防火墙失败]
     systemctl disable firewalld && ok [设置防火墙禁止开机启动成功] || fail [设置防火墙禁止开机启动失败]
     setenforce 0 && ok [关闭selinux成功] || fail [关闭selinux失败]
     sed -i 's/^SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
     
}
install_docker(){
     bblue_echo "--------------------docker install--------------------"
     yum remove podman &> /dev/null
     yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine &> /dev/null

     yum install -y yum-utils 
     yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

    yum install -y docker-ce docker-ce-cli containerd.io
 
    systemctl start docker && ok [启动docker成功] || fail [启动docker失败]
    systemctl enable docker && ok [设置开机自启动成功] || fail [自启动设置失败]
}
park_install (){
   bblue_echo "--------------------parkedge install--------------------"
   cd $SELF_DIR
   echo "当前脚本所在目录$SELF_DIR" 
   #导入镜像
   purple_echo '正在导入镜像>>>>>>>>>>>>' 
   for f in $(ls imagesrepo/*.tar);do docker load -i $f;done
   [ $? -eq 0 ] && ok [导入镜像成功] || fail [导入镜像失败]
   #移动docker-compose
   if [ -f $SELF_DIR/docker-compose ]; then
       chmod +x docker-compose
       [ $? -eq 0 ] && ok [设置权限docker-compose成功]|| fail [设置权限docker-compose失败]
       cp docker-compose /usr/local/bin
       #打印日志
       [ $? -eq 0 ] && ok [拷贝docker-compose成功]|| fail [拷贝docker-compose失败p
       bpurple_echo [启动parkedge服务]
       docker-compose up -d
       sleep 2
       docker-compose ps
   else 
      red_echo "[err] docker-compose 没有文件"
      exit 1
   fi
}
process_is_running () {
    # 模糊匹配, 检测时输入更精确匹配进程的模式表达式
    local pattern="$1"

    ps -ef | grep "$pattern" \
           | grep -v grep \
           | awk '{print $2;a++}END{if (a>0) {exit 0} else {exit 1}}'
}

case $1 in 
    dk|DK)
       if process_is_running docker ;then 
         blue_echo [docker 已经在运行中]
         exit 0
       else
         stop_firewalld
         install_docker
         park_install
         if process_is_running docker ;then
            ok Docker install [SUCCEED] 
         else
           fail Docker install [FAIL] 
         fi
       fi 
#       echo ""
#       echo "如果以上步骤没有报错, 已经完成 $(green_echo Docker) 的部署，接下来可以:"
#       echo " 1. 通过./zb_install pk 部署停车场服务"
#       echo ""

    ;;
    pk|PK)
    park_install
    ;;
    up|UP)
    $SELF_DIR/docker-compose -f $SELF_DIR/docker-compose.yml up -d 
    ;;
    down|DOWN)
    $SELF_DIR/docker-compose -f $SELF_DIR/docker-compose.yml down
    ;;
    ps|PS)
    $SELF_DIR/docker-compose -f $SELF_DIR/docker-compose.yml ps
    ;;
    *)
    usage; exit 0
    ;;
esac
