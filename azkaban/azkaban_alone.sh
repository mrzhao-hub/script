#!/bin/bash

azkaban_port=8010

docker run -d --name azkaban_solo -p ${azkaban_port}:8081 gayakwad/azkaban-solo:3.40.0 

echo "===azkaban====azkaban"
