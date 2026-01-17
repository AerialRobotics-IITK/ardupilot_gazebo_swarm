#!/usr/bin/env bash

# --- CONFIGURATION ---
N_DRONES=3   # <--- Set to 3 as requested
GZ_AP_PATH=$HOME/ardupilot_gazebo
ROOTDIR=$HOME/ardupilot

# 1. SETUP ENVIRONMENT
export GZ_SIM_SYSTEM_PLUGIN_PATH=$GZ_AP_PATH/build:$GZ_SIM_SYSTEM_PLUGIN_PATH
export GZ_SIM_RESOURCE_PATH=$GZ_AP_PATH/models:$GZ_AP_PATH/worlds:$GZ_SIM_RESOURCE_PATH

# 2. GENERATE WORLD
echo "Generating world for $N_DRONES drones..."
python3 gen_world.py $N_DRONES

# 3. CLEANUP OLD SESSIONS
echo "Cleaning up old processes..."
pkill -f arducopter
pkill -f gz
pkill -f mavproxy
sleep 2

# 4. START GAZEBO
echo "Starting Gazebo..."
# Running in background, sending logs to /dev/null to keep terminal clean
gz sim -v4 -r generated_swarm.sdf > /dev/null 2>&1 &
GZ_PID=$!
sleep 5

# 5. START ARDUPILOT SWARM LOOP
COPTER=$ROOTDIR/build/sitl/bin/arducopter
DEFAULTS="$ROOTDIR/Tools/autotest/default_params/copter.parm"

# Loop from 0 to N-1
for (( i=0; i<N_DRONES; i++ ))
do
    SYSID=$((i + 1))
    INSTANCE=$i
    
    # Calculate Standard SITL TCP Port (5760, 5770, 5780...)
    TCP_PORT=$((5760 + i * 10))

    echo "Preparing Drone $i (SYSID $SYSID) on Port $TCP_PORT..."

    # Define unique parameters for this specific drone
    mkdir -p swarm_sim/drone_$i
    PARAM_FILE="swarm_sim/drone_$i/params.parm"
    LOG_FILE="swarm_sim/drone_$i/copter.log"

    if [ $i -eq 0 ]; then
        # --- LEADER (Drone 0) ---
        echo "SYSID_THISMAV $SYSID" > $PARAM_FILE
    else
        # --- FOLLOWER (Drone 1..N) ---
        OFFSET_Y=$((i * 3)) 
        cat <<EOF > $PARAM_FILE
SYSID_THISMAV $SYSID
FOLL_ENABLE 1
FOLL_SYSID 1
FOLL_DIST_MAX 1000
FOLL_OFS_X -5
FOLL_OFS_Y $OFFSET_Y
FOLL_OFS_TYPE 1
EOF
    fi

    # LAUNCH SEPARATE TERMINAL FOR EACH DRONE
    # We use --serial0 tcp:0 to ensure the GCS port (5760+i*10) is open.
    # We use --serial1 mcast: for swarm comms.
    gnome-terminal --tab --title="Drone $i GCS" -- bash -c "
        echo '----------------------------------------';
        echo 'DRONE $i (SYSID $SYSID) INITIALIZING...';
        echo '----------------------------------------';
        
        # Start ArduCopter in background
        $COPTER \
            --model JSON \
            --serial0 tcp:0 \
            --serial1 mcast: \
            --defaults $DEFAULTS,$PARAM_FILE \
            -I$INSTANCE \
            --sysid $SYSID > $LOG_FILE 2>&1 &
        COPTER_PID=\$!
        
        echo 'ArduCopter PID: '\$COPTER_PID;
        echo 'Waiting for TCP port $TCP_PORT to open...';

        # Wait loop: Check if port is listening (requires netcat/nc)
        # If you don't have nc, just use 'sleep 5'
        while ! nc -z localhost $TCP_PORT; do   
          sleep 0.5
        done
        
        echo 'Port $TCP_PORT is open! Starting MAVProxy...';
        sleep 1; 

        # Start MAVProxy
        mavproxy.py --master=tcp:127.0.0.1:$TCP_PORT --console --map --aircraft=Drone$i;
        
        # Cleanup when MAVProxy exits
        echo 'MAVProxy closed. Killing ArduCopter...';
        kill \$COPTER_PID
        "
        
    sleep 1
done

echo "Swarm launched! Separate GCS terminals have been spawned."
echo "Press Enter here to kill the Simulation (Gazebo)..."
read
kill $GZ_PID
pkill -f arducopter
pkill -f mavproxy
