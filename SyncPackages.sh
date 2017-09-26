#! /bin/sh -xe

export LANG=C
export PATH=/bin:/usr/bin:/usr/local/bin

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

if [ "${dryRunSync}" == "y" ]; then
    DRYRUN_FLAG="-n"
fi
if  [ "${verboseSync}" == "y" ]; then
    VERBOSE_FLAG="-v"
fi
for i in ${ARCHLIST}; do
    arch=$(echo ${i}|sed -e 's/x$//')
    echo "Syncing packages for ${arch} architecture."
    PKGDIR=${PKGBASEDIR}/${JAILNAMEPREFIX}${i}-${PORTSTREE}
    ABI=FreeBSD:${MAJORREL}:${arch}

    rsync ${DRYRUN_FLAG} ${VERBOSE_FLAG} -e "ssh -p ${SYNCPORT}" \
        -a --info=STATS3 --delete --stats \
        ${PKGDIR}/ \
        ${SYNCUSER}@${SYNCHOST}:${SYNCBASE}/${ABI}
done
