#!/bin/bash

TEMPDIR=out/temp_for_preloaded
JAR_DIR=$(basename $2)
JAR_FILE=${JAR_DIR/.jar.out/}.jar
echo "prepare preloaded for $2"
rm -rf $TEMPDIR/
if [ -f stockrom/system/framework/${JAR_FILE} ]
then
	unzip stockrom/system/framework/${JAR_FILE} -d $TEMPDIR
else
	unzip $1 system/framework/${JAR_FILE} -d $TEMPDIR
	unzip ${TEMPDIR}/system/framework/${JAR_FILE} -d $TEMPDIR
fi

if [ -f ${TEMPDIR}/preloaded-classes ]
then
	rm -f $2/preloaded-classes
	cp ${TEMPDIR}/preloaded-classes $2/
fi

rm -rf $TEMPDIR/
if [ ! -f $3/${JAR_FILE} ]
then
	exit 0
fi

unzip $3/${JAR_FILE} -d $TEMPDIR
if [ -f ${TEMPDIR}/preloaded-classes ]
then
	cat ${TEMPDIR}/preloaded-classes >> $2/preloaded-classes
	sort $2/preloaded-classes | uniq | grep -v "#" | sed '/^\s*$/d' > $2/temp
	cp $2/temp $2/preloaded-classes
fi
rm -rf $TEMPDIR/

