require swupdate.inc

SRCREV = "1a6dfbb5a0be978ac1a159758e278ab4d44167e2"

SRC_URI += "file://0001-diskpart-force-kernel-to-reread-partition-table.patch \
	    file://0001-Shellscript-stops-before-completing.patch \
	    file://0001-diskpart-fix-adding-more-as-4-partitions.patch \
	    "

# Licenses have been changed and moved for newer releases of swupdate. 2020.04 is now broken.
LIC_FILES_CHKSUM = "file://COPYING;md5=0636e73ff0215e8d672dc4c32c317bb3 \
                    file://Licenses/lgpl-2.1.txt;md5=4fbd65380cdd255951079008b364516c \
                    file://Licenses/mit.txt;md5=838c366f69b72c5df05c96dff79b35f2 \
                    file://Licenses/Exceptions;md5=5f205fe7a7f2b056b4fa42603fe2d63a"

# Building out of tree is broken in this version
B = "${S}"
