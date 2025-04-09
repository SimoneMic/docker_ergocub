#!/bin/bash
NAME=simonemiche/ergocub_nav_base
TAG=ergocubSN002     

sudo xhost +

if [ -z "$YARP_ROBOT_NAME" ]; then
    echo "YARP_ROBOT_NAME is not set or is empty. Please "
    exit 1
else
    echo "Launching docker for robot: $YARP_ROBOT_NAME"
fi

CYCLONE_PATH=""
YARP_CONF_PATH=""

if [ "$YARP_ROBOT_NAME" == "ergoCubSN000" ]; then
    CYCLONE_PATH=./config/cyclonedds_ergoCubSN000.xml
    YARP_CONF_PATH=./config/yarp_ergoCubSN000.conf
    TAG=ergocubSN000
elif [ "$YARP_ROBOT_NAME" == "ergoCubSN001" ]; then
    CYCLONE_PATH=./config/cyclonedds_ergoCubSN001.xml
    YARP_CONF_PATH=./config/yarp_ergoCubSN001.conf
    TAG=ergocubSN001
elif [ "$YARP_ROBOT_NAME" == "ergoCubSN002" ]; then
    CYCLONE_PATH=./config/cyclonedds_ergoCubSN002.xml
    YARP_CONF_PATH=./config/yarp_ergoCubSN002.conf
    TAG=ergocubSN002
else
     echo "Unknown robot name: $YARP_ROBOT_NAME exiting..."
     exit 1
fi

sudo docker run \
     --network=host --privileged \
     -it \
     --rm \
     -e DISPLAY=unix${DISPLAY} \
     --device /dev/dri/card0:/dev/dri/card0 \
     -v /tmp/.X11-unix:/tmp/.X11-unix \
     -v $YARP_CONF_PATH:/home/ecub_docker/.config/yarp/yarp.conf \
     -v $CYCLONE_PATH:/home/ecub_docker/cyclonedds.xml \
     ${NAME}:${TAG} bash
