#!/bin/bash

TOOL_PATH=${path:=}

if [ -z "`which ${TOOL_PATH}baksmali`" ]
then
     echo "Error: Can not find baksmali/smali, use -p to specify the right path."
     exit -1
fi

# $1: the classpath 
# $2: the odex files for processing
# $3: the result file type: jar or apk
function deodex_one_file() {
    classpath=$1
    file=$2
    tofile=${file/odex/$3}
    echo "processing $tofile"
    ${TOOL_PATH}baksmali -c $classpath -d framework -I -x $file || exit -2 
    ${TOOL_PATH}smali out -o classes.dex || exit -2
    jar uf $tofile classes.dex
    rm classes.dex
    rm -rf out
    rm $file
    zipalign 4 $tofile $tofile.aligned
    mv $tofile.aligned $tofile
}

if [ $# -ne 1 ] || [ $1 = '--help' ] 
then
    echo "usage: ./deodex.sh absolute_path_to_ota_file"
    exit 0
fi    

stockzip=$1
temppath=`echo $PWD`
tempdir=`mktemp -p $temppath -d tempdir.XXX`
echo "temp dir: $tempdir"
echo "unzip $stockzip to $tempdir"
unzip -q $stockzip -d $tempdir

cd $tempdir/[Ss][Yy][Ss][Tt][Ee][Mm]

ls framework/core.odex > /dev/null
if [ $? -eq 0 ] 
then
    deodex_one_file "" framework/core.odex jar
fi

for f in framework/*.jar
do
    classpath=$classpath:$f
done
#echo "classpath=$classpath"

ls framework/*.odex > /dev/null
if [ $? -eq 0 ]
then
    for file in framework/*.odex
    do
        deodex_one_file $classpath $file jar
    done
fi

ls app/*.odex > /dev/null
if [ $? -eq 0 ]
then
    for file in app/*.odex
    do
        deodex_one_file $classpath $file apk
    done
fi

cd $tempdir
echo "zip tmp_target_files"
zip -q -r -y "tmp_target_files" *
echo "replaces $stockzip"
cp -f "tmp_target_files.zip" $stockzip
rm -rf $tempdir
echo "Leavm all locale files at $tempdir, and delete it manually for next executing"
