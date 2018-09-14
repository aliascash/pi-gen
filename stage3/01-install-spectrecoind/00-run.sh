#!/bin/bash -e
SPECTRECOIN_VERSION=v2.0.7
#RASPI_ARCHIVE_VERSION=${SPECTRECOIN_VERSION}
RASPI_ARCHIVE_VERSION=v2.0.7
DIALOG_ARCHIVE_VERSION=1.3-20180621

# ============================================================================
# Install Spectrecoin binaries
wget https://github.com/spectrecoin/spectre/releases/download/${SPECTRECOIN_VERSION}/Spectrecoin-${RASPI_ARCHIVE_VERSION}-RaspberryPi.tgz
tar xzf Spectrecoin-${RASPI_ARCHIVE_VERSION}-RaspberryPi.tgz

#install -v -o 1000 -g 1000 -m 744 usr/local/bin/spectrecoin     "${ROOTFS_DIR}/usr/bin/"
install -v -o 1000 -g 1000 -m 744 usr/local/bin/spectrecoind    "${ROOTFS_DIR}/usr/bin/"

rm -f /tmp/Spectrecoin-${RASPI_ARCHIVE_VERSION}-RaspberryPi.tgz
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
git clone https://github.com/spectrecoin/spectrecoin-blockchain-bootstrap.git

install -d -o 1000 -g 1000 -m 755 "${ROOTFS_DIR}/home/pi/.spectrecoin/"
install -d -o 1000 -g 1000 -m 755 "${ROOTFS_DIR}/home/pi/.spectrecoin/txleveldb/"

install -v -o 1000 -g 1000 -m 600 spectrecoin-blockchain-bootstrap/data/txleveldb/*  "${ROOTFS_DIR}/home/pi/.spectrecoin/txleveldb/"
install -v -o 1000 -g 1000 -m 600 spectrecoin-blockchain-bootstrap/data/blk0001.dat  "${ROOTFS_DIR}/home/pi/.spectrecoin/"

rm -rf spectrecoin-blockchain-bootstrap



# ============================================================================
# Install prebuild dialog binaries
# Necessary as long as the official dialog package is outdated
wget https://github.com/spectrecoin/spectre-rpc-sh-ui/releases/download/latest/Dialog-${DIALOG_ARCHIVE_VERSION}.tgz
tar xzf Dialog-${DIALOG_ARCHIVE_VERSION}.tgz

install -v -o 1000 -g 1000 -m 755 usr/local/bin/dialog                "${ROOTFS_DIR}/usr/local/bin/"
install -v -o 1000 -g 1000 -m 644 usr/local/lib/libdialog.a           "${ROOTFS_DIR}/usr/local/lib/"
install -d -o 1000 -g 1000 -m 755                                     "${ROOTFS_DIR}/usr/local/share/man/man1/"
install -v -o 1000 -g 1000 -m 644 usr/local/share/man/man1/dialog.1   "${ROOTFS_DIR}/usr/local/share/man/man1/"

rm -f Dialog-${DIALOG_ARCHIVE_VERSION}.tgz
rm -rf usr/

on_chroot << EOF
ln -s /usr/local/bin/dialog              /usr/bin/dialog
ln -s /usr/local/share/man/man1/dialog.1 /usr/share/man/man1/dialog.1
EOF



# ============================================================================
# Install Spectrecoin-RPC-UI
git clone https://github.com/HLXEasy/spectre-rpc-sh-ui.git

install -d -o 1000 -g 1000                                                  "${ROOTFS_DIR}/home/pi/spectrecoin-rpc-sh-ui"
install -d -o 1000 -g 1000                                                  "${ROOTFS_DIR}/home/pi/spectrecoin-rpc-sh-ui/include"
install -d -o 1000 -g 1000                                                  "${ROOTFS_DIR}/home/pi/spectrecoin-rpc-sh-ui/sample_config_daemon"
install -v -o 1000 -g 1000 -m 644 spectre-rpc-sh-ui/include/*               "${ROOTFS_DIR}/home/pi/spectrecoin-rpc-sh-ui/include/"
install -v -o 1000 -g 1000 -m 644 spectre-rpc-sh-ui/sample_config_daemon/*  "${ROOTFS_DIR}/home/pi/spectrecoin-rpc-sh-ui/sample_config_daemon"
install -v -o 1000 -g 1000 -m 644 spectre-rpc-sh-ui/README.md               "${ROOTFS_DIR}/home/pi/spectrecoin-rpc-sh-ui/README.md"
install -v -o 1000 -g 1000 -m 755 spectre-rpc-sh-ui/spectrecoin_rpc_ui.sh   "${ROOTFS_DIR}/home/pi/spectrecoin-rpc-sh-ui/spectrecoin_rpc_ui.sh"
install -v -o 1000 -g 1000 -m 644 spectre-rpc-sh-ui/VERSION                 "${ROOTFS_DIR}/home/pi/spectrecoin-rpc-sh-ui/VERSION"

# Use config from RPC-UI also on wallet
install -v -o 1000 -g 1000 -m 644 spectre-rpc-sh-ui/sample_config_daemon/spectrecoin.conf  "${ROOTFS_DIR}/home/pi/.spectrecoin/"

rm -rf spectre-rpc-sh-ui/



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
