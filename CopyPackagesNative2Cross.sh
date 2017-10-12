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

# Simply sync contents of native and cross package directories
# (Sync direction is cross pkg dir -> native pkg dir.)
if [ "${DRYRUNCOPY}" == "true" ]; then
    DRYRUN_FLAG="-n"
fi
if  [ "${VERBOSECOPY}" == "true" ]; then
    VERBOSE_FLAG="-v"
fi
sudo rsync ${DRYRUN_FLAG} ${VERBOSE_FLAG} \
    -a --info=STATS3 --delete --stats \
    ${NATIVEPKGDIR}/ ${CROSSPKGDIR}
# sudo cpdup ${DRYRUN_FLAG} -i0 -x -I ${NATIVEPKGDIR} ${CROSSPKGDIR}
