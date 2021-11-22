# Copyright (C) 2015-2021 Stefano Babic <sbabic@denx.de>
#
# This class is thought to be used in an image recipe.
# It generates a SWU file from the image itself
# User *must* add a sw-descitpion file
#
# To use this class, add the inherit clause of the update image bb file.
# The generated output file is an swu archive ready to be uploaded to a device running
# swupdate.

inherit swupdate-common.bbclass
inherit image-artifact-names

S = "${WORKDIR}/${PN}"

SRC_URI += "file://sw-description"
SWUPDATE_IMAGES += "${IMAGE_BASENAME}"

python do_swupdate_copy_swdescription() {

    import shutil

    workdir = d.getVar('S', True)
    image = d.getVar('IMAGE_BASENAME', True)
    filespath = d.getVar('FILESPATH')
    sw_desc_path = bb.utils.which(filespath, "sw-description")
    shutil.copyfile(sw_desc_path, os.path.join(workdir, "sw-description"))

    if d.getVarFlag("SWUPDATE_IMAGES_FSTYPES", image) is None:
       bb.fatal("SWUPDATE_IMAGES_FSTYPES[%s] is not set !" % image)
}

addtask swupdate_copy_swdescription before do_image_complete after do_unpack
addtask swuimage after do_swupdate_copy_swdescription do_image_complete before do_build

# Read all variables from sw-description file and add them to the vardeps of the do_swuimage task. Bitbake
# cannot know that the do_swuimage task which evaluates the templated sw-description file needs to be executed
# if a variable which is refered by the sw-description file but not by the recipe itself.
do_swuimage[vardeps] ?= "${@swupdate_find_bitbake_variables(d)}"
