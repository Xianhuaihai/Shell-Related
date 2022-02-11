#!/bin/bash

#**************************************************
#说明:风电项目部署脚本，适用于Jenkins主从，在从节点拷贝部署
#Author:xianhuaihai
#Date:2021-10-14
#QQ:xianhuaihai@qq.com
#Description:本脚本可以扩展，扩展时在尾部case语句添加git仓库名即可，同时需设置4个变量，
# srcpath：指定jenkens从节点的工作目录。destpath：指定部署位置，如nginx的根目录。src_target：指定vue编译后的目录名。dest_target：指定部署时目录名
#***************************************************

set -e
srcpath="/root/jenkins-work/workspace/wind-front"
destpath="/data/wind/frontend"
repo=${1##*/}
mytype=$2
echo "仓库地址$repo"
#一个实现复制目录前备份一次，并且可以回退的功能copy
function copylogic(){
	#回滚
	if [ $mytype == "rollback" ];then
		echo "开始回退，检查有无备份"
		echo "要恢复的旧备份文件：$destpath/${dest_target}.bak"
		if [ -d $destpath/${dest_target}.bak ];then
			echo "有旧备份文件,开始回退！"
			rm -rf $destpath/${dest_target}||true
			sleep 2
			mv $destpath/${dest_target}.bak $destpath/${dest_target}
			echo "回退成功！！！"
		else
			echo "没有可以回退的文件"
		fi
	#部署
	elif [ $mytype == "deploy" ];then
		#检查目标地址有无文件目录，有就先备份
		if [ -d $destpath/$dest_target ];then
			#判断有无备份文件，有就删除旧备份
			echo "旧备份文件：$destpath/${dest_target}.bak"
			if [ -d $destpath/${dest_target}.bak ];then
				echo "有旧备份文件"
				rm -rf $destpath/${dest_target}.bak
				echo "成功删除旧备份"
			fi
			mv $destpath/${dest_target} $destpath/${dest_target}.bak
			echo "备份成功！！！"	
			cp -a $srcpath/$src_target $destpath/$dest_target
			echo "部署成功！！！"	
		else
			echo "没有文件直接拷贝"
			cp -a $srcpath/$src_target $destpath/$dest_target
			echo "部署成功！！！"	
		fi
	else
		echo "没有接收到部署类型mytype变量"
	fi
}
case "${repo%.*}" in
	"wind_power_system.app")
		echo "执行仓库块--${1%.*}"
		#编译后生成的静态目录
		src_target="wind-app"
		#将编译后静态目录最终部署名
		dest_target="wind-app"
		copylogic
	;;
	"wind_iot_system.frontend")
		echo "执行仓库块--${1%.*}"
		#编译后生成的静态目录
		src_target="dest"
		#将编译后静态目录最终部署名
		dest_target="wind-iot"
		copylogic
	;;
	"wind_power_system.frontend")
		echo "执行仓库块--${1%.*}"
		#编译后生成的静态目录
		src_target="dest"
		#将编译后静态目录最终部署名
		dest_target="wind-power"
		copylogic
	;;
	*)
		echo "没有匹配到要部署的仓库，请检查是否添加仓库部署"
	;;
esac

