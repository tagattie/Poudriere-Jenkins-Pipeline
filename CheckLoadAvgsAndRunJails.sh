#! /bin/sh -xe

export LANG=C
export PATH=/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin

LOAD_THRESH=2

WAIT_CNT=0
WAIT_INTERVAL=301
#MAX_WAIT=$((3600 * 6)) # 6 hours

while true; do
    LOADS=$(uptime | sed -e 's/^.*load averages: //')
    LOAD_1=$(echo ${LOADS} | awk -F', ' '{print $1}' | awk -F. '{print $1}')
    LOAD_5=$(echo ${LOADS} | awk -F', ' '{print $2}' | awk -F. '{print $1}')
    LOAD_15=$(echo ${LOADS} | awk -F', ' '{print $3}' | awk -F. '{print $1}')

    if [ ${LOAD_1} -lt ${LOAD_THRESH} ] &&
           [ ${LOAD_5} -lt ${LOAD_THRESH} ] &&
           [ ${LOAD_15} -lt ${LOAD_THRESH} ] &&
           [ $(( $(jls | wc -l) - 1 )) -le 1 ]; then
        break
    else
        WAIT_CNT=$((WAIT_CNT + 1))
        # if [ $((WAIT_CNT * WAIT_INTERVAL)) -ge ${MAX_WAIT} ]; then
        #     echo "Max wait reached."
        #     break
        # else
        echo "Current wait count = ${WAIT_CNT}."
        sleep ${WAIT_INTERVAL}
        # fi
    fi
done

exit 0
