#!/bin/bash

if [ -f "./patch_bootimg.sh" ];then
    bash ./patch_bootimg.sh $1
    exit $?
fi

BOOTIMG=$1

# Unpack bootimg
rm -rf $TARGET_BOOT_DIR
mkdir -p $TARGET_BOOT_DIR
$UNPACKBOOTIMG -i $BOOTIMG -o $TARGET_BOOT_DIR > /dev/null

# Unpack ramdisk
gunzip $TARGET_BOOT_DIR/boot.img-ramdisk.gz
mkdir -p $TARGET_BOOT_DIR/ramdisk
cd $TARGET_BOOT_DIR/ramdisk
cpio -i < ../boot.img-ramdisk
cd - > /dev/null

# Change init
if [ ! -f $TARGET_BOOT_DIR/ramdisk/init_vendor ];then
mv $TARGET_BOOT_DIR/ramdisk/init $TARGET_BOOT_DIR/ramdisk/init_vendor
fi
cp -f $PREBUILT_BOOT_DIR/$TARGET_BIT/init $TARGET_BOOT_DIR/ramdisk/init

# Pack ramdisk
$MKBOOTFS $TARGET_BOOT_DIR/ramdisk | gzip > $TARGET_BOOT_DIR/ramdisk.gz


# Disable selinux
OLDCMDLINE=$(cat $TARGET_BOOT_DIR/boot.img-cmdline)
NEWCMDLINE="androidboot.selinux=disabled"
for prop in $OLDCMDLINE
do
    echo $prop | grep "androidboot.selinux=" > /dev/null
    if [ $? -eq 0 ];then
        continue
    fi
    NEWCMDLINE="$NEWCMDLINE $prop"
done

echo "NEWCMDLINE: $NEWCMDLINE"

BASEADDR=$(cat $TARGET_BOOT_DIR/boot.img-base)
PAGESIZE=$(cat $TARGET_BOOT_DIR/boot.img-pagesize)
RAMDISKOFFSET=$(cat $TARGET_BOOT_DIR/boot.img-ramdisk_offset)
TAGSOFFSET=$(cat $TARGET_BOOT_DIR/boot.img-tags_offset)

# Pack bootimg
$MKBOOTIMG --kernel $TARGET_BOOT_DIR/boot.img-zImage --ramdisk $TARGET_BOOT_DIR/ramdisk.gz --dt $TARGET_BOOT_DIR/boot.img-dt --base "$BASEADDR" --pagesize "$PAGESIZE" --ramdisk_offset "$RAMDISKOFFSET" --tags_offset "$TAGSOFFSET" --cmdline "$NEWCMDLINE" -o $BOOTIMG
