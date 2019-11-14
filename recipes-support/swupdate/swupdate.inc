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
    file://swupdate.sh \
    file://swupdate.service \
    file://swupdate.socket.tmpl \
    file://swupdate-usb.rules \
    file://swupdate-usb@.service \
    file://swupdate-progress.service \
    file://tmpfiles-swupdate.conf \
    file://10-mongoose-args \
    file://90-start-progress \
"

PACKAGES =+ " \
    ${PN}-client \
    ${PN}-lua \
    ${PN}-progress \
    ${PN}-tools \
    ${PN}-tools-hawkbit \
    ${PN}-usb \
    ${PN}-www \
"

# tools is now an empty meta package for backward compatibility
ALLOW_EMPTY_${PN}-tools = "1"

FILES_${PN}-client = "${bindir}/swupdate-client"
FILES_${PN}-lua += "${libdir}/lua/"
FILES_${PN}-progress = " \
    ${bindir}/swupdate-progress \
    ${systemd_system_unitdir}/swupdate-progress.service \
    ${libdir}/swupdate/conf.d/90-start-progress \
"
FILES_${PN}-usb = " \
    ${sysconfdir}/udev/rules.d/swupdate-usb.rules \
    ${systemd_system_unitdir}/swupdate-usb@.service \
"
FILES_${PN}-tools-hawkbit = " \
    ${bindir}/swupdate-hawkbitcfg \
    ${bindir}/swupdate-sendtohawkbit \
"
FILES_${PN} += " \
    ${libdir}/tmpfiles.d \
    ${libdir}/swupdate/* \
    ${systemd_system_unitdir}/swupdate.socket \
    ${systemd_system_unitdir}/swupdate.service \
    ${sysconfdir}/init.d/* \
"
FILES_${PN}-www = " \
    ${libdir}/swupdate/conf.d/*mongoose* \
    /www/* \
"

RDEPENDS_${PN}-usb += "${PN}-client"

# The tools package is deprecated, it is an empty meta package for backward compatibility
RDEPENDS_${PN}-tools += "${PN}-client ${PN}-progress ${PN}-tools-hawkbit \
    ${@bb.utils.contains('DISTRO_FEATURES','systemd','${PN}-usb','',d)} \
"

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

    if 'CONFIG_MONGOOSE=y\n' in features:
        d.setVar('SWUPDATE_MONGOOSE', 'true')
    else:
        d.setVar('SWUPDATE_MONGOOSE', 'false')

    if 'CONFIG_MONGOOSE_WEB_API_V2=y\n' in features:
        d.setVar('SWUPDATE_WWW', 'webapp')

    if 'CONFIG_BOOTLOADER_EBG=y\n' in features:
        depends = d.getVar('DEPENDS', False)
        d.setVar('DEPENDS', depends + ' efibootguard')

    # Values not used here might be used in a bbappend
    d.setVar('SWUPDATE_SOCKET_CTRL_PATH', '/tmp/sockinstctrl')
    d.setVar('SWUPDATE_SOCKET_PROGRESS_PATH', '/tmp/swupdateprog')
    d.setVar('SWUPDATE_HW_COMPATIBILITY_FILE', '/etc/hwrevision')
    d.setVar('SWUPDATE_SW_VERSIONS_FILE', '/etc/sw-versions')
    for feature in features:
        if feature.startswith('CONFIG_SOCKET_CTRL_PATH='):
            ctrl_path = feature.split('=')[1].strip()
            d.setVar('SWUPDATE_SOCKET_CTRL_PATH', ctrl_path)
        elif feature.startswith('CONFIG_SOCKET_PROGRESS_PATH='):
            prog_path = feature.split('=')[1].strip()
            d.setVar('SWUPDATE_SOCKET_PROGRESS_PATH', prog_path)
        elif feature.startswith('CONFIG_HW_COMPATIBILITY_FILE='):
            hwrev_file = feature.split('=')[1].strip()
            d.setVar('SWUPDATE_HW_COMPATIBILITY_FILE', hwrev_file)
        elif feature.startswith('CONFIG_SW_VERSIONS_FILE='):
            swver_file = feature.split('=')[1].strip()
            d.setVar('SWUPDATE_SW_VERSIONS_FILE', swver_file)
}

do_configure () {
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

    # shell based configuration loader allows to place code snippets into this folder
    install -d ${D}${libdir}/swupdate/conf.d
    install -m 755 ${WORKDIR}/swupdate.sh ${D}${libdir}/swupdate
    if ${SWUPDATE_MONGOOSE}; then
        install -m 644 ${WORKDIR}/10-mongoose-args ${D}${libdir}/swupdate/conf.d/
    fi
    install -d ${D}${systemd_unitdir}/system
    install -m 644 ${WORKDIR}/swupdate.service ${D}${systemd_system_unitdir}
    install -m 644 ${WORKDIR}/swupdate.socket.tmpl ${D}${systemd_system_unitdir}/swupdate.socket
    sed -e "s,@@SWUPDATE_SOCKET_CTRL_PATH@@,${SWUPDATE_SOCKET_CTRL_PATH},g" \
        -e "s,@@SWUPDATE_SOCKET_PROGRESS_PATH@@,${SWUPDATE_SOCKET_PROGRESS_PATH},g" \
        -i ${D}${systemd_system_unitdir}/swupdate.socket
    install -m 644 ${WORKDIR}/swupdate-usb@.service ${D}${systemd_system_unitdir}
    install -m 644 ${WORKDIR}/swupdate-progress.service ${D}${systemd_system_unitdir}

    if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
        install -d ${D}${libdir}/tmpfiles.d
        install -m 0644 ${WORKDIR}/tmpfiles-swupdate.conf ${D}${libdir}/tmpfiles.d/swupdate.conf
        install -d ${D}${sysconfdir}/udev/rules.d
        install -m 0644 ${WORKDIR}/swupdate-usb.rules ${D}${sysconfdir}/udev/rules.d/
    else
        # in case of systemd there is a service file, for sysv init we need to start it as well
        install -m 0644 ${WORKDIR}/90-start-progress ${D}${libdir}/swupdate/conf.d/
    fi
}

INITSCRIPT_NAME = "swupdate"
INITSCRIPT_PARAMS = "defaults 70"

SYSTEMD_PACKAGES = "${PN} ${PN}-progress ${PN}-usb"
SYSTEMD_SERVICE_${PN} = "swupdate.service swupdate.socket"
SYSTEMD_SERVICE_${PN}-progress = "swupdate-progress.service"
SYSTEMD_SERVICE_${PN}-usb = "swupdate-usb@.service"
