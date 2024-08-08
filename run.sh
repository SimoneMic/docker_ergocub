#!/bin/bash
NAME=simonemiche/vlm_navigation
TAG=vlmap_light
# Docker network config for local machine only
LOCAL_IP_="127.0.0.1"
REMOTE_IP_1="127.0.1.1"
ALLOW_MULTICAST=false

sudo xhost +
sudo docker run \
     --network=host --privileged \
     -it \
     --rm \
     --gpus all \
     -e DISPLAY=unix${DISPLAY} \
     --device /dev/dri/card0:/dev/dri/card0 \
     -v /tmp/.X11-unix:/tmp/.X11-unix \
     -e CYCLONE_LOCAL_IP=${LOCAL_IP_} \
     -e CYCLONE_REMOTE_IP=${REMOTE_IP_1} \
     -e CYCLONE_ALLOW_MULTICAST=${ALLOW_MULTICAST} \
     ${NAME}:${TAG} bash

     #-v /home/simomic/rosbag2_2024_01_11-16_35_16:/home/ecub_docker/rosbags \
