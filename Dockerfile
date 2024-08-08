FROM nvidia/cuda:12.1.0-devel-ubuntu22.04

ARG RELEASE
ARG LAUNCHPAD_BUILD_ARCH
ENV USER=ergocub
ARG PASSWORD=ergocub

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

# # Installing python packages
# Can't use env.yml because cuda install asks to accept agreement
RUN sudo apt update && DEBIAN_FRONTEND=noninteractive sudo apt install ffmpeg libsm6 libxext6 -y

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

# VS code
RUN wget -O- https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor | sudo tee /usr/share/keyrings/vscode.gpg && \
    echo deb [arch=amd64 signed-by=/usr/share/keyrings/vscode.gpg] https://packages.microsoft.com/repos/vscode stable main | sudo tee /etc/apt/sources.list.d/vscode.list
RUN sudo apt update && sudo apt install -y code
# Install VisualStudio Code extensions
RUN code --install-extension ms-vscode.cpptools \
		--install-extension ms-vscode.cpptools-themes \
		--install-extension ms-vscode.cmake-tools \
                --install-extension ms-python.python \
                --install-extension eamodio.gitlens

# Git Setup
ARG GIT_USERNAME
ARG GIT_USER_EMAIL
RUN git config --global user.name ${GIT_USERNAME} && git config --global user.email ${GIT_USER_EMAIL}
# Installing VLMaps
RUN git clone https://github.com/SimoneMic/vlmaps.git
RUN sudo apt update && sudo apt install -y python3-pip
# Manually install requirements - we don't need all the requirements
RUN sudo apt update && sudo apt install python3-opencv python3-shapely -y
RUN pip3 install hydra-core gdown openai-clip torch torchvision h5py timm pyvisgraph pytorch_lightning
#shapely serve ma da problemi con numpy -> installato con apt?
RUN echo "export PYTHONPATH=$PYTHONPATH:/home/${USER}/vlmaps" >> /home/${USER}/.bashrc
RUN pip3 install matplotlib "numpy == 1.21.5"
RUN pip3 install open3d "numpy == 1.21.5"

ENV PYTHONPATH=$"${PYTHONPATH}:/home/${USER}/vlmaps"
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> /home/${USER}/.bashrc

# Clip backbone
RUN wget https://openaipublic.azureedge.net/clip/models/40d365715913c9da98579312b702a82c18be219cc2a73407c4526f58eba950af/ViT-B-32.pt && \
    mkdir ~/.cache/clip && mv ViT-B-32.pt ~/.cache/clip/ViT-B-32.pt

# Update repo
SHELL ["/bin/bash", "-c"]
RUN cd vlmaps && git pull && git switch feat-ros2 && cd vlmaps/lseg && mkdir checkpoints && cd && \
    cd vlmaps/ros2_vlmaps_interfaces && source /opt/ros/${ROS_DISTRO}/setup.bash && colcon build --symlink-install --cmake-args -DCMAKE_CXX_FLAGS=-w && \
    echo "source /home/${USER}/vlmaps/ros2_vlmaps_interfaces/install/local_setup.bash" >> /home/${USER}/.bashrc
# Set checkpoints
COPY ./demo_e200.ckpt /home/${USER}/vlmaps/vlmaps/lseg/checkpoints/demo_e200.ckpt
# Hugging Face Model
COPY ./download_hf_model.py /home/${USER}/download_hf_model.py
RUN python3 download_hf_model.py

#ENV CYCLONEDDS_URI=/home/${USER}/cyclonedds.xml

COPY ./generate_cyclone_config.sh /home/${USER}/generate_cyclone_config.sh
# Cleanup
RUN sudo apt update && sudo apt install -y iproute2 unzip terminator bash-completion gedit mlocate && sudo apt clean && sudo rm -rf /var/lib/apt/lists/* && sudo updatedb

CMD ["bash", "-c", ". generate_cyclone_config.sh"]
