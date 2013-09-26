#!/bin/bash

if [ -d "android.policy.jar.out/smali/com/android/internal/policy/impl/keyguard_obsolete" ];then

cd android.policy.jar.out/smali/com/android/internal/policy/impl
cp keyguard_obsolete/*.smali .

rm -r ./keyguard_obsolete
mv ./keyguard ../

for smali in `find . -name '*.smali'`
do
	sed -i "s/\/keyguard_obsolete\//\//g" $smali
	sed -i "s/\/keyguard\//\//g" $smali
done

mv ../keyguard ./

cd -

fi
