#!/bin/bash
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo
make -j4
echo 'export GZ_SIM_SYSTEM_PLUGIN_PATH=/sim/ardupilot_gazebo/build:${GZ_SIM_SYSTEM_PLUGIN_PATH}' >> /root/.bashrc
echo 'export GZ_SIM_RESOURCE_PATH=/sim/ardupilot_gazebo/models:/sim/ardupilot_gazebo/worlds:${GZ_SIM_RESOURCE_PATH}' >> /root/.bashrc
