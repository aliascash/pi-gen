#!/usr/bin/env bash
# ============================================================================
# Automatic installation of Alias blockchain bootstrap
#
# Created: 2020-10-24 HLXEasy
# ============================================================================

# Script is executed as root at system boot but should write onto pi's home
HOME=/home/pi

aliasDatafolder=${HOME}/.aliaswallet
blkdataFile=${aliasDatafolder}/blk0001.dat
txdateFolder=${aliasDatafolder}/txleveldb
maxChainAge=3
performBootstrapDownload=false
bootstrapDownloadUrl=https://download.alias.cash/files/bootstrap/BootstrapChain.zip
bootstrapArchive=${HOME}/BootstrapChain.zip
bootstrapRunningMarker=${HOME}/bootstrapInstallerRunning

# Check if blk0001.dat exists and if yes, determine if last modification time
# is longer than ${maxChainAge} days ago
if [ -e "${blkdataFile}" ] ; then
    maxLastChainAccess=$(date -d "now - ${maxChainAge} days" +%s)
    blkdataFileTime=$(date -r "${blkdataFile}" +%s)

    if (( blkdataFileTime <= maxLastChainAccess )); then
        echo "${blkdataFile} is older than ${maxChainAge} days, performing update"
        performBootstrapDownload=true
    fi
else
    echo "${blkdataFile} not found, downloading and installing bootstrap"
    performBootstrapDownload=true
fi

if ${performBootstrapDownload} ; then
    if [ -e "${bootstrapArchive}" ] ; then
        echo "Removing old bootstrap archive"
        rm -rf "${bootstrapArchive}"
    fi

    # Shell-UI will check for this file to prevent service start in case
    # the bootstrap chain download and install process is running
    touch "${bootstrapRunningMarker}"

    # On subsequent executions aliaswalletd might be running, so stop it
    echo "Stopping potentially running Alias wallet"
    systemctl stop aliaswalletd || true

    echo "Downloading and installing bootstrap archive"
    if wget -O "${bootstrapArchive}" ${bootstrapDownloadUrl} ; then
        chown 1000:1000 ${bootstrapArchive}
        if [ -d "${aliasDatafolder}" ] ; then
            if [ -e "${blkdataFile}" ] ; then
                rm -f "${blkdataFile}"
            fi
            if [ -e "${txdateFolder}" ] ; then
                rm -rf "${txdateFolder}"
            fi
        else
            mkdir -p "${aliasDatafolder}"
        fi
        cd "${aliasDatafolder}" || exit
        unzip "${bootstrapArchive}"
        chown -R 1000:1000 ./*

        # On first boot, aliaswalletd service is not enabled, so enable it now
        systemctl enable aliaswalletd
    else
        echo "Unable to download ${bootstrapDownloadUrl}"
    fi

    # Shell-UI can be used now
    rm -f "${bootstrapRunningMarker}"
fi
