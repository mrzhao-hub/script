#/bin/bash

#引入系统函数库
. /etc/init.d/functions

mysql_version="5.7"
mysql_image="mysql:${mysql_version}"
mysql_name="mysql"
mysql_port=3306
mysql_passwd=123456

my-cnf="""
[client]
default-character-set=utf8

[mysql]
default-character-set=utf8

[mysqld]
init_connect='SET collation_connection = utf8_unicode_ci'
init_connect='SET NAMES utf8'
character-set-server=utf8
collation-server=utf8_unicode_ci
skip-character-set-client-handshake
skip-name-resolve
transaction-isolation=READ-COMMITTED
innodb_log_file_size=256M
max_allowed_packet=34M
"""
base_dir="/opt/mysql"

# 判断容器是否启动
exit_container() {
    if [[ "$(docker inspect -f {{.State.Status}} ${mysql_name}) 2> /dev/null" == "" ]]; then
        echo "${mysql_name}尚未启动"
        exit 1
    fi
}


# 创建MYSQL容器
build() {
    # 设置数据目录
    [[ ! -d ${base_dir} ]] && mkdir -p ${base_dir}/{log,data,conf}
    echo ${my-cnf} > ${base_dir}/conf/my.cnf
    # 拉取镜像
    [[ "$(docker images -q ${mysql_image}:${mysql_version}) 2> /dev/null" == "" ]] && docker pull ${mysql_image}:${mysql_version}
    docker run -p ${mysql_port}:3306 --name ${mysql_name} \
    -v  ${base_dir}/log:/logs \
    -v  ${base_dir}/data:/var/lib/mysql \
    -v  ${base_dir}/conf:/etc/mysql/conf.d \
    -e MYSQL_ROOT_PASSWORD=${mysql_passwd} \
    --privileged=true \
    -d ${mysql_image}:${mysql_version}

    exit_container
    retval=$?
    return ${retval}
}

# 启动MYSQL容器
start() {
    docker start ${mysql_name}
    retval=$?
    return ${retval}
}

# 重启MSYQL容器
restart() {
    docker restart ${mysql_name}
    retval=$?
    return ${retval}
}

# 停止MYSQL容器
stop() {
    docker stop ${mysql_name}
    retval=$?
    return ${retval}
}

case "$1" in
    build)
        build
        retval=$?
        ;;
    start)
        start
        retval=$?
        ;;
    stop)
        stop
        retval=$?
        ;;
    restart)
        restart
        sleep 2
        retval=$?
        ;;
    *)
        echo $"Usage:$0 {build|start|restart|stop}"
        exit 2
esac
exit $retval