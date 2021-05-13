# Copyright (C) 2015 Stefano Babic <sbabic@denx.de>
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

    # Add files listed in SRC_URI to the swu file
    for url in fetch.urls:
        local = fetch.localpath(url)
        filename = os.path.basename(local)
        aes_file = d.getVar('SWUPDATE_AES_FILE', True)
        if aes_file:
            key,iv = swupdate_extract_keys(d.getVar('SWUPDATE_AES_FILE', True))
        if (filename != 'sw-description') and (os.path.isfile(local)):
            encrypted = (d.getVarFlag("SWUPDATE_IMAGES_ENCRYPTED", filename, True) or "")
            dst = os.path.join(s, "%s" % filename )
            if encrypted == '1':
                bb.note("Encryption requested for %s" %(filename))
                if not key or not iv:
                    bb.fatal("Encryption required, but no key found")
                swupdate_encrypt_file(local, dst, key, iv)
            else:
                shutil.copyfile(local, dst)
            list_for_cpio.append(filename)

    def add_image_to_swu(deploydir, imagename, s, encrypt):
        src = os.path.join(deploydir, imagename)
        if not os.path.isfile(src):
            return False
        target_imagename = os.path.basename(imagename)  # allow images in subfolders of DEPLOY_DIR_IMAGE
        dst = os.path.join(s, target_imagename)
        if encrypt == '1':
            key,iv = swupdate_extract_keys(d.getVar('SWUPDATE_AES_FILE', True))
            bb.note("Encryption requested for %s" %(imagename))
            swupdate_encrypt_file(src, dst, key, iv)
        else:
            shutil.copyfile(src, dst)
        list_for_cpio.append(target_imagename)
        return True

    # Search for images listed in SWUPDATE_IMAGES in the DEPLOY directory.
    deploydir = d.getVar('DEPLOY_DIR_IMAGE', True)
    imgdeploydir = d.getVar('IMGDEPLOYDIR', True)
    for image in images:
        fstypes = (d.getVarFlag("SWUPDATE_IMAGES_FSTYPES", image, True) or "").split()
        encrypted = (d.getVarFlag("SWUPDATE_IMAGES_ENCRYPTED", image, True) or "")
        if fstypes:
            noappend_machine = d.getVarFlag("SWUPDATE_IMAGES_NOAPPEND_MACHINE", image, True)
            if noappend_machine == "0":  # Search for a file explicitly with MACHINE
                imagebases = [ image + '-' + d.getVar('MACHINE', True) ]
            elif noappend_machine == "1":  # Search for a file explicitly without MACHINE
                imagebases = [ image ]
            else:  # None, means auto mode. Just try to find an image file with MACHINE or without MACHINE
                imagebases = [ image + '-' + d.getVar('MACHINE', True), image ]
            for fstype in fstypes:
                image_found = False
                for imagebase in imagebases:
                    image_found = add_image_to_swu(deploydir, imagebase + fstype, s, encrypted)
                    if image_found:
                        break
                if not image_found:
                    bb.fatal("swupdate cannot find image file: %s" % os.path.join(deploydir, imagebase + fstype))
        else:  # Allow also complete entries like "image.ext4.gz" in SWUPDATE_IMAGES
            if not add_image_to_swu(deploydir, image, s, encrypted):
                bb.fatal("swupdate cannot find %s image file" % image)

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

addtask do_swuimage after do_unpack do_prepare_recipe_sysroot before do_build
