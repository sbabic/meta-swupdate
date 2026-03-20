LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=eea9910b0620641551736d969a197076"

DEPENDS = "lua"


SRC_URI = "git://github.com/keplerproject/luafilesystem;protocol=https;branch=master \
	file://0001-Fix-for-OE.patch"

# Modify these as desired
PV = "1.9.0"
SRCREV = "a186cca5833691e830ed255e38ace8ff6b870dbf"

inherit pkgconfig


EXTRA_OEMAKE = 'PREFIX=${D}/${prefix} CROSS_COMPILE=${TARGET_PREFIX} CC="${CC} -fpic" LDFLAGS="${LDFLAGS}"'

# NOTE: this is a Makefile-only piece of software, so we cannot generate much of the
# recipe automatically - you will need to examine the Makefile yourself and ensure
# that the appropriate arguments are passed in.

FILES:${PN} = "${nonarch_base_libdir} ${datadir}/lua"

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

