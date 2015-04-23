#!/usr/bin/env python
#
# Copyright (C) 2009 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import sys

# Put the modifications that you need to make into the /system/build.prop into this
# function. The prop object has get(name) and put(name,value) methods.
def mangle_build_prop(prop, overlaylines):
  for i in range(0,len(overlaylines)):
    pair = overlaylines[i].split('=')
    if len(pair) == 2:
      name = pair[0].strip()
      value = pair[1].strip()
      if not name.startswith("#"):
        prop.put(name,value)
  pass

class PropFile:
  def __init__(self, lines):
    self.lines = [s[:-1] for s in lines]

  def get(self, name):
    key = name + "="
    for line in self.lines:
      if line.startswith(key):
        return line[len(key):]
    return ""

  def put(self, name, value):
    key = name + "="
    for i in range(0,len(self.lines)):
      if self.lines[i].startswith(key):
        self.lines[i] = key + value
        return
    self.lines.append(key + value)

  def delete(self, name):
    key = name + "="
    i = 0
    while i < len(self.lines):
      if self.lines[i].startswith(key):
        del self.lines[i]
      else:
        i += 1

  def write(self, f):
    f.write("\n".join(self.lines))
    f.write("\n")

def main(argv):
  srcfilename = argv[1]
  overlayfilename = argv[2]
  fs = open(srcfilename)
  srclines = fs.readlines()
  fs.close()

  fo = open(overlayfilename)
  overlaylines = fo.readlines()
  fo.close()

  properties = PropFile(srclines)
  if srcfilename.endswith("/build.prop"):
    mangle_build_prop(properties, overlaylines)
  else:
    sys.stderr.write("bad command line: " + str(argv) + "\n")
    sys.exit(1)

  fs = open(srcfilename, 'w+')
  properties.write(fs)
  fs.close()

if __name__ == "__main__":
  main(sys.argv)
