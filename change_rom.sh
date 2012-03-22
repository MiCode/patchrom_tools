#!/bin/bash

# $1: the old smali code  $2: the new smali code $3: the destination smali code

if [ $# -ne 5 ];then
	echo "Usage: change_rom.sh APP|JAR APP_NAME SUFFIX old_rom.zip new_rom.zip"
    exit
fi

# todo run me under product dir, such as i9100
WS_DIR=`pwd`
APKTOOL=$PORT_ROOT/tools/apktool

# such as app/Phone (no .apk here)
APPFRM=$1
appname=$4
suffix=$5
app=$APPFRM/$appname.$suffix

temp_dir=$WS_DIR/temp
old_smali_dir=$WS_DIR/temp_old
dst_smali_dir=$WS_DIR/temp_dst
new_smali_dir=$WS_DIR

echo ">>> Extract $app from ROM_ZIP file..."
unzip $2 system/$app -d $old_smali_dir
$APKTOOL d $old_smali_dir/system/$app $old_smali_dir/$appname
unzip $3 system/$app -d $dst_smali_dir
$APKTOOL d $dst_smali_dir/system/$app $dst_smali_dir/$appname
echo "<<< Done!"

temp_old_smali_dir=$temp_dir/old_smali
temp_new_smali_dir=$temp_dir/new_smali
temp_dst_smali_orig_dir=$temp_dir/dst_smali_orig
temp_dst_smali_patched_dir=$temp_dir/dst_smali_patched
reject_dir=$temp_dir/reject

rm -rf $temp_dir

echo ">>> create temp directory to store the old, new source and destination smali code with .line removed"
mkdir -p $temp_old_smali_dir
mkdir -p $temp_new_smali_dir
mkdir -p $temp_dst_smali_orig_dir
mkdir -p $temp_dst_smali_patched_dir
mkdir -p $reject_dir

cp -r $old_smali_dir/$appname $temp_old_smali_dir
cp -r $dst_smali_dir/$appname $temp_dst_smali_orig_dir
if [ "$suffix" = "jar" ];then
    cp -r $new_smali_dir/$appname.jar.out $temp_new_smali_dir/$appname
else
    cp -r $new_smali_dir/$appname $temp_new_smali_dir
fi

$PORT_ROOT/tools/rmline.sh $temp_dir

function apply_miui_patch() {
	old_code_noline=$temp_old_smali_dir/$1
	new_code_noline=$temp_new_smali_dir/$1
	dst_code_noline=$temp_dst_smali_orig_dir/$1
	dst_code=$dst_smali_dir/$1
	dst_code_orig=$dst_code.orig

	echo ">>> compute the difference between $old_code_noline and $new_code_noline"
	cd $old_code_noline
	for file in `find ./ -name "*.[sx]*"`
	do
       	if [ -f $new_code_noline/$file ]
       	then
        	diff $file $new_code_noline/$file > /dev/null || {
					diff -B -c $file $new_code_noline/$file > $file.diff
			}
       	else
        	echo "$file does not exist at $new_code_noline"
       	fi
	done

	cd $dst_smali_dir
	mv $dst_code $dst_code_orig
	cp -r $dst_code_noline $dst_code

	echo ">>> apply the patch into the $dst_code"
	cd $old_code_noline
	for file in `find ./ -name "*.diff"`
	do
		mkdir -p $reject_dir/$1/`dirname $file`
        patch $dst_code/${file%.diff} -r $reject_dir/$1/${file%.diff}.rej < $file
	done

	cp -r $dst_code $temp_dst_smali_patched_dir

	cd $dst_code_noline
	for file in `find ./ -name "*.smali"`
	do
        rm -f $file.diff
        diff -B -c $file $dst_code_orig/$file > $file.diff
        patch -f $dst_code/$file -r /dev/null < $file.diff >/dev/null 2>&1
		rm -f $file.diff
	done

    find $dst_code -name "*.smali.orig" -exec rm {} \;
	find $temp_dst_smali_patched_dir -name "*.smali.orig" -exec rm {} \;
	rm -rf $dst_code_orig
}

apply_miui_patch $appname

echo ">>> copy out the result smali files and clean the workspace"
mv $new_smali_dir/$appname $new_smali_dir/$appname-old
mv $dst_smali_dir/$appname $new_smali_dir/$appname
rm -rf $old_smali_dir
rm -rf $dst_smali_dir

echo "<<< patch miui into target $app is done."
echo "Please look at $reject_dir to resolve any conflicts!"
tree -f $reject_dir
