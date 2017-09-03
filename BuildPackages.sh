#! /bin/sh -xe

export PATH=/bin:/usr/bin:/usr/local/bin

. ${WORKSPACE-.}/local.conf

# Command-line format:
# BuildPackages.sh arch native|cross buildname
ARCH=${1}
if [ "${2}" == "native" ]; then
    echo "Native building packages for ${ARCH} architecture."
    CROSS=""
else
    echo "Cross building packages for ${ARCH} architecture."
    CROSS="x"
fi
BUILDNAME=${3}

# Jail for package building with poudriere
JAILNAME="${JAILNAMEPREFIX}${ARCH}${CROSS}"
# Packages to be built
PKGLIST="${POUDRIERECONFDIR}/${ARCH}${CROSS}-pkgs.txt"

# Make a temporary file to store the packages to be built
pkglist=$(mktemp ${WORKSPACE}/poudriere.XXXXXX)
cat ${PKGLIST} > ${pkglist}

# Build the packages
sudo poudriere bulk ${DRYRUN} -f ${pkglist} -j ${JAILNAME} -p ${PORTSTREE} -B ${BUILDNAME} || ESTAT=$?

# Show jail information after build has finished
sudo poudriere jails -i -j ${JAILNAME}

exit ${ESTAT}
