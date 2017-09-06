#! /bin/sh -xe

export LANG=C
export PATH=/bin:/usr/bin:/usr/local/bin

# Command-line Format:
# SyncPackages.sh [arch ...]
if [ $# -ne 0 ]; then
    ARCHLIST=$@
fi

if [ "${DRYRUN_SYNC}" == "y" ]; then
    DRYRUN_FLAG="-n"
fi
if  [ "${VERBOSE_SYNC}" == "y" ]; then
    VERBOSE_FLAG="-v"
fi
for i in ${ARCHLIST}; do
    arch=$(echo ${i}|sed -e 's/x$//')
    echo "Syncing packages for ${arch} architecture."
    PKGDIR=${PKGBASEDIR}/${JAILNAMEPREFIX}${i}-${PORTSTREE}
    ABI=FreeBSD:${MAJORREL}:${arch}

    rsync ${DRYRUN_FLAG} ${VERBOSE_FLAG} -e "ssh -p ${syncPort}" \
        -a --info=STATS3 --delete --stats \
        ${PKGDIR}/ \
        ${syncUser}@${syncHost}:${syncBase}/${ABI}
done
