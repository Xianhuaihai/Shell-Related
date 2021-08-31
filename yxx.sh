#!/bin/bash

#**************************************************
#说明：可能存在上个命令没执行完就执行下个命令导致报错并对出程序脚本，只需再次执行脚本即可
#Author:xianhuaihai
#Date:2021-8-30
#QQ:xianhuaihai@qq.com
#Description:指定目录后可启动、停止、搜索jar程序
#***************************************************

set -e
#项目jar包目录 若有多个目录需要用空格隔开，目录后不能指定/ 如/data/不能有后面的/, 正确写法/data
APP_PATH="/data/crayfish /data/crayfish_government"
#运行环境依赖
depenv="consul mysqld redis rabbit"
#java参数
javaArg="-XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=256m -Xms256m -Xmx256m -Xmn512m -Xss512k -XX:SurvivorRatio=8 -XX:+UseConcMarkSweepGC -server"
#开关
#switch="pass"
#颜色
RP="\e[1;31m"
GP="\e[1;32m"
P="\e[0m"
#启动目录下及其子目录的jar程序,仅会启动没有运行的jar程序
function mystart(){
	for i in `ls $1`;do
		dir_file=$1"/"$i
		if [ -d $dir_file ];then
			mystart $dir_file
		else
			if [[ $i =~ .*jar$ ]];then
			#	echo -e  "$RP${dir_file##*/}$P"
			#	echo -e  "$RP${dir_file%/*}/len.log$P"
	 			[ ! -z $(ps aux | grep $i | grep -v grep| awk '{print $2}' | head -n1) ] || nohup java -jar $javaArg $dir_file > ${dir_file%/*}/${i%.*}.log  2>&1 &
				sleep 2
				if [ -z $(ps aux | grep $i | grep -v grep | awk '{print $2}' | head -n1) ];then
					echo -e "$RP$i 停止状态。。。$P"
				else
					echo -e "$GP$i 启动成功$P"
				fi

			fi
		fi
	done
}
#搜检目录下及其子目录的jar并打印
function myfind(){
	for i in `ls $1`;do
		dir_file=$1"/"$i
		if [ -d $dir_file ];then
			myfind $dir_file
		else
			if [[ $i =~ .*jar$ ]];then
			#	只打印jar包名
			#	echo -e  "$RP${dir_file##*/}$P"
			#	打印jar完整路径
				echo -e  "$RP$dir_file$P"
			#	打印jar所在的路径目录
			#	echo -e  "$RP${dir_file%/*}/len.log$P"
			fi
		fi
	done
}
#搜索目录下及其子目录的jar程序并停止
function mystop(){
	for i in `ls $1`;do
		dir_file=$1"/"$i
		if [ -d $dir_file ];then
			mystop $dir_file
		else
			if [[ $i =~ .*jar$ ]];then
			#	获取jar包	
			#	echo -e  "$RP${dir_file##*/}$P"
				pidapp=`ps aux | grep $i | grep -v grep | awk '{print $2}' | head -n1`
				#当jar运行时就执行kill命令，否则不执行
	        		[ -z $(ps aux | grep $i | grep -v grep| awk '{print $2}' | head -n1) ] || kill -15 $pidapp
				sleep 5
				#如果没有正常退出，就强制停止jar
				if [ -z $(ps aux | grep $i | grep -v grep | awk '{print $2}' |head -n1) ];then
					echo -e "$RP$i 已被关闭$P"
				else
					echo -e "$RP$i 正在强制退出....$P"
					sleep 5
					#再次判断jar有没有退出，因为会出现停止花费时间太慢导致进程没发现
					if [ -z $(ps aux | grep $i | grep -v grep | awk '{print $2}' | head -n1)];then
						echo -e "$RP$i 已被退出$P"
					else
						kill -9 $pidapp 
						sleep 2
						#再次判断jar是否退出
						if [ -z $(ps aux | grep $i | grep -v grep | awk '{print $2}' | head -n1)];then
							echo -e "$RP$i 已被退出$P"
						else
							echo -e "$RP$i 停止失败$P"
						fi
					fi

				fi
			fi
		fi
	done
}
#搜索目录下及其子目录下的jar程序，并查看是否在运行状态
function myjar_check(){
	for i in `ls $1`;do
		dir_file=$1"/"$i
		if [ -d $dir_file ];then
			myjar_check $dir_file
		else
			if [[ $i =~ .*jar$ ]];then
			#	打印jar
			#	echo -e  "$RP${dir_file##*/}$P"
			#	echo -e  "$RP${dir_file%/*}/len.log$P"
				if [ -z $(ps aux | grep $i | grep -v grep | awk '{print $2}' | head -n1) ];then
					echo -e "$RP$i 停止状态。。。$P"
				else
					echo -e "$GP$i 正在运行中。。。$P"
				fi
			fi
		fi
	done
}


function mydep_check(){
	for i in $depenv;do
		if [ ! -z $(ps aux | grep $i | grep -v grep | awk '{print $2}' | head -n1) ];then
			echo -e "$GP $i\t运行中 $P"
		else
			echo -e "$GP $i\t停止状态 $P"
			switch=$i
		fi
	done
}
case "$1" in 
	"start")
		#只有当依赖环境都启动完成才能运行jar程序
		#开关设置
		switch="pass"
		mydep_check > /dev/null 2>&1
		if [[ $switch == "pass" ]];then
			for i in $APP_PATH;do
				mystart $i
			done
		else
			echo "说明：必须具备依赖环境才能成功运行jar程序"
			echo "$switch 号没有启动"
			
		fi
		;;
	"no_dep_start")
		#直接启动jar程序，不考虑依赖环境因素
		for i in $APP_PATH;do
			mystart $i
		done
		;;	
	"stop")
		for i in $APP_PATH;do
			mystop $i
		done
		;;
	"jar_check")
		for i in $APP_PATH;do
			myjar_check $i |awk '{printf "%-50s %10s\n",$1,$2}'
		done
		;;
	"dep_check")
		mydep_check
		;;
	"find")
		for i in $APP_PATH;do
			myfind $i
		done
		;;
	*)
		echo "参数错误，请输入参数 start stop jar_check dep_check"
		;;
esac
