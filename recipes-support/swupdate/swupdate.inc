SUMMARY="Image updater for Yocto projects"
DESCRIPTION = "Application for automatic software update from USB Pen"
SECTION="swupdate"
DEPENDS += "libconfig zlib"

# SWUpdate licensing is described in the following pages:
# https://sbabic.github.io/swupdate/licensing.html
# rst form: file://doc/source/licensing.rst
LICENSE = "GPLv2+ & LGPLv2+ & MIT"
LICENSE_${PN}-lua = "LGPLv2+"
LICENSE_${PN}-www = "MIT"
LIC_FILES_CHKSUM = "file://LICENSES/GPL-2.0-only.txt;md5=4ee23c52855c222cba72583d301d2338 \
                    file://LICENSES/LGPL-2.1-or-later.txt;md5=4fbd65380cdd255951079008b364516c \
                    file://LICENSES/MIT.txt;md5=838c366f69b72c5df05c96dff79b35f2 \
                    file://LICENSES/BSD-3-Clause.txt;md5=4a1190eac56a9db675d58ebe86eaf50c"

inherit cml1 update-rc.d systemd pkgconfig

SRC_URI = "git://github.com/sbabic/swupdate.git;protocol=https;branch=master \
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

LTOEXTRA += "-flto-partition=none"

PACKAGES =+ " \
    ${PN}-client \
    ${PN}-lua \
    ${PN}-progress \
    ${PN}-tools \
    ${PN}-tools-hawkbit \
    ${PN}-tools-ipc \
    ${PN}-usb \
    ${PN}-www \
"
INSANE_SKIP_${PN}-lua = "dev-so"
wwwdir ?= "/www"

