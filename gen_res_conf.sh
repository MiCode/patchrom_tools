#!/bin/bash

CONF=$1
APKDIR=$2
SYSDIR=$3

for line in `cat $CONF`
do
    name=`echo $line | cut -d= -f1`
    value=`echo $line | cut -d= -f2`
    echo $line - [$name] [$value]

    if [ "$name" = "APK" ]; then
        apkfile=$value
    elif [ "$name" = "package" ]; then
        package=$value
        rm -f $SYSDIR/res_overlay_$package.txt
        echo "Generate conf file:$SYSDIR/res_overlay_$package.txt"
    else
        resv=`aapt d resources $APKDIR/$apkfile | sed -n -e "s/^.*spec resource 0x\(.*\) .*$name.*$/\1/p"`
        echo "$name=$resv" >> $SYSDIR/res_overlay_$package.txt
        echo "   Add $name=$resv"
    fi
done

