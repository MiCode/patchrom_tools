#! /usr/bin/env python
"""
This script is very specific for framework-res/res/values/drawables.xml.
Currently ResValuesModify can't process <item name="screen_background_light" type="drawable" />.
use this script to remove multiple definitions
"""
import sys
import xml
import xml.dom
from xml.dom import minidom

fdir=sys.argv[1]
filename=fdir +"/res/values/drawables.xml"
xmldoc = minidom.parse(filename)
root = xmldoc.firstChild
elements = [ e for e in root.childNodes if e.nodeType == e.ELEMENT_NODE ]
elem_defs = {}
for elem in elements:
	name = elem.attributes["name"].value
	elem_defs[name] = elem_defs.get(name, 0) + 1

repeat_defs = [ name for name in elem_defs.keys() if elem_defs[name] > 1]
xmldoc.unlink()

f = open(filename, "r")
lines = f.readlines()
f.close()

for line in lines:
	for rdef in repeat_defs:
		if rdef in line:
			lines.remove(line)
			repeat_defs.remove(rdef)

f = open(filename, "w")
f.writelines(lines)
f.close()

		
