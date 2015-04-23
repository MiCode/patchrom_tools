#!/usr/bin/env python

import sys

if len(sys.argv) != 4:
    print("Usage: rewrite filename old-string new-string")
    sys.exit(1)

filename = sys.argv[1]
oldstr = sys.argv[2]
newstr = sys.argv[3]
with open(filename) as f:
    content = f.read()
    content = content.replace(oldstr, newstr)

with open(filename, "w") as f:
    f.write(content)
