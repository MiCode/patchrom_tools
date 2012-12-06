#!/bin/bash

#{JAR_DIVIDE}:i9100:framework.jar.out|framework2.jar.out
#{JAR_DIVIDE}:sensation:framework.jar.out|widget.jar.out
#{JAR_DIVIDE}:razr:framework.jar.out|framework-ext.jar.out
#{JAR_DIVIDE}:vivo:framework.jar.out|framework2.jar.out
#{JAR_DIVIDE}:i9300:framework.jar.out|framework2.jar.out
#{JAR_DIVIDE}:gnote:framework.jar.out|framework2.jar.out
#{JAR_DIVIDE}:onex:framework.jar.out|framework2.jar.out
#{JAR_DIVIDE}:ones:framework.jar.out|framework2.jar.out
#{JAR_DIVIDE}:x515m:framework.jar.out|framework2.jar.out
#{JAR_DIVIDE}:saga:framework.jar.out|framework2.jar.out
#{JAR_DIVIDE}:me865:framework.jar.out|framework-ext.jar.out
#{JAR_DIVIDE}:lu6200:framework.jar.out|framework2.jar.out

ANDROID_PATH=$PORT_ROOT/android
PATCH_SH=$PORT_ROOT/tools/merge_divide_jar_out.sh
PATCH_SWAP_PATH=$PORT_ROOT/android/patch

function error_exit {
    echo -e "ERROR: $1"
    exit 1
}

function merge_jar {
    local phone="$1"
    local OLD_PWD=$PWD
    local config=`grep "#{JAR_DIVIDE}:$phone:" $PATCH_SH | sed "s/#{JAR_DIVIDE}:$1://g"`
    if [ -z "$config" ];then
        return
    fi

    local jar_out=`echo "$config" | cut -d'|' -f1`
    local divide_jar_out=`echo "$config" | cut -d'|' -f2`
    
    cd $PORT_ROOT/$phone
    #git checkout . >/dev/null
    #git clean -df >/dev/null

    cd $PORT_ROOT/$phone/$divide_jar_out/smali
    mkdir $PATCH_SWAP_PATH/divide_jar/ -p
    find -type f >"$PATCH_SWAP_PATH/divide_jar/$phone:$jar_out:$divide_jar_out"
    cp $PORT_ROOT/$phone/$divide_jar_out/smali/ $PORT_ROOT/$phone/$jar_out/ -r
    rm $PORT_ROOT/$phone/$divide_jar_out/smali/ -rf
    cd $OLD_PWD
}

function divide_jar {
    local phone="$1"
    local OLD_PWD="$PWD"
    local recovery_file="`find $PATCH_SWAP_PATH/divide_jar/ -name $phone:*`"
    if [ -z "$recovery_file" ];then
        return
    fi
    local jar_out=`basename "$recovery_file" | cut -d':' -f2`
    local divide_jar_out=`echo "$recovery_file" | cut -d':' -f3`
    OLD_IFS="$IFS"
    IFS=$'\n'
    for f in `cat "$recovery_file"`
    do
        dir=`dirname $f`
        mkdir $PORT_ROOT/$phone/$divide_jar_out/smali/$dir -p
        mv "$PORT_ROOT/$phone/$jar_out/smali/$f" "$PORT_ROOT/$phone/$divide_jar_out/smali/$f"
    done
    IFS="$OLD_IFS"
    rm "$recovery_file"
    cd "$PORT_ROOT/$phone"
    git clean -df >/dev/null
    cd "$OLD_PWD"
}

######START#######
[ -z "$PORT_ROOT" ] && error_exit "Please setup environment firstly"
[[ ! -d "$PORT_ROOT/$2" || -z "$2" ]] && error_exit "$2 is wrong phone's name"
if [ "$1" = "-m" ];then
    merge_jar $2
elif [ "$1" = "-d" ];then
    divide_jar $2
fi

