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
			if not (line.split()[0] in content):
				df.write(line)

def filter_miui(miui_file, filter_file, make_dir):
	lines = []
	miui_apps = os.popen("make -C "+ make_dir + " miui-apps-included").read()
	with open(miui_file, 'r') as mf:
		lines = mf.readlines()

	with open(filter_file, 'w') as ff:
		for line in lines:
			if line.split():
				if (line.split()[0].split('"')[1] in miui_apps):
					ff.write(line)

def main(args):
	if len(args) != 3:
		print("Usage: uniq_first src_file dst_file make_dir")
		sys.exit(1)

	filtered = args[1] + '.filter'
	filter_miui(args[1], filtered, args[2])
	uniq_first(args[0], filtered)
	os.rename(filtered, args[1])

if __name__ == '__main__':
	main(sys.argv[1:])
