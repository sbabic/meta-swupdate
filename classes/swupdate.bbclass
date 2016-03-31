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

S = "${WORKDIR}/${PN}"

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
        depstr += " " + dep + ":do_populate_sysroot"
    return depstr

do_swuimage[dirs] = "${TOPDIR}"
do_swuimage[cleandirs] += "${S}"
do_swuimage[umask] = "022"

do_configure[noexec] = "1"
do_compile[noexec] = "1"
do_install[noexec] = "1"
do_package[noexec] = "1"
do_package_qa[noexec] = "1"
do_packagedata[noexec] = "1"
do_package_write_ipk[noexec] = "1"
do_package_write_deb[noexec] = "1"
do_package_write_rpm[noexec] = "1"

python () {
    deps = " " + swupdate_getdepends(d)
    d.appendVarFlag('do_build', 'depends', deps)
}

do_install () {
}

do_createlink () {
    cd ${DEPLOY_DIR_IMAGE}
    ln -sf ${IMAGE_NAME}.swu ${IMAGE_LINK_NAME}.swu
}

python do_swuimage () {
    import shutil

    workdir = d.getVar('WORKDIR', True)
    images = (d.getVar('SWUPDATE_IMAGES', True) or "").split()
    s = d.getVar('S', True)
    shutil.copyfile(os.path.join(workdir, "sw-description"), os.path.join(s, "sw-description"))
    fetch = bb.fetch2.Fetch([], d)
    list_for_cpio = "sw-description"

    for url in fetch.urls:
        local = fetch.localpath(url)
        filename = os.path.basename(local)
        shutil.copyfile(local, os.path.join(s, "%s" % filename ))
        if (filename != 'sw-description'):
            list_for_cpio += " " + filename

    deploydir = d.getVar('DEPLOY_DIR_IMAGE', True)

    for image in images:
        imagename = image + '-' + d.getVar('MACHINE', True)
        fstypes = (d.getVarFlag("SWUPDATE_IMAGES_FSTYPES", image, True) or "").split()
        for fstype in fstypes:
            imagebase = image + '-' + d.getVar('MACHINE', True)
            imagename = imagebase + fstype
            src = os.path.join(deploydir, "%s" % imagename)
            dst = os.path.join(s, "%s" % imagename)
            shutil.copyfile(src, dst)
            list_for_cpio += " " + imagename

    line = 'for i in ' + list_for_cpio + '; do echo $i;done | cpio -ov -H crc >' + os.path.join(deploydir,d.getVar('IMAGE_NAME', True) + '.swu')
    os.system("cd " + s + ";" + line)
}

COMPRESSIONTYPES = ""
PACKAGE_ARCH = "${MACHINE_ARCH}"

addtask do_swuimage after do_unpack before do_install
addtask do_createlink after do_swuimage before do_install
