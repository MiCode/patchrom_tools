#!/bin/bash
#
# Fix Grayscale PNG conversion increase brightness bug
# Bug discription
#   APKTOOL issue id: 326
#   JDK bug uri: http://bugs.sun.com/bugdatabase/view_bug.do?bug_id=5051418
# Root cause
#   1.when apktool decode gray adn gray-alpha 9Patch png,
#     it will use jdk drawImage() method, and the method
#     has a bug which increase brightness.
#   2.the bug is only exist 9Patch png, other png without
#     the problem, as apktool won't decode it.
# Fix method
#   1.unzip original and target apk, not use apktool.
#   2.copy 9Patch pngs from original apk to target apk.
#   3.re-zip taget apk.
# $1: the original apk name
# $2: the original apk dir
# $3: the out dir
# $4: filter dir
# $5: filter dir

APK_FILE=$1.apk
ORIGINAL_APK=$2/$APK_FILE
REPLACE_APK=$3/$APK_FILE

TMP_ORIGINAL_FILE=$3/$1-original.apk
TMP_TARGET_FILE=$3/$1-target.apk

TMP_ORIGINAL_DIR=$3/$1-original
TMP_TARGET_DIR=$3/$1-target

HAS_FILTER1=false
HAS_FILTER2=false
if [ $# -gt 3 ];then
	HAS_FILTER1=true
fi
if [ $# -gt 4 ];then
	HAS_FILTER2=true
fi

cp -r $ORIGINAL_APK $TMP_ORIGINAL_FILE
mv  $REPLACE_APK $TMP_TARGET_FILE
unzip -o $TMP_ORIGINAL_FILE -d $TMP_ORIGINAL_DIR > /dev/null
unzip -o $TMP_TARGET_FILE -d $TMP_TARGET_DIR > /dev/null
for file in `find $TMP_ORIGINAL_DIR -name *.9.png`; do
	targetfile=`echo $file | sed -e "s/-original/-target/"`
	overlay=`echo $file | sed -e "s/$3\/$1-original\/res\///"`
	if [ "$HAS_FILTER1" == "true" -a -f $4/$overlay ];then
		continue
	elif [ "$HAS_FILTER2" == "true" -a -f $5/$overlay ];then
		continue
	fi
	cp $file $targetfile
done
cd $TMP_TARGET_DIR
#only store all files, not compress files
#as raw resource can't be compressed.
zip -r0 ../$APK_FILE ./ > /dev/null
