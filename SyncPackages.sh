#! /bin/sh -xe

export LANG=C
export PATH=/bin:/usr/bin:/usr/local/bin

RSYNC_FLAGS="-a --info=STATS3 --delete --partial --stats --exclude=.building"

# Command-line Format:
# SyncPackages.sh pkgBaseDir portsTree syncUser syncHost syncPort syncBase [arch ...]
PKGBASEDIR=${1}
PORTSTREE=${2}
SYNCUSER=${3}
SYNCHOST=${4}
SYNCPORT=${5}
SYNCBASE=${6}
if [ $# -gt 6 ]; then
    shift 6
    ARCHLIST=$@
fi

if [ "${DRYRUNSYNC}" == "true" ]; then
    DRYRUN_FLAG="-n"
fi
if  [ "${VERBOSESYNC}" == "true" ]; then
    VERBOSE_FLAG="-v"
fi
for i in ${ARCHLIST}; do
    arch=$(echo ${i}|sed -e 's/x$//')
    echo "Syncing packages for ${arch} architecture."
    PKGDIR=${PKGBASEDIR}/${JAILNAMEPREFIX}${i}-${PORTSTREE}
    ABI=FreeBSD:${MAJORREL}:${arch}

    LATESTPKG_LOCAL=$(basename $(find -s ${PKGDIR} -type d -depth 1 -print|tail -n 1))
    LATESTPKG_REMOTE=$(basename $(ssh -p ${SYNCPORT} ${SYNCUSER}@${SYNCHOST} \
                                      find -s ${SYNCBASE}/${ABI} -type d -depth 1 -print|tail -n 1))
    if [ -n "${LATESTPKG_LOCAL}" ] && \
           [ -n "${LATESTPKG_REMOTE}" ] && \
           [ "${LATESTPKG_LOCAL}" != "${LATESTPKG_REMOTE}" ]; then
        ssh -p ${SYNCPORT} ${SYNCUSER}@${SYNCHOST} \
            cp -pR ${SYNCBASE}/${ABI}/${LATESTPKG_REMOTE} ${SYNCBASE}/${ABI}/${LATESTPKG_LOCAL}
    fi

    rsync ${DRYRUN_FLAG} ${VERBOSE_FLAG} \
          -e "ssh ${SSH_FLAGS} -p ${SYNCPORT}" \
          ${RSYNC_FLAGS} \
          ${PKGDIR}/ \
          ${SYNCUSER}@${SYNCHOST}:${SYNCBASE}/${ABI}
done
