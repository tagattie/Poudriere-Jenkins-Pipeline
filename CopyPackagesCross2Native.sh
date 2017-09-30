#! /bin/sh -xe

export LANG=C
export PATH=/bin:/usr/bin:/usr/local/bin

# Command-line format:
# CopyPackagesCross2Native.sh arch pkgBaseDir portsTree
ARCH=${1}
PKGBASEDIR=${2}
PORTSTREE=${3}

NATIVEPKGDIR=${PKGBASEDIR}/${JAILNAMEPREFIX}${ARCH}-${PORTSTREE}
CROSSPKGDIR=${PKGBASEDIR}/${JAILNAMEPREFIX}${ARCH}${CROSSSUFFIX}-${PORTSTREE}

# Find the newest .real-XXXX directory of cross-built packages
LATESTCROSSREALDIR=$(find ${CROSSPKGDIR}/ -type d -depth 1 -print | \
                         awk -F'/' '{print $NF}' | \
                         sort -nr | \
                         head -n 1)
# Find the newest .real-XXXX directory of native-built packages
LATESTNATIVEREALDIR=$(find ${NATIVEPKGDIR}/ -type d -depth 1 -print | \
                    awk -F'/' '{print $NF}' | \
                    sort -nr | \
                    head -n 1)

# Copy cross-built packages to native-build directory
if [ "${dryRunCopy}" == "y" ]; then
    DRYRUN_FLAG="-n"
fi
if  [ "${verboseCopy}" == "y" ]; then
    VERBOSE_FLAG="-v"
fi
if [ -n "${LATESTNATIVEREALDIR}" ]; then
    # Only when there is already one, copy the contents of cross-built
    # directory to a native building working directory
    sudo mkdir -p ${NATIVEPKGDIR}/.building
    cd ${CROSSPKGDIR}/${LATESTCROSSREALDIR}
    for i in "All" "Latest"; do
        # find ${i} -print -depth | \
        #     sudo cpio -pdam ${NATIVEPKGDIR}/.building
        # sudo cpdup -i0 -x ${i} ${NATIVEPKGDIR}/.building/${i}
        sudo rsync ${DRYRUN_FLAG} ${VERBOSE_FLAG} \
            -a --info=STATS3 --delete --stats \
            ${i} ${NATIVEPKGDIR}/.building
    done
else
    echo "No directory named ${LATESTNATIVEREALDIR}."
    echo "Seems this is the very first run of poudriere."
    echo "Skipping copying cross -> native package directory."
fi
