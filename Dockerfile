# syntax=docker/dockerfile:1
FROM nvidia/cuda:12.1.0-devel-ubuntu22.04

ARG RELEASE
ARG LAUNCHPAD_BUILD_ARCH
ENV USER=ergocub
ARG PASSWORD=ergocub

ARG CONDA_SCRIPT=Mambaforge-Linux-x86_64.sh
ARG CONDA_LINK=https://github.com/conda-forge/miniforge/releases/latest/download/${CONDA_SCRIPT}
ENV CONDA_MD5=aef279d6baea7f67940f16aad17ebe5f6aac97487c7c03466ff01f4819e5a651

ENV PYTHONDONTWRITEBYTECODE=true

RUN ln -fs /usr/share/zoneinfo/Europe/Rome /etc/localtime && \
    apt update &&\
    apt install --no-install-recommends -y -qq sudo git cmake && \
    rm -rf /var/lib/apt/lists/*

RUN addgroup ${USER} \
    && useradd -ms /bin/bash ${USER} -g ${USER} \
    && echo "${USER}:${PASSWORD}" | chpasswd \
    && usermod -a -G sudo ${USER} \
    && sed -i.bak -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers

USER ${USER}
WORKDIR /home/${USER}

# Installing mamba
RUN sudo apt-get update && sudo apt-get install -y --no-install-recommends wget bzip2 \
    && wget ${CONDA_LINK} \
    && bash ./${CONDA_SCRIPT} -b \
    && /home/${USER}/mambaforge/bin/mamba init bash \
    && sudo find /home/${USER}/mambaforge -follow -type f -name '*.a' -delete \
    && sudo find /home/${USER}/mambaforge -follow -type f -name '*.pyc' -delete \
    && /home/${USER}/mambaforge/bin/mamba clean -afy \
    && rm ${CONDA_SCRIPT}

# # Installing python packages
# Can't use env.yml because cuda install asks to accept agreement
RUN sudo apt update && DEBIAN_FRONTEND=noninteractive sudo apt install ffmpeg libsm6 libxext6 -y

# Installing VLMaps
RUN git clone https://github.com/SimoneMic/vlmaps.git
RUN /home/${USER}/mambaforge/bin/mamba create -n vlmaps python=3.8 -y  
#RUN echo "mamba activate vlmaps" >> /home/${USER}/.bashrc

RUN cd vlmaps && \
    /home/${USER}/mambaforge/envs/vlmaps/bin/pip install -r requirements.txt
RUN cd ~ &&\
    git clone --recursive https://github.com/cvg/Hierarchical-Localization/
RUN cd Hierarchical-Localization/ &&\
    /home/${USER}/mambaforge/envs/vlmaps/bin/pip install -e .
RUN /home/${USER}/mambaforge/bin/mamba run -n vlmaps /home/${USER}/mambaforge/bin/mamba install habitat-sim=0.2.2 -c conda-forge -c aihabitat -y

# ROS2 Install
ENV ROS_DISTRO=iron
RUN sudo apt update && sudo apt install -y locales && sudo locale-gen en_US en_US.UTF-8 \
    && sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    && export LANG=en_US.UTF-8
    
RUN sudo apt install software-properties-common -y\
    && sudo add-apt-repository universe \
    && sudo apt update && sudo apt install curl -y
    
RUN sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg 
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
    
RUN sudo apt update && sudo apt install ros-$ROS_DISTRO-ros-base \
    ros-$ROS_DISTRO-sensor-msgs ros-$ROS_DISTRO-geometry-msgs \
    ros-$ROS_DISTRO-action-msgs ros-$ROS_DISTRO-actionlib-msgs \
    ros-$ROS_DISTRO-nav2-msgs ros-$ROS_DISTRO-cv-bridge ros-$ROS_DISTRO-nav2-simple-commander ros-dev-tools -y

RUN sudo apt update && sudo apt install ros-$ROS_DISTRO-rmw-cyclonedds-cpp -y
ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> /home/${USER}/.bashrc

# Cleanup
RUN /home/${USER}/mambaforge/bin/mamba clean --all -y
RUN sudo apt update && sudo apt install -y unzip firefox terminator bash-completion gedit mlocate && sudo apt clean && sudo rm -rf /var/lib/apt/lists/* && sudo updatedb
RUN echo "mamba activate vlmaps" >> /home/${USER}/.bashrc
