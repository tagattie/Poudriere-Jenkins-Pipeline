#! /bin/sh -xe

export LANG=C
export PATH=/bin:/usr/bin:/usr/local/bin

# Update the ports tree
if [ "${dryRunUpdate}" != "y" ]; then
    # Update the specified ports tree
    sudo poudriere ports -v -u -p ${PORTSTREE}
else
    # When dry run is enabled,
    # show list of ports trees instead of updating
    sudo poudriere ports -l
fi
