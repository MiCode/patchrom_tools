#!/bin/bash

TEMPDIR=out/temp_for_preloaded
JAR_DIR=$(basename $1)
JAR_FILE=${JAR_DIR/.jar.out/}.jar
echo "prepare preloaded for $1"
rm -rf $TEMPDIR/
if [ -f stockrom/system/framework/${JAR_FILE} ]
then
	unzip stockrom/system/framework/${JAR_FILE} -d $TEMPDIR
fi

if [ -f ${TEMPDIR}/preloaded-classes ]
then
	rm -f $1/preloaded-classes
	cp ${TEMPDIR}/preloaded-classes $1/
fi

rm -rf $TEMPDIR/
if [ ! -f $2/${JAR_FILE} ]
then
	exit 0
fi

unzip $2/${JAR_FILE} -d $TEMPDIR
if [ -f ${TEMPDIR}/preloaded-classes ]
then
	cat ${TEMPDIR}/preloaded-classes >> $1/preloaded-classes
	sort $1/preloaded-classes | uniq | grep -v "#" | sed '/^\s*$/d' > $1/temp
	cp $1/temp $1/preloaded-classes
fi
rm -rf $TEMPDIR/

