#!/bin/bash

DOCKER_CONTAINER=ubuntu:latest

DESIRED_USER=$(whoami)
DOCKER_NAME="${DESIRED_USER}_shell"

DESIRED_UID=$(id -u $DESIRED_USER)
DESIRED_GID=$(id -g $DESIRED_USER)
HOMEDIR=$(eval echo ~$DESIRED_USER)
#MYHOSTNAME="$(hostname --fqdn)-${DESIRED_USER}-docker"
MYHOSTNAME="${DESIRED_USER}.bemban2u.com"
FQDN="${DESIRED_USER}.bemban2u.com"

# Create container if does not exist
id=$(docker ps -aq --no-trunc --filter name=^/${DOCKER_NAME}$)
if [ -z "$id" ]; then

find_ip () {
for i in {2..253}; do
  ping -c 1 172.28.0.$i >/dev/null;
  if [ $? -ne 0 ]; then
        echo "172.28.0.$i";
        break;
  fi;
 done
}

ip=$(find_ip)

FRPCCONF="${HOMEDIR}/frpc.ini"
cat <<EOT >> $FRPCCONF
[common]
server_addr = 148.251.225.99
server_port = 7000
log_file = /var/log/frpc.log
log_level = info
log_max_days = 3
privilege_token = bemban
token = bemban
user = $DESIRED_USER
admin_addr = 127.0.0.1
admin_port = 7400

[baota]
type = http
local_ip = $ip
local_port = 8888
custom_domains = $FQDN

[phpmyadmin]
type = tcp
local_ip = $ip
local_port = 888
remote_port = 888
custom_domains =  $FQDN

[http]
type = http
local_ip = $ip
local_port = 80
custom_domains =  $FQDN

[https]
type = https
local_ip = $ip
local_port = 443
custom_domains =  $FQDN

[ftp]
privilege_mode = true
type = tcp
remote_port = 21
local_ip = $ip
local_port = 21
custom_domains =  $FQDN

[20]
privilege_mode = true
type = tcp
remote_port = 20
local_ip = $ip
local_port = 20
custom_domains =  $FQDN

EOT

    # New docker
    docker run -d --hostname="$MYHOSTNAME" -v $HOMEDIR:$HOMEDIR:rw \
         --name="$DOCKER_NAME" \
	 --security-opt seccomp=unconfined \
         --cap-add SYS_ADMIN \
         --cap-add NET_ADMIN \
         -v /opt/frpc:/usr/bin/frpc:ro \
         -v $HOMEDIR/frpc.ini:/etc/frpc.ini:rw \
         --ip $ip \
         --dns 8.8.8.8 --dns 8.8.4.4 \
         --network netpool \
         "$DOCKER_CONTAINER" /init
fi

# Start the container (no matter if already running)
docker start "$DOCKER_NAME"

# Exec a shell in it
docker exec -it "$DOCKER_NAME" bash
