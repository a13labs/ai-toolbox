if [ -n "$_DOWNLOADER_TOOL_INCLUDE_" ]; then
    return
fi

_DOWNLOADER_TOOL_INCLUDE_=1

if [ -z "$_BOOTSTRAP_INCLUDE_" ]; then
    log_err "bootstrap.sh must be included before including this file"
    exit 1
fi

_DOWNLOADER_TOOL_REPO_=$(read_config ".tools.download_tool.repo" "a13labs/downloader_tool")
_DOWNLOADER_TOOL_VERSION_=$(read_config ".tools.download_tool.version" "latest")
_DOWNLOADER_TOOL_IMAGE_=$_DOWNLOADER_TOOL_REPO_:$_DOWNLOADER_TOOL_VERSION_

function downloader_tool_build {
    podman_build $_DOWNLOADER_TOOL_IMAGE_ $_BUILDDIR_/downloader_tool
}

function downloader_tool_run {
    local target_folder=$1
    shift
    downloader_tool_build
    if [ $? -ne 0 ]; then
        log_err "Failed to build/pull downloader_tool image"
        exit 1
    fi
    podman run --rm --userns=keep-id --security-opt=label=disable \
            -v $target_folder:/target_folder:Z \
            $_DOWNLOADER_TOOL_IMAGE_ $@
}

function downloader_tool_download {
    local source_url=$1
    local target_folder=$2
    local target_file=$(basename $source_url)
    local checksum=$3
    mkdir -vp $target_folder
    log_info "Downloading from %s to %s" $source_url $target_file
    downloader_tool_run $target_folder aria2c -x 10 --disable-ipv6 $source_url --dir /target_folder --out $target_file --continue
    if [ $? -ne 0 ]; then
        log_err "Failed to download %s" $source_url
        exit 1
    fi
    if [ -n "$checksum" ]; then
        log_info "Verifying checksum for %s" $source_url
        downloader_tool_run $target_folder sha256sum -b /target_folder/$target_file > /tmp/checksums.sha256
        grep $checksum /tmp/checksums.sha256
        if [ $? -ne 0 ]; then
            log_err "Checksum mismatch for %s" $source_url
            exit 1
        fi
    fi
}

function downloader_tool_clean {
    podman_clean $_DOWNLOADER_TOOL_IMAGE_
}

