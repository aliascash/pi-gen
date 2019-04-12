#!/bin/bash -e
if [ -z "${SPECTRECOIN_RELEASE}" ] ; then
    SPECTRECOIN_RELEASE=3.0.7
fi
if [ -z "${GIT_COMMIT_SHORT}" ] ; then
    GIT_COMMIT_SHORT=HEAD
fi
if [ -z "${BLOCKCHAIN_ARCHIVE_VERSION}" ] ; then
    BLOCKCHAIN_ARCHIVE_VERSION=2019-04-08
fi
DIALOG_ARCHIVE_VERSION=1.3-20180621

# ============================================================================
# Install Spectrecoin binaries
wget https://github.com/spectrecoin/spectre/releases/download/${SPECTRECOIN_RELEASE}/Spectrecoin-${SPECTRECOIN_RELEASE}-${GIT_COMMIT_SHORT}-RaspberryPi.tgz -O Spectrecoin-RaspberryPi.tgz
tar xzf Spectrecoin-RaspberryPi.tgz

#install -v -o 1000 -g 1000 -m 744 usr/local/bin/spectrecoin     "${ROOTFS_DIR}/usr/local/bin/"
install -v -o 1000 -g 1000 -m 744 usr/local/bin/spectrecoind    "${ROOTFS_DIR}/usr/local/bin/"

rm -f /tmp/Spectrecoin-RaspberryPi.tgz
rm -rf usr/



# ============================================================================
# Install Spectrecoin init script
install -m 755 files/spectrecoind.sh	"${ROOTFS_DIR}/etc/init.d/spectrecoind"
install -m 644 files/spectrecoin.conf	"${ROOTFS_DIR}/usr/lib/tmpfiles.d/"
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
# Install prebuild dialog binaries
# Necessary as long as the official dialog package is outdated
wget https://github.com/spectrecoin/spectrecoin-sh-rpc-ui/releases/download/latest/Dialog-${DIALOG_ARCHIVE_VERSION}.tgz -O Dialog.tgz
tar xzf Dialog.tgz

install -v -o 1000 -g 1000 -m 755 usr/local/bin/dialog                "${ROOTFS_DIR}/usr/local/bin/"
install -v -o 1000 -g 1000 -m 644 usr/local/lib/libdialog.a           "${ROOTFS_DIR}/usr/local/lib/"
install -d -o 1000 -g 1000 -m 755                                     "${ROOTFS_DIR}/usr/local/share/man/man1/"
install -v -o 1000 -g 1000 -m 644 usr/local/share/man/man1/dialog.1   "${ROOTFS_DIR}/usr/local/share/man/man1/"

rm -f Dialog.tgz
rm -rf usr/

on_chroot << EOF
# Handle possible existing dialog
if [ -e /usr/bin/dialog ] ; then
    mv /usr/bin/dialog /usr/bin/dialog_
fi
if [ -e /usr/share/man/man1/dialog.1 ] ; then
    mv /usr/share/man/man1/dialog.1 /usr/share/man/man1/dialog.1_
fi

# Create links to new binary
ln -s /usr/local/bin/dialog              /usr/bin/dialog
ln -s /usr/local/share/man/man1/dialog.1 /usr/share/man/man1/dialog.1
EOF



# ============================================================================
# Install Spectrecoin-RPC-UI
git clone https://github.com/spectrecoin/spectrecoin-sh-rpc-ui.git

install -d -o 1000 -g 1000                                                      "${ROOTFS_DIR}/home/pi/spectrecoin-rpc-sh-ui"
install -d -o 1000 -g 1000                                                      "${ROOTFS_DIR}/home/pi/spectrecoin-rpc-sh-ui/include"
install -d -o 1000 -g 1000                                                      "${ROOTFS_DIR}/home/pi/spectrecoin-rpc-sh-ui/sample_config_daemon"
install -v -o 1000 -g 1000 -m 644 spectrecoin-sh-rpc-ui/include/*               "${ROOTFS_DIR}/home/pi/spectrecoin-rpc-sh-ui/include/"
install -v -o 1000 -g 1000 -m 644 spectrecoin-sh-rpc-ui/sample_config_daemon/*  "${ROOTFS_DIR}/home/pi/spectrecoin-rpc-sh-ui/sample_config_daemon"
install -v -o 1000 -g 1000 -m 644 spectrecoin-sh-rpc-ui/README.md               "${ROOTFS_DIR}/home/pi/spectrecoin-rpc-sh-ui/README.md"
install -v -o 1000 -g 1000 -m 755 spectrecoin-sh-rpc-ui/spectrecoin_rpc_ui.sh   "${ROOTFS_DIR}/home/pi/spectrecoin-rpc-sh-ui/spectrecoin_rpc_ui.sh"
install -v -o 1000 -g 1000 -m 644 spectrecoin-sh-rpc-ui/VERSION                 "${ROOTFS_DIR}/home/pi/spectrecoin-rpc-sh-ui/VERSION"

# Use config from RPC-UI also on wallet
install -v -o 1000 -g 1000 -m 644 spectrecoin-sh-rpc-ui/sample_config_daemon/spectrecoin.conf  "${ROOTFS_DIR}/home/pi/.spectrecoin/"

rm -rf spectrecoin-sh-rpc-ui/



# ============================================================================
# Define aliases:
# - 'ui' for the Spectrecoin-RPC-UI
# - 'wallet-start' to start daemon
# - 'wallet-stop' to stop daemon
# - 'wallet-status' to show daemon status
echo "alias ui='/home/pi/spectrecoin-rpc-sh-ui/spectrecoin_rpc_ui.sh'"   > bash_aliases
echo "alias wallet-start='sudo service spectrecoind start'"             >> bash_aliases
echo "alias wallet-stop='sudo service spectrecoind stop'"               >> bash_aliases
echo "alias wallet-status='sudo service spectrecoind status'"           >> bash_aliases
install -v -o 1000 -g 1000 -m 644 bash_aliases                          "${ROOTFS_DIR}/home/pi/.bash_aliases"
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
