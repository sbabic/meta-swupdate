SUMMARY = "U-Boot libraries and tools to acces environment"
DEPENDS += "mtd-utils"

DESCRIPTION = "This package contains tools and libraries to read \
and modify U-Boot environment"

HOMEPAGE = "https://github.com/sbabic/libubootenv"
LICENSE = "LGPL-2.1"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/LGPL-2.1;md5=1a6d268fd218675ffea8be556788b780"
SECTION = "libs"

SRC_URI = "git://github.com/sbabic/libubootenv;protocol=https"
SRCREV = "e67ce380d6e27d057ff6b8eb2b0a649a2c2d360a"

S = "${WORKDIR}/git"

inherit cmake

PACKAGE_ARCH = "${MACHINE_ARCH}"

PROVIDES += "u-boot-fw-utils"
RPROVIDES_${PN} += "u-boot-fw-utils"

BBCLASSEXTEND = "cross"
