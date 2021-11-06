LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=ab6706baf6d39a6b0fa2613a3b0831e7"

DEPENDS = "lua"

RDEPENDS_${PN} += "lua"

SRC_URI = "git://github.com/diegonehab/luasocket;protocol=https;branch=master \
	file://0001-fix-for-OE.patch \
"

# Modify these as desired
PV = "0.0+git${SRCPV}"
SRCREV = "652959890943c34d7180cae372339b91e62f0d7b"

S = "${WORKDIR}/git"

FILES_${PN} = "${libdir} ${datadir}/lua" 

EXTRA_OEMAKE = 'DESTDIR=${D} BASELIB=${base_libdir} PREFIX=/usr CC="${CC}" LD="${CC}" MYLDFLAGS="${LDFLAGS}"'

inherit pkgconfig

do_configure () {
}

do_compile () {
	# You will almost certainly need to add additional arguments here
	oe_runmake
}

do_install () {
	# This is a guess; additional arguments may be required
	oe_runmake install
}

