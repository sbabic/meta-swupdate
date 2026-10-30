# Copyright (C) 2015-2026 Stefano Babic
#
# SPDX-License-Identifier: GPLv3
#
# The SWU is created by swugenerator: this class collects the artifacts,
# expands the BitBake variables and functions in sw-description and calls
# swugenerator to hash, encrypt, sign and pack them.

inherit swupdate-lib

S = "${UNPACKDIR}"

DEPENDS += "\
    swugenerator-native \
    ${@ 'openssl-native' if d.getVar('SWUPDATE_SIGNING') or d.getVar('SWUPDATE_ENCRYPT_SWDESC') or d.getVarFlags('SWUPDATE_IMAGES_ENCRYPTED') else ''} \
"

# Where the artifacts are collected for swugenerator
SWUPDATE_ARTIFACTS_DIR = "${WORKDIR}/swu-artifacts"
# Further arguments for swugenerator, e.g. "-l DEBUG"
SWUGENERATOR_EXTRA_ARGS ??= ""
# "1": a new IV for each encrypted artifact, else the IV of SWUPDATE_AES_FILE
SWUPDATE_UNIQUE_IV ??= ""
# "1": encrypted artifacts keep their name, as before swugenerator, else
# swugenerator appends ".enc" to it, in the SWU and in sw-description
SWUPDATE_KEEP_NAMES ??= "1"

do_swuimage[umask] = "022"
SSTATETASKS += "do_swuimage"
SSTATE_SKIP_CREATION:task-swuimage = '1'
SWUDEPLOYDIR = "${WORKDIR}/deploy-${PN}-swuimage"

do_swuimage[dirs] = "${SWUDEPLOYDIR}"
do_swuimage[cleandirs] += "${SWUDEPLOYDIR} ${SWUPDATE_ARTIFACTS_DIR}"
do_swuimage[sstate-inputdirs] = "${SWUDEPLOYDIR}"
do_swuimage[sstate-outputdirs] = "${DEPLOY_DIR_IMAGE}"
do_swuimage[stamp-extra-info] = "${IMAGE_MACHINE_SUFFIX}"

python () {
    deps = " " + swupdate_getdepends(d)
    d.appendVarFlag('do_swuimage', 'depends', deps)
    d.delVarFlag('do_fetch', 'noexec')
    d.delVarFlag('do_unpack', 'noexec')
}

def get_pwd_file_args(d, passfile):
    pwd_args = []
    pwd_file = d.getVar(passfile)
    if pwd_file:
       pwd_args = ["-passin", "file:%s" % pwd_file]
    return pwd_args

def swupdate_getdepends(d):
    def adddep(depstr, deps):
        for i in (depstr or "").split():
            if i not in deps:
                deps.append(i)

    deps = []
    images = (d.getVar('IMAGE_DEPENDS') or "").split()
    for image in images:
        adddep(image , deps)

    depstr = ""
    for dep in deps:
        depstr += " " + dep + ":do_build"

    return depstr

# Functions that swugenerator runs itself, on the artifacts it packs
SWUGENERATOR_FUNCTIONS = "swupdate_get_sha256 swupdate_get_size"

def swupdate_convert_old_sha256(lines):
    import re
    # sha256 = "@<file>" is the old syntax of $swupdate_get_sha256(<file>)
    old = re.compile(r"^(?P<before_placeholder>.+)(sha256|version).+[=:].*(?P<quote>[\'\"])@(?P<filename>.*)(?P=quote)")
    for index, line in enumerate(lines):
        m = old.match(line)
        if m:
            filename = m.group('filename')
            bb.warn("Syntax for sha256 changed, please use $swupdate_get_sha256(%s)" % filename)
            lines[index] = line.replace("@%s" % filename, "$swupdate_get_sha256(%s)" % filename)

def swupdate_exec_functions(d, s, write_lines):
    import re
    keep = d.getVar('SWUGENERATOR_FUNCTIONS').split()
    function = re.compile(r"\$(?P<bitbake_function_name>\w+)\((?P<parms>[^)]+)\)")

    def call(m):
        name = m.group('bitbake_function_name')
        if name in keep:
            return m.group(0)
        try:
            fn = eval(name)
        except NameError:
            bb.fatal("Function %s in sw-description is not defined" % name)
        ret = fn(d, s, m.group('parms'))
        bb.debug(2, "%s return %s " % (name, ret))
        return str(ret)

    for index, line in enumerate(write_lines):
        write_lines[index] = function.sub(call, line)

