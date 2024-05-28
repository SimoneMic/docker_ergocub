#!/bin/bash
NAME=simonemiche/ergocub_nav_base
TAG=latest

sudo xhost +
sudo docker run \
     --network=host --privileged \
     -it \
     --rm \
     -e DISPLAY=unix${DISPLAY} \
     --device /dev/dri/card0:/dev/dri/card0 \
     -v /tmp/.X11-unix:/tmp/.X11-unix \
     ${NAME}:${TAG} bash

     #-v /home/simomic/rosbag2_2024_01_11-16_35_16:/home/ecub_docker/rosbags \
