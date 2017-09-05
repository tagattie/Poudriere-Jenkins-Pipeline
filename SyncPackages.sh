#! /bin/sh -xe

export LANG=C
export PATH=/bin:/usr/bin:/usr/local/bin

# Command-line Format:
# SyncPackages.sh [arch ...]
if [ $# -ne 0 ]; then
    ARCHLIST=$@
fi

for i in ${ARCHLIST}; do
    arch=$(echo ${i}|sed -e 's/x$//')
    echo "Syncing packages for ${arch} architecture."
    PKGDIR=${PKGBASEDIR}/${JAILNAMEPREFIX}${i}-${PORTSTREE}
    ABI=FreeBSD:${MAJORREL}:${arch}

    rsync ${DRYRUN_SYNC} -e "ssh -p ${syncPort}" \
        -a --info=STATS3 --delete --stats \
        ${PKGDIR}/ \
        ${syncUser}@${syncHost}:${syncBase}/${ABI}
done
