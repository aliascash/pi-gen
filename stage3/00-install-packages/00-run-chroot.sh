#!/bin/bash -e
echo "deb http://ftp.debian.org/debian stretch-backports main" > /etc/apt/sources.list.d/stretch-backports.list

apt-get update -y
apt-get install -y --no-install-recommends \
    libboost-chrono1.67.0 \
    libboost-filesystem1.67.0 \
    libboost-program-options1.67.0 \
    libboost-thread1.67.0
