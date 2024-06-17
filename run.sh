#!/bin/bash
NAME=simonemiche/vlm_navigation
TAG=vlmaps

sudo xhost +
sudo docker run \
     --network=host --privileged \
     -it \
     --rm \
     --gpus all \
     -e DISPLAY=unix${DISPLAY} \
     --device /dev/dri/card0:/dev/dri/card0 \
     -v /tmp/.X11-unix:/tmp/.X11-unix \
     ${NAME}:${TAG} bash

     #-v /home/simomic/rosbag2_2024_01_11-16_35_16:/home/ecub_docker/rosbags \
