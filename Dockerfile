# syntax=docker/dockerfile:1
FROM ubuntu:22.04

ARG RELEASE

ARG LAUNCHPAD_BUILD_ARCH


CMD ["/bin/bash"]

# Linux stuff
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends libxau6 libxau6:i386 libxdmcp6 libxdmcp6:i386  libxcb1 libxcb1:i386 libxext6 libxext6:i386 libx11-6 libx11-6:i386 && rm -rf /var/lib/apt/lists/*

# Nvidia Graphics
ENV NVIDIA_VISIBLE_DEVICES  ${NVIDIA_VISIBLE_DEVICES:-all}

ENV NVIDIA_DRIVER_CAPABILITIES ${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}graphics,compat32,utility

RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf &&     echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV LD_LIBRARY_PATH /usr/lib/x86_64-linux-gnu:/usr/lib/i386-linux-gnu${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}:/usr/local/nvidia/lib:/usr/local/nvidia/lib64

RUN apt-get update  && apt-get install -y --no-install-recommends         pkg-config         libglvnd-dev libglvnd-dev:i386         libgl1-mesa-dev libgl1-mesa-dev:i386         libegl1-mesa-dev libegl1-mesa-dev:i386         libgles2-mesa-dev libgles2-mesa-dev:i386 &&     rm -rf /var/lib/apt/lists/*

ARG DEBIAN_FRONTEND=noninteractive

# Essentials pkgs setup
RUN apt-get update  && apt-get install -y build-essential         cmake         cppcheck         curl         doxygen         gdb         git         gnupg2         libbluetooth-dev         libcwiid-dev         libgoogle-glog-dev         libspnav-dev         libusb-dev         locales         lsb-release         mercurial         python3-dbg         python3-empy         python3-numpy         python3-pip         python3-psutil         python3-venv         software-properties-common         sudo         tzdata         vim         wget         curl	 tmux   psmisc  firefox && \
   sudo add-apt-repository ppa:gnome-terminator && sudo apt install -y terminator && \
   apt-get clean

# Xorg setup
RUN apt update && \
    apt install -y xfce4 xfce4-goodies xserver-xorg-video-dummy xserver-xorg-legacy && \
    sed -i 's/allowed_users=console/allowed_users=anybody/' /etc/X11/Xwrapper.config
COPY ./xorg.conf /etc/X11/xorg.conf
# Latest x11vnc
RUN sed -Ei 's/^# deb-src /deb-src /' /etc/apt/sources.list && \
    apt update && \
    git clone https://github.com/LibVNC/x11vnc.git /opt/x11vnc && \
    cd /opt/x11vnc && \
    apt build-dep -y x11vnc && \
    autoreconf -fiv && \
    ./configure && \
    make -j && \
    make install && \
    rm /opt/x11vnc -Rf

# ROS2 preparation
RUN locale-gen en_US en_US.UTF-8 &&   update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 &&   export LANG=en_US.UTF-8 && \
    curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null


# ROS2 install
RUN apt-get update  && apt-get install -y     python3-rosdep     python3-vcstool     python3-colcon-common-extensions     python3-colcon-mixin     ros-humble-control-msgs     ros-humble-controller-manager     ros-humble-desktop     ros-humble-generate-parameter-library     ros-humble-geometric-shapes     ros-humble-gripper-controllers     ros-humble-joint-state-broadcaster     ros-humble-joint-state-publisher     ros-humble-joint-trajectory-controller     ros-humble-moveit-common     ros-humble-moveit-configs-utils     ros-humble-moveit-core     ros-humble-moveit-hybrid-planning     ros-humble-moveit-msgs     ros-humble-moveit-resources-panda-moveit-config     ros-humble-moveit-ros-move-group     ros-humble-moveit-ros-perception     ros-humble-moveit-ros-planning     ros-humble-moveit-ros-planning-interface     ros-humble-moveit-ros-visualization     ros-humble-moveit-servo     ros-humble-moveit-visual-tools     ros-humble-moveit     ros-humble-rmw-cyclonedds-cpp     ros-humble-ros2-control     ros-humble-rviz-visual-tools     ros-humble-xacro   ros-humble-test-msgs  && apt-get clean

ENV ROS_DISTRO=humble

#USER root 

RUN useradd -l -u 33334 -G sudo -md /home/ecub_docker -s /bin/bash -p ecub_docker ecub_docker &&     sed -i.bkp -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers

ENV USERNAME ecub_docker

USER $USERNAME

WORKDIR /home/$USERNAME

RUN sudo rosdep init && rosdep update

RUN colcon mixin add default https://raw.githubusercontent.com/colcon/colcon-mixin-repository/master/index.yaml && colcon mixin update default && rm -rf log

RUN sudo apt install software-properties-common apt-transport-https wget -y

RUN wget -O- https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor | sudo tee /usr/share/keyrings/vscode.gpg

RUN echo deb [arch=amd64 signed-by=/usr/share/keyrings/vscode.gpg] https://packages.microsoft.com/repos/vscode stable main | sudo tee /etc/apt/sources.list.d/vscode.list

RUN sudo apt update

RUN sudo apt install -y code

# Git Setup
ARG GIT_USERNAME
ARG GIT_USER_EMAIL
RUN git config --global user.name ${GIT_USERNAME} && git config --global user.email ${GIT_USER_EMAIL}

### Robotology Superbuild Install Section
ARG BUILD_TYPE=Release

# YARP Standalone dep
RUN git clone https://github.com/robotology/ycm.git -b master && \
    cd ycm && mkdir build && cd build &&     cmake ..     -DCMAKE_BUILD_TYPE=$BUILD_TYPE &&     make -j4 &&     sudo make install

RUN sudo apt-get install -y build-essential git cmake cmake-curses-gui \
  ycm-cmake-modules \
  libeigen3-dev \
  libace-dev \
  libedit-dev \
  libsqlite3-dev \
  libtinyxml-dev \
  qtbase5-dev qtdeclarative5-dev qtmultimedia5-dev \
  qml-module-qtquick2 qml-module-qtquick-window2 \
  qml-module-qtmultimedia qml-module-qtquick-dialogs \
  qml-module-qtquick-controls qml-module-qt-labs-folderlistmodel \
  qml-module-qt-labs-settings \
  libqcustomplot-dev \
  libgraphviz-dev \
  libjpeg-dev \
  gedit \
  libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
  gstreamer1.0-plugins-base \
  gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-bad \
  gstreamer1.0-libav

# YARP Standalone
RUN git clone https://github.com/robotology/yarp.git -b master && \
    cd yarp && mkdir build && cd build &&     cmake ..     -DCMAKE_BUILD_TYPE=$BUILD_TYPE     -DYARP_COMPILE_libYARP_math=ON     -DYARP_COMPILE_GUIS=ON     -DYARP_COMPILE_DEVICE_PLUGINS=ON     -DENABLE_yarpcar_mjpeg=ON     -DENABLE_yarpcar_depthimage=ON     -DENABLE_yarpcar_depthimage2=ON     -DENABLE_yarpcar_segmentationimage=ON     -DENABLE_yarpcar_portmonitor=ON     -DENABLE_yarpmod_fakeAnalogSensor=ON     -DENABLE_yarpmod_fakeBattery=ON      -DENABLE_yarpmod_fakeDepthCamera=ON     -DENABLE_yarpmod_fakeIMU=ON      -DENABLE_yarpmod_fakeLaser=ON      -DENABLE_yarpmod_fakeLocalizer=ON     -DENABLE_yarpmod_fakeMicrophone=ON      -DENABLE_yarpmod_fakeMotionControl=ON      -DENABLE_yarpmod_fakeNavigation=ON      -DENABLE_yarpmod_fakeSpeaker=ON      -DENABLE_yarpmod_fakebot=ON     -DENABLE_yarpmod_portaudioPlayer=ON     -DENABLE_yarpmod_portaudioRecorder=ON     -DENABLE_yarpmod_laserFromDepth=ON     -DENABLE_yarpmod_laserFromExternalPort=ON     -DENABLE_yarpmod_laserFromDepth=ON     -DENABLE_yarpmod_laserFromPointCloud=ON     -DENABLE_yarpmod_laserFromRosTopic=ON     -DENABLE_yarpmod_rpLidar3=ON  &&     make -j4 &&     sudo make install


RUN sudo ln -s /usr/local/share/bash-completion/completions/yarp /usr/share/bash-completion/completions && \
    sudo apt install -y glpk-doc glpk-utils libglpk-dev libglpk40

# Superbuild cloning and installing
RUN git clone https://github.com/robotology/robotology-superbuild && \
    sudo chmod +x robotology-superbuild/scripts/install_apt_dependencies.sh && \
    sudo bash ./robotology-superbuild/scripts/install_apt_dependencies.sh

RUN cd robotology-superbuild && mkdir build && cd build && \
    export OpenCV_DIR=/usr/lib/x86_64-linux-gnu/cmake/opencv4 && cmake -DROBOTOLOGY_ENABLE_CORE=OFF -DROBOTOLOGY_ENABLE_DYNAMICS=ON -DROBOTOLOGY_ENABLE_DYNAMICS_FULL_DEPS=ON .. && \
    make -j8 && make install -j8

# Gazebo
RUN curl -sSL http://get.gazebosim.org | sh

# Gazebo Yarp Plugins
RUN git clone https://github.com/robotology/gazebo-yarp-plugins.git && cd gazebo-yarp-plugins && mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE="Release "../ -DCMAKE_INSTALL_PREFIX=/home/$USERNAME/robotology-superbuild/build/install .. && \
    cmake --build . --target install
    

# ergocub-software install
RUN git clone https://github.com/SimoneMic/ergocub-software.git && cd ergocub-software && git switch wip-SimoneMic-ros2-default && \
    mkdir build && cd build && cmake -DCMAKE_INSTALL_PREFIX=/home/$USERNAME/robotology-superbuild/build/install .. && make -j8 && make install

# Environment setup for simulation
ENV YARP_COLORED_OUTPUT=1
ENV WalkingControllers_INSTALL_DIR=/home/$USERNAME/robotology-superbuild/build/install
ENV YARP_DATA_DIRS=$YARP_DATA_DIRS:$WalkingControllers_INSTALL_DIR/share/yarp
ENV YARP_DATA_DIRS=${YARP_DATA_DIRS}:/home/$USERNAME/robotology-superbuild/build/install/share/iCub
ENV YARP_DATA_DIRS=${YARP_DATA_DIRS}:/home/$USERNAME/robotology-superbuild/build/install/share/ergoCub
ENV GAZEBO_MODEL_PATH=${GAZEBO_MODEL_PATH}:/home/$USERNAME/robotology-superbuild/build/install/share/iCub/robots:/home/$USERNAME/robotology-superbuild/build/install/share/ergoCub/robots
ENV GAZEBO_MODEL_PATH=${GAZEBO_MODEL_PATH}:/home/$USERNAME/robotology-superbuild/build/install/share
ENV YARP_DATA_DIRS=${YARP_DATA_DIRS}:/home/$USERNAME/robotology-superbuild/build/install/share/ICUBcontrib
ENV PATH=${PATH}:/home/$USERNAME/robotology-superbuild/build/install/bin
ENV GAZEBO_PLUGIN_PATH=${GAZEBO_PLUGIN_PATH}:/home/$USERNAME/robotology-superbuild/build/install/lib

# Bimanual
RUN git clone https://github.com/Woolfrey/ergocub-bimanual.git && cd ergocub-bimanual && mkdir build && cd build && \
    cmake .. && make -j

# Bashrc setup
RUN echo "export PATH=$PATH:/home/$USERNAME/robotology-superbuild/build/install/bin" >> ~/.bashrc && \
    echo "alias 0_yarpserver='yarpserver --write'" >> ~/.bashrc && \
    echo "alias 1_clock_export='export YARP_CLOCK=/clock'" >> ~/.bashrc && \
    echo "alias 2_gazebo='export YARP_CLOCK=/clock && gazebo -s libgazebo_yarp_clock.so -s libgazebo_ros_init.so'" >> ~/.bashrc && \
    echo "source /opt/ros/humble/setup.bash" >> /home/$USERNAME/.bashrc && \
    echo "source /home/$USERNAME/ros2_workspace/install/setup.bash" >> /home/$USERNAME/.bashrc

EXPOSE 8080
EXPOSE 8888
EXPOSE 6080
EXPOSE 10000/tcp 10000/udp


# Nav2
RUN sudo apt update && sudo apt install -y ros-humble-navigation2 ros-humble-nav2-bringup ros-humble-perception
# Adding ergocub_navigation on ROS2 WS
SHELL ["/bin/bash", "-c"]
RUN mkdir -p /home/$USERNAME/ros2_workspace/src && cd /home/$USERNAME/ros2_workspace && \
    /bin/bash -c "source /opt/ros/$ROS_DISTRO/setup.sh && colcon build"  && \
    cd src && \
    git clone https://github.com/SimoneMic/ergocub_navigation.git && \
    git clone https://github.com/SimoneMic/bt_nav2_ergocub.git && \
    cd .. && source /opt/ros/$ROS_DISTRO/setup.bash && colcon build --symlink-install --cmake-args -DCMAKE_CXX_FLAGS=-w
ENV AMENT_PREFIX_PATH=$AMENT_PREFIX_PATH:/opt/ros/humble
    
# Update walking-comtrollers in robotology superbuild to work in navigation
RUN cd robotology-superbuild/src/walking-controllers && git remote add SimoneMic https://github.com/SimoneMic/walking-controllers && \
    git fetch SimoneMic && \
    git checkout SimoneMic/ergoCub_SN000 && \
    cd ../../build/src/walking-controllers && make install -j
    
# Install VisualStudio Code extensions
RUN curl -fsSL https://code-server.dev/install.sh | sh &&code-server --install-extension ms-vscode.cpptools \
		--install-extension ms-vscode.cpptools-themes \
		--install-extension ms-vscode.cmake-tools \
                --install-extension ms-python.python \
                --install-extension eamodio.gitlens

# yarp-devices-ros2
CMD ["bash"]
ENV AMENT_PREFIX_PATH=$AMENT_PREFIX_PATH:/home/$USERNAME/robotology-superbuild/build/install
RUN git clone https://github.com/robotology/yarp-devices-ros2 && \
    cd yarp-devices-ros2/ros2_interfaces_ws && \
    source /opt/ros/humble/setup.sh && colcon build && \
    cd .. && mkdir build && cd build && /bin/bash -c "source /opt/ros/$ROS_DISTRO/setup.bash; source /home/$USERNAME/yarp-devices-ros2/ros2_interfaces_ws/install/setup.bash; cmake .. -DYARP_ROS2_USE_SYSTEM_map2d_nws_ros2_msgs=ON -DYARP_ROS2_USE_SYSTEM_yarp_control_msgs=ON; make -j11" && \
    echo "source /home/$USERNAME/yarp-devices-ros2/ros2_interfaces_ws/install/local_setup.bash" >> ~/.bashrc
    #cmake -S. -Bbuild -DCMAKE_INSTALL_PREFIX=/home/$USERNAME/robotology-superbuild/build/install -DBUILD_TESTING=OFF && \
    #cmake --build build && \
    #cmake --build build --target install
ENV YARP_DATA_DIRS=${YARP_DATA_DIRS}:/home/$USERNAME/yarp-devices-ros2/build/share/yarp:/home/$USERNAME/yarp-devices-ros2/build/share/yarp-devices-ros2   
#:/home/$USERNAME/robotology-superbuild/build/install/share/yarp-devices-ros2
RUN 

# Set Read and Write permissions to all home and robotology subfolders
#USER root
#RUN sudo chown -R $USERNAME:$USERNAME /home/$USERNAME/robotology-superbuild/ && echo '  ALL=(ALL) /bin/su' >>  /etc/sudoers && \
#	chown -R $USERNAME:$USERNAME /home/$USERNAME/ && echo 'ecub_docker  ALL=(ALL) /bin/su' >>  /etc/sudoers 
#USER $USERNAME
#RUN sudo chmod 777 /home/$USERNAME/robotology-superbuild

WORKDIR /home/$USERNAME

RUN sudo apt install -y mlocate && sudo apt clean && sudo rm -rf /var/lib/apt/lists/* && sudo updatedb

