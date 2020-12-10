SUMMARY = "librsync is a library for calculating and applying network deltas, \
with an interface designed to ease integration into diverse network applications."
HOMEPAGE = "http://librsync.sourceforge.net"

SECTION = "libs"

LICENSE = "LGPLv2.1"
LIC_FILES_CHKSUM = "file://COPYING;md5=d8045f3b8f929c1cb29a1e3fd737b499 \
                    file://debian/copyright;md5=365dc7c8a0d1b88cfc01021bcc5d2a30"

SRC_URI = "git://github.com/librsync/librsync.git;protocol=https"

PV = "2.1.0+git${SRCPV}"
SRCREV = "ac2274f562e74578b533ee734c8dada1aa5d93dc"

S = "${WORKDIR}/git"

DEPENDS = "bzip2 zlib"
inherit cmake

# Specify any options you want to pass to cmake using EXTRA_OECMAKE:
EXTRA_OECMAKE = ""
