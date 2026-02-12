#!/bin/bash
NAME=simonemiche/ergocub_nav_base
TAG=ergocubSN001     

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

CONTAINER_NAME="ecub_docker"
IMAGE_NAME=${NAME}:${TAG}
MACVLAN_NET="macvlan_net"
MACVLAN_PARENT="enp45s0"
CONTAINER_IP="10.0.2.50"
HOST_SSH_KEY="$HOME/.ssh/id_ed25519.pub"
CONTAINER_USER="ecub_docker"

# Generate ssh key
#if [ ! -f "${HOST_SSH_KEY}" ]; then
#    echo "SSH key not found, generating one..."
#    ssh-keygen -t ed25519 -f "${HOME}/.ssh/id_ed25519" -N "" -C "$CONTAINER_USER"
#fi
#echo "SSH key found: ${HOST_SSH_KEY}"

# Maclavan network for isolating the container with its own IP
#if ! docker network ls | grep -q "${MACVLAN_NET}"; then
#    echo "Creating macvlan network ${MACVLAN_NET}..."
#    docker network create -d macvlan \
#        --subnet=10.0.2.0/24 \
#        --gateway=10.0.2.1 \
#        -o parent=${MACVLAN_PARENT} \
#        ${MACVLAN_NET}
#fi

# create container
sudo docker run --rm\
     --name ${CONTAINER_NAME} \
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
#--ip ${CONTAINER_IP} \
#-v ${HOST_SSH_KEY}:/home/ecub_docker/.ssh/authorized_keys \