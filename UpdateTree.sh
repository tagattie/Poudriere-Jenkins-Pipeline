#! /bin/sh -xe

export PATH=/bin:/usr/bin:/usr/local/bin

. ${WORKSPACE}/local.conf

# Update the poudriere default ports tree
sudo poudriere ports -v -u -p ${PORTSTREE}
