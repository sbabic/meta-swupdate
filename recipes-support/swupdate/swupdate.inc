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
     "

PACKAGES =+ " \
    ${PN}-client \
    ${PN}-lua \
    ${PN}-progress \
    ${PN}-progress-sd \
    ${PN}-sd \
    ${PN}-sv \
    ${PN}-tools \
    ${PN}-tools-hawkbit \
    ${PN}-usb \
    ${PN}-usb-sd \
    ${PN}-www \
"

FILES_${PN}-client = "${bindir}/swupdate-client"
FILES_${PN}-lua += "${libdir}/lua/"
FILES_${PN}-progress = "${bindir}/swupdate-progress"
FILES_${PN}-progress-sd = "${systemd_system_unitdir}/swupdate-progress.service"
FILES_${PN}-sd = " \
    ${systemd_system_unitdir}/swupdate.socket \
    ${systemd_system_unitdir}/swupdate.service \
"
FILES_${PN}-sv = "${sysconfdir}/init.d/*"
FILES_${PN}-usb = "${sysconfdir}/udev/rules.d/swupdate-usb.rules"
FILES_${PN}-usb-sd = "${systemd_system_unitdir}/swupdate-usb@.service"
FILES_${PN}-tools-hawkbit = " \
    ${bindir}/swupdate-hawkbitcfg \
    ${bindir}/swupdate-sendtohawkbit \
"
FILES_${PN} += " \
    ${libdir}/tmpfiles.d \
    ${libdir}/swupdate/* \
"
FILES_${PN}-www = " \
    ${libdir}/swupdate/conf.d/*mongoose* \
    /www/* \
"

RDEPENDS_${PN}-progress += "${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'swupdate-progress-sd', '', d)}"
RDEPENDS_${PN}-usb += "${PN}-client ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'swupdate-usb-sd', '', d)}"
RDEPENDS_${PN} += "${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'swupdate-sd', 'swupdate-sv', d)}"

# The tools package is deprecated, it is an empty meta package for backward compatibility
RDEPENDS_${PN}-tools += "${PN}-client ${PN}-progress ${PN}-tools-hawkbit ${PN}-usb"


S = "${WORKDIR}/git/"

EXTRA_OEMAKE += " HOSTCC="${BUILD_CC}" HOSTCXX="${BUILD_CXX}" LD="${CC}" DESTDIR="${D}" V=1 ARCH=${TARGET_ARCH} CROSS_COMPILE=${TARGET_PREFIX} SKIP_STRIP=y"

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
        if 'CONFIG_UBOOT_NEWAPI=y\n' in features:
            d.setVar('DEPENDS', depends + ' libubootenv')
        else:
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

    if 'CONFIG_UCFWHANDLER=y\n' in features:
        depends = d.getVar('DEPENDS', False)
        d.setVar('DEPENDS', depends + ' libgpiod')

    if 'CONFIG_SWUFORWARDER_HANDLER=y\n' in features:
        depends = d.getVar('DEPENDS', False)
        d.setVar('DEPENDS', depends + ' curl libwebsockets uriparser')

    if 'CONFIG_RDIFFHANDLER=y\n' in features:
        depends = d.getVar('DEPENDS', False)
        d.setVar('DEPENDS', depends + ' librsync')

    if 'CONFIG_MONGOOSE_WEB_API_V2=y\n' in features:
        d.setVar('SWUPDATE_WWW', 'webapp')

    if 'CONFIG_BOOTLOADER_EBG=y\n' in features:
        depends = d.getVar('DEPENDS', False)
        d.setVar('DEPENDS', depends + ' efibootguard')
}

do_configure () {
    # Always install systemd support and the swupdate.sh shell wrapper.
    # This allows to build swupdate packages init manager agnostic and splitt the file to separate packages.
    #grep -v 'CONFIG_SYSTEMD' ${WORKDIR}/defconfig > ${S}/.config
    #echo "# Global settings from swupdate recipe" >> ${S}/.config
    #echo "CONFIG_SYSTEMD=y" >> ${S}/.config
    #echo "CONFIG_SYSTEMD_SYSTEM_UNITDIR=\"${systemd_system_unitdir}\"" >> ${S}/.config

    cp ${WORKDIR}/defconfig ${S}/.config
    merge_config.sh -m .config ${@" ".join(find_cfgs(d))}
    cml1_do_configure
}

do_compile() {
  unset LDFLAGS
  oe_runmake
}

do_install () {

  oe_runmake install

  install -m 0755 -d ${D}/www
  if [ -d ${S}/web-app ];then
	cp -R --no-dereference --preserve=mode,links -v ${S}/examples/www/v2/* ${D}/www
  else
	install -m 0755 ${S}/www/* ${D}/www
  fi

  install -d ${D}${sysconfdir}/init.d
  install -m 755 ${WORKDIR}/swupdate ${D}${sysconfdir}/init.d
}

INITSCRIPT_NAME = "swupdate"
INITSCRIPT_PARAMS = "defaults 70"

SYSTEMD_PACKAGES_append = " ${PN}-sd ${PN}-progress-sd ${PN}-usb-sd"
SYSTEMD_SERVICE_${PN}-sd = "swupdate.service"
SYSTEMD_SERVICE_${PN}-progress-sd = "swupdate-progress.service"
SYSTEMD_SERVICE_${PN}-usb-sd = "swupdate-usb@.service"

# Prevents the systemd.bbclass from deleting scripts or service files.
rm_systemd_unitdir () {
    return 0
}
rm_sysvinit_initddir () {
    return 0
}
