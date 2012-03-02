PWD=`pwd`
METADATA_DIR=$PWD/metadata
OUT_DIR=$PWD/out
ZIP_DIR=$OUT_DIR/ZIP
TARGET_FILES_DIR=$OUT_DIR/target_files
TARGET_FILES_ZIP=$OUT_DIR/target_files.zip
TARGET_FILES_TEMPLATE_DIR=$PORT_ROOT/tools/target_files_template
TOOL_DIR=$PORT_ROOT/tools
OTA_FROM_TARGET_FILES=$TOOL_DIR/releasetools/ota_from_target_files
SIGN_TARGET_FILES_APKS=$TOOL_DIR/releasetools/sign_target_files_apks

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

function recover_link {
    cp -f $METADATA_DIR/linkinfo.txt $TARGET_FILES_DIR/SYSTEM
    python $TOOL_DIR/releasetools/recoverylink.py $TARGET_FILES_DIR
    rm $TARGET_FILES_DIR/SYSTEM/linkinfo.txt
}

function process_metadata {
    echo "Process metadata"
    cp -f $METADATA_DIR/filesystem_config.txt $TARGET_FILES_DIR/META
    cp -f $METADATA_DIR/recovery.fstab $TARGET_FILES_DIR/RECOVERY/RAMDISK/etc
    python $TOOL_DIR/uniq_first.py $METADATA_DIR/apkcerts.txt $TARGET_FILES_DIR/META/apkcerts.txt
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
    echo "Build full ota package: $OUTPUT_OTA_PACKAGE"
    if [ -n "$PORT_PRODUCT" ];then
        cd $PORT_ROOT/$PORT_PRODUCT
    fi
    $OTA_FROM_TARGET_FILES -n -k $TOOL_DIR/platform $TARGET_FILES_ZIP $OUT_DIR/update_miui.zip
    cd -
}

copy_target_files_template
copy_bootimage
copy_system_dir
process_metadata
zip_target_files
sign_target_files
build_ota_package
