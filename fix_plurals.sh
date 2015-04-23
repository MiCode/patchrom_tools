#!/bin/bash

resdir=$1
for file in `find $resdir -name "plurals.xml"`
do
	$PORT_ROOT/tools/multi_format_subst.pl $file > temp.xml
	cp temp.xml $file
done
rm temp.xml
