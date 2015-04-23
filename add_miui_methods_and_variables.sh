#!/bin/bash
#
# Copyright 2016 Miui Patchrom
#

BASE_DIR=$1
MOD_DIR=$2
TARGET_DIR=$3

IFS=$'\x0A'

tmp_fifo_file="/tmp/$$.fifo"
mkfifo $tmp_fifo_file
exec 9<>$tmp_fifo_file

# 8 threads
for((i=0;i<8;i++))
do
    echo ""
done >&9


for modSmaliFile in $(find $MOD_DIR -name "*.smali" ! -name "*\$[0-9]*.smali" ! -name "R\$*.smali")
do
    baseSmaliFile=${modSmaliFile/$MOD_DIR/$BASE_DIR}
    targetSmaliFile=${modSmaliFile/$MOD_DIR/$TARGET_DIR}
    read -u9
    {
        if [ -f $baseSmaliFile ];then
            if [ "$(diff $baseSmaliFile $modSmaliFile)" == "" ];then
                echo "" >&9
                continue
            fi
            methodBeginLines=($(grep -n "^.method " $modSmaliFile))
            methodEndLines=($(grep -n "^.end method" $modSmaliFile))
            for((i=0;i<${#methodBeginLines[@]};i++))
            do
                if [ "$(echo ${methodBeginLines[$i]} | grep -E 'static synthetic|clinit')" == "" ];then
                    grepPattern="[^->]$(echo ${methodBeginLines[$i]##* } | sed 's/\[/\\\[/g')"
                    if [ "$(grep $grepPattern $baseSmaliFile)" == "" ];then
                        beginLineNum=$(echo ${methodBeginLines[$i]} | cut -d ':' -f1)
                        endLineNum=$(echo ${methodEndLines[$i]} | cut -d ':' -f1)
                        echo "Add method ${methodBeginLines[$i]##* } into $targetSmaliFile"
                        sed -n ${beginLineNum},${endLineNum}p $modSmaliFile >> $targetSmaliFile
                    fi
                fi
            done

            fieldLines=($(grep -En "^.field |^.end field" $modSmaliFile))
            linesCount=${#fieldLines[@]}
            for ((i=0;i<$linesCount;i++))
            do
                beginLine=${fieldLines[$i]%% =*}
                grepPattern="[^->]$(echo ${beginLine##* } | sed 's/\[/\\\[/g')"
                if [ "$(grep $grepPattern $baseSmaliFile)" == "" ];then
                    echo "Add field ${beginLine##* } into $targetSmaliFile"
                    beginLineNum=$(echo $beginLine | cut -d ":" -f1)
                    if [ $(($linesCount-$i)) -ne 1 -a "$(echo ${fieldLines[$i+1]} | grep ".end field")" != "" ];then
                        endLineNum=$(echo ${fieldLines[$i+1]} | cut -d ":" -f1)
                        sed -n ${beginLineNum},${endLineNum}p $modSmaliFile >> $targetSmaliFile
                        i=$(($i+1))
                    else
                        sed -n ${beginLineNum}p $modSmaliFile >> $targetSmaliFile
                    fi
                fi
            done
        fi
        echo "" >&9
    }&
done
wait
exec 9>&-

exit 0
