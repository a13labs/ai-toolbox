if [ -n "$_STABLE_DIFFUSION_INCLUDE_" ]; then
    return
fi

_STABLE_DIFFUSION_INCLUDE_=1

if [ -z "$_BOOTSTRAP_INCLUDE_" ]; then
    echo "bootstrap.sh must be included before including this file"
    exit 1
fi

include tools/downloader_tool.sh

_STABLE_DIFFUSION_REPO_=$(read_config ".apps.stable_diffusion.repo" "a13labs/stable_diffusion")
_STABLE_DIFFUSION_VERSION_=$(read_config ".apps.stable_diffusion.version" "latest")
_STABLE_DIFFUSION_NV_VISIBLE_DEVICES_=$(read_config ".apps.stable_diffusion.nvidia_visible_devices" ${NVIDIA_VISIBLE_DEVICES:-"all"})
_STABLE_DIFFUSION_PORT_=$(read_config ".apps.stable_diffusion.port" "8081")
_STABLE_DIFFUSION_IMAGE_=$_STABLE_DIFFUSION_REPO_:$_STABLE_DIFFUSION_VERSION_

function stable_diffusion_create_dirs {
    log_debug "Creating stable_diffusion directories"
    mkdir -p ${_DATADIR_}/stable_diffusion/.cache 
    mkdir -p ${_DATADIR_}/stable_diffusion/embeddings 
    mkdir -p ${_DATADIR_}/stable_diffusion/config 
    mkdir -p ${_DATADIR_}/stable_diffusion/models
    mkdir -p ${_DATADIR_}/stable_diffusion/output
}

function stable_diffusion_build {
    podman_build $_STABLE_DIFFUSION_IMAGE_ $_BUILDDIR_/stable_diffusion $@
    if [ $? -ne 0 ]; then
        log_err "failed to build/pull stable_diffusion image"
        exit 1
    fi
}

function stable_diffusion_create {
    stable_diffusion_build    
    if ! podman container exists stable_diffusion; then
        log_info "creating stable_diffusion container"
        podman container create --userns=keep-id --security-opt=label=disable \
                    -v ${_DATADIR_}/stable_diffusion:/data:U \
                    -v ${_DATADIR_}/stable_diffusion/output:/output:U \
                    -e CLI_ARGS="--allow-code --enable-insecure-extension-access --api" \
                    -p 0.0.0.0:$_STABLE_DIFFUSION_PORT_:7860 \
                    --network ai_toolbox \
                    --device nvidia.com/gpu=$_STABLE_DIFFUSION_NV_VISIBLE_DEVICES_ \
                    --name stable_diffusion $_STABLE_DIFFUSION_IMAGE_
        if [ $? -ne 0 ]; then
            log_err "failed to create stable_diffusion container"
            exit 1
        fi
    fi
}

function stable_diffusion_start {
    podman_start stable_diffusion
}

function stable_diffusion_stop {
    podman_stop stable_diffusion
}

function stable_diffusion_clean {
    podman_clean $_STABLE_DIFFUSION_IMAGE_ stable_diffusion
}

function stable_diffusion_run {
    stable_diffusion_create
    stable_diffusion_start
}

function stable_diffusion_logs {
    podman_logs stable_diffusion $@
}

function stable_diffusion_exec {
    podman_exec stable_diffusion stable_diffusion $@
}

function stable_diffusion_shell {
    podman_shell stable_diffusion stable_diffusion
}

function stable_diffusion_is_running {
    podman_is_running stable_diffusion
}

function stable_diffusion_download_model {
    model_name=$1
    source_url=$2
    checksum=$3
    
    if [ -z $source_url ] || [ -z $model_name ] ; then
        echo "Usage: $(basename $0) download <source_url> <model_name> [<checksum>]"
        exit 1
    fi

    mkdir -p ${_DATADIR_}/stable_diffusion/models/$model_name
    downloader_tool_download $source_url ${_DATADIR_}/stable_diffusion/models/$model_name $checksum
}

stable_diffusion_create_dirs
