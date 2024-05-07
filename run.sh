#!/bin/bash
NAME=simonemiche/ergocub_nav_base
TAG=ergocubSN002     

sudo xhost +
sudo docker run \
     --network=host --privileged \
     -it \
     --rm \
     -e DISPLAY=unix${DISPLAY} \
     --device /dev/dri/card0:/dev/dri/card0 \
     -v /tmp/.X11-unix:/tmp/.X11-unix \
     -v ./config/yarp.conf:/home/ecub_docker/.config/yarp/yarp.conf \
     -v ./config/cyclonedds.xml:/home/ecub_docker/cyclonedds.xml \
     ${NAME}:${TAG} bash
