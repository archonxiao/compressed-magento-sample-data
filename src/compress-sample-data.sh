#!/bin/bash

#
# This script agressivly compresses the magento sample data images and mp3 files
# Use at your own risk!
#
# It is a quick hack, intended only to run on OSX with the following dependencies:
# - ImageMagick (that is, the convert command)
# - ImageOptim
# - lame
# - grealpath
# - curl (only for downloading the sample data)
# - 7za
#
# (c) 2014 Vinai Kopp <vinai@netzarbeiter.com>
# 

TARGET_MP3_BITRATE=48
TARGET_IMAGE_QUALITY_PERCENTAGE=50
EXCLUDE_FILES='\._*'


if [ -z "$1" ]; then
    echo "No sample data specified."
    read -r -p "Do you want to download the 1.9 sample data? [yN] "
    [[ "$REPLY" = [Yy] ]] && download=http://www.magentocommerce.com/downloads/assets/1.9.1.0/magento-sample-data-1.9.1.0.tar.bz2

elif echo "$1" | grep -q '^https\?:'; then
    download="$1"
fi

if [ -n "$download" ]; then
    echo "Downloading $download"
    curl -O "$download"
    SOURCE_ARCHIVE="$(grealpath "$(basename "$download")")"

elif [ -n "$1" ]; then
    SOURCE_ARCHIVE="$(grealpath "$1")"
fi

[ ! -e "$SOURCE_ARCHIVE" ] && {
    echo -e "Usage:\n$0 magento-sample-data-1.x.x.x.tar.bz2"
    exit 2
}
echo "Using sample data $SOURCE_ARCHIVE"

ORIG_SIZE=$(du -sh "$SOURCE_ARCHIVE" | awk '{ print $1 }')
SAMPLE_DATA_DIR=$(tar -tvzf "$SOURCE_ARCHIVE" | head -1 | awk '{ print $9 }' | xargs basename)
IMAGE_OPTIM_PATH="$(locate ImageOptim.app/Contents/MacOS/ImageOptim)"

WORK_DIR="./tmp-work-dir"
echo "Creating temporary working dir $WORK_DIR"
mkdir "$WORK_DIR" && cd "$WORK_DIR"
echo "Extracting sample data..."
tar -xzf "$SOURCE_ARCHIVE"

echo "Removing resized images cache files"
rm -rf "$SAMPLE_DATA_DIR"/media/catalog/product/cache/*
echo "Compressing images..."
find "$SAMPLE_DATA_DIR" -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.gif' \) -exec convert -quality $TARGET_IMAGE_QUALITY_PERCENTAGE "{}" "{}" \;
$IMAGE_OPTIM_PATH 2>/dev/null "$SAMPLE_DATA_DIR"
echo "Compressing mp3 files..."
find "$SAMPLE_DATA_DIR" -type f -iname '*.mp3' -exec lame --silent -b $TARGET_MP3_BITRATE "{}" "{}.out" \; -exec mv "{}.out" "{}" \;

echo "Building new sample data archive compressed-$SAMPLE_DATA_DIR.tgz..."
tar --exclude $EXCLUDE_FILES -czf "../compressed-$SAMPLE_DATA_DIR.tgz" "$SAMPLE_DATA_DIR"

echo "Building new sample data archive compressed-$SAMPLE_DATA_DIR.tbz..."
tar --exclude $EXCLUDE_FILES -cjf "../compressed-$SAMPLE_DATA_DIR.tbz" "$SAMPLE_DATA_DIR"

echo "Building new sample data archive compressed-$SAMPLE_DATA_DIR.tar.7z..."
tar --exclude $EXCLUDE_FILES -cf - "$SAMPLE_DATA_DIR" | 7za a -si "../compressed-$SAMPLE_DATA_DIR.tar.7z"

cd .. # get out of the tmp-work-dir
rm -r "$WORK_DIR"

echo "New compressed sample data archive:"
echo "Original size:   $ORIG_SIZE"
NEW_SIZE=$(du -sh "compressed-$SAMPLE_DATA_DIR.tgz" | awk '{ print $1 }');
echo "Compressed size tgz:    $NEW_SIZE"
NEW_SIZE=$(du -sh "compressed-$SAMPLE_DATA_DIR.tbz" | awk '{ print $1 }');
echo "Compressed size tbz:    $NEW_SIZE"
NEW_SIZE=$(du -sh "compressed-$SAMPLE_DATA_DIR.tar.7z" | awk '{ print $1 }');
echo "Compressed size tar.7z: $NEW_SIZE"
