#!/usr/bin/python
import os
import sys

path = sys.argv[1]
linkfile_path = path + '/SYSTEM/linkinfo.txt'
#print linkfile_path

try:
    file_object = open(linkfile_path)
    linelist = file_object.read( ).split()
    for line in linelist:
        line = line.rstrip()
        filepath = line.split('|')
        link_name = filepath[0].replace('system', 'SYSTEM')
        target = '/' + filepath[1]
        rm = 'rm -f ' + path+ '/' + link_name
        os.popen(rm)
        ln = 'cd ' + path + ';' + 'ln -s ' + target + ' ' +  link_name
        #print ln
        os.popen(ln)
except IOError:
    print r"%s isn't exist" % linkfile_path
    sys.exit(1)
file_object.close( )
print r"Recovery link files success"
sys.exit(0)
