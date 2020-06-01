# Recipe created by recipetool
# This is the basis of a recipe and may need further editing in order to be fully functional.
# (Feel free to remove these comments when editing.)

# WARNING: the following LICENSE and LIC_FILES_CHKSUM values are best guesses - it is
# your responsibility to verify that the values are complete and correct.
#
# The following license files were not able to be identified and are
# represented as "Unknown" below, you will need to check them yourself:
#   COPYRIGHT
#   tek/ui/font/COPYRIGHT.TXT
#   doc/copyright.html
#   src/display_rawfb/vnc/COPYING
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://COPYRIGHT;md5=a12f233f3497ee1f8a18dddfde5a7fc3"

SRC_URI = " \
	git://github.com/sbabic/tekUI.git;protocol=https;branch=tekui-devel \
        file://0001-Fix-config-for-OE.patch \
	"

SRCREV = "b0a20f57e47548099e443d54fc6fb33666543b72"

PR = "r1"

S = "${WORKDIR}/git"

PACKAGES += "${PN}-examples"
FILES_${PN} = "${libdir} ${datadir}/lua" 

inherit pkgconfig

# NOTE: the following library dependencies are unknown, ignoring: imgload display_directfb tekc tek region imgcache tekdebug utf8 display_win visual exec hal display_rawfb cachemanager display_x11 pixconv
#       (this is based on recipes that have previously been built and packaged)
# NOTE: some of these dependencies may be optional, check the Makefile and/or upstream documentation
DEPENDS = "libx11 readline lua freetype libpng fontconfig"
DEPENDS = "lua freetype libpng fontconfig"
RDEPENDS_${PN} += "lua"

EXTRA_OEMAKE = 'PREFIX=${D}/usr BASELIB=${base_libdir} DISPLAY_DRIVER=rawfb CROSS_COMPILE=${TARGET_PREFIX} CC="${CC} -fpic"'

do_compile () {
	oe_runmake all
}

do_install () {
	oe_runmake install
}
