#! /bin/sh -xe

export PATH=/bin:/usr/bin:/usr/local/bin

. ${WORKSPACE}/local.conf

# Command-line format:
# SyncNativeCrossPkgDirs arch
ARCH=${1}

NATIVEPKGDIR=${PKGBASEDIR}/${JAILNAMEPREFIX}${ARCH}-${PORTSTREE}
CROSSPKGDIR=${PKGBASEDIR}/${JAILNAMEPREFIX}${ARCH}x-${PORTSTREE}

# Simply sync contents of native and cross package directories
# (Sync direction is cross pkg dir -> native pkg dir.)
rsync ${DRYRUN_COPY} -av --info=STATS3 --delete --stats \
    ${CROSSPKGDIR}/ ${NATIVEPKGDIR}
