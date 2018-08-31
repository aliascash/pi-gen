#!/bin/bash -e
SPECTRECOIN_VERSION=v2.0.6

wget https://github.com/spectrecoin/spectre/releases/download/${SPECTRECOIN_VERSION}/Spectrecoin-${SPECTRECOIN_VERSION}-RaspberryPi.tgz
tar xzf Spectrecoin-${SPECTRECOIN_VERSION}-RaspberryPi.tgz

install -v -m 744 usr/local/bin/spectrecoin     "${ROOTFS_DIR}/usr/local/bin/"
install -v -m 744 usr/local/bin/spectrecoind    "${ROOTFS_DIR}/usr/local/bin/"

rm -f /tmp/Spectrecoin-${SPECTRECOIN_VERSION}-RaspberryPi.tgz
rm -rf usr/