def swupdate_expand_bitbake_variables(d, s):
    write_lines = []

    with open(os.path.join(s, "sw-description"), 'r') as f:
        import re
        for line in f:
            found = False
            while True:
                m = re.match(r"^(?P<before_placeholder>.*)@@(?P<bitbake_variable_name>\w+)@@(?P<after_placeholder>.*)$", line)
                if m:
                    bitbake_variable_value = d.getVar(m.group('bitbake_variable_name'), True)
                    if bitbake_variable_value is None:
                       bitbake_variable_value = ""
                       bb.warn("BitBake variable %s not set" % (m.group('bitbake_variable_name')))
                    line = m.group('before_placeholder') + bitbake_variable_value + m.group('after_placeholder')
                    found = True
                    continue
                else:
                    m = re.match(r"^(?P<before_placeholder>.*)@@(?P<bitbake_variable_name>.+)\[(?P<flag_var_name>.+)\]@@(?P<after_placeholder>.*)$", line)
                    if m:
                       bitbake_variable_value = (d.getVarFlag(m.group('bitbake_variable_name'), m.group('flag_var_name'), True) or "")
                       line = m.group('before_placeholder') + bitbake_variable_value + m.group('after_placeholder')
                       continue

                    if found:
                       line = line + "\n"
                    break

            write_lines.append(line)
    return write_lines

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
                    m = re.match(r"^(?P<before_placeholder>.*)@@(?P<bitbake_variable_name>\w+)@@(?P<after_placeholder>.*)$", line)
                    if m:
                        bitbake_variable_value = m.group('bitbake_variable_name')
                        vardeps.append(bitbake_variable_value)
                        line = m.group('before_placeholder') + bitbake_variable_value + m.group('after_placeholder')
                        found = True
                        continue
                    else:
                        m = re.match(r"^(?P<before_placeholder>.*)@@(?P<bitbake_variable_name>.+)\[(?P<flag_var_name>.+)\]@@(?P<after_placeholder>.*)$", line)
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

def prepare_sw_description(d, artifacts):
    """Expands the BitBake variables and functions of sw-description

    The functions run by swugenerator are left in it. Returns the path
    of the expanded sw-description.
    """
    s = d.getVar('S')
    workdir = d.getVar('WORKDIR')
    write_lines = swupdate_expand_bitbake_variables(d, s)
    swupdate_convert_old_sha256(write_lines)
    swupdate_exec_functions(d, artifacts, write_lines)

    swdesc = os.path.join(workdir, "sw-description")
    with open(swdesc, 'w+') as f:
        for line in write_lines:
            f.write(line)
    return swdesc

def swupdate_stage_file(src, artifacts, list_for_swu):
    """Puts an artifact where swugenerator looks for it, linked if possible"""
    import shutil

    filename = os.path.basename(src)
    dst = os.path.join(artifacts, filename)
    if os.path.lexists(dst):
        os.unlink(dst)
    try:
        # images in DEPLOY_DIR_IMAGE are often relative symlinks: link the
        # file they point to, os.link() links the symlink itself before
        # Python 3.14
        os.link(os.path.realpath(src), dst)
    except OSError:
        shutil.copyfile(src, dst)
    if filename not in list_for_swu:
        list_for_swu.append(filename)

def swupdate_add_src_uri(d, artifacts, list_for_swu):
    exclude = (d.getVar("SWUPDATE_SRC_URI_EXCLUDE") or "").split()

    fetch = bb.fetch2.Fetch([], d)

    # Add files listed in SRC_URI to the swu file
    for url in fetch.urls:
        local = fetch.localpath(url)
        filename = os.path.basename(local)
        if filename in exclude:
            continue
        if (filename != 'sw-description') and (os.path.isfile(local)):
            swupdate_stage_file(local, artifacts, list_for_swu)

def add_image_to_swu(d, deploydir, imagename, artifacts, list_for_swu):
    src = os.path.join(deploydir, imagename)
    if not os.path.isfile(src):
        return False
    # allow images in subfolders of DEPLOY_DIR_IMAGE
    swupdate_stage_file(src, artifacts, list_for_swu)
    return True

