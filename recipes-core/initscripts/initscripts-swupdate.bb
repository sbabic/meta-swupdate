SUMMARY = "Different startup scripts"
SECTION = "base"
PR = "r0"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/LICENSE;md5=4d92cd373abda3937c2bc47fbc49d690"

SRC_URI = "file://rcS.swupdate \
	"

S = "${WORKDIR}"

do_install () {
	install -d ${D}/${sysconfdir}
	install -d ${D}/${sysconfdir}/init.d
	rm -f ${D}${sysconfdir}/init.d/rcS
	install -m 755 ${S}/rcS.swupdate ${D}${sysconfdir}/init.d
}

PACKAGES = "${PN}"
FILES_${PN} = "/"

PACKAGE_ARCH = "${MACHINE_ARCH}"

CONFFILES_${PN} = ""
