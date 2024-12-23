if [ -z "$DATADIR" ] || [ -z "$BUILDDIR" ]; then
    echo "DATADIR or BUILDDIR must be set"
    exit 1
fi

DOWNLOADER_TOOL_IMAGE=${DOWNLOADER_TOOL_IMAGE:-"localhost/downloader_tool:latest"}

function downloader_tool_build {
    if ! podman image exists $DOWNLOADER_TOOL_IMAGE; then
        echo "Building downloader_tool"
        podman build --force-rm --tag $DOWNLOADER_TOOL_IMAGE $BUILDDIR/downloader_tool
    fi
}

function downloader_tool_run {
    TARGET_FOLDER=$1
    podman run --rm --userns=keep-id \
            -v $TARGET_FOLDER:/target_folder:U --security-opt=label=disable \
            $DOWNLOADER_TOOL_IMAGE ${@:2}
}

function downloader_tool_download {
    SOURCE_URL=$1
    TARGET_FOLDER=$2
    TARGET_FILE=$(basename $SOURCE_URL)
    CHECKSUM=$3
    mkdir -vp $TARGET_FOLDER
    echo "Downloading, this might take a while..."
    downloader_tool_run $TARGET_FOLDER aria2c -x 10 --disable-ipv6 $SOURCE_URL --dir /target_folder --out $TARGET_FILE --continue
    if [ $? -ne 0 ]; then
        echo "Failed to download $SOURCE_URL"
        exit 1
    fi
    if [ -n "$CHECKSUM" ]; then
        echo "Checking SHAs..."
        downloader_tool_run $TARGET_FOLDER sha256sum -b /target_folder/$TARGET_FILE > /tmp/checksums.sha256
        grep $CHECKSUM /tmp/checksums.sha256
        if [ $? -ne 0 ]; then
            echo "Checksum mismatch for $SOURCE_URL"
            exit 1
        fi
    fi
}