def swupdate_add_artifacts(d, artifacts, list_for_swu):
    # Search for images listed in SWUPDATE_IMAGES in the DEPLOY directory.
    images = (d.getVar('SWUPDATE_IMAGES') or "").split()
    deploydir = d.getVar('DEPLOY_DIR_IMAGE')
    for image in images:
        fstypes = (d.getVarFlag("SWUPDATE_IMAGES_FSTYPES", image) or "").split()
        if fstypes:
            noappend_machine = d.getVarFlag("SWUPDATE_IMAGES_NOAPPEND_MACHINE", image)
            if noappend_machine == "0":  # Search for a file explicitly with IMAGE_MACHINE_SUFFIX
                imagebases = [ image + d.getVar('IMAGE_MACHINE_SUFFIX') ]
            elif noappend_machine == "1":  # Search for a file explicitly without IMAGE_MACHINE_SUFFIX
                imagebases = [ image ]
            else:  # None, means auto mode. Just try to find an image file with IMAGE_MACHINE_SUFFIX or without IMAGE_MACHINE_SUFFIX
                imagebases = [ image + d.getVar('IMAGE_MACHINE_SUFFIX'), image ]
            for fstype in fstypes:
                image_found = False
                for imagebase in imagebases:
                    image_found = add_image_to_swu(d, deploydir, imagebase + fstype, artifacts, list_for_swu)
                    if image_found:
                        break
                if not image_found:
                    bb.fatal("swupdate cannot find image file: %s" % os.path.join(deploydir, imagebase + fstype))
        else:  # Allow also complete entries like "image.ext4.gz" in SWUPDATE_IMAGES
            if not add_image_to_swu(d, deploydir, image, artifacts, list_for_swu):
                bb.fatal("swupdate cannot find %s image file" % image)

def swupdate_check_path(var, path):
    # swugenerator separates the fields of -k with ","
    if "," in path:
        bb.fatal("%s %s: a path with \",\" cannot be passed to swugenerator" % (var, path))
    if not os.path.exists(path):
        bb.fatal("%s %s doesn't exist" % (var, path))
    return path

def swupdate_signing_args(d):
    """swugenerator arguments for SWUPDATE_SIGNING"""
    signing = d.getVar('SWUPDATE_SIGNING')
    if not signing:
        return []
    if signing == "1":
        bb.warn('SWUPDATE_SIGNING = "1" is deprecated, falling back to "RSA". It is advised to set it to "RSA" if using RSA signing.')
        signing = "RSA"

    passfile = d.getVar('SWUPDATE_PASSWORD_FILE')
    pwd = [swupdate_check_path('SWUPDATE_PASSWORD_FILE', passfile)] if passfile else []

    if signing in ("RSA", "RSA-PSS"):
        privkey = d.getVar('SWUPDATE_PRIVATE_KEY')
        if not privkey:
            bb.fatal("SWUPDATE_PRIVATE_KEY isn't set")
        mode = "RSA" if signing == "RSA" else "RSAPSS"
        return ["-k", ",".join([mode, swupdate_check_path('SWUPDATE_PRIVATE_KEY', privkey)] + pwd)]

    if signing == "CMS":
        cms_certs = (d.getVar('SWUPDATE_CMS_CERT') or "").split()
        if not cms_certs:
            bb.fatal("SWUPDATE_CMS_CERT is not set")
        cms_keys = (d.getVar('SWUPDATE_CMS_KEY') or "").split()
        if not cms_keys:
            bb.fatal("SWUPDATE_CMS_KEY isn't set")
        if len(cms_certs) != len(cms_keys):
            bb.fatal("SWUPDATE_CMS_CERT and SWUPDATE_CMS_KEY must list the same number of entries (got %d certs, %d keys)" % (len(cms_certs), len(cms_keys)))
        args = []
        for cms_cert, cms_key in zip(cms_certs, cms_keys):
            args += ["-k", ",".join(["CMS", swupdate_check_path('SWUPDATE_CMS_KEY', cms_key),
                                     swupdate_check_path('SWUPDATE_CMS_CERT', cms_cert)] + pwd)]
        for crt_path in (d.getVar('SWUPDATE_CMS_EXTRA_CERTS') or "").split():
            if not os.path.exists(crt_path):
                bb.fatal("SWUPDATE_CMS_EXTRA_CERTS path %s doesn't exist" % (crt_path))
            args += ["--cms-certfile", crt_path]
        cms_md = d.getVar('SWUPDATE_CMS_MD')
        if cms_md:
            args += ["--cms-md", cms_md]
        return args

    if signing == "CUSTOM":
        # swugenerator appends sw-description and the signature to the command
        signtool = (d.getVar('SWUPDATE_SIGN_TOOL') or "").split()
        if not signtool:
            bb.fatal("Custom SWUPDATE_SIGN_TOOL is not given")
        if any("," in arg for arg in signtool):
            bb.fatal("SWUPDATE_SIGN_TOOL: an argument with \",\" cannot be passed to swugenerator")
        return ["-k", ",".join(["CUSTOM"] + signtool)]

    bb.fatal("Unrecognized SWUPDATE_SIGNING mechanism.")

