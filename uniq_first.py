#!/usr/bin/env python

import os
import sys
def uniq_first(src_file, dst_file):
	lines = []
	with open(src_file, 'r') as sf:
		lines = sf.readlines()
	with open(dst_file, 'r') as tf:
		content = tf.read()

	with open(dst_file, 'a') as df:
		for line in lines:
			if not (line.split()[0] + " " in content):
				df.write(line)

def main(args):
	if len(args) != 2:
		print("Usage: uniq_first src_file dst_file")
		sys.exit(1)

	uniq_first(args[0], args[1])


if __name__ == '__main__':
	main(sys.argv[1:])
