#!/bin/bash

action=$1
file=$2
method=$3
OUT=out

function get_method_content() {
    dir=$1
    file=$2
    method=$3

    number=`find $dir -name $file.smali | wc -l`
    if [ ! "$number" == 1 ]; then
        echo "no or more than one file named $file.smali!"
        exit -1
    fi

    file=`find $dir -name $file.smali`

    patchfile=`basename $file`.method
    patchdir=`dirname $file`
    patchdir=`echo $patchdir | sed -e "s/$dir\///"`

    echo patch $file at $patchdir/$patchfile
    mkdir -p $patchdir
    cat $file | sed -n -e "/^\.method.*$method/,/^\.end method/p" > $patchdir/$patchfile
}

function apply_method() {
    dir=$1
    patch=$2

    to=$dir/`echo $patch | sed -e "s/.method//"`
    # now only support one method in one file
    method=`cat $patch | grep "^.method" | sed -e "s/^.* //" -e "s/(.*$//"`

    echo patch method $method to file $to
    cat $to | sed -e "/^\.method.*$method/,/^\.end method/d" > $to.patched
    cat $patch >> $to.patched
    mv $to.patched $to
}

if [ "$action" == "patch" ]; then
    get_method_content $OUT $file $method
fi

if [ "$action" == "apply" ]; then
    apply_method $OUT $file
fi
