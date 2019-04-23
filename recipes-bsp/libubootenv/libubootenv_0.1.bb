SUMMARY = "U-Boot libraries and tools to acces environment"
DEPENDS += "mtd-utils"

DESCRIPTION = "This package contains tools and libraries to read \
and modify U-Boot environment"

HOMEPAGE = "https://github.com/sbabic/libubootenv"
LICENSE = "LGPL-2.1"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/LGPL-2.1;md5=1a6d268fd218675ffea8be556788b780"
SECTION = "libs"

SRC_URI = "git://github.com/sbabic/libubootenv;protocol=https"
SRCREV = "8a7d4030bcb106de11632e85b6a0e7b7d4cb47af"
PV_append = "+git${SRCPV}"

S = "${WORKDIR}/git"

inherit cmake

PACKAGE_ARCH = "${MACHINE_ARCH}"

PROVIDES += "u-boot-fw-utils"
RPROVIDES_${PN} += "u-boot-fw-utils"

BBCLASSEXTEND = "cross"
