#! /bin/sh -xe

export LANG=C
export PATH=/bin:/usr/bin:/usr/local/bin

# Determine buildname for this execusion
# (this is shared with package builder for multiple architectures)
buildname=${WORKSPACE}/poudriere.buildname
date +%Y-%m-%d_%Hh%Mm%Ss
