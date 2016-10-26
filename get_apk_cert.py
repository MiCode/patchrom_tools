#!/usr/bin/env python
#
# Copyright (C) 2016 The Miui Patchrom
#

import os
import sys
import re

# Values for "certificate" in apkcerts that mean special things.
SPECIAL_CERT_STRINGS = ("PRESIGNED", "EXTERNAL")
PUBLIC_KEY_SUFFIX = ".x509.pem"
PRIVATE_KEY_SUFFIX = ".pk8"


def ReadApkCerts(apkcerts):
  """parse the apkcerts.txt file and return a {package: cert} dict."""
  certmap = {}
  with open(apkcerts, 'r') as certs:
    for line in certs.readlines():
      m = re.match(r'^name="(.*)"\s+certificate="(.*)"\s+'
                 r'private_key="(.*)"$', line)
      if m:
        name, cert, privkey = m.groups()
        public_key_suffix_len = len(PUBLIC_KEY_SUFFIX)
        private_key_suffix_len = len(PRIVATE_KEY_SUFFIX)
        if cert in SPECIAL_CERT_STRINGS and not privkey:
          certmap[name] = cert
        elif (cert.endswith(PUBLIC_KEY_SUFFIX) and
            privkey.endswith(PRIVATE_KEY_SUFFIX) and
            cert[:-public_key_suffix_len] == privkey[:-private_key_suffix_len]):
          certmap[name] = cert[:-public_key_suffix_len]
      else:
        raise ValueError("failed to parse line from apkcerts.txt:\n" + line)
  return certmap

if __name__ == '__main__':
    apkPath = sys.argv[1]
    apkCerts = sys.argv[2]
    certmap = ReadApkCerts(apkCerts)
    cert = os.path.basename(certmap[os.path.basename(apkPath)])
    print cert
