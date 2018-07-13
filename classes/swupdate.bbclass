# Copyright (C) 2015 Stefano Babic <sbabic@denx.de>
#
# Some parts from the patch class
#
# swupdate allows to generate a compound image for the
# in the "swupdate" format, used for updating the targets
# in field.
# See also http://sbabic.github.io/swupdate/
#
#
# To use, add swupdate to the inherit clause and set
# set the images (all of them must be found in deploy directory)
# that are part of the compound image.
inherit swupdate-common.bbclass

S = "${WORKDIR}/${PN}"

DEPENDS += "${@ 'openssl-native' if d.getVar('SWUPDATE_SIGNING', True) else ''}"
IMAGE_DEPENDS ?= ""

def swupdate_getdepends(d):
    def adddep(depstr, deps):
        for i in (depstr or "").split():
            if i not in deps:
                deps.append(i)

    deps = []
    images = (d.getVar('IMAGE_DEPENDS', True) or "").split()
    for image in images:
            adddep(image , deps)

    depstr = ""
    for dep in deps:
        depstr += " " + dep + ":do_build"
    return depstr

IMGDEPLOYDIR = "${WORKDIR}/deploy-${PN}-swuimage"

do_swuimage[dirs] = "${TOPDIR}"
do_swuimage[cleandirs] += "${S} ${IMGDEPLOYDIR}"
do_swuimage[umask] = "022"
SSTATETASKS += "do_swuimage"
SSTATE_SKIP_CREATION_task-swuimage = '1'
do_swuimage[sstate-inputdirs] = "${IMGDEPLOYDIR}"
do_swuimage[sstate-outputdirs] = "${DEPLOY_DIR_IMAGE}"
do_swuimage[stamp-extra-info] = "${MACHINE}"

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

python () {
    deps = " " + swupdate_getdepends(d)
    d.appendVarFlag('do_swuimage', 'depends', deps)
}

python do_swuimage () {
    import shutil

    workdir = d.getVar('WORKDIR', True)
    images = (d.getVar('SWUPDATE_IMAGES', True) or "").split()
    s = d.getVar('S', True)
    shutil.copyfile(os.path.join(workdir, "sw-description"), os.path.join(s, "sw-description"))
    fetch = bb.fetch2.Fetch([], d)
    list_for_cpio = ["sw-description"]

    if d.getVar('SWUPDATE_SIGNING', True):
        list_for_cpio.append('sw-description.sig')

    for url in fetch.urls:
        local = fetch.localpath(url)
        filename = os.path.basename(local)
        if (filename != 'sw-description'):
            shutil.copyfile(local, os.path.join(s, "%s" % filename ))
            list_for_cpio.append(filename)

# SWUPDATE_IMAGES refers to images in the DEPLOY directory
# If they are not there, additional file can be added
# by fetching from URLs
    deploydir = d.getVar('DEPLOY_DIR_IMAGE', True)
    imgdeploydir = d.getVar('IMGDEPLOYDIR', True)

    for image in images:
        fstypes = (d.getVarFlag("SWUPDATE_IMAGES_FSTYPES", image, True) or "").split()
        if not fstypes:
            fstypes = [""]

        for fstype in fstypes:

            appendmachine = d.getVarFlag("SWUPDATE_IMAGES_NOAPPEND_MACHINE", image, True)
            if appendmachine == None:
                imagebase = image + '-' + d.getVar('MACHINE', True)
            else:
                imagebase = image

            imagename = imagebase + fstype
            src = os.path.join(deploydir, "%s" % imagename)
            dst = os.path.join(s, "%s" % imagename)
            shutil.copyfile(src, dst)
            list_for_cpio.append(imagename)

    prepare_sw_description(d, s, list_for_cpio)

    line = 'for i in ' + ' '.join(list_for_cpio) + '; do echo $i;done | cpio -ov -H crc >' + os.path.join(imgdeploydir,d.getVar('IMAGE_NAME', True) + '.swu')
    os.system("cd " + s + ";" + line)

    line = 'ln -sf ' + d.getVar('IMAGE_NAME', True) + '.swu ' + d.getVar('IMAGE_LINK_NAME', True) + '.swu'
    os.system("cd " + imgdeploydir + "; " + line)
}

COMPRESSIONTYPES = ""
PACKAGE_ARCH = "${MACHINE_ARCH}"

INHIBIT_DEFAULT_DEPS = "1"
EXCLUDE_FROM_WORLD = "1"

addtask do_swuimage after do_unpack after do_prepare_recipe_sysroot before do_build
