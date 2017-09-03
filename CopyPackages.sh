#! /bin/sh -xe

export PATH=/bin:/usr/bin:/usr/local/bin:/usr/local/libexec/poudriere

. ${WORKSPACE}/local.conf

# Command-line format:
# CopyPackages.sh arch
ARCH=${1}

PKGDIR=${PKGBASEDIR}/${JAILNAMEPREFIX}${ARCH}-${PORTSTREE}
CROSSPKGDIR=${PKGBASEDIR}/${JAILNAMEPREFIX}${ARCH}x-${PORTSTREE}

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

if [ -n "${LATESTCROSSREALDIR}" ]; then
    # Only when there is already one, copy the contents of native-built
    # directory to a cross building working directory
    sudo mkdir -p ${CROSSPKGDIR}/.building
    cd ${PKGDIR}/${LATESTREALDIR}
    for i in "All Latest"; do
        # find ${i} -print -depth | \
        #     sudo cpio -pdam ${CROSSPKGDIR}/.building
        sudo cpdup -i0 x ${i} ${CROSSPKGDIR}/.building/${i}
    done
fi
