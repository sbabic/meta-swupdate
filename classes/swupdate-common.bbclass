DEPENDS += "\
    cpio-native \
    ${@ 'openssl-native' if d.getVar('SWUPDATE_SIGNING') or d.getVar('SWUPDATE_ENCRYPT_SWDESC') or d.getVarFlags('SWUPDATE_IMAGES_ENCRYPTED') else ''} \
"

do_swuimage[umask] = "022"
SSTATETASKS += "do_swuimage"
SSTATE_SKIP_CREATION_task-swuimage = '1'
SWUDEPLOYDIR = "${WORKDIR}/deploy-${PN}-swuimage"

do_swuimage[dirs] = "${SWUDEPLOYDIR}"
do_swuimage[cleandirs] += "${SWUDEPLOYDIR}"
do_swuimage[sstate-inputdirs] = "${SWUDEPLOYDIR}"
do_swuimage[sstate-outputdirs] = "${DEPLOY_DIR_IMAGE}"
do_swuimage[stamp-extra-info] = "${MACHINE}"

python () {
    deps = " " + swupdate_getdepends(d)
    d.appendVarFlag('do_swuimage', 'depends', deps)
    d.delVarFlag('do_fetch', 'noexec')
    d.delVarFlag('do_unpack', 'noexec')
}

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

def swupdate_get_sha256(s, filename):
    import hashlib

    m = hashlib.sha256()

    with open(os.path.join(s, filename), 'rb') as f:
        while True:
            data = f.read(1024)
            if not data:
                break
            m.update(data)
    return m.hexdigest()

def swupdate_extract_keys(keyfile_path):
    try:
        with open(keyfile_path, 'r') as f:
            lines = f.readlines()
    except IOError:
        bb.fatal("Failed to open file with keys %s" % (keyfile))

    data = {}
    for _ in lines:
        k,v = _.split('=',maxsplit=1)
        data[k.rstrip()] = v

    key = data['key'].rstrip('\n')
    iv = data['iv'].rstrip('\n')

    return key,iv

def swupdate_encrypt_file(f, out, key, ivt):
    import subprocess
    encargs = ["openssl", "enc", "-aes-256-cbc", "-in", f, "-out", out]
    encargs += ["-K", key, "-iv", ivt, "-nosalt"]
    subprocess.run(encargs, check=True)

def swupdate_write_sha256(s):
    import re
    write_lines = []
    with open(os.path.join(s, "sw-description"), 'r') as f:
       for line in f:
          shastr = r"sha256.+=.+@(.+\")"
          #m = re.match(r"^(?P<before_placeholder>.+)sha256.+=.+(?P<filename>\w+)", line)
          m = re.match(r"^(?P<before_placeholder>.+)(sha256|version).+[=:].*(?P<quote>[\'\"])@(?P<filename>.*)(?P=quote)", line)
          if m:
              filename = m.group('filename')
              hash = swupdate_get_sha256(s, filename)
              write_lines.append(line.replace("@%s" % (filename), hash))
          else:
              write_lines.append(line)

    with open(os.path.join(s, "sw-description"), 'w+') as f:
        for line in write_lines:
            f.write(line)

def swupdate_expand_bitbake_variables(d, s):
    write_lines = []

    with open(os.path.join(s, "sw-description"), 'r') as f:
        import re
        for line in f:
            found = False
            while True:
                m = re.match(r"^(?P<before_placeholder>.+)@@(?P<bitbake_variable_name>\w+)@@(?P<after_placeholder>.+)$", line)
                if m:
                    bitbake_variable_value = d.getVar(m.group('bitbake_variable_name'), True)
                    if bitbake_variable_value is None:
                       bitbake_variable_value = ""
                       bb.warn("BitBake variable %s not set" % (m.group('bitbake_variable_name')))
                    line = m.group('before_placeholder') + bitbake_variable_value + m.group('after_placeholder')
                    found = True
                    continue
                else:
                    m = re.match(r"^(?P<before_placeholder>.+)@@(?P<bitbake_variable_name>.+)\[(?P<flag_var_name>.+)\]@@(?P<after_placeholder>.+)$", line)
                    if m:
                       bitbake_variable_value = (d.getVarFlag(m.group('bitbake_variable_name'), m.group('flag_var_name'), True) or "")
                       if bitbake_variable_value is None:
                          bitbake_variable_value = ""
                       line = m.group('before_placeholder') + bitbake_variable_value + m.group('after_placeholder')
                       continue

                    if found:
                       line = line + "\n"
                    break

            write_lines.append(line)

    with open(os.path.join(s, "sw-description"), 'w+') as f:
        for line in write_lines:
            f.write(line)

