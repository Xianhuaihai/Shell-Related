# Shell-Related
Some experiences in my work

yxx.sh 原理说明：指定目录后可启动、停止、搜索jar程序，工作原理是在给定的目录下搜索jar程序并启动、停止、检查运行状态。同时可以指定多个目录搜索jar。

### 使用脚本：

变量说明：

APP_PATH : 指定扫描目录，程序会扫描到目录下的java程序文件，若有多个目录需要用空格隔开，目录结尾不能有 ‘/’ , 正确示例：APP_PATH="/data/a /data/b"

depenv: 指定程序的依赖环境，启动时会考虑依赖程序是否启动

javaArg: java参数



启动参数说明：

start : 启动

stop: 停止

no_dep_start: 不考虑依赖环境启动

jar_check: 检查所有java程序启动状态

 dep_check：检查依赖环境启动状态
