#!/bin/bash
#
# $1: dir for original miui app 
# $2: dir for target miui app
#
if [ -f "customize_miui_app.sh" ]; then
	./customize_miui_app.sh $1 $2
fi

if [ $1 = "MiuiHome" ];then
   if [ -f $1/res/xml/default_workspace.xml.part ]; then
       $PORT_ROOT/tools/gen_desklayout.pl $1/res/xml/default_workspace.xml.part $2/res/xml
       for file in $2/res/xml/default_workspace*.xml; do
           mv $file.new $file
       done
   fi
fi
