SUMMARY = "Root filesystem for swupdate as rescue system including GUI"
DESCRIPTION = "Root FS to start swupdate in rescue mode	\
		"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/GPL-2.0;md5=801f80980d171dd6425610833a22dbe6"

require swupdate-image.inc

IMAGE_INSTALL += " \
	freetype \
	init-ifupdown \
	lua \
	luafilesystem \
	rescuegui \
	swupdate-tools \
	tekui \
	ttf-dejavu-sans \
	ttf-dejavu-sans-mono \
	ttf-dejavu-common \
	u-boot-fw-utils \
	udev \
	udev-extraconf \
	"

IMAGE_FSTYPES += "ext4.gz.u-boot tar.gz ext4.xz"
