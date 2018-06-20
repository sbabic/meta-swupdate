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
LIC_FILES_CHKSUM = "file://COPYRIGHT;md5=f8640872a50cd4ee663b8fb2f603b854 \
                    file://tek/ui/font/COPYRIGHT.TXT;md5=27d7484b1e18d0ee4ce538644a3f04be \
                    file://doc/copyright.html;md5=e0ef847c1e1b62ee80317a79b7cd99de \
                    file://src/display_rawfb/vnc/COPYING;md5=361b6b837cad26c6900a926b62aada5f"

SRC_URI = "http://tekui.neoscientists.org/releases/tekui-1.12-r1.tgz \
           file://0001-Fix-config-for-OE.patch \
	"
SRC_URI[md5sum] = "cf67e1aa5583ee22e5f63ad2b297e2c9"
SRC_URI[sha256sum] = "d3130a9403e05b8322e47b5e8c0716f5ccf2956ecae6e1268b05085a774b0894"

PR = "r1"

S = "${WORKDIR}/${PN}-${PV}-${PR}"

PACKAGES += "${PN}-examples"
FILES_${PN} = "${libdir} ${datadir}/lua" 

inherit pkgconfig

# NOTE: the following library dependencies are unknown, ignoring: imgload display_directfb tekc tek region imgcache tekdebug utf8 display_win visual exec hal display_rawfb cachemanager display_x11 pixconv
#       (this is based on recipes that have previously been built and packaged)
# NOTE: some of these dependencies may be optional, check the Makefile and/or upstream documentation
DEPENDS = "libx11 readline lua freetype libpng fontconfig"
DEPENDS = "lua freetype libpng fontconfig"
RDEPENDS_${PN} += "lua"

EXTRA_OEMAKE = 'PREFIX=${D}/usr DISPLAY_DRIVER=rawfb CROSS_COMPILE=${TARGET_PREFIX} CC="${CC} -fpic"'

do_compile () {
	oe_runmake all
}

do_install () {
	oe_runmake install
}
