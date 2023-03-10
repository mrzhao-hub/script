#!/bin/bash

logs_path="/opt/nginx/logs"
bk_path="/data/nginx/logs/history"
YESTERDAY=$(date -d "yesterday" +%Y-%m-%d-%H-%M-%S)
mv ${logs_path}/access.log ${bk_path}/access_${YESTERDAY}.log
mv ${logs_path}/error.log ${bk_path}/error_${YESTERDAY}.log

docker exec -it nginx sh -c "kill -USR1 \$(cat /run/nginx.pid)"