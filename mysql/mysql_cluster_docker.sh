#!/bin/bash

mysql_version="5.7"
mysql_image="mysql:${mysql_version}"
mysql_name="mysql"
mysql_port=3306
mysql_root_passwd=123456

base_dir="/opt/mysql_cluster"
mysql_master="${base_dir}/master"
mysql_slave1="${base_dir}/slave1"
mysql_slave2="${base_dir}/slave2"

#master
master_container="mysql_master"
#slave
slave_containers=("mysql_slave1" "mysql_slave2")
#all containers
all_containers=("${master_container}" "${slave_containers[@]}")
#重试间隔5s
retry_duration=5

# 判断容器是否启动
# exit_container() {
#     if [[ "$(docker inspect -f {{.State.Status}} ${mysql_name}) 2> /dev/null" == "" ]]; then
#         echo "${mysql_name}尚未启动"
#         exit 1
#     fi
# }

#获取mysql容器ip
docker_ip() {
    docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$@"
}


# 创建MYSQL容器
build() {
    # 设置数据目录
    [[ ! -d ${base_dir} ]] && mkdir -p ${base_dir}/{master,slave1,slave2}/{log,data,conf}
    
    cat << EOF > ${mysql_master}/conf/my.cnf
[mysqld]
## 设置server_id，同一局域网中需要唯一
server-id=101
## 指定不需要同步的数据库名称
binlog-ignore-db=mysql
## 开启二进制日志功能
log-bin=my-mysql-bin
## 设置二进制日志使用内存大小（事务）
binlog_cache_size=1M
## 设置使用的二进制日志格式（mixed,statement,row）
binlog_format=mixed
## 二进制日志过期清理时间。默认值为0，表示不自动清理。
expire_logs_days=7
## 跳过主从复制中遇到的所有错误或指定类型的错误，避免slave端复制中断。
## 如：1062错误是指一些主键重复，1032错误是因为主从数据库数据不一致
slave_skip_errors=1062
init_connect='SET collation_connection = utf8_unicode_ci'
init_connect='SET NAMES utf8'
character-set-server=utf8
collation-server=utf8_unicode_ci
skip-character-set-client-handshake
skip-name-resolve
[client]
default-character-set=utf8
[mysql]
default-character-set=utf8
EOF
    cat << EOF > ${mysql_slave1}/conf/my.cnf
[mysqld]
## 设置server_id，同一局域网中需要唯一
server-id=102
## 指定不需要同步的数据库名称
binlog-ignore-db=mysql
## 开启二进制日志功能，以备Slave作为其它数据库实例的Master时使用
log-bin=my-mysql-slave1-bin
## 设置二进制日志使用内存大小（事务）
binlog_cache_size=1M
## 设置使用的二进制日志格式（mixed,statement,row）
binlog_format=mixed
## 二进制日志过期清理时间。默认值为0，表示不自动清理。
expire_logs_days=7
## 跳过主从复制中遇到的所有错误或指定类型的错误，避免slave端复制中断。
## 如：1062错误是指一些主键重复，1032错误是因为主从数据库数据不一致
slave_skip_errors=1062
## relay_log配置中继日志
relay_log=my-mysql-relay-bin
## log_slave_updates表示slave将复制事件写进自己的二进制日志
log_slave_updates=1  
## slave设置为只读（具有super权限的用户除外）
read_only=1
init_connect='SET collation_connection = utf8_unicode_ci'
init_connect='SET NAMES utf8'
character-set-server=utf8
collation-server=utf8_unicode_ci
skip-character-set-client-handshake
skip-name-resolve

[client]
default-character-set=utf8
[mysql]
default-character-set=utf8
EOF
    cat << EOF > ${mysql_slave2}/conf/my.cnf
[mysqld]
## 设置server_id，同一局域网中需要唯一
server-id=103
## 指定不需要同步的数据库名称
binlog-ignore-db=mysql
## 开启二进制日志功能，以备Slave作为其它数据库实例的Master时使用
log-bin=my-mysql-slave2-bin
## 设置二进制日志使用内存大小（事务）
binlog_cache_size=1M
## 设置使用的二进制日志格式（mixed,statement,row）
binlog_format=mixed
## 二进制日志过期清理时间。默认值为0，表示不自动清理。
expire_logs_days=7
## 跳过主从复制中遇到的所有错误或指定类型的错误，避免slave端复制中断。
## 如：1062错误是指一些主键重复，1032错误是因为主从数据库数据不一致
slave_skip_errors=1062
## relay_log配置中继日志
relay_log=my-mysql-relay-bin
## log_slave_updates表示slave将复制事件写进自己的二进制日志
log_slave_updates=1  
## slave设置为只读（具有super权限的用户除外）
read_only=1
init_connect='SET collation_connection = utf8_unicode_ci'
init_connect='SET NAMES utf8'
character-set-server=utf8
collation-server=utf8_unicode_ci
skip-character-set-client-handshake
skip-name-resolve

[client]
default-character-set=utf8
[mysql]
default-character-set=utf8
EOF

    cat <<EOF > ${mysql_master}/mysql_master.env
MYSQL_ROOT_PASSWORD=${mysql_root_passwd}
MYSQL_PORT=${mysql_port}
# 数据库配置
MYSQL_USER=mydb_slave_user
MYSQL_PASSWORD=mydb_slave_pwd
# MYSQL_DATABASE=mydb
# 设置为大小写不敏感
MYSQL_LOWER_CASE_TABLE_NAMES=0
EOF
    cat << EOF > ${mysql_slave1}/mysql_slave1.env
MYSQL_ROOT_PASSWORD=${mysql_root_passwd}
MYSQL_PORT=${mysql_port}
# 数据库配置
MYSQL_USER=mydb_slave_user
MYSQL_PASSWORD=mydb_slave_pwd
# MYSQL_DATABASE=mydb
# 设置为大小写不敏感
MYSQL_LOWER_CASE_TABLE_NAMES=0
EOF
    cat << EOF > {mysql_slave2}/mysql_slave2.env
MYSQL_ROOT_PASSWORD=${mysql_root_passwd}
MYSQL_PORT=${mysql_port}
# 数据库配置
MYSQL_USER=mydb_slave_user
MYSQL_PASSWORD=mydb_slave_pwd
# MYSQL_DATABASE=mydb
# 设置为大小写不敏感
MYSQL_LOWER_CASE_TABLE_NAMES=0
EOF

    # 拉取镜像
    [[ "$(docker images -q ${mysql_image}) 2> /dev/null" == "" ]] && $(docker pull ${mysql_image})

    cat << EOF > ${base_dir}/docker-compose.yml
version: '3'

networks:
 mysql_net:
  driver: bridge
  name: mysql_net
  ipam:
   driver: default
   config:
    - subnet: "172.21.0.0/16"

services:
 mysql_master:
  image: mysql:5.7
  container_name: mysql_master
  env_file:
   - ${mysql_master}/mysql_master.env
  ports:
   - 3307:3306
  restart: "no"
  networks:
   mysql_net:
    ipv4_address: 172.21.0.11
  volumes:
   - ${mysql_master}/conf/my.cnf:/etc/mysql/conf.d/my.cnf
   - ${mysql_master}/data:/var/lib/mysql
   - ${mysql_master}/log:/var/log/mysql

 mysql_slave1:
  image: mysql:5.7
  container_name: mysql_slave1
  env_file:
   - ${mysql_slave1}/mysql_slave1.env
  ports:
   - 3308:3306
  restart: "no"
  networks:
   mysql_net:
    ipv4_address: 172.21.0.12
  depends_on:
   - mysql_master
  volumes:
   - ${mysql_slave1}/conf/my.cnf:/etc/mysql/conf.d/my.cnf
   - ${mysql_slave1}/data:/var/lib/mysql
   - ${mysql_slave1}/log:/var/log/mysql

 mysql_slave2:
  image: mysql:5.7
  container_name: mysql_slave2
  env_file:
   - ${mysql_slave2}/mysql_slave2.env
  ports:
   - 3309:3306
  restart: "no"
  networks:
   mysql_net:
    ipv4_address: 172.21.0.13
  depends_on:
   - mysql_master
  volumes:
   - ${mysql_slave2}/conf/my.cnf:/etc/mysql/conf.d/my.cnf
   - ${mysql_slave2}/data:/var/lib/mysql
   - ${mysql_slave2}/log:/var/log/mysql
EOF

    cd ${base_dir}
    docker-compose up -d
    ###检查容器是否启动成功
    for container in "${all_containers[@]}"
    do
        until docker exec ${container} sh -c 'export MYSQL_PWD='${root_password}'; mysql -u root -e ";"'
        do
            echo "连接${container}中...  每${retry_duration}s尝试连接一次，知道容器正常启动....."
            sleep ${retry_duration}
        done
        echo ${container}"连接成功。。。。"
    done

    #扩权给${mysq_user}
    privi_user='GRANT REPLICATION SLAVE ON *.* TO "'${mysql_user}'"@"%" IDENTIFIED BY "'${mysql_password}'"; FLUSH PRIVILEGES;'
    docker exec ${master_container} sh -c "export MYSQL_PWD="${root_password}"; mysql -u root -e '${privi_user}'"
    #查看主服务器状态
    master_status=`docker exec ${master_container} sh -c 'export MYSQL_PWD='${root_password}'; mysql -u root -e "SHOW MASTER STATUS"'`
    #获取信息
    current_log=`echo ${master_status} | awk '{print $6}'`
    current_position=`echo ${master_status} | awk '{print $7}'`
    echo $current_log
    echo "------------------------------------------------------------------"
    #slave互通master
    start_slave_stmt="CHANGE MASTER TO
            MASTER_HOST='$(docker_ip $master_container)',
            MASTER_USER='$mysql_user',
            MASTER_PASSWORD='$mysql_password',
            MASTER_LOG_FILE='$current_log',
            MASTER_LOG_POS=$current_position;"

    start_slave_cmd='export MYSQL_PWD='$root_password'; mysql -u root -e "'
    start_slave_cmd+="$start_slave_stmt"
    start_slave_cmd+='START SLAVE;"'
    # exit_container
    # 执行从服务器与主服务器互通
    for slave in "${slave_containers[@]}";do
        # 从服务器连接主互通
        docker exec $slave sh -c "$start_slave_cmd"
        # 查看从服务器得状态
        docker exec $slave sh -c "export MYSQL_PWD='$root_password'; mysql -u root -e 'SHOW SLAVE STATUS \G'"
    done
    echo -e "\033[42;34m finish success !!! \033[0m"
    retval=$?
    return ${retval}
}

# 启动MYSQL容器
start() {
    cd ${base_dir}
    docker-compose up -d
    retval=$?
    return ${retval}
}

# 重启MSYQL容器
restart() {
    cd ${base_dir}
    docker-compose restart
    retval=$?
    return ${retval}
}

# 停止MYSQL容器
stop() {
    cd ${base_dir}
    docker-compose down
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