 #!/bin/bash
cd $PWD
ROS_VER=jazzy
docker build . --build-arg "GIT_USERNAME=$1" --build-arg "GIT_USER_EMAIL=$2" -t simonemiche/ergocub_nav_base:ergocubSN001_$ROS_VER -f Dockerfile_$ROS_VER
