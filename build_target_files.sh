PRJ_DIR=`pwd`
METADATA_DIR=$PRJ_DIR/metadata
OUT_DIR=$PRJ_DIR/out
ZIP_DIR=$OUT_DIR/ZIP
TARGET_FILES_DIR=$OUT_DIR/target_files
TARGET_FILES_ZIP=$OUT_DIR/target_files.zip
TARGET_FILES_TEMPLATE_DIR=$PORT_ROOT/tools/target_files_template
TOOL_DIR=$PORT_ROOT/tools
OTA_FROM_TARGET_FILES=$TOOL_DIR/releasetools/ota_from_target_files
SIGN_TARGET_FILES_APKS=$TOOL_DIR/releasetools/sign_target_files_apks
OUT_ZIP_FILE=
NO_SIGN=false

# copy the whole target_files_template dir
function copy_target_files_template {
    echo "Copy target file template into current working directory"
    rm -rf $TARGET_FILES_DIR
    mkdir -p $TARGET_FILES_DIR
    cp -r $TARGET_FILES_TEMPLATE_DIR/* $TARGET_FILES_DIR
}

function copy_bootimage {
    echo "Copy bootimage"
    for file in boot.img zImage */boot.img */zImage
    do
        if [ -f $ZIP_DIR/$file ]
        then
            cp $ZIP_DIR/$file $TARGET_FILES_DIR/BOOTABLE_IMAGES/boot.img
            return
        fi
    done
}

function copy_system_dir {
    echo "Copy system dir"
    cp -rf $ZIP_DIR/system/* $TARGET_FILES_DIR/SYSTEM
}

function copy_data_dir {
    #The thirdpart apps have copyed in copy_target_files_template function,
    #here, just to decide whether delete them.
    if [ $INCLUDE_THIRDPART_APP = "true" ];then
       echo "Copy thirdpart apps"
    else
       rm -rf $TARGET_FILES_DIR/DATA/*
    fi
    echo "Copy miui preinstall apps"
    mkdir -p $TARGET_FILES_DIR/DATA/
    cp -rf $ZIP_DIR/data/media/preinstall_apps $TARGET_FILES_DIR/DATA/
    if [ -f customize_data.sh ];then
        ./customize_data.sh $PRJ_DIR
    fi
}

function recover_link {
    cp -f $METADATA_DIR/linkinfo.txt $TARGET_FILES_DIR/SYSTEM
    python $TOOL_DIR/releasetools/recoverylink.py $TARGET_FILES_DIR
    rm $TARGET_FILES_DIR/SYSTEM/linkinfo.txt
}

function process_metadata {
    echo "Process metadata"
    cp -f $METADATA_DIR/filesystem_config.txt $TARGET_FILES_DIR/META
    cat $TOOL_DIR/target_files_template/META/filesystem_config.txt >> $TARGET_FILES_DIR/META/filesystem_config.txt
    cp -f $METADATA_DIR/recovery.fstab $TARGET_FILES_DIR/RECOVERY/RAMDISK/etc
    python $TOOL_DIR/uniq_first.py $METADATA_DIR/apkcerts.txt $TARGET_FILES_DIR/META/apkcerts.txt $PRJ_DIR
    cat $TARGET_FILES_DIR/META/apkcerts.txt | sort > $TARGET_FILES_DIR/temp.txt
    mv $TARGET_FILES_DIR/temp.txt $TARGET_FILES_DIR/META/apkcerts.txt
    recover_link
}

# compress the target_files dir into a zip file
function zip_target_files {
    echo "Compress the target_files dir into zip file"
    echo $TARGET_FILES_DIR
    cd $TARGET_FILES_DIR
    echo "zip -q -r -y $TARGET_FILES_ZIP *"
    zip -q -r -y $TARGET_FILES_ZIP *
    cd -
}

function sign_target_files {
    echo "Sign target files"
    $SIGN_TARGET_FILES_APKS -d $PORT_ROOT/build/security $TARGET_FILES_ZIP temp.zip
    mv temp.zip $TARGET_FILES_ZIP
}

# build a new full ota package
function build_ota_package {
    echo "Build full ota package: $OUT_DIR/$OUT_ZIP_FILE"
    $OTA_FROM_TARGET_FILES -n -k $PORT_ROOT/build/security/testkey $TARGET_FILES_ZIP $OUT_DIR/$OUT_ZIP_FILE
}


if [ $# -eq 3 ];then
    NO_SIGN=true
    OUT_ZIP_FILE=$3
    INCLUDE_THIRDPART_APP=$1
elif [ $# -eq 2 ];then
    OUT_ZIP_FILE=$2
    INCLUDE_THIRDPART_APP=$1
elif [ $# -eq 1 ];then
    INCLUDE_THIRDPART_APP=$1
fi

copy_target_files_template
copy_bootimage
copy_system_dir
copy_data_dir
process_metadata
if [ -f "customize_target_files.sh" ]; then
    ./customize_target_files.sh
    if [ $? -ne 0 ];then
       exit 1
    fi
fi
zip_target_files
if [ -n "$OUT_ZIP_FILE" ];then
    if [ "$NO_SIGN" == "false" ];then
        sign_target_files
    fi
    build_ota_package
fi
