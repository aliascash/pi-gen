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
wget https://github.com/aliascash/alias-wallet/releases/download/${ALIAS_RELEASE}/Alias-${ALIAS_RELEASE}-${GIT_COMMIT_SHORT}-RaspberryPi-Buster-aarch64.tgz -O Alias-RaspberryPi.tgz
tar xzf Alias-RaspberryPi.tgz

#install -v -o 1000 -g 1000 -m 744 usr/local/bin/aliaswallet     "${ROOTFS_DIR}/usr/local/bin/"
install -v -o 1000 -g 1000 -m 744 usr/local/bin/aliaswalletd    "${ROOTFS_DIR}/usr/local/bin/"

rm -f /tmp/Alias-RaspberryPi.tgz
rm -rf usr/



# ============================================================================
# Install Aliaswallet service
install -m 644 files/aliaswalletd.service	"${ROOTFS_DIR}/lib/systemd/system/"

# Enabling of aliaswalletd service will be done by bootstrap installer service
# after download and installation of bootstrap chain
#on_chroot << EOF
#systemctl enable aliaswalletd
#EOF



# ============================================================================
# Install Aliaswallet bootstrap installer service
install -m 644 files/aliasbootstrapinstaller.service	"${ROOTFS_DIR}/lib/systemd/system/"
install -o 1000 -g 1000 -m 754 files/aliasbootstrapinstaller.sh	        "${ROOTFS_DIR}/usr/local/bin/"
on_chroot << EOF
systemctl enable aliasbootstrapinstaller
EOF



# ============================================================================
# Bootstrap blockchain
#wget https://download.alias.cash/files/bootstrap/BootstrapChain.zip -O Alias-Blockchain.zip
#
#mkdir Alias-Blockchain
#unzip Alias-Blockchain.zip -d Alias-Blockchain/
#
install -d -o 1000 -g 1000 -m 755 "${ROOTFS_DIR}/home/pi/.aliaswallet/"
#install -d -o 1000 -g 1000 -m 755 "${ROOTFS_DIR}/home/pi/.aliaswallet/txleveldb/"
#
#install -v -o 1000 -g 1000 -m 600 Alias-Blockchain/txleveldb/*0.ldb      "${ROOTFS_DIR}/home/pi/.aliaswallet/txleveldb/"
#install -v -o 1000 -g 1000 -m 600 Alias-Blockchain/txleveldb/*1.ldb      "${ROOTFS_DIR}/home/pi/.aliaswallet/txleveldb/"
#install -v -o 1000 -g 1000 -m 600 Alias-Blockchain/txleveldb/*2.ldb      "${ROOTFS_DIR}/home/pi/.aliaswallet/txleveldb/"
#install -v -o 1000 -g 1000 -m 600 Alias-Blockchain/txleveldb/*3.ldb      "${ROOTFS_DIR}/home/pi/.aliaswallet/txleveldb/"
#install -v -o 1000 -g 1000 -m 600 Alias-Blockchain/txleveldb/*4.ldb      "${ROOTFS_DIR}/home/pi/.aliaswallet/txleveldb/"
#install -v -o 1000 -g 1000 -m 600 Alias-Blockchain/txleveldb/*5.ldb      "${ROOTFS_DIR}/home/pi/.aliaswallet/txleveldb/"
#install -v -o 1000 -g 1000 -m 600 Alias-Blockchain/txleveldb/*6.ldb      "${ROOTFS_DIR}/home/pi/.aliaswallet/txleveldb/"
#install -v -o 1000 -g 1000 -m 600 Alias-Blockchain/txleveldb/*7.ldb      "${ROOTFS_DIR}/home/pi/.aliaswallet/txleveldb/"
#install -v -o 1000 -g 1000 -m 600 Alias-Blockchain/txleveldb/*8.ldb      "${ROOTFS_DIR}/home/pi/.aliaswallet/txleveldb/"
#install -v -o 1000 -g 1000 -m 600 Alias-Blockchain/txleveldb/*9.ldb      "${ROOTFS_DIR}/home/pi/.aliaswallet/txleveldb/"
#install -v -o 1000 -g 1000 -m 600 Alias-Blockchain/txleveldb/CURRENT     "${ROOTFS_DIR}/home/pi/.aliaswallet/txleveldb/"
#install -v -o 1000 -g 1000 -m 600 Alias-Blockchain/txleveldb/MANIFEST*   "${ROOTFS_DIR}/home/pi/.aliaswallet/txleveldb/"
#install -v -o 1000 -g 1000 -m 600 Alias-Blockchain/blk0001.dat           "${ROOTFS_DIR}/home/pi/.aliaswallet/"
#
#rm -rf Alias-Blockchain*



# ============================================================================
# Install Alias wallet RPC-UI
on_chroot << EOF
cd "/home/pi/"

git clone https://github.com/aliascash/alias-sh-rpc-ui.git
chown -R 1000:1000 alias-sh-rpc-ui

# Use config from RPC-UI also on wallet
cp alias-sh-rpc-ui/sample_config_daemon/alias.conf  .aliaswallet/
chown 1000:1000 .aliaswallet/alias.conf
EOF



# ============================================================================
# Define aliases:
# - 'ui' for the Aliaswallet-Shell-UI
# - 'update-ui' to update the Shell-UI
# - 'wallet-start' to start daemon
# - 'wallet-stop' to stop daemon
# - 'wallet-status' to show daemon status
echo "alias ui='/home/pi/alias-sh-rpc-ui/aliaswallet_rpc_ui.sh'"                                 > bash_aliases
echo "alias update-ui='cd /home/pi/alias-sh-rpc-ui ; git reset --hard HEAD ; git pull ; cd -'"  >> bash_aliases
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
