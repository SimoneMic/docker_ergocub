#!/bin/bash
NAME=simonemiche/ergocub_nav_base
TAG=ergocubSN001

sudo xhost +
YARP_CONF_PATH=""

if [ "$YARP_ROBOT_NAME" == "ergoCubSN000" ]; then
    YARP_CONF_PATH=./config/yarp_ergoCubSN000.conf
elif [ "$YARP_ROBOT_NAME" == "ergoCubSN001" ]; then
    CYCLONE_PATH=./config/cyclonedds_ergoCubSN001.xml
    YARP_CONF_PATH=./config/yarp_ergoCubSN001.conf
elif [ "$YARP_ROBOT_NAME" == "ergoCubSN002" ]; then
    CYCLONE_PATH=./config/cyclonedds_ergoCubSN002.xml
    YARP_CONF_PATH=./config/yarp_ergoCubSN002.conf
else
    YARP_CONF_PATH=./config/yarp.conf
fi

sudo docker run \
     --network=host --privileged \
     -it \
     --rm \
     -e DISPLAY=unix${DISPLAY} \
     --device /dev/dri/card0:/dev/dri/card0 \
     -v /tmp/.X11-unix:/tmp/.X11-unix \
     -v $YARP_CONF_PATH:/home/ecub_docker/.config/yarp/yarp.conf \
     -v ./config/cyclonedds.xml:/home/ecub_docker/cyclonedds.xml \
     ${NAME}:${TAG} bash
