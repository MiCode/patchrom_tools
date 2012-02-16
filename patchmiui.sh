#!/bin/bash

last_framework_dir=$PORT_ROOT/android/last-framework
current_framework_dir=$PORT_ROOT/android
target_framework_dir=`pwd`
temp_dir=$target_framework_dir/temp
reject_dir=$temp_dir/reject

RMLINE=$PORT_ROOT/tools/rmline.sh
function remove_lines() {
	$RMLINE $1/framework.jar.out
	$RMLINE $1/services.jar.out
	$RMLINE $1/android.policy.jar.out
}

if [ ! -d $temp_dir ]
then
	echo "Create temp directory to store the last, current and target framework smali code with .line removed."
    mkdir -p $temp_dir
	mkdir -p $temp_dir/current-framework
	mkdir -p $temp_dir/target-framework
	mkdir -p $reject_dir
	cp -r $last_framework_dir $temp_dir
	cp -r $current_framework_dir/framework.jar.out $temp_dir/current-framework
	cp -r $current_framework_dir/android.policy.jar.out $temp_dir/current-framework
	cp -r $current_framework_dir/services.jar.out $temp_dir/current-framework
	remove_lines $temp_dir/last-framework
	remove_lines $temp_dir/current-framework
fi

function apply_miui_patch() {
	echo "Compute the diff between google and patch-miui-to-google smali code..."
	old_src=$temp_dir/last-framework/$1
	new_src=$temp_dir/current-framework/$1
	dst_src=$target_framework_dir/$1
	dst_src_orig=$dst_src.orig
	dst_src_noline=$dst_src.noline

	cd $old_src
	for file in `find ./ -name "*.smali"`
	do
       	if [ -f $new_src/$file ]
       	then
        	diff $file $new_src/$file > /dev/null || {
					diff -B -c $file $new_src/$file > $file.diff
			}
       	else
        	echo "$file does not exist at $new_src"
       	fi
	done

	cd $dst_src/..
	cp -r $dst_src $dst_src_orig
	echo "Remove .line from target smali code..."
	$RMLINE $dst_src

	echo "Apply the patch into the target smali code..."
	cp -r $dst_src $dst_src_noline
	cd $old_src
	for file in `find ./ -name "*.smali.diff"`
	do
		mkdir -p $reject_dir/$1/`dirname $file`
        patch $dst_src/${file%.diff} -r $reject_dir/$1/${file%.diff}.rej < $file
	done

	echo "Add .line back to the phone smali code..."
	cd $dst_src_noline
	for file in `find ./ -name "*.smali"`
	do
        rm -f $file.diff
        diff -B -c $file $dst_src_orig/$file > $file.diff
        patch -f $dst_src/$file -r /dev/null < $file.diff >/dev/null 2>&1
		rm -f $file.diff
	done
	rm -rf $dst_src_orig
	mv $dst_src_noline $temp_dir/target-framework/$1
}

apply_miui_patch android.policy.jar.out
apply_miui_patch services.jar.out
apply_miui_patch framework.jar.out

echo "Patch miui into target framework is done. Please look at $reject_dir to resolve any conflicts."
