#!/usr/bin/env python

import sys
import string
import xml
import xml.dom
from xml.dom import minidom

def getName(codePath):
    if codePath.startswith("/system/app"):
        return codePath.replace("/system/app/", "")
    else :
        return ""

def usage():
    print "Usage: python ./apkcerts.py path-to-packages.xml path-to-apkcerts.txt"

def main():
    if len(sys.argv) != 3:
        usage()
        sys.exit(1)

    try:
        xmldoc = minidom.parse(sys.argv[1])
    except :
        print "Error: %s doesn't exist or isn't a vaild xml file" %(sys.argv[1])
        sys.exit(1)

    packages = xmldoc.getElementsByTagName("package")
    sigpkgs = {}
    for pkg in packages:
        name = getName(pkg.attributes["codePath"].value)
        cert= pkg.getElementsByTagName("cert")
        if not cert or not name: continue
        index = cert[0].getAttribute("index")
        sigpkgs[index] = sigpkgs.get(index, []) + [name]

    sharedUsers = xmldoc.getElementsByTagName("shared-user")
    sigmap = {}
    for user in sharedUsers:
        name = user.getAttribute("name")
        cert = user.getElementsByTagName("cert")
        if not cert: continue
        index = cert[0].getAttribute("index")
        if name == "android.uid.system":
            sigmap[index] = "platform"
        elif name == "android.media":
            sigmap[index] = "media"
        elif name == "android.uid.shared":
            sigmap[index] = "shared"

    with open(sys.argv[2], "w") as f:
        for keyindex, pkgnames in sigpkgs.items():
            sig = sigmap.get(keyindex, None)
            for pkgname in pkgnames:
                if sig:
                    line = 'name="{0}" certificate="build/target/product/security/{1}.x509.pem" private_key="build/target/product/security/{1}.pk8"\n'.format(pkgname, sig)
                else:
                    line = 'name="{0}" certificate="PRESIGNED" private_key=""\n'.format(pkgname)
                f.write(line)

if "__main__" == __name__:
    main()
