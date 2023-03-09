#!/bin/bash

### redis集群三主三从

base_dir="opt/redis_cluster"
retry_duration=5

[[ ! -d ${base_dir} ]] && mkdir -p ${base_dir}

cat << EOF > ${base_dir}/docker-compose.yml
version: '3'

services:
EOF

for node in $(seq 1 6)
do
	mkdir -p ${base_dir}/redis-node${node}/conf
	cat << EOF > ${base_dir}/redis-node${node}/conf/redis.conf
port 639${node}
daemonize no
bind 0.0.0.0
cluster-enabled yes
cluster-config-file node.conf
cluster-node-timeout 5000
cluster-announce-port 639${node}
cluster-announce-bus-port 1639${node}
protected-mode no
appendonly yes
EOF

compose="""
 redis-node${node}:
  image: redis:6.0.8
  container_name: redis-node${node}
  network_mode: host
  expose:
   - 639${node}
  privileged: true
  environment:
   TZ: Asia/Shanghai
  volumes:
   - ${base_dir}/redis-node${node}/conf/redis.conf:/etc/redis/redis.conf
   - ${base_dir}/redis-node${node}/data:/data
  command:
   - 'redis-server'
   - '/etc/redis/redis.conf'
""""${compose}"
done

echo "${compose}" >> ${base_dir}/docker-compose.yml

cd ${base_dir}
docker-compose up -d

# 判断是否启动成功

docker_ip() {
    # docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$@"
    ifconfig ens33 | awk '/broadcast/ {print $2}'
}

for node in $(seq 1 6)
do
 until docker exec redis-node${node} sh -c " redis-cli -h 192.168.48.30 -p 639${node} info | grep redis_version"
 do
   echo "连接redis-node${node}中...  每${retry_duration}s尝试连接一次，知道容器正常启动....."
   sleep ${retry_duration}
 done
#  iplist+=$(docker_ip redis-node${node}):6379" "
 iplist+=$(docker_ip redis-node${node}):639${node}" "
 echo "redis-node${node},$(docker_ip redis-node${node}) 已启动...."
done

echo $iplist
#创建集群连接
docker exec redis-node1 sh -c " echo yes | redis-cli --cluster create ${iplist}  --cluster-replicas 1"