#!/bin/bash
NAME=simonemiche/ergocub_nav_base

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
    TAG=ergocubSN001_jazzy
elif [ "$YARP_ROBOT_NAME" == "ergoCubSN002" ]; then
    CYCLONE_PATH=./config/cyclonedds_ergoCubSN002.xml
    YARP_CONF_PATH=./config/yarp_ergoCubSN002.conf
    TAG=ergocubSN002
else
     echo "Unknown robot name: $YARP_ROBOT_NAME exiting..."
     exit 1
fi

CONTAINER_NAME="ecub_docker"
IMAGE_NAME=${NAME}:${TAG}
CONTAINER_USER="ecub_docker"

echo "Running container with image: ${IMAGE_NAME}"

# create container
sudo docker run --rm\
     --network=host \
     --privileged \
     -it \
     -e DISPLAY=unix${DISPLAY} \
     --device /dev/dri/card0:/dev/dri/card0 \
     -v /tmp/.X11-unix:/tmp/.X11-unix \
     -v $YARP_CONF_PATH:/home/ecub_docker/.config/yarp/yarp.conf \
     -v $CYCLONE_PATH:/home/ecub_docker/cyclonedds.xml \
     -e YARP_ROBOT_NAME=${YARP_ROBOT_NAME} \
     -v /media/ergocub/OS/rosbags:/home/ecub_docker/rosbags \
     ${IMAGE_NAME}
    bash
