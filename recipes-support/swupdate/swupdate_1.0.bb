SUMMARY="Image updater for Yocto projects"
DESCRIPTION = "Application for automatic software update from USB Pen"
SECTION="swupdate"
DEPENDS = "mtd-utils libconfig openssl lua"
LICENSE = "GPLv2+"
LIC_FILES_CHKSUM = "file://COPYING;md5=0636e73ff0215e8d672dc4c32c317bb3"

PR = "r0"

inherit cml1 update-rc.d


SRCREV = "${AUTOREV}"
SRC_URI = "git://github.com/sbabic/swupdate.git;protocol=git \
	   file://defconfig \
	   file://swupdate \
	   "

PACKAGES =+ "${PN}-www"

FILES_${PN}-www = "/www/*"
FILES_${PN} = "${bindir}/* /etc/init.d"
CONFFILES_${PN} += "${sysconfdir}/init.d/recovery"

S = "${WORKDIR}/git/"

EXTRA_OEMAKE += "V=1 ARCH=${TARGET_ARCH} CROSS_COMPILE=${TARGET_PREFIX} SKIP_STRIP=y"

do_configure () {
	cp ${WORKDIR}/defconfig ${S}/.config
	cml1_do_configure
}

do_install () {
	install -d ${D}${bindir}/
	install -m 0755 swupdate ${D}${bindir}/

	install -m 0755 -d ${D}/www
        install -m 0755 ${S}www/* ${D}/www

	install -d ${D}${sysconfdir}/init.d
	install -m 755 ${WORKDIR}/swupdate ${D}${sysconfdir}/init.d

}

do_compile() {
	unset CFLAGS CPPFLAGS CXXFLAGS LDFLAGS
	oe_runmake swupdate_unstripped
	cp swupdate_unstripped swupdate
}

PARALLEL_MAKE = ""

INITSCRIPT_NAME = "swupdate"
INITSCRIPT_PARAMS = "defaults 70"
