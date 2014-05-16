SUMMARY = "Root file system image for MCX board"
DESCRIPTION = "Root FS includes the following functionality: 				\
		Busybox: standard for ELDK 5.2 (syslogd removed) 			\
		mtd-utils: standard for ELDK 5.2 					\
		base-files: standard script for ELDK 5.2 (/var/log placement changed) 	\
		tinylogin: standard for ELDK 5.2 					\
		sysvinit: standard for ELDK 5.2 (bootlogd removed)			\
		initscripts: modified standard script for ELDK 5.2			\
		"

IMAGE_INSTALL = "base-files \
		busybox \
		mtd-utils \
		libconfig \
		swupdate \
		swupdate-www \
		sysvinit \
		initscripts-swupdate \
		 "

USE_DEVFS = "1"
#IMAGE_DEVICE_TABLES = "files/device_table-minimal.txt"

LIC_FILES_CHKSUM = "file://${COREBASE}/LICENSE;md5=3f40d7994397109285ec7b81fdeb3b58 \
                    file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420 \
		   "

# This variable is triggered to check if sysvinit must be overwritten by a single rcS
export SYSVINIT = "no"

LICENSE = "MIT"

IMAGE_CLASSES += " image_types_uboot"
IMAGE_FSTYPES = "ext3.gz.u-boot"

IMAGE_ROOTFS_SIZE = "8192"

inherit image

remove_locale_data_files() {
	printf "Post processing local %s\n" ${IMAGE_ROOTFS}${libdir}/locale
	rm -rf ${IMAGE_ROOTFS}${libdir}/locale
}

fix_inittab_swupdate () {
	sed -e 's/1\:2345.*/1\:2345:respawn:\/bin\/sh/' \
		"${IMAGE_ROOTFS}${sysconfdir}/inittab" | \
		sed -e 's/^z6/#&/' | \
		 sed -e 's/S:2345.*//' \
		> "${IMAGE_ROOTFS}${sysconfdir}/inittab.swupdate"
	rm ${IMAGE_ROOTFS}${sysconfdir}/inittab
	mv ${IMAGE_ROOTFS}${sysconfdir}/inittab.swupdate ${IMAGE_ROOTFS}${sysconfdir}/inittab
}

exchange_rcs () {
	rm ${IMAGE_ROOTFS}${sysconfdir}/init.d/rcS
	mv ${IMAGE_ROOTFS}${sysconfdir}/init.d/rcS.swupdate \
		${IMAGE_ROOTFS}${sysconfdir}/init.d/rcS
}
	 
# remove not needed ipkg informations
ROOTFS_POSTPROCESS_COMMAND += "remove_locale_data_files ; "
ROOTFS_POSTPROCESS_COMMAND += "fix_inittab_swupdate ; "
ROOTFS_POSTPROCESS_COMMAND += "exchange_rcs ; "