# Get all the variables referred by the sw-description at parse time.
def swupdate_find_bitbake_variables(d):
    import re

    vardeps = []
    filespath = d.getVar('FILESPATH')
    sw_desc_path = bb.utils.which(filespath, "sw-description")
    try:
        with open(sw_desc_path, "r") as f:
            for line in f:
                found = False
                while True:
                    m = re.match(r"^(?P<before_placeholder>.+)@@(?P<bitbake_variable_name>\w+)@@(?P<after_placeholder>.+)$", line)
                    if m:
                        bitbake_variable_value = m.group('bitbake_variable_name')
                        vardeps.append(bitbake_variable_value)
                        line = m.group('before_placeholder') + bitbake_variable_value + m.group('after_placeholder')
                        found = True
                        continue
                    else:
                        m = re.match(r"^(?P<before_placeholder>.+)@@(?P<bitbake_variable_name>.+)\[(?P<flag_var_name>.+)\]@@(?P<after_placeholder>.+)$", line)
                        if m:
                            bitbake_variable_value = m.group('bitbake_variable_name')
                            vardeps.append(bitbake_variable_value)
                            flag_name = m.group('flag_var_name')
                            vardeps.append(flag_name)
                            line = m.group('before_placeholder') + bitbake_variable_value + m.group('after_placeholder')
                            continue
                        break
    except IOError:
        pass
    return ' '.join(set(vardeps))

def swupdate_expand_auto_versions(d, s):
    import re
    import oe.packagedata
    AUTO_VERSION_TAG = "@SWU_AUTO_VERSION"
    AUTOVERSION_REGEXP = "version\s*=\s*\"%s" % AUTO_VERSION_TAG

    with open(os.path.join(s, "sw-description"), 'r') as f:
        data = f.read()

    def get_package_name(group, file_list):
        package = None

        m = re.search(r"%s:(?P<package>.+?(?=[\"@]))" % (AUTOVERSION_REGEXP), group)
        if m:
            package = m.group('package')
            return (package, True)

        for filename in file_list:
            if filename in group:
                package = filename

        if not package:
            bb.fatal("Failed to find file in group %s" % (group))

        return (package, False)

    def get_packagedata_key(group):
        m = re.search(r"%s.+?(?<=@)(?P<key>.+?(?=\"))" % (AUTOVERSION_REGEXP), group)
        if m:
            return (m.group('key'), True)
        return ("PV", False)

    regexp = re.compile(r"\{[^\{]*%s.[^\}]*\}" % (AUTOVERSION_REGEXP))
    while True:
        m = regexp.search(data)
        if not m:
            break

        group = data[m.start():m.end()]

        (package, pkg_name_defined) = get_package_name(group, (d.getVar('SWUPDATE_IMAGES', True) or "").split())

        pkg_info = os.path.join(d.getVar('PKGDATA_DIR'), 'runtime-reverse', package)
        pkgdata = oe.packagedata.read_pkgdatafile(pkg_info)

        (key, key_defined) = get_packagedata_key(group)

        if not key in pkgdata.keys():
            bb.warn("\"%s\" not set for package %s - using \"1.0\"" % (key, package))
            version = "1.0"
        else:
            version = pkgdata[key].split('+')[0]

        replace_str = AUTO_VERSION_TAG
        if pkg_name_defined:
            replace_str = replace_str + ":" + package
        if key_defined:
            replace_str = replace_str + "@" + key

        group = group.replace(replace_str, version)
        data = data[:m.start()] + group + data[m.end():]

    with open(os.path.join(s, "sw-description"), 'w+') as f:
        f.write(data)