# tools is now an empty meta package for backward compatibility
ALLOW_EMPTY_${PN}-tools = "1"
ALLOW_EMPTY_${PN}-tools-hawkbit = "1"
ALLOW_EMPTY_${PN}-tools-ipc = "1"

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
FILES_${PN}-tools-ipc = " \
    ${bindir}/swupdate-ipc \
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
    ${wwwdir}/* \
"

RDEPENDS_${PN}-usb += "${PN}-client"

# The tools package is deprecated, it is an empty meta package for backward compatibility
RDEPENDS_${PN}-tools += "${PN}-client ${PN}-progress ${PN}-tools-hawkbit \
    ${@bb.utils.contains('DISTRO_FEATURES','systemd','${PN}-usb','',d)} \
"

S = "${WORKDIR}/git"
B = "${WORKDIR}/build"

EXTRA_OEMAKE += " O=${B} HOSTCC="${BUILD_CC}" HOSTCXX="${BUILD_CXX}" LD="${CC}" DESTDIR="${D}" LIBDIR="${libdir}" V=1 ARCH=${TARGET_ARCH} CROSS_COMPILE=${TARGET_PREFIX} SKIP_STRIP=y"

DEPENDS += "kern-tools-native"

# returns all the elements from the src uri that are .cfg files
def find_cfgs(d):
    return [s for s in src_patches(d, True) if s.endswith('.cfg')]

python () {
    import re

    try:
        defconfig = bb.fetch2.localpath('file://defconfig', d)
    except bb.fetch2.FetchError:
        return

    try:
        configfile = open(defconfig)
    except IOError:
        return

    features = configfile.read()
    configfile.close()

    for current_fragment in find_cfgs(d):
        try:
            fragment_fd = open(current_fragment)
        except IOError:
            continue

        fragment = fragment_fd.read()
        fragment_fd.close()

        fragment_search = re.findall('^(?:# )?(CONFIG_[a-zA-Z0-9_]*)[= ].*\n?', fragment, re.MULTILINE)

        for feature in fragment_search:
            features = re.sub("^(?:# )?" + feature + "[= ].*\n?", "", features, flags=re.MULTILINE)

        features = features + fragment

    features = features.splitlines(True)


    depends = d.getVar('DEPENDS', False)

    if 'CONFIG_REMOTE_HANDLER=y\n' in features:
        depends += ' zeromq'

    if 'CONFIG_SSL_IMPL_OPENSSL=y\n' in features:
        depends += ' openssl'
    elif 'CONFIG_SSL_IMPL_MBEDTLS=y\n' in features:
        depends += ' mbedtls'
    elif 'CONFIG_SSL_IMPL_WOLFSSL=y\n' in features:
        depends += ' wolfssl'

    if 'CONFIG_JSON=y\n' in features:
        depends += ' json-c'

    if 'CONFIG_SYSTEMD=y\n' in features:
        depends += ' systemd'

    if 'CONFIG_ARCHIVE=y\n' in features:
        depends += ' libarchive'

    if 'CONFIG_LUA=y\n' in features:
        depends += ' lua'

    if 'CONFIG_UBOOT=y\n' in features:
        depends += ' libubootenv'

    if 'CONFIG_DOWNLOAD=y\n' in features or 'CONFIG_SURICATTA=y\n' in features:
        depends += ' curl'

    if 'CONFIG_MTD=y\n' in features or 'CONFIG_CFI=y\n' in features or 'CONFIG_UBIVOL=y\n' in features:
        depends += ' mtd-utils'

    if 'CONFIG_UCFWHANDLER=y\n' in features:
        depends += ' libgpiod'

    if 'CONFIG_SWUFORWARDER_HANDLER=y\n' in features:
        depends += ' curl libwebsockets uriparser'

    if 'CONFIG_RDIFFHANDLER=y\n' in features:
        depends += ' librsync'

    if 'CONFIG_BOOTLOADER_EBG=y\n' in features:
        depends += ' efibootguard'

    if 'CONFIG_ZSTD=y\n' in features:
        depends += ' zstd'

    if 'CONFIG_DISKPART=y\n' in features:
        depends += ' util-linux e2fsprogs'

    d.setVar('DEPENDS', depends)

    if 'CONFIG_MONGOOSE=y\n' in features:
        d.setVar('SWUPDATE_MONGOOSE', 'true')
    else:
        d.setVar('SWUPDATE_MONGOOSE', 'false')

    if 'CONFIG_MONGOOSE_WEB_API_V2=y\n' in features:
        d.setVar('SWUPDATE_WWW', 'webapp')

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
    cat > ${WORKDIR}/.config <<HEREDOC
CONFIG_EXTRA_CFLAGS="${CFLAGS}"
CONFIG_EXTRA_LDFLAGS="${LDFLAGS}"
HEREDOC
    cat ${WORKDIR}/defconfig >> ${WORKDIR}/.config

    merge_config.sh -O ${B} -m ${WORKDIR}/.config ${@" ".join(find_cfgs(d))}
    (cd ${S} && cml1_do_configure)
}

do_compile() {
    unset LDFLAGS
    (cd ${S} && oe_runmake)
}

do_install () {
    (cd ${S} && oe_runmake install)

    install -m 0755 -d ${D}${wwwdir}
    if [ -d ${S}/web-app ];then
        cp -R --no-dereference --preserve=mode,links -v ${S}/examples/www/v2/* ${D}${wwwdir}
    else
        install -m 0755 ${S}/www/* ${D}${wwwdir}
    fi

    install -d ${D}${sysconfdir}/init.d
    install -m 755 ${WORKDIR}/swupdate ${D}${sysconfdir}/init.d
    sed -i -e "s|/usr/lib/|${libdir}/|" ${D}${sysconfdir}/init.d/swupdate

    # shell based configuration loader allows to place code snippets into this folder
    install -d ${D}${libdir}/swupdate/conf.d
    install -m 755 ${WORKDIR}/swupdate.sh ${D}${libdir}/swupdate
    sed -i 's#@LIBDIR@#${libdir}#g' ${D}${libdir}/swupdate/swupdate.sh
    if ${SWUPDATE_MONGOOSE}; then
        install -m 644 ${WORKDIR}/10-mongoose-args ${D}${libdir}/swupdate/conf.d/
    fi
    install -d ${D}${systemd_unitdir}/system
    install -m 644 ${WORKDIR}/swupdate.service ${D}${systemd_system_unitdir}
    sed -i 's#@LIBDIR@#${libdir}#' ${D}${systemd_system_unitdir}/swupdate.service
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
