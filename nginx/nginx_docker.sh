#!/bin/bash

base_dir="/opt/nginx"
nginx_image="nginx:1.18.0"
nginx_port=80
nginx_name="nginx"

[[ ! -d ${base_dir} ]] && mkdir -p ${base_dir}/{conf,html,logs}

docker run --name nginx_tmp -d ${nginx_image}
docker cp nginx_tmp:/etc/nginx/nginx.conf ${base_dir}/conf
docker cp nginx_tmp:/etc/nginx/conf.d ${base_dir}/conf
docker cp tnginx_tmpest:/usr/share/nginx/html ${base_dir}/
docker stop nginx_tmp
docker rm nginx_tmp
docker stop nginx
docker rm nginx

docker run -p ${nginx_port}:80 --name "${nginx_name}" \
    --privileged=true \
    -v  ${base_dir}/conf/nginx.conf:/etc/nginx/nginx.conf \
    -v  ${base_dir}/conf/conf.d:/etc/nginx/conf.d \
    -v  ${base_dir}/logs:/var/log/nginx \
    -v  ${base_dir}/html:/usr/share/nginx/html \
    -v /etc/localtime:/etc/localtime \
    -d "${nginx_image}"
	 
