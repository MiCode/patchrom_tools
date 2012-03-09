#!/bin/bash
#
# $1: dir for original miui app 
# $2: dir for target miui app
#
if [ -f "customize_miui_app.sh" ]; then
	./customize_miui_app.sh $1 $2
fi
