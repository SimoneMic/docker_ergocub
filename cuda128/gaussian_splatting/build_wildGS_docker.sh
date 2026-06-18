#!/bin/bash
cd $PWD
docker build . --build-arg "GIT_USERNAME=$1" --build-arg "GIT_USER_EMAIL=$2" -t wild_gs_slam:latest -f Dockerfile_wildGS
