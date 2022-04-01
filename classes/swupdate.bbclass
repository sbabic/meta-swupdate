# Copyright (C) 2015-2021 Stefano Babic <sbabic@denx.de>
#
# SPDX-License-Identifier: GPLv3
#
# Some parts from the patch class
#
# swupdate allows to generate a compound image for the
# in the "swupdate" format, used for updating the targets
# in field.
# See also http://sbabic.github.io/swupdate/
#
# To use this class, add swupdate to the inherit clause of the update image bb file.
# The generated output file is an swu archive ready to be uploaded to a device running
# swupdate.
#
# Files listed in the SRC_URI variable are added the the swu archive.
#
# For each entry in the SWUPDATE_IMAGES variable an image file is searched for in the
# ${DEPLOY_DIR_IMAGE} folder and added to the swu archive. Different types of entries
# are supported:
# * image name(s) and fstype(s):
#   Example:
#     SWUPDATE_IMAGES = "core-image-full-cmdline"
#     SWUPDATE_IMAGES_FSTYPES[core-image-full-cmdline] = ".ext4.gz"
#   For this example either a file core-image-full-cmdline-${MACHINE}.ext4.gz or a file
#   core-image-full-cmdline.ext4.gz gets added the swu archive. Optionally the variable
#   SWUPDATE_IMAGES_NOAPPEND_MACHINE allows to explicitly define if the MACHINE name
#   must be part of the image file name or not.
# * image file name(s)
#   Example:
#     SWUPDATE_IMAGES = "core-image-full-cmdline.ext4.gz"
#   If SWUPDATE_IMAGES_FSTYPES is not defined for an entry in SWUPDATE_IMAGES or the
#   corresponding image files cannot be found in the ${DEPLOY_DIR_IMAGE} folder, an
#   image file with exactly the name as specified in SWUPDATE_IMAGES is searched for.

inherit swupdate-common.bbclass

S = "${WORKDIR}/${PN}"

IMAGE_DEPENDS ?= ""

do_configure[noexec] = "1"
do_compile[noexec] = "1"
do_install[noexec] = "1"
deltask do_populate_sysroot
do_package[noexec] = "1"
deltask do_package_qa
do_packagedata[noexec] = "1"
do_package_write_ipk[noexec] = "1"
do_package_write_deb[noexec] = "1"
do_package_write_rpm[noexec] = "1"

COMPRESSIONTYPES = ""
PACKAGE_ARCH = "${MACHINE_ARCH}"

INHIBIT_DEFAULT_DEPS = "1"
EXCLUDE_FROM_WORLD = "1"

addtask do_swuimage after do_unpack do_prepare_recipe_sysroot before do_build
