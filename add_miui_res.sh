#!/bin/bash
#
# $1: dir for miui overlay framework-res
# $2: dir for target framework-res
#
if [ -f "customize_framework-res.sh" ]; then
	./customize_framework-res.sh $1 $2
fi
