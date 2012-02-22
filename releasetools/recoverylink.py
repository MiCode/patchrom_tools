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
        filepath[0] = filepath[0].replace('system', 'SYSTEM');
        filepath[1] = filepath[1].replace('system', 'SYSTEM');
        rm = 'rm -f ' + path+ '/' + filepath[0]
        os.popen(rm)
        filepath[0] = filepath[0].replace('SYSTEM/bin/', '');
        filepath[1] = filepath[1].replace('SYSTEM/bin/', '');
        #ln = 'ln -s '+ path+ '/'+ filepath[1] + ' ' + path+ '/'+  filepath[0]
        ln = 'cd ' + path + '/SYSTEM/bin;' + 'ln -s ' + filepath[1] + ' ' +  filepath[0]
        print ln
        os.popen(ln)
except IOError:
    print r"%s isn't exist" % linkfile_path
    sys.exit(1)
file_object.close( )
print r"Recovery link files success"
sys.exit(0)

