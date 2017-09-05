#! /bin/sh -xe

export LANG=C
export PATH=/bin:/usr/bin:/usr/local/bin

# Command-line format:
# BuildPackages.sh arch native|cross buildName jailName pkgListFileName
ARCH=${1}
if [ "${2}" == "native" ]; then
    echo "Native building packages for ${ARCH} architecture."
    CROSS=""
else
    echo "Cross building packages for ${ARCH} architecture."
    CROSS="x"
fi
BUILDNAME=${3}
JAILNAME=${4}${1}${CROSS}
PKGLIST=${5}/${1}${CROSS}-pkgs.txt

# Make a temporary file to store the packages to be built
pkgList=$(mktemp ${WORKSPACE}/poudriere.XXXXXX)
cat ${PKGLIST} > ${pkgList}

# Build the packages
if [ "${DRYRUN_BUILD}" == "y" ]; then
    DRYRUN_FLAG="-n"
fi
sudo poudriere bulk ${DRYRUN_FLAG} -f ${pkgList} -j ${JAILNAME} -p ${PORTSTREE} -B ${BUILDNAME} || ESTAT=$?

# Show jail information after build has finished
sudo poudriere jails -i -j ${JAILNAME}

rm -f ${pkgList}

exit ${ESTAT}
