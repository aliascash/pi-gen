#!/bin/bash -e
SPECTRECOIN_VERSION=v2.0.6

# Install Spectrecoin binaries
wget https://github.com/spectrecoin/spectre/releases/download/${SPECTRECOIN_VERSION}/Spectrecoin-${SPECTRECOIN_VERSION}-RaspberryPi.tgz
tar xzf Spectrecoin-${SPECTRECOIN_VERSION}-RaspberryPi.tgz

install -v -m 744 usr/local/bin/spectrecoin     "${ROOTFS_DIR}/usr/local/bin/"
install -v -m 744 usr/local/bin/spectrecoind    "${ROOTFS_DIR}/usr/local/bin/"

rm -f /tmp/Spectrecoin-${SPECTRECOIN_VERSION}-RaspberryPi.tgz
rm -rf usr/

# Install Spectrecoin-RPC-UI
git clone https://github.com/HLXEasy/spectre-rpc-sh-ui.git

install -d "${ROOTFS_DIR}/home/pi/spectrecoin-rpc-sh-ui/include"
install -d "${ROOTFS_DIR}/home/pi/spectrecoin-rpc-sh-ui/sample_config_daemon"
install -v -m 644 spectre-rpc-sh-ui/include/*               "${ROOTFS_DIR}/home/pi/spectrecoin-rpc-sh-ui/include/"
install -v -m 644 spectre-rpc-sh-ui/sample_config_daemon/*  "${ROOTFS_DIR}/home/pi/spectrecoin-rpc-sh-ui/sample_config_daemon"
install -v -m 644 spectre-rpc-sh-ui/readme.txt              "${ROOTFS_DIR}/home/pi/spectrecoin-rpc-sh-ui/readme.txt"
install -v -m 644 spectre-rpc-sh-ui/script.conf             "${ROOTFS_DIR}/home/pi/spectrecoin-rpc-sh-ui/script.conf"
install -v -m 744 spectre-rpc-sh-ui/spectre_rps_ui.sh       "${ROOTFS_DIR}/home/pi/spectrecoin-rpc-sh-ui/spectre_rps_ui.sh"

rm -rf spectre-rpc-sh-ui/
