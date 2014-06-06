DESCRIPTION = "Lua is a powerful light-weight programming language designed \
for extending applications."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://doc/readme.html;beginline=362;endline=396;md5=ffcafb3f03e29955d3f1fdfd5a4a72e7"
HOMEPAGE = "http://www.lua.org/"

DEPENDS += "readline"
PR = "r0"
SRC_URI = "http://www.lua.org/ftp/lua-${PV}.tar.gz \
           file://lua5.2.pc \
          "
S = "${WORKDIR}/lua-${PV}"

inherit pkgconfig binconfig

TARGET_CC_ARCH += " -fPIC ${LDFLAGS}"
EXTRA_OEMAKE = "'CC=${CC} -fPIC' 'MYCFLAGS=${CFLAGS} -DLUA_USE_LINUX -fPIC' MYLDFLAGS='${LDFLAGS}'"

do_configure_prepend() {
	sed -i -e s:/usr/local:${prefix}:g src/luaconf.h
}

do_compile () {
	oe_runmake linux
}

do_install () {
	oe_runmake \
		'INSTALL_TOP=${D}${prefix}' \
		'INSTALL_BIN=${D}${bindir}' \
		'INSTALL_INC=${D}${includedir}/' \
		'INSTALL_MAN=${D}${mandir}/man1' \
		'INSTALL_SHARE=${D}${datadir}/lua' \
		install
	install -d ${D}${libdir}/pkgconfig
	install -m 0644 ${WORKDIR}/lua5.2.pc ${D}${libdir}/pkgconfig/lua5.2.pc
}
BBCLASSEXTEND = "native"

FILES_${PN} += "${libdir}/lua"
FILES_${PN} += "${datadir}/lua"

SRC_URI[md5sum] = "ae08f641b45d737d12d30291a5e5f6e3"
SRC_URI[sha256sum] = "64304da87976133196f9e4c15250b70f444467b6ed80d7cfd7b3b982b5177be5"
