#!/bin/bash
NAME=elandini84/nlp_tools
TAG=gccpp_v2.22_llm_master

sudo xhost +
sudo docker run \
     --network=host --privileged \
     -it \
     --rm \
     -e DISPLAY=unix${DISPLAY} \
     --device /dev/dri/card0:/dev/dri/card0 \
     -v /tmp/.X11-unix:/tmp/.X11-unix \
     -v /usr/local/src/robot/hsp/docker_ergocub/config/yarp.conf:/home/yarp-user/.config/yarp/yarp.conf \
     -v /usr/local/src/robot/hsp/docker_ergocub/credentials/google-credential/hsp_google.json:/home/yarp-user/.config/google-credential/hsp_google.json \
     ${NAME}:${TAG} bash
