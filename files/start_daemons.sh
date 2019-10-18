#!/bin/bash

service ssh start
#nohup dockerd &
nohup dockerd >&1>&2 &

while /bin/true; do
  sleep 60
done
