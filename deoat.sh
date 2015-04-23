#!/bin/bash
#
# Copyright (C) 2016, Miui Patchrom
#

TARGET_DIR=$1

function removeDuplicateFiles() {
    local bootOat64Path=$(find $TARGET_DIR -name "boot.oat" | grep "64\/")
    if [ -n $bootOat64Path ];then
        rm -rf ${bootOat64Path/64\///}
        rm -rf ${bootOat64Path/64\/boot.oat//boot.art}
    fi
    local odex
    for odex in $(find $TARGET_DIR -name "*.odex" | grep "64\/")
    do
        echo "rm -rf ${odex/64\///}"
        rm -rf ${odex/64\///}
    done
}

function zipDex() {
    local zipDir=$1
    local dexPath=$2
    local suffix=$3
    local dexName=$(basename $dexPath .dex)
    local zipName=${dexName%%-classes*}
    if [ $dexName = $zipName ];then
        local zipDexName=classes.dex
    else
        local zipDexName=classes${dexName##*-classes}.dex
    fi
    mv $dexPath $zipDexName
    if [ -f $zipDir/$zipName.$suffix ];then
        zip -m $zipDir/$zipName.$suffix $zipDexName > /dev/null
    fi
}

function decodeBootOat() {
    BOOTOAT_PATH=$(find $TARGET_DIR -name "boot.oat")
    if [ -z $BOOTOAT_PATH ];then
        return
    fi
    BOOTOAT_DIR=$(dirname $BOOTOAT_PATH)
    echo "Decoding $BOOTOAT_PATH"
    oat2dex boot $BOOTOAT_PATH > /dev/null
    local bootDex
    for bootDex in $(find $BOOTOAT_DIR/dex -name "*.dex")
    do
        zipDex $(dirname $BOOTOAT_DIR) $bootDex jar
    done
}

function decodeOdex() {
    local suffix=$1
    local zipPath  
    for zipPath in $(find $TARGET_DIR -name "*.$suffix")
    do
        local zipDir=$(dirname $zipPath)
        local zipName=$(basename $zipPath)
        local odexPath=$(find $zipDir -name ${zipName/.$suffix/.odex})
        if [ -z $odexPath ];then
            continue
        fi
        echo "Decoding $odexPath"
        local bootClassPath=$BOOTOAT_DIR/odex
        if [ "$suffix" = "apk" ];then
            bootClassPath=$(dirname $BOOTOAT_DIR)
        fi
        local ret=$(oat2dex -o $zipDir $odexPath $bootClassPath)
        if [ -n "$(echo $ret | grep -i "failed")" -a -f $PORT_ROOT/tools/oat2dex-0.86.jar ];then
            echo "Decoding $odexPath failed, try to use old version oat2dex"
            java -jar $PORT_ROOT/tools/oat2dex-0.86.jar -o $zipDir $odexPath $bootClassPath > /dev/null
        fi
        rm -rf $odexPath
        local dexPath
        for dexPath in $(find $zipDir -maxdepth 1 -name "*.dex")
        do
            zipDex $zipDir $dexPath $suffix
        done
    done
}

removeDuplicateFiles
decodeBootOat
decodeOdex jar
decodeOdex apk
rm -rf $BOOTOAT_DIR/boot.oat $BOOTOAT_DIR/boot.art $BOOTOAT_DIR/odex $BOOTOAT_DIR/dex
