#!/bin/bash

if [ $# -ne 2 ]
then
	echo $0 src_package_name dest_package_name
	echo 
	exit
fi

src="$1"
des="$2"

#replace xml
for f in $(find -name "*.xml")
do
	echo $f
	sed "s/$src/$des/g" $f > tmp
	mv tmp $f
done

#replace smali
src2=$(echo $src | sed "s#\.#\\\/#g")
des2=$(echo $des | sed "s#\.#\\\/#g")
for f in $(find -name "*.smali")
do
	echo $f
	sed "s/$src2/$des2/g" $f > tmp
	mv tmp $f
done



