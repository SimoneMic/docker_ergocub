#!/bin/bash
NAME=lerobot_moge
TAG=latest
ROSBAGS_PATH=/home/ergocub/rosbags
SEMANTIC_MAPS_FOLDER=/usr/local/src/robot/hsp/semantic_maps

sudo xhost +
sudo docker run \
     --network=host --privileged \
     -it \
     --rm \
     --gpus all \
     -e DISPLAY=unix${DISPLAY} \
     --device /dev/dri/card0:/dev/dri/card0 \
     -v /tmp/.X11-unix:/tmp/.X11-unix \
     --ipc=host \
     --ulimit memlock=-1 \
     --ulimit stack=67108864 \
     -v ./config/cyclonedds.xml:/home/user1/cyclonedds.xml \
     -e CYCLONEDDS_URI=/home/user1/cyclonedds.xml \
     -v ./config/yarp.conf:/home/user1/.config/yarp/yarp.conf \
     -v $SEMANTIC_MAPS_FOLDER:/home/user1/semantic_maps \
     -v ${ROSBAGS_PATH}:/home/user1/rosbags \
     ${NAME}:${TAG} bash
