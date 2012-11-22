#!/bin/bash

# $1 -- res dir of framework-res

if [ -z "$PORT_ROOT" ]
then
	echo "Error! Please setup environment"
	exit 1
fi
if [ -f res_whitelist ]
then
	WHITELIST_FILE=res_whitelist
else
	WHITELIST_FILE=${PORT_ROOT}/tools/res_whitelist
fi

for d in $(ls $1 | grep  -e "raw-"  -e "values-")
do
	if ! grep -q -E "^$d$" $WHITELIST_FILE 
	then
		rm -rf $1/$d
	fi
done
