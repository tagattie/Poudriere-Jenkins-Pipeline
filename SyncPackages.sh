#! /bin/sh -xe

export LANG=C
export PATH=/bin:/usr/bin:/usr/local/bin

RSYNC_FLAGS="-a --info=STATS3 --delete --stats"

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

    rsync ${DRYRUN_FLAG} ${VERBOSE_FLAG} \
          -e "ssh ${SSH_FLAGS} -p ${SYNCPORT}" \
          ${RSYNC_FLAGS} \
          ${PKGDIR}/ \
          ${SYNCUSER}@${SYNCHOST}:${SYNCBASE}/${ABI}
done
