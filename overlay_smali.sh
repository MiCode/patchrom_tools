#!/bin/bash

TARGET_DIR=$1
OVERLAY_DIR=$2

for overlay_smali in `find $OVERLAY_DIR -name "*.smali" | sed 's/\$.*/.smali/' | uniq`
do
    target_smali=${overlay_smali/$OVERLAY_DIR/$TARGET_DIR}
    if [ -f "$target_smali" ];then
        cp -f ${overlay_smali/.smali/}*.smali `dirname $target_smali`
    fi
done
