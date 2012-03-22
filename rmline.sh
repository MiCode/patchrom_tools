#!/bin/bash

function rm_line() {
    local action=$1
    local file=$2
    local diff_file=$file-{line}.diff

    if [ "$action" == "remove" ]; then
        mv $file $file.original
        more $file.original | sed -e '/^\s*\.line.*$/d' | sed -e 's/\/jumbo//' > $file
        diff -B -c $file $file.original > $diff_file
        rm $file.original
    else
        patch -f $file -r /dev/null < $diff_file >/dev/null 2>&1
        rm -f $diff_file
    fi
}

action=remove
if [ "$1" == "-r" ]; then
    action=add
    shift
fi

if [ -f "$1" ]; then
    rm_line $action $1
    exit
fi

for file in `find $1 -name "*.smali"`
do
    rm_line $action $file
done
