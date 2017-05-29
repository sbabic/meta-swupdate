FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}-${PV}:"

SRC_URI += "\
            file://0001-Rename-aes.h-to-uboot_aes.h.patch \
            file://0002-env-split-fw_env.h-in-public-and-private-parts.patch \
            file://0003-env-add-a-version-number-to-check-API.patch \
            file://0004-env-fix-memory-leak-in-fw_env-routines.patch \
        "
