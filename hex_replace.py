#!/usr/bin/env pyhon

from sys import argv
import struct

def usage():
    print "Usage: %s orignal target file" % argv[0]


def do_replace(inFile, outFile, oldHex, newHex):
    inFp = open(inFile, 'rb')
    outFp = open(outFile, 'wb')
    oldstr = struct.pack('LH', 4611950241719001088, 18288)
    newstr = struct.pack('LH', 5147649559655096320, 18112)
    while 1:
        s = inFp.read(10)
        if s:
            print struct.unpack('LH', s)
            if s == oldstr:
                print "replace"
                outFp.write(newstr)
            else:
                outFp.write(s)
        else:
            break

    inFp.close()
    outFp.close()
    


if __name__ == "__main__":
    #if len(argv) < 4:
    #    exit(usage())

    do_replace(argv[1], argv[2], 0, 0)


