#!/bin/bash -e

if [[ -e /config ]] ; then
    . /config
fi

if [[ -z "${SPECTRECOIN_RELEASE}" ]] ; then
    SPECTRECOIN_RELEASE=4.0.0
fi
if [[ -z "${GIT_COMMIT_SHORT}" ]] ; then
    GIT_COMMIT_SHORT=HEAD
fi
if [[ -z "${BLOCKCHAIN_ARCHIVE_VERSION}" ]] ; then
    BLOCKCHAIN_ARCHIVE_VERSION=2019-09-04
fi

# ============================================================================
# Install Spectrecoin binaries
wget https://github.com/spectrecoin/spectre/releases/download/${SPECTRECOIN_RELEASE}/Spectrecoin-${SPECTRECOIN_RELEASE}-${GIT_COMMIT_SHORT}-RaspberryPi-Buster.tgz -O Spectrecoin-RaspberryPi.tgz
tar xzf Spectrecoin-RaspberryPi.tgz

#install -v -o 1000 -g 1000 -m 744 usr/local/bin/spectrecoin     "${ROOTFS_DIR}/usr/local/bin/"
install -v -o 1000 -g 1000 -m 744 usr/local/bin/spectrecoind    "${ROOTFS_DIR}/usr/local/bin/"

rm -f /tmp/Spectrecoin-RaspberryPi.tgz
rm -rf usr/



# ============================================================================
# Install Spectrecoin service
install -m 644 files/spectrecoind.service	"${ROOTFS_DIR}/lib/systemd/system/"
on_chroot << EOF
systemctl enable spectrecoind
EOF



# ============================================================================
# Bootstrap blockchain
wget https://github.com/spectrecoin/spectre/releases/download/${SPECTRECOIN_RELEASE}/Spectrecoin-Blockchain-v3-${BLOCKCHAIN_ARCHIVE_VERSION}.zip -O Spectrecoin-Blockchain.zip

mkdir Spectrecoin-Blockchain
unzip Spectrecoin-Blockchain.zip -d Spectrecoin-Blockchain/

install -d -o 1000 -g 1000 -m 755 "${ROOTFS_DIR}/home/pi/.spectrecoin/"
install -d -o 1000 -g 1000 -m 755 "${ROOTFS_DIR}/home/pi/.spectrecoin/txleveldb/"

install -v -o 1000 -g 1000 -m 600 Spectrecoin-Blockchain/txleveldb/*0.ldb      "${ROOTFS_DIR}/home/pi/.spectrecoin/txleveldb/"
install -v -o 1000 -g 1000 -m 600 Spectrecoin-Blockchain/txleveldb/*1.ldb      "${ROOTFS_DIR}/home/pi/.spectrecoin/txleveldb/"
install -v -o 1000 -g 1000 -m 600 Spectrecoin-Blockchain/txleveldb/*2.ldb      "${ROOTFS_DIR}/home/pi/.spectrecoin/txleveldb/"
install -v -o 1000 -g 1000 -m 600 Spectrecoin-Blockchain/txleveldb/*3.ldb      "${ROOTFS_DIR}/home/pi/.spectrecoin/txleveldb/"
install -v -o 1000 -g 1000 -m 600 Spectrecoin-Blockchain/txleveldb/*4.ldb      "${ROOTFS_DIR}/home/pi/.spectrecoin/txleveldb/"
install -v -o 1000 -g 1000 -m 600 Spectrecoin-Blockchain/txleveldb/*5.ldb      "${ROOTFS_DIR}/home/pi/.spectrecoin/txleveldb/"
install -v -o 1000 -g 1000 -m 600 Spectrecoin-Blockchain/txleveldb/*6.ldb      "${ROOTFS_DIR}/home/pi/.spectrecoin/txleveldb/"
install -v -o 1000 -g 1000 -m 600 Spectrecoin-Blockchain/txleveldb/*7.ldb      "${ROOTFS_DIR}/home/pi/.spectrecoin/txleveldb/"
install -v -o 1000 -g 1000 -m 600 Spectrecoin-Blockchain/txleveldb/*8.ldb      "${ROOTFS_DIR}/home/pi/.spectrecoin/txleveldb/"
install -v -o 1000 -g 1000 -m 600 Spectrecoin-Blockchain/txleveldb/*9.ldb      "${ROOTFS_DIR}/home/pi/.spectrecoin/txleveldb/"
install -v -o 1000 -g 1000 -m 600 Spectrecoin-Blockchain/txleveldb/CURRENT     "${ROOTFS_DIR}/home/pi/.spectrecoin/txleveldb/"
install -v -o 1000 -g 1000 -m 600 Spectrecoin-Blockchain/txleveldb/MANIFEST*   "${ROOTFS_DIR}/home/pi/.spectrecoin/txleveldb/"
install -v -o 1000 -g 1000 -m 600 Spectrecoin-Blockchain/blk0001.dat           "${ROOTFS_DIR}/home/pi/.spectrecoin/"

rm -rf Spectrecoin-Blockchain*



# ============================================================================
# Install Spectrecoin-RPC-UI
on_chroot << EOF
cd "/home/pi/"

git clone https://github.com/spectrecoin/spectrecoin-sh-rpc-ui.git
chown -R 1000:1000 spectrecoin-sh-rpc-ui

# Use config from RPC-UI also on wallet
cp spectrecoin-sh-rpc-ui/sample_config_daemon/spectrecoin.conf  .spectrecoin/
chown 1000:1000 .spectrecoin/spectrecoin.conf
EOF



# ============================================================================
# Define aliases:
# - 'ui' for the Spectrecoin-Shell-UI
# - 'update-ui' to update the Shell-UI
# - 'wallet-start' to start daemon
# - 'wallet-stop' to stop daemon
# - 'wallet-status' to show daemon status
echo "alias ui='/home/pi/spectrecoin-sh-rpc-ui/spectrecoin_rpc_ui.sh'"                           > bash_aliases
echo "alias update-ui='cd ~/spectrecoin-sh-rpc-ui ; git reset --hard HEAD ; git pull ; cd -'"   >> bash_aliases
echo "alias wallet-start='sudo service spectrecoind start'"                                     >> bash_aliases
echo "alias wallet-stop='sudo service spectrecoind stop'"                                       >> bash_aliases
echo "alias wallet-status='sudo service spectrecoind status'"                                   >> bash_aliases
install -v -o 1000 -g 1000 -m 644 bash_aliases                            "${ROOTFS_DIR}/home/pi/.bash_aliases"
rm -f bash_aliases



# ============================================================================
# Disable swapping
on_chroot << EOF
dphys-swapfile swapoff && dphys-swapfile uninstall && systemctl disable dphys-swapfile
EOF



# ============================================================================
# Activate ssh,
# see https://www.raspberrypi.org/documentation/remote-access/ssh/
touch ssh
install -v ssh "${ROOTFS_DIR}/boot/"
rm -f ssh



# ============================================================================
# Add Tor repository and install it
torRepoBuster="deb https://deb.torproject.org/torproject.org buster main"
echo "${torRepo}" > tor_repo
install -v -o 0 -g 0 -m 644 tor_repo "${ROOTFS_DIR}/etc/apt/sources.list.d/tor.list"
rm -f tor_repo
on_chroot << EOF
apt-get update -y
apt-get install -y tor
apt-get clean
EOF
