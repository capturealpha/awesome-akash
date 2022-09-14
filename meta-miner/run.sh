#!/bin/bash
echo "Checking CPU in pod"
if [ -f /sys/fs/cgroup/cpu/cpu.cfs_quota_us ]; then
CPU_COUNT=$(cat /sys/fs/cgroup/cpu/cpu.cfs_quota_us)
else
CPU_COUNT=$(cat /sys/fs/cgroup/cpu.max | awk '{print $1}')
fi
CPU_COUNT=$(echo "scale=0; $CPU_COUNT/100000" | bc -l) #Convert to Cores
echo "Found $CPU_COUNT cpus available."

echo "Checking Memory in pod"
if [ -f /sys/fs/cgroup/memory/memory.limit_in_bytes ]; then
MEMORY_SIZE=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)
else
MEMORY_SIZE=$(cat /sys/fs/cgroup/memory.max)
fi
MEMORY_SIZE=$(echo "scale=2; $MEMORY_SIZE/1024/1024/1024" | bc -l) #Convert to Gi

echo "Found $MEMORY_SIZE of memory available."

if [ -z $WALLET ]; then
    echo "Please examine the SDL and be sure to set your Monero Wallet Address in the WALLET= variable."
    sleep 300
    exit
fi

if [ -z $CPU_COUNT ]; then
    echo "Please examine the SDL and be sure to set the CPU_UNITS= variable equal to the cpu.units requested."
    sleep 300
    exit
fi

if [ -z $RANDOMX_MODE ]; then
    echo "Please examine the SDL and be sure to set the mode to fast or light in the MODE= variable."
    sleep 300
    exit
fi

if [ -z $MEMORY_SIZE ]; then
    echo "Please set MEMORY_SIZE equal to the memory requested.  This is required to determine if we can use randomx-mode fast or light."
    echo "You must close this deployment to change the memory requested."
    sleep 300
    exit
fi

echo "Checking for NUMA nodes"
if [[ $(lscpu | grep "NUMA" | head -n1 | awk '{print $3}') > 1 ]]; then

    echo "Got more than 1 NUMA node on this provider!  Ensuring you have set enough memory..."

    if [[ $RANDOMX_MODE == fast ]]; then
        NUMA_MIN_MEMORY=4.75
        #4416Mi

        if (($(echo "$MEMORY_SIZE >= $NUMA_MIN_MEMORY" | bc -l))); then
            echo "Found enough memory!"
        else
            echo "This provider has $(lscpu | grep "NUMA" | head -n1 | awk '{print $3}') NUMA nodes"
            echo "Increase the requested memory for this deployment to >= 4.75Gi"
            echo "You must close this deployment to change the memory requested."
            echo "------------------------------------------"
            echo "Deployment will continue in SLOW mode after 30 seconds, setting RANDOMX_MODE=light."
            sleep 30
            RANDOMX_MODE=light
        fi

    fi

    if [[ $RANDOMX_MODE == light ]]; then
        NUMA_MIN_MEMORY=0.1
        if (($(echo "$MEMORY_SIZE >= $NUMA_MIN_MEMORY" | bc -l))); then
            echo "Found enough memory!"
        else
            echo "This provider has $(lscpu | grep "NUMA" | head -n1 | awk '{print $3}') NUMA nodes"
            echo "Increase the requested memory for this deployment to >= 0.1Gi"
            echo "You must close this deployment to change the memory requested."
            sleep 300
            exit
        fi

    fi

else

    echo "Could not detect more than 1 NUMA node, assuming single NUMA and lowering memory limits."

    if [[ $RANDOMX_MODE == fast ]]; then
        NUMA_MIN_MEMORY=3
        #4416Mi

        if (($(echo "$MEMORY_SIZE >= $NUMA_MIN_MEMORY" | bc -l))); then
            echo "Found enough memory!"
        else
            echo "This provider has $(lscpu | grep "NUMA" | head -n1 | awk '{print $3}') NUMA nodes"
            echo "Increase the requested memory for this deployment to >= 3Gi"
            echo "You must close this deployment to change the memory requested."
            echo "If you don't want to close this deployment, please switch to RANDOMX_MODE=light and update the deployment."
            echo "------------------------------------------"
            echo "Deployment will continue in SLOW mode after 30 seconds, setting RANDOMX_MODE=light."
            sleep 30
            RANDOMX_MODE=light
        fi

    fi

    if [[ $RANDOMX_MODE == light ]]; then
        NUMA_MIN_MEMORY=0.1
        if (($(echo "$MEMORY_SIZE >= $NUMA_MIN_MEMORY" | bc -l))); then
            echo "Found enough memory!"
        else
            echo "This provider has $(lscpu | grep "NUMA" | head -n1 | awk '{print $3}') NUMA nodes"
            echo "Increase the requested memory for this deployment to >= 0.1Gi"
            echo "You must close this deployment to change the memory requested."
            sleep 300
            exit
        fi

    fi
fi

WORKER=$(echo ${WORKER}-${AKASH_CLUSTER_PUBLIC_HOSTNAME})
POOL="localhost:3333"
PASS=x

echo "Using POOL: ${POOL} WALLET: ${WALLET}  WORKER: ${WORKER}"
CUSTOM_OPTIONS=$(sed -e 's/^"//' -e 's/"$//' <<<"$CUSTOM_OPTIONS") #Remove quotes

#if [[ ${TLS_FINGERPRINT} != "" && ${TLS} == "true" ]]; then
#    ./xmrig -a ${ALGO} --url ${POOL} --user ${WALLET} --rig-id ${WORKER} --pass ${WORKER} --tls --tls-fingerprint ${TLS_FINGERPRINT} --http-host 0.0.0.0 --http-port 8080 --syslog --no-color --verbose --randomx-mode=$RANDOMX_MODE -t $CPU_COUNT --randomx-init=$CPU_COUNT $CUSTOM_OPTIONS
#if [[ ${TLS_FINGERPRINT} == "" && ${TLS} == "true" ]]; then



#./mm.js -p=gulf.moneroocean.stream:10001 -m="xmrig --url ${POOL} --user ${WALLET} --rig-id ${WORKER} --pass ${PASS} --http-host 0.0.0.0 --http-port 8080 --syslog --no-color --verbose --randomx-mode=$RANDOMX_MODE -t $CPU_COUNT --randomx-init=$CPU_COUNT $CUSTOM_OPTIONS"










#./xmrig -a ${ALGO} --url ${POOL} --user ${WALLET} --rig-id ${WORKER} --pass ${WORKER} --tls --http-host 0.0.0.0 --http-port 8080 --syslog --no-color --verbose --randomx-mode=$RANDOMX_MODE -t $CPU_COUNT --randomx-init=$CPU_COUNT $CUSTOM_OPTIONS
#else
#    ./xmrig -a ${ALGO} --url ${POOL} --user ${WALLET} --rig-id ${WORKER} --pass ${WORKER} --http-host 0.0.0.0 --http-port 8080 --syslog --no-color --verbose --randomx-mode=$RANDOMX_MODE -t $CPU_COUNT --randomx-init=$CPU_COUNT $CUSTOM_OPTIONS
#fi

./mm.js -p=gulf.moneroocean.stream:10001 -m="xmrig --config=/config.json"
