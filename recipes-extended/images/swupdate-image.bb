SUMMARY = "Root filesystem for swuupdate as rescue system"
DESCRIPTION = "Root FS to start swupdate in rescue mode	\
		"

IMAGE_INSTALL = "base-files \
		base-passwd \
		busybox \
		mtd-utils \
		mtd-utils-ubifs \
		libconfig \
		swupdate \
		swupdate-www \
                ${@bb.utils.contains('SWUPDATE_INIT', 'tiny', 'initscripts-swupdate', 'initscripts sysvinit', d)} \
		util-linux-sfdisk \
		 "

USE_DEVFS = "1"

# This variable is triggered to check if sysvinit must be overwritten by a single rcS
export SYSVINIT = "no"

LICENSE = "MIT"

IMAGE_CLASSES += " image_types_uboot"
IMAGE_FSTYPES = "ext3.gz.u-boot"

IMAGE_ROOTFS_SIZE = "8192"

inherit image

IMAGE_LINGUAS = " "

fix_inittab_swupdate () {
	sed -e 's/1\:2345.*/1\:2345:respawn:\/bin\/sh/' \
		"${IMAGE_ROOTFS}${sysconfdir}/inittab" | \
		sed -e 's/^z6/#&/' | \
		 sed -e 's/.*getty.*//' \
		> "${IMAGE_ROOTFS}${sysconfdir}/inittab.swupdate"
	rm ${IMAGE_ROOTFS}${sysconfdir}/inittab
	mv ${IMAGE_ROOTFS}${sysconfdir}/inittab.swupdate ${IMAGE_ROOTFS}${sysconfdir}/inittab
}

ROOTFS_POSTPROCESS_COMMAND += "${@bb.utils.contains('SWUPDATE_INIT', 'tiny', 'fix_inittab_swupdate', '',  d)}"
