from docker.io/ros:humble

# Zenoh
env RMW_IMPLEMENTATION=rmw_zenoh_cpp
run apt-get update && apt-get install -y ros-${ROS_DISTRO}-rmw-zenoh-cpp

# ArduPilot Gazebo
run apt-get update && apt-get install -y curl lsb-release gnupg
run curl https://packages.osrfoundation.org/gazebo.gpg --output /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg
run echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] https://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null
run apt-get update && apt-get install -y gz-harmonic
run apt-get update && apt-get install -y libgz-sim8-dev rapidjson-dev
run apt-get update && apt-get install -y libopencv-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-gl

run apt-get install -y ros-humble-ros-gzharmonic-bridge
ARG USER_NAME=gazebo
ARG USER_UID=1000
ARG USER_GID=1000

RUN groupadd ${USER_NAME} --gid ${USER_GID}\
    && useradd -l -m ${USER_NAME} -u ${USER_UID} -g ${USER_GID} -s /bin/bash

run mkdir -p /ardupilot_gazebo
workdir /ardupilot_gazebo
copy . .
run chmod +x /ardupilot_gazebo/build.sh
run ./build.sh

RUN chown -R ${USER_NAME}:${USER_NAME} /ardupilot_gazebo
USER ${USER_NAME}
env GZ_SIM_SYSTEM_PLUGIN_PATH=/ardupilot_gazebo/build
env GZ_SIM_RESOURCE_PATH=/ardupilot_gazebo/models:/ardupilot_gazebo/worlds
cmd [ "bash" ]