def prepare_sw_description(d):
    import shutil
    import subprocess

    s = d.getVar('S', True)
    swupdate_expand_bitbake_variables(d, s)
    swupdate_expand_auto_versions(d, s)

    swupdate_write_sha256(s)

    encrypt = d.getVar('SWUPDATE_ENCRYPT_SWDESC', True)
    if encrypt:
        bb.note("Encryption of sw-description")
        shutil.copyfile(os.path.join(s, 'sw-description'), os.path.join(s, 'sw-description.plain'))
        key,iv = swupdate_extract_keys(d.getVar('SWUPDATE_AES_FILE', True))
        swupdate_encrypt_file(os.path.join(s, 'sw-description.plain'), os.path.join(s, 'sw-description'), key, iv)

    signing = d.getVar('SWUPDATE_SIGNING', True)
    if signing == "1":
        bb.warn('SWUPDATE_SIGNING = "1" is deprecated, falling back to "RSA". It is advised to set it to "RSA" if using RSA signing.')
        signing = "RSA"
    if signing:
        def get_pwd_file_args():
            pwd_args = []
            pwd_file = d.getVar('SWUPDATE_PASSWORD_FILE', True)
            if pwd_file:
                pwd_args = ["-passin", "file:%s" % pwd_file]
            return pwd_args

        sw_desc_sig = os.path.join(s, 'sw-description.sig')
        sw_desc =  os.path.join(s, 'sw-description.plain' if encrypt else 'sw-description')

        if signing == "CUSTOM":
            signcmd = []
            sign_tool = d.getVar('SWUPDATE_SIGN_TOOL', True)
            signtool = sign_tool.split()
            for i in range(len(signtool)):
                signcmd.append(signtool[i])
            if not signcmd:
                bb.fatal("Custom SWUPDATE_SIGN_TOOL is not given")
        elif signing == "RSA":
            privkey = d.getVar('SWUPDATE_PRIVATE_KEY', True)
            if not privkey:
                bb.fatal("SWUPDATE_PRIVATE_KEY isn't set")
            if not os.path.exists(privkey):
                bb.fatal("SWUPDATE_PRIVATE_KEY %s doesn't exist" % (privkey))
            signcmd = ["openssl", "dgst", "-sha256", "-sign", privkey] + get_pwd_file_args() + ["-out", sw_desc_sig, sw_desc]
        elif signing == "CMS":
            cms_cert = d.getVar('SWUPDATE_CMS_CERT', True)
            if not cms_cert:
                bb.fatal("SWUPDATE_CMS_CERT is not set")
            if not os.path.exists(cms_cert):
                bb.fatal("SWUPDATE_CMS_CERT %s doesn't exist" % (cms_cert))
            cms_key = d.getVar('SWUPDATE_CMS_KEY', True)
            if not cms_key:
                bb.fatal("SWUPDATE_CMS_KEY isn't set")
            if not os.path.exists(cms_key):
                bb.fatal("SWUPDATE_CMS_KEY %s doesn't exist" % (cms_key))
            signcmd = ["openssl", "cms", "-sign", "-in", sw_desc, "-out", sw_desc_sig, "-signer", cms_cert, "-inkey", cms_key] + get_pwd_file_args() + ["-outform", "DER", "-nosmimecap", "-binary"]
        else:
            bb.fatal("Unrecognized SWUPDATE_SIGNING mechanism.")
        subprocess.run(signcmd, check=True)


def swupdate_add_src_uri(d, list_for_cpio):
    import shutil

    s = d.getVar('S', True)

    if d.getVar('SWUPDATE_SIGNING', True):
        list_for_cpio.append('sw-description.sig')
    fetch = bb.fetch2.Fetch([], d)

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

def add_image_to_swu(d, deploydir, imagename, s, encrypt, list_for_cpio):
    import shutil

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

def swupdate_add_artifacts(d, list_for_cpio):
    import shutil
    # Search for images listed in SWUPDATE_IMAGES in the DEPLOY directory.
    images = (d.getVar('SWUPDATE_IMAGES', True) or "").split()
    deploydir = d.getVar('DEPLOY_DIR_IMAGE', True)
    imgdeploydir = d.getVar('SWUDEPLOYDIR', True)
    s = d.getVar('S', True)
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
                    image_found = add_image_to_swu(d, deploydir, imagebase + fstype, s, encrypted, list_for_cpio)
                    if image_found:
                        break
                if not image_found:
                    bb.fatal("swupdate cannot find image file: %s" % os.path.join(deploydir, imagebase + fstype))
        else:  # Allow also complete entries like "image.ext4.gz" in SWUPDATE_IMAGES
            if not add_image_to_swu(d, deploydir, image, s, encrypted, list_for_cpio):
                bb.fatal("swupdate cannot find %s image file" % image)


def swupdate_create_cpio(d, swudeploydir, list_for_cpio):
    s = d.getVar('S', True)
    os.chdir(s)
    updateimage = d.getVar('IMAGE_NAME', True) + '.swu'
    updateimage_link =  d.getVar('IMAGE_LINK_NAME', True) + '.swu'
    line = 'for i in ' + ' '.join(list_for_cpio) + '; do echo $i;done | cpio -ov -H crc > ' + os.path.join(swudeploydir, updateimage)
    os.system(line)
    os.chdir(swudeploydir)
    os.symlink(updateimage, updateimage_link)

python do_swuimage () {
    import shutil

    list_for_cpio = ["sw-description"]
    workdir = d.getVar('WORKDIR', True)
    s = d.getVar('S', True)
    imgdeploydir = d.getVar('SWUDEPLOYDIR', True)
    shutil.copyfile(os.path.join(workdir, "sw-description"), os.path.join(s, "sw-description"))

    # Add artifacts added via SRC_URI
    swupdate_add_src_uri(d, list_for_cpio)
    # Add artifacts set via SWUPDATE_IMAGES
    swupdate_add_artifacts(d, list_for_cpio)

    prepare_sw_description(d)

    swupdate_create_cpio(d, imgdeploydir, list_for_cpio)
}
