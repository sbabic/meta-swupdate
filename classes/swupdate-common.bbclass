def swupdate_is_hash_needed(s, filename):
    with open(os.path.join(s, "sw-description"), 'r') as f:
        for line in f:
            if line.find("@%s" % (filename)) != -1:
                return True
    return False

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

def swupdate_write_sha256(s, filename, hash):
    write_lines = []

    with open(os.path.join(s, "sw-description"), 'r') as f:
        for line in f:
            write_lines.append(line.replace("@%s" % (filename), hash))

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

def swupdate_expand_auto_versions(d, s, list_for_cpio):
    import re
    import oe.packagedata
    AUTO_VERSION_TAG = "SWU_AUTO_VERSION"

    with open(os.path.join(s, "sw-description"), 'r') as f:
        data = f.read()

    def get_package_name(group, file_list):
        m = re.search(r"%s:(?P<package>.+?(?=\"))" % (AUTO_VERSION_TAG), group)
        if m:
            package = m.group('package')
            return (package, True)

        for filename in file_list:
            if filename in group:
                package = filename

        if not package:
            bb.fatal("Failed to find %s in group with \"%s\"" % (filename, AUTO_VERSION_TAG))

        return (package, False)

    regexp = re.compile(r"\{[^\{]*%s.[^\}]*\}" % (AUTO_VERSION_TAG))
    while True:
        m = regexp.search(data)
        if not m:
            break

        group = data[m.start():m.end()]

        (package, pkg_name_defined) = get_package_name(group, list_for_cpio)

        pkg_info = os.path.join(d.getVar('PKGDATA_DIR'), 'runtime-reverse', package)
        pkgdata = oe.packagedata.read_pkgdatafile(pkg_info)

        if not "PV" in pkgdata.keys():
            bb.fatal("Failed to find version for package %s" % (package))

        replace_str = AUTO_VERSION_TAG
        if pkg_name_defined:
            replace_str = replace_str + ":" + package

        group = group.replace(replace_str, pkgdata['PV'].split('+')[0])
        data = data[:m.start()] + group + data[m.end():]

    with open(os.path.join(s, "sw-description"), 'w+') as f:
        f.write(data)

def prepare_sw_description(d, s, list_for_cpio):
    import shutil

    swupdate_expand_bitbake_variables(d, s)
    swupdate_expand_auto_versions(d, s, list_for_cpio)

    for file in list_for_cpio:
        if file != 'sw-description' and swupdate_is_hash_needed(s, file):
            hash = swupdate_get_sha256(s, file)
            swupdate_write_sha256(s, file, hash)

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
        if signing == "CUSTOM":
            sign_tool = d.getVar('SWUPDATE_SIGN_TOOL', True)
            if sign_tool:
                ret = os.system(sign_tool)
                if ret != 0:
                    bb.fatal("Failed to sign with %s" % (sign_tool))
            else:
                bb.fatal("Custom SWUPDATE_SIGN_TOOL is not given")
        elif signing == "RSA":
            privkey = d.getVar('SWUPDATE_PRIVATE_KEY', True)
            if not privkey:
                bb.fatal("SWUPDATE_PRIVATE_KEY isn't set")
            if not os.path.exists(privkey):
                bb.fatal("SWUPDATE_PRIVATE_KEY %s doesn't exist" % (privkey))
            passout = d.getVar('SWUPDATE_PASSWORD_FILE', True)
            if passout:
                passout = "-passin file:'%s' " % (passout)
            else:
                passout = ""
            signcmd = "openssl dgst -sha256 -sign '%s' %s -out '%s' '%s'" % (
                privkey,
                passout,
                os.path.join(s, 'sw-description.sig'),
                os.path.join(s, 'sw-description.plain' if encrypt else 'sw-description'))
            if os.system(signcmd) != 0:
                bb.fatal("Failed to sign sw-description with %s" % (privkey))
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
            passout = d.getVar('SWUPDATE_PASSWORD_FILE', True)
            if passout:
                passout = "-passin file:'%s' " % (passout)
            else:
                passout = ""
            signcmd = "openssl cms -sign -in '%s' -out '%s' -signer '%s' -inkey '%s' %s -outform DER -nosmimecap -binary" % (
                os.path.join(s, 'sw-description.plain' if encrypt else 'sw-description'),
                os.path.join(s, 'sw-description.sig'),
                cms_cert,
                cms_key,
                passout)
            if os.system(signcmd) != 0:
                bb.fatal("Failed to sign sw-description with %s" % (privkey))
        else:
            bb.fatal("Unrecognized SWUPDATE_SIGNING mechanism.");
