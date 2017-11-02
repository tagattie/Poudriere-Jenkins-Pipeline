#! /bin/sh -xe

export LANG=C
export PATH=/bin:/usr/bin:/usr/local/bin

# Command-line format:
# SyncNativeCrossPkgDirs arch pkgBaseDir portsTree
ARCH=${1}
PKGBASEDIR=${2}
PORTSTREE=${3}

NATIVEPKGDIR=${PKGBASEDIR}/${JAILNAMEPREFIX}${ARCH}-${PORTSTREE}
CROSSPKGDIR=${PKGBASEDIR}/${JAILNAMEPREFIX}${ARCH}${CROSSSUFFIX}-${PORTSTREE}

# Find the latest .real-XXXX directory of cross-built packages
LATESTCROSSREALDIR=$(find ${CROSSPKGDIR}/ -type d -depth 1 -print | \
    awk -F'/' '{print $NF}' | \
    sort -nr | \
    head -n 1)
# Find the latest .real-XXXX directory of native-built packages
LATESTNATIVEREALDIR=$(find ${NATIVEPKGDIR}/ -type d -depth 1 -print | \
    awk -F'/' '{print $NF}' | \
    sort -nr | \
    head -n 1)
echo "Latest cross-built .real-XXXX directory is ${LATESTCROSSREALDIR}."
echo "Latest native-built .real-XXXX directory is ${LATESTNATIVEREALDIR}."

# Sync contents of native and cross package directories
# when native building succeeded
# (Sync direction is cross pkg dir -> native pkg dir.)
if [ "${DRYRUNCOPY}" == "true" ]; then
    DRYRUN_FLAG="-n"
fi
if  [ "${VERBOSECOPY}" == "true" ]; then
    VERBOSE_FLAG="-v"
fi
REALDIRSUBSTR="real"
# Check if the latest real dirs are really .real_XXXX and not .building
if [ "${LATESTCROSSREALDIR#*$REALDIRSUBSTR*}" != "${LATESTCROSSREALDIR}" ] && \
    [ "${LATESTNATIVEREALDIR#*$REALDIRSUBSTR*}" != "${LATESTNATIVEREALDIR}" ]; then
    CROSSREALDIREPOCH=$(echo ${LATESTCROSSREALDIR} | awk -F'_' '{print $NF}')
    NATIVEREALDIREPOCH=$(echo ${LATESTNATIVEREALDIR} | awk -F'_' '{print $NF}')
    if [ ${NATIVEREALDIREPOCH} -gt ${CROSSREALDIREPOCH} ]; then
        # Sync only when some new packages have been commited in the latest
        # native-built real directory
        echo "Syncing native-built package directory with cross-built one."
        sudo rsync ${DRYRUN_FLAG} ${VERBOSE_FLAG} \
            -a --info=STATS3 --delete --stats \
            ${NATIVEPKGDIR}/ ${CROSSPKGDIR}
        # sudo cpdup ${DRYRUN_FLAG} -i0 -x -I ${NATIVEPKGDIR} ${CROSSPKGDIR}
    else
        echo "${LATESTNATIVEREALDIR} is not newer than ${LATESTCROSSREALDIR}."
        echo "Skipping copying native -> cross package directory."
    fi
fi
