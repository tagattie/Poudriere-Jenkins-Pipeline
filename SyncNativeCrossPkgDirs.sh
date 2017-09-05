#! /bin/sh -xe

export LANG=C
export PATH=/bin:/usr/bin:/usr/local/bin

# Command-line format:
# SyncNativeCrossPkgDirs arch
ARCH=${1}
CROSS="x"

NATIVEPKGDIR=${PKGBASEDIR}/${JAILNAMEPREFIX}${ARCH}-${PORTSTREE}
CROSSPKGDIR=${PKGBASEDIR}/${JAILNAMEPREFIX}${ARCH}${CROSS}-${PORTSTREE}

# Simply sync contents of native and cross package directories
# (Sync direction is cross pkg dir -> native pkg dir.)
if [ "${DRYRUN_COPY}" == "y" ]; then
    DRYRUN_FLAG="-n"
fi
sudo rsync ${DRYRUN_FLAG} -a --info=STATS3 --delete --stats \
    ${CROSSPKGDIR}/ ${NATIVEPKGDIR}
# sudo cpdup ${DRYRUN_COPY} -i0 -x -I ${CROSSPKGDIR} ${NATIVEPKGDIR}
