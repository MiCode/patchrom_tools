#!/bin/bash

TOOL_PATH=$PORT_ROOT/tools
SMALI=$TOOL_PATH/smali
BAKSMALI=$TOOL_PATH/baksmali

function deodex_one_file() {
    if [ "$1" = '-a' ]
    then
        apilevel=$2
        classpath=$3
        file=$4
        tofile=${file/odex/$5} 
        echo "processing $tofile"
        $BAKSMALI -a $apilevel -c $classpath -d framework -I -x $file || exit -2
    else
        classpath=$1
        file=$2
        tofile=${file/odex/$3}
        echo "processing $tofile"
        $BAKSMALI -c $classpath -d framework -I -x $file || exit -2
    fi
    $SMALI out -o classes.dex || exit -2
    jar uf $tofile classes.dex
    rm classes.dex
    rm -rf out
    rm $file
    zipalign 4 $tofile $tofile.aligned
    mv $tofile.aligned $tofile
}

#usage
if [ $1 = '--help' ] 
then
    echo "usage: ./deodex.sh [-a APILevel] absolute_path_to_ota_zip_file"
    echo "  -a    specify APILevel, default Level is 15"
    exit 0
fi    

if [ ! -x $BAKSMALI -o ! -x $SMALI ]
then
     echo "Error: Can not find baksmali/smali"
     exit -1
fi

if [ $1 = '-a' ]
then 
    apilevel=$2
    stockzip=$3
else
    stockzip=$1
fi

temppath=`echo $PWD`
tempdir=`mktemp -p $temppath -d tempdir.XXX`
echo "temp dir: $tempdir"
echo "unzip $stockzip to $tempdir"
unzip -q $stockzip -d $tempdir

if [ -d $tempdir/system ]
then
    cd $tempdir/system
elif [ -d $tempdir/SYSTEM ]
then
    cd $tempdir/SYSTEM
else
    echo "can't find system or SYSTEM dir in $tempdir"
    exit -1
fi

ls framework/core.odex > /dev/null
if [ $? -eq 0 ] 
then
    if [ $1 = '-a' ]
    then
        deodex_one_file -a $apilevel "" framework/core.odex jar
    else
        deodex_one_file "" framework/core.odex jar
    fi
fi

for f in framework/*.jar
do
    classpath=$classpath:$f
done

echo "classpath=$classpath"

ls framework/*.odex > /dev/null
if [ $? -eq 0 ]
then
    for file in framework/*.odex
    do
        if [ $1 = '-a' ]
        then
            deodex_one_file -a $apilevel $classpath $file jar
        else
            deodex_one_file $classpath $file jar
        fi
    done
fi

ls app/*.odex > /dev/null
if [ $? -eq 0 ]
then
    for file in app/*.odex
    do
        if [ $1 = '-a' ]
        then
            deodex_one_file -a $apilevel $classpath $file apk
        else
            deodex_one_file $classpath $file apk
        fi
    done
fi

cd $tempdir
echo "zip tmp_target_files"
zip -q -r -y "tmp_target_files" *
echo "replaces $stockzip"
cp -f "tmp_target_files.zip" $stockzip
echo "remove $tempdir"
rm -rf $tempdir
echo "deodex done. deodex zip: $stockzip"
