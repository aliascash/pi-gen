#!/usr/bin/env bash
# ============================================================================
# Automatic installation of Alias blockchain bootstrap
#
# Created: 2020-10-24 HLXEasy
# ============================================================================

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
        echo "${blkdataFile} is older than ${maxChainAge} days"
        performBootstrapDownload=true
    fi
else
    performBootstrapDownload=true
fi

if ${performBootstrapDownload} ; then
    if [ -e "${bootstrapArchive}" ] ; then
        rm -rf "${bootstrapArchive}"
    fi

    # Shell-UI will check for this file to prevent service start in case
    # the bootstrap chain download and install process is running
    touch "${bootstrapRunningMarker}"

    sudo systemctl stop aliaswalletd || true

    if wget -O "${bootstrapArchive}" ${bootstrapDownloadUrl} ; then
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
    else
        echo "Unable to download ${bootstrapDownloadUrl}"
    fi

    # Shell-UI can be used now
    rm -f "${bootstrapRunningMarker}"
fi
