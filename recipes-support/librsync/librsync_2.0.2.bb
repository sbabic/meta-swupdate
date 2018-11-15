SUMMARY = "librsync is a library for calculating and applying network deltas, \
with an interface designed to ease integration into diverse network applications."
HOMEPAGE = "http://librsync.sourceforge.net"

SECTION = "libs"

LICENSE = "LGPLv2.1"
LIC_FILES_CHKSUM = "file://COPYING;md5=d8045f3b8f929c1cb29a1e3fd737b499 \
                    file://debian/copyright;md5=365dc7c8a0d1b88cfc01021bcc5d2a30"

SRC_URI = "git://github.com/librsync/librsync.git;protocol=https"

PV = "2.0.2+git${SRCPV}"
SRCREV = "dfba8988ef12d6a2f96dc16e608923a9a5d6371d"

S = "${WORKDIR}/git"

DEPENDS = "bzip2 zlib"
inherit cmake

# Specify any options you want to pass to cmake using EXTRA_OECMAKE:
EXTRA_OECMAKE = ""
