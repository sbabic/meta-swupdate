SUMMARY="Image updater for Yocto projects"
DESCRIPTION = "Application for automatic software update from USB Pen"
SECTION="swupdate"
DEPENDS = "libconfig"
LICENSE = "GPLv2+"
LIC_FILES_CHKSUM = "file://COPYING;md5=0636e73ff0215e8d672dc4c32c317bb3"

inherit cml1 update-rc.d systemd pkgconfig

SRC_URI = "git://github.com/sbabic/swupdate.git;protocol=https \
     file://defconfig \
     file://swupdate \
     file://swupdate.service \
     file://swupdate-usb.rules \
     file://swupdate-usb@.service \
     file://swupdate-progress.service \
     "

INSANE_SKIP_${PN} = "ldflags"
PACKAGES =+ "${PN}-www"

FILES_${PN}-www = "/www/*"
FILES_${PN}-dev = "${includedir}"
FILES_${PN}-staticdev = "${libdir}"
FILES_${PN} = "${bindir}/* ${sysconfdir}"

S = "${WORKDIR}/git/"

EXTRA_OEMAKE += "V=1 ARCH=${TARGET_ARCH} CROSS_COMPILE=${TARGET_PREFIX} SKIP_STRIP=y"

DEPENDS += "kern-tools-native"

# returns all the elements from the src uri that are .cfg files
def find_cfgs(d):
    return [s for s in src_patches(d, True) if s.endswith('.cfg')]

python () {
    try:
        defconfig = bb.fetch2.localpath('file://defconfig', d)
    except bb.fetch2.FetchError:
        return

    try:
        configfile = open(defconfig)
    except IOError:
        return

    features = configfile.readlines()
    configfile.close()

    if 'CONFIG_REMOTE_HANDLER=y\n' in features:
        depends = d.getVar('DEPENDS', False)
        d.setVar('DEPENDS', depends + ' zeromq')

    if 'CONFIG_ENCRYPTED_IMAGES=y\n' in features or 'CONFIG_MONGOOSESSL=y\n' in features or 'CONFIG_HASH_VERIFY=y\n' in features or 'CONFIG_SURICATTA_SSL=y\n' in features:
        depends = d.getVar('DEPENDS', False)
        d.setVar('DEPENDS', depends + ' openssl')

    if 'CONFIG_JSON=y\n' in features:
        depends = d.getVar('DEPENDS', False)
        d.setVar('DEPENDS', depends + ' json-c')

    if 'CONFIG_SYSTEMD=y\n' in features:
        depends = d.getVar('DEPENDS', False)
        d.setVar('DEPENDS', depends + ' systemd')

    if 'CONFIG_ARCHIVE=y\n' in features:
        depends = d.getVar('DEPENDS', False)
        d.setVar('DEPENDS', depends + ' libarchive')

    if 'CONFIG_LUA=y\n' in features:
        depends = d.getVar('DEPENDS', False)
        d.setVar('DEPENDS', depends + ' lua')

    if 'CONFIG_UBOOT=y\n' in features:
        depends = d.getVar('DEPENDS', False)
        d.setVar('DEPENDS', depends + ' u-boot-fw-utils')

    if 'CONFIG_DOWNLOAD=y\n' in features or 'CONFIG_SURICATTA=y\n' in features:
        depends = d.getVar('DEPENDS', False)
        d.setVar('DEPENDS', depends + ' curl')

    if 'CONFIG_MTD=y\n' in features:
        depends = d.getVar('DEPENDS', False)
        d.setVar('DEPENDS', depends + ' mtd-utils')

    if 'CONFIG_CFI=y\n' in features:
        depends = d.getVar('DEPENDS', False)
        d.setVar('DEPENDS', depends + ' mtd-utils')

    if 'CONFIG_UBIVOL=y\n' in features:
        depends = d.getVar('DEPENDS', False)
        d.setVar('DEPENDS', depends + ' mtd-utils')
}

do_configure () {
  cp ${WORKDIR}/defconfig ${S}/.config
  merge_config.sh -m .config ${@" ".join(find_cfgs(d))}
  cml1_do_configure
}

do_compile() {
  unset LDFLAGS
  oe_runmake swupdate_unstripped progress_unstripped
  cp swupdate_unstripped swupdate
  cp progress_unstripped progress

}

do_install () {
  install -d ${D}${bindir}/
  install -m 0755 swupdate ${D}${bindir}/

  install -m 0755 -d ${D}/www
  install -m 0755 ${S}www/* ${D}/www

  install -d ${D}${libdir}/
  install -d ${D}${includedir}/
  install -m 0644 ${S}include/network_ipc.h ${D}${includedir}
  install -m 0644 ${S}include/swupdate_status.h ${D}${includedir}
  install -m 0644 ${S}include/progress.h ${D}${includedir}
  install -m 0755 ${S}ipc/lib.a ${D}${libdir}/libswupdate.a

  install -d ${D}${sysconfdir}/init.d
  install -m 755 ${WORKDIR}/swupdate ${D}${sysconfdir}/init.d

  install -d ${D}${systemd_unitdir}/system
  install -m 644 ${WORKDIR}/swupdate.service ${D}${systemd_unitdir}/system
  install -m 644 ${WORKDIR}/swupdate-usb@.service ${D}${systemd_unitdir}/system
  install -m 644 ${WORKDIR}/swupdate-progress.service ${D}${systemd_unitdir}/system


  if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
    install -d ${D}${sysconfdir}/udev/rules.d
    install -m 0644 ${WORKDIR}/swupdate-usb.rules ${D}${sysconfdir}/udev/rules.d/
  fi
}

INITSCRIPT_NAME = "swupdate"
INITSCRIPT_PARAMS = "defaults 70"

SYSTEMD_SERVICE_${PN} = "swupdate.service"
SYSTEMD_SERVICE_${PN} += "swupdate-usb@.service swupdate-progress.service"
