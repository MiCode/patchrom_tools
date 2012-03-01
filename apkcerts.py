#!/usr/bin/env python

import sys
import string
import xml
import xml.dom
from xml.dom import minidom

def insertToDestText(fileContent, uid, name, shareUserId):    
    if (1000 == uid) or (1001 == uid):
        node = "name=\"" + name + "\" certificate=\"build/target/product/security/platform.x509.pem\" private_key=\"build/target/product/security/platform.pk8\""
    elif 1013 == uid:
        node = "name=\"" + name + "\" certificate=\"build/target/product/security/media.x509.pem\" private_key=\"build/target/product/security/media.pk8\""
    elif shareUserId == uid:
        node = "name=\"" + name + "\" certificate=\"build/target/product/security/shared.x509.pem\" private_key=\"build/target/product/security/shared.pk8\""
    else:
        node = "name=\"" + name + "\" certificate=\"build/target/product/security/testkey.x509.pem\" private_key=\"build/target/product/security/testkey.pk8\""
    print "Insert --> uid: %d     node: %s" %(uid, node)
    return  node + "\n"

def getName(codePath):
    if string.rfind(codePath, "/system/app/") > -1:
        return string.replace(codePath, "/system/app/", "")
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
        packages = xmldoc.getElementsByTagName("package")
    except :
        print "Error: %s doesn't exist or isn't a vaild xml file" %(sys.argv[1])
        sys.exit(1)

    for pkg in packages:
        if pkg.attributes["codePath"].value == "/system/app/ContactsProvider.apk":
            shareUserId = string.atoi(pkg.attributes["sharedUserId"].value)
            #print shareUserId
            break
        
    fileContent = ""
    for pkg in packages:
        if pkg.hasAttribute("userId"):
                uid = string.atoi(pkg.attributes["userId"].value)
        else:
                uid = string.atoi(pkg.attributes["sharedUserId"].value)
        name = getName(pkg.attributes["codePath"].value)
        if name:
            fileContent +=  insertToDestText(fileContent, uid, name, shareUserId)

    open(sys.argv[2], "w").write(fileContent)
if "__main__" == __name__:
    main()
