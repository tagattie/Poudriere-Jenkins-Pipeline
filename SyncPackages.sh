#! /bin/sh -xe

export PATH=/bin:/usr/bin:/usr/local/bin

. ${WORKSPACE-.}/local.conf

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

    # Sync built packages with www server
    rsync ${DRYRUN_SYNC} -e "ssh -p ${RSYNCPORT}" \
        -a --info=STATS3 --delete --stats \
        ${PKGDIR}/ \
        ${RSYNCUSER}@${RSYNCHOST}:${RSYNCBASE}/${ABI}
done
