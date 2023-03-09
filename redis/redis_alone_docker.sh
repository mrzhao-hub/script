#!/bin/bash

#####  单机

base_dir="/opt/redis"
redis_port="6379"
redis_name="redis"
redis_version="6.0.8"
redis_image="redis:${redis_version}"

build() {
    # 校验目录是否存在
    [[ ! -d base_dir ]] && mkdir -p ${base_dir}/data

    # 写入配置文件
    cat << EOF > ${base_dir}/redis.conf
bind 0.0.0.0
#默认yes，开启保护模式，限制为本地访问
protected-mode no
#默认no，改为yes意为以守护进程方式启动，可后台运行，除非kill进程，改为yes会使配置文件方#式启动redis失败
daemonize no
#redis持久化（可选）
appendonly yes
#设置密码
#requirepass 123456
EOF
    docker run -p ${redis_port}:6379 --name ${redis_name} \
        -v ${base_dir}/redis.conf:/etc/redis/redis.conf \
        -v ${base_dir}/data:/data \
        -d ${redis_image} redis-server /etc/redis/redis.conf
    retval=$?
    return ${retval}
}

start() {
    docker start ${redis_name}
    retval=$?
    return ${retval}
}

stop() {
    docker stop ${redis_name}
    retval=$?
    return ${retval}
}

restart() {
    docker restart ${redis_name}
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