#!/bin/bash

rm -r tmp
rm -r tmp2
mkdir tmp
mkdir tmp2

for f in `grep -rn "access" $1 | cut -d: -f1 | uniq | sort`
do
    sed -i "s/access\$.*.(/access\$9999(/g" $f
done

for f in `grep -rn "access" $2 | cut -d: -f1 | uniq | sort`
do
    sed -i "s/access\$.*.(/access\$9999(/g" $f
done

for ori in `find $1 -name *.smali`
do
   filepath=`dirname $ori`
   filename=`basename $ori .smali`  
   if [ -f ${ori/$1/$2} ];then
   diff -Naur $ori ${ori/$1/$2} > tmp/"$filename.patch"
   if [ $? -eq 0 ] ; then
   rm tmp/"$filename.patch"
   echo "Processing file:$filename.patch"
   else java -jar PatchResolver.jar ${ori/$1/$3} ${ori/$1/$4} tmp/"$filename.patch" > tmp2/"$filename.patch"
   fi
   fi
done




