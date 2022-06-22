LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=d9b7e441d51a96b17511ee3be5a75857"

DEPENDS = "lua"


SRC_URI = "git://github.com/keplerproject/luafilesystem;protocol=https;branch=master \
	file://0001-Fix-for-OE.patch"

# Modify these as desired
PV = "1.8.0"
SRCREV = "7c6e1b013caec0602ca4796df3b1d7253a2dd258"

inherit pkgconfig

S = "${WORKDIR}/git"

EXTRA_OEMAKE = 'PREFIX=${D}/usr BASELIB=${base_libdir} CROSS_COMPILE=${TARGET_PREFIX} CC="${CC} -fpic" LDFLAGS="${LDFLAGS}"'

# NOTE: this is a Makefile-only piece of software, so we cannot generate much of the
# recipe automatically - you will need to examine the Makefile yourself and ensure
# that the appropriate arguments are passed in.

FILES:${PN} = "${libdir} ${datadir}/lua"

do_configure () {
	# Specify any needed configure commands here
	:
}

do_compile () {
	# You will almost certainly need to add additional arguments here
	oe_runmake
}

do_install () {
	# This is a guess; additional arguments may be required
	oe_runmake install
}

