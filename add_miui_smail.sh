#!/bin/bash
#
# $1: dir for miui
# $2: dir for original
#
for file in `find $1 -name "*.smali"`
do
        newfile=${file/$1/$2}
        if [ ! -f "$newfile" ]
        then
                mkdir -p `dirname $newfile`
                echo "add smali from miui: $file"
                cp $file $newfile
        fi
done

if [ -f "customize_framework.sh" ]; then
	./customize_framework.sh $1 $2
fi