def swupdate_encryption_args(d, swdesc):
    """swugenerator arguments for the encryption"""
    import re

    args = []
    aes_file = d.getVar('SWUPDATE_AES_FILE')
    encrypted_flags = [f for f, v in (d.getVarFlags('SWUPDATE_IMAGES_ENCRYPTED') or {}).items()
                       if v == '1' and not f.startswith('_')]
    with open(swdesc, 'r') as f:
        text = f.read()
    # swugenerator encrypts the artifacts with encrypted = true in sw-description
    if encrypted_flags and not re.search(r"\bencrypted\b", text):
        bb.warn("SWUPDATE_IMAGES_ENCRYPTED is set for %s, but sw-description has no "
                "\"encrypted = true\": the artifacts are encrypted as sw-description says" %
                " ".join(encrypted_flags))

    if aes_file:
        args += ["-K", aes_file]
        # the IV of SWUPDATE_AES_FILE, as swupdate_get_IV() returns, unless
        # SWUPDATE_UNIQUE_IV asks for a new IV for each artifact
        if d.getVar('SWUPDATE_UNIQUE_IV') != "1":
            args += ["-x"]
    if d.getVar('SWUPDATE_ENCRYPT_SWDESC'):
        if not aes_file:
            bb.fatal("SWUPDATE_ENCRYPT_SWDESC is set, but SWUPDATE_AES_FILE is not")
        args += ["-t"]
    return args

def swupdate_create_swu(d, swudeploydir, swdesc, artifacts, list_for_swu):
    import shlex
    import subprocess

    updateimage = d.getVar('IMAGE_NAME') + '.swu'
    # the artifacts are packed as they are: images are already compressed
    cmd = ["swugenerator", "-n", "-a", artifacts, "-s", swdesc,
           "-o", os.path.join(swudeploydir, updateimage)]
    cmd += swupdate_signing_args(d)
    cmd += swupdate_encryption_args(d, swdesc)
    if d.getVar('SWUPDATE_KEEP_NAMES') == "1":
        cmd += ["--keep-names"]
    # every collected file is packed, even if sw-description does not use it
    for filename in list_for_swu:
        cmd += ["--add-file", filename]
    cmd += shlex.split(d.getVar('SWUGENERATOR_EXTRA_ARGS') or "")
    cmd += ["create"]

    bb.note("Running %s" % " ".join(cmd))
    result = subprocess.run(cmd, cwd=artifacts, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, text=True)
    if result.stdout:
        bb.note(result.stdout)
    if result.returncode:
        bb.fatal("swugenerator failed with %d:\n%s" % (result.returncode, result.stdout))

    updateimage_link = d.getVar('IMAGE_LINK_NAME')
    if updateimage_link:
        updateimage_link += '.swu'
        if updateimage_link != updateimage:
            os.symlink(updateimage, os.path.join(swudeploydir, updateimage_link))

python do_swuimage () {
    list_for_swu = []
    artifacts = d.getVar('SWUPDATE_ARTIFACTS_DIR')
    imgdeploydir = d.getVar('SWUDEPLOYDIR')
    bb.utils.mkdirhier(artifacts)

    # Add artifacts added via SRC_URI
    if not d.getVar('INHIBIT_SWUPDATE_ADD_SRC_URI'):
        swupdate_add_src_uri(d, artifacts, list_for_swu)

    # Add artifacts set via SWUPDATE_IMAGES
    swupdate_add_artifacts(d, artifacts, list_for_swu)

    swdesc = prepare_sw_description(d, artifacts)

    swupdate_create_swu(d, imgdeploydir, swdesc, artifacts, list_for_swu)
}
