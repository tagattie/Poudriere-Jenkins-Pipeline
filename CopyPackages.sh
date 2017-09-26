#! /bin/sh -xe

export LANG=C
export PATH=/bin:/usr/bin:/usr/local/bin

# Command-line format:
# CopyPackages.sh arch pkgBaseDir portsTree
ARCH=${1}
PKGBASEDIR=${2}
PORTSTREE=${3}

PKGDIR=${PKGBASEDIR}/${JAILNAMEPREFIX}${ARCH}-${PORTSTREE}
CROSSPKGDIR=${PKGBASEDIR}/${JAILNAMEPREFIX}${ARCH}${CROSSSUFFIX}-${PORTSTREE}

# Find the newest .real-XXXX directory of native-built packages
LATESTREALDIR=$(find ${PKGDIR}/ -type d -depth 1 -print | \
                    awk -F'/' '{print $NF}' | \
                    sort -nr | \
                    head -n 1)
# Find the newest .real-XXXX directory of cross-built packages
LATESTCROSSREALDIR=$(find ${CROSSPKGDIR}/ -type d -depth 1 -print | \
                         awk -F'/' '{print $NF}' | \
                         sort -nr | \
                         head -n 1)

# Copy natively-built packages to cross-build directory
if [ "${dryRunCopy}" == "y" ]; then
    DRYRUN_FLAG="-n"
fi
if  [ "${verboseCopy}" == "y" ]; then
    VERBOSE_FLAG="-v"
fi
if [ -n "${LATESTCROSSREALDIR}" ]; then
    # Only when there is already one, copy the contents of native-built
    # directory to a cross building working directory
    sudo mkdir -p ${CROSSPKGDIR}/.building
    cd ${PKGDIR}/${LATESTREALDIR}
    for i in "All" "Latest"; do
        # find ${i} -print -depth | \
        #     sudo cpio -pdam ${CROSSPKGDIR}/.building
        # sudo cpdup -i0 -x ${i} ${CROSSPKGDIR}/.building/${i}
        sudo rsync ${DRYRUN_FLAG} ${VERBOSE_FLAG} \
            -a --info=STATS3 --delete --stats \
            ${i} ${CROSSPKGDIR}/.building
    done
else
    echo "No directory named ${LATESTCROSSREALDIR}."
    echo "Seems this is a very first run of poudriere."
    echo "Skipping copying native -> cross package directory."
fi
