#!/bin/bash

if [ $# -ne 3 ]
then
	echo $0 path src_package_name dest_package_name
	echo 
	exit
fi

path="$1"
src="$2"
des="$3"

cd $path
#replace xml
for f in $(find . -name "*.xml")
do
	echo $f
	sed "s/$src/$des/g" $f > tmp
	mv tmp $f
done

#replace smali
src2=$(echo $src | sed "s#\.#\\\/#g")
des2=$(echo $des | sed "s#\.#\\\/#g")
for f in $(find . -name "*.smali")
do
	echo $f
	sed "s/$src2/$des2/g" $f > tmp
	mv tmp $f
done



