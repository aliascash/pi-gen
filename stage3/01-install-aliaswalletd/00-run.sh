#!/bin/bash -e

if [[ -e /config ]] ; then
    . /config
fi

if [[ -z "${ALIAS_RELEASE}" ]] ; then
    ALIAS_RELEASE=4.1.0
fi
if [[ -z "${GIT_COMMIT_SHORT}" ]] ; then
    GIT_COMMIT_SHORT=HEAD
fi



# ============================================================================
# Add Tor repository and install it
#torRepoBuster="deb https://deb.torproject.org/torproject.org buster main"
#echo "${torRepoBuster}" > tor_repo
#install -v -o 0 -g 0 -m 644 tor_repo "${ROOTFS_DIR}/etc/apt/sources.list.d/tor.list"
#rm -f tor_repo
#on_chroot << EOF
#curl --insecure https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --import
#gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | sudo apt-key add -
#apt-get update
#apt-get install -y tor deb.torproject.org-keyring
#apt-get clean
#EOF



# ============================================================================
# Install Aliaswallet binaries
wget https://github.com/aliascash/aliaswallet/releases/download/${ALIAS_RELEASE}/Aliaswallet-${ALIAS_RELEASE}-${GIT_COMMIT_SHORT}-RaspberryPi-Buster.tgz -O Aliaswallet-RaspberryPi.tgz
tar xzf Aliaswallet-RaspberryPi.tgz

#install -v -o 1000 -g 1000 -m 744 usr/local/bin/aliaswallet     "${ROOTFS_DIR}/usr/local/bin/"
install -v -o 1000 -g 1000 -m 744 usr/local/bin/aliaswalletd    "${ROOTFS_DIR}/usr/local/bin/"

rm -f /tmp/Aliaswallet-RaspberryPi.tgz
rm -rf usr/



# ============================================================================
# Install Aliaswallet service
install -m 644 files/aliaswalletd.service	"${ROOTFS_DIR}/lib/systemd/system/"
on_chroot << EOF
systemctl enable aliaswalletd
EOF



# ============================================================================
# Bootstrap blockchain
wget https://download.alias.cash/files/bootstrap/BootstrapChain.zip -O Aliaswallet-Blockchain.zip

mkdir Aliaswallet-Blockchain
unzip Aliaswallet-Blockchain.zip -d Aliaswallet-Blockchain/

install -d -o 1000 -g 1000 -m 755 "${ROOTFS_DIR}/home/pi/.aliaswallet/"
install -d -o 1000 -g 1000 -m 755 "${ROOTFS_DIR}/home/pi/.aliaswallet/txleveldb/"

install -v -o 1000 -g 1000 -m 600 Aliaswallet-Blockchain/txleveldb/*0.ldb      "${ROOTFS_DIR}/home/pi/.aliaswallet/txleveldb/"
install -v -o 1000 -g 1000 -m 600 Aliaswallet-Blockchain/txleveldb/*1.ldb      "${ROOTFS_DIR}/home/pi/.aliaswallet/txleveldb/"
install -v -o 1000 -g 1000 -m 600 Aliaswallet-Blockchain/txleveldb/*2.ldb      "${ROOTFS_DIR}/home/pi/.aliaswallet/txleveldb/"
install -v -o 1000 -g 1000 -m 600 Aliaswallet-Blockchain/txleveldb/*3.ldb      "${ROOTFS_DIR}/home/pi/.aliaswallet/txleveldb/"
install -v -o 1000 -g 1000 -m 600 Aliaswallet-Blockchain/txleveldb/*4.ldb      "${ROOTFS_DIR}/home/pi/.aliaswallet/txleveldb/"
install -v -o 1000 -g 1000 -m 600 Aliaswallet-Blockchain/txleveldb/*5.ldb      "${ROOTFS_DIR}/home/pi/.aliaswallet/txleveldb/"
install -v -o 1000 -g 1000 -m 600 Aliaswallet-Blockchain/txleveldb/*6.ldb      "${ROOTFS_DIR}/home/pi/.aliaswallet/txleveldb/"
install -v -o 1000 -g 1000 -m 600 Aliaswallet-Blockchain/txleveldb/*7.ldb      "${ROOTFS_DIR}/home/pi/.aliaswallet/txleveldb/"
install -v -o 1000 -g 1000 -m 600 Aliaswallet-Blockchain/txleveldb/*8.ldb      "${ROOTFS_DIR}/home/pi/.aliaswallet/txleveldb/"
install -v -o 1000 -g 1000 -m 600 Aliaswallet-Blockchain/txleveldb/*9.ldb      "${ROOTFS_DIR}/home/pi/.aliaswallet/txleveldb/"
install -v -o 1000 -g 1000 -m 600 Aliaswallet-Blockchain/txleveldb/CURRENT     "${ROOTFS_DIR}/home/pi/.aliaswallet/txleveldb/"
install -v -o 1000 -g 1000 -m 600 Aliaswallet-Blockchain/txleveldb/MANIFEST*   "${ROOTFS_DIR}/home/pi/.aliaswallet/txleveldb/"
install -v -o 1000 -g 1000 -m 600 Aliaswallet-Blockchain/blk0001.dat           "${ROOTFS_DIR}/home/pi/.aliaswallet/"

rm -rf Aliaswallet-Blockchain*



# ============================================================================
# Install Aliaswallet RPC-UI
on_chroot << EOF
cd "/home/pi/"

git clone https://github.com/aliascash/aliaswallet-sh-rpc-ui.git
chown -R 1000:1000 aliaswallet-sh-rpc-ui

# Use config from RPC-UI also on wallet
cp aliaswallet-sh-rpc-ui/sample_config_daemon/alias.conf  .aliaswallet/
chown 1000:1000 .aliaswallet/alias.conf
EOF



# ============================================================================
# Define aliases:
# - 'ui' for the Aliaswallet-Shell-UI
# - 'update-ui' to update the Shell-UI
# - 'wallet-start' to start daemon
# - 'wallet-stop' to stop daemon
# - 'wallet-status' to show daemon status
echo "alias ui='/home/pi/aliaswallet-sh-rpc-ui/aliaswallet_rpc_ui.sh'"                           > bash_aliases
echo "alias update-ui='cd /home/pi/aliaswallet-sh-rpc-ui ; git reset --hard HEAD ; git pull ; cd -'"   >> bash_aliases
echo "alias wallet-start='sudo service aliaswalletd start'"                                     >> bash_aliases
echo "alias wallet-stop='sudo service aliaswalletd stop'"                                       >> bash_aliases
echo "alias wallet-status='sudo service aliaswalletd status'"                                   >> bash_aliases
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
