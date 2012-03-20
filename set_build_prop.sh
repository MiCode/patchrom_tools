#!/bin/bash

build_prop_file=$1
# other arguments: # product=$2 # number=$3 # version=$4

cat $build_prop_file | sed -e "s/ro\.build\.version\.incremental=.*/ro\.build\.version\.incremental=$3/" \
                      | sed -e "s/ro\.product\.mod_device=.*//" > $build_prop_file.new

echo "ro.product.mod_device=$2" >> $build_prop_file.new
echo "ro.skia.use_data_fonts=1" >> $build_prop_file.new
mv $build_prop_file.new $build_prop_file

