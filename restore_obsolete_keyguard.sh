#!/bin/bash

cd android.policy.jar.out/smali/com/android/internal/policy/impl
cp keyguard_obsolete/*.smali .


for class in `find ./keyguard_obsolete -name '*.smali' \
	| sed 's#./keyguard_obsolete/##g' | sed 's#.smali##g' \
	| cut -d$ -f1 | sort | uniq`
do
	for smali in `grep -rn $class . | cut -d: -f1 | sort | uniq`
	do
		sed -i "s/keyguard_obsolete\/$class/$class/g" $smali
		sed -i "s/keyguard_obsolete\$$class/$class/g" $smali
	done
done

rm -r ./keyguard_obsolete

cd -
