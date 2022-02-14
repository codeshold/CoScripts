#!/bin/bash
set -x

# GatewayPorts clientspecified

# ssh -p RELAY_SERVER_PORT root@RELAY_SERVER

function exec_ssh(){
    RELAY_SERVER=$1
    RELAY_SERVER_PORT=$2
    SSH_PORT=$3
    ssh -fN -o 'PubkeyAuthentication=yes' -o 'StrictHostKeyChecking=false' -o 'PasswordAuthentication=no' -o 'ServerAliveInterval 60' -o 'ServerAliveCountMax 3' -R ${RELAY_SERVER}:${RELAY_SERVER_PORT}:localhost:22 -p ${SSH_PORT} root@${RELAY_SERVER}
}


#### main ####
while true; do
    # digitocean
    (ps aux | grep "ssh -fN" | grep 120.201.15.48 | grep -qv grep) || exec_ssh 121.201.15.58 19911 8080
    # qingcloud
    (ps aux | grep "ssh -fN" | grep 120.201.15.58 | grep -qv grep) || exec_ssh 121.201.15.58 19911 22
    sleep 60
done
