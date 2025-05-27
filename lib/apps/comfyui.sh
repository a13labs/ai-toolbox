if [ -n "$_COMFY_UI_INCLUDE_" ]; then
    return
fi

_COMFY_UI_INCLUDE_=1

if [ -z "$_BOOTSTRAP_INCLUDE_" ]; then
    echo "bootstrap.sh must be included before including this file"
    exit 1
fi

include tools/downloader_tool.sh

_COMFY_UI_REPO_=$(read_config ".apps.comfyui.repo" "a13labs/comfyui")
_COMFY_UI_VERSION_=$(read_config ".apps.comfyui.version" "latest")
_COMFY_UI_NV_VISIBLE_DEVICES_=$(read_config ".apps.comfyui.nvidia_visible_devices" ${NVIDIA_VISIBLE_DEVICES:-"all"})
_COMFY_UI_PORT_=$(read_config ".apps.comfyui.port" "8083")
_COMFY_UI_IMAGE_=$_COMFY_UI_REPO_:$_COMFY_UI_VERSION_

function comfyui_create_dirs {
    log_debug "Creating comfyui directories"
    mkdir -p ${_DATADIR_}/comfyui/.cache
    mkdir -p ${_DATADIR_}/comfyui/models
    mkdir -p ${_DATADIR_}/comfyui/models/checkpoints
    mkdir -p ${_DATADIR_}/comfyui/models/clip
    mkdir -p ${_DATADIR_}/comfyui/models/clip_vision
    mkdir -p ${_DATADIR_}/comfyui/models/configs
    mkdir -p ${_DATADIR_}/comfyui/models/controlnet
    mkdir -p ${_DATADIR_}/comfyui/models/diffusers
    mkdir -p ${_DATADIR_}/comfyui/models/diffusion_models
    mkdir -p ${_DATADIR_}/comfyui/models/embeddings
    mkdir -p ${_DATADIR_}/comfyui/models/gligen
    mkdir -p ${_DATADIR_}/comfyui/models/hypernetworks
    mkdir -p ${_DATADIR_}/comfyui/models/loras
    mkdir -p ${_DATADIR_}/comfyui/models/photomaker
    mkdir -p ${_DATADIR_}/comfyui/models/style_models
    mkdir -p ${_DATADIR_}/comfyui/models/text_encoders
    mkdir -p ${_DATADIR_}/comfyui/models/unet
    mkdir -p ${_DATADIR_}/comfyui/models/upscale_models
    mkdir -p ${_DATADIR_}/comfyui/models/vae
    mkdir -p ${_DATADIR_}/comfyui/models/vae_approx
    mkdir -p ${_DATADIR_}/comfyui/output
}

function comfyui_build {
    podman_build $_COMFY_UI_IMAGE_ $_BUILDDIR_/comfyui $@
    if [ $? -ne 0 ]; then
        log_err "failed to build/pull comfyui image"
        exit 1
    fi
}

function comfyui_create {
    comfyui_build    
    if ! podman container exists comfyui; then
        log_info "creating comfyui container"
        podman container create --userns=keep-id --security-opt=label=disable \
                    -v ${_DATADIR_}/comfyui/.cache:/home/worker/.cache:U \
                    -v ${_DATADIR_}/comfyui/models:/home/worker/ComfyUI/models:U \
                    -v ${_DATADIR_}/comfyui/custom_nodes:/home/worker/ComfyUI/custom_nodes:U \
                    -v ${_DATADIR_}/comfyui/output:/home/worker/ComfyUI/output:U \
                    -p 0.0.0.0:$_COMFY_UI_PORT_:8188 \
                    --network ai_toolbox \
                    --device nvidia.com/gpu=$_COMFY_UI_NV_VISIBLE_DEVICES_ \
                    --name comfyui $_COMFY_UI_IMAGE_
        if [ $? -ne 0 ]; then
            log_err "failed to create comfyui container"
            exit 1
        fi
    fi
}

function comfyui_start {
    podman_start comfyui
}

function comfyui_stop {
    podman_stop comfyui
}

function comfyui_clean {
    podman_clean $_COMFY_UI_IMAGE_ comfyui
}

function comfyui_run {
    comfyui_create
    comfyui_start
}

function comfyui_logs {
    podman_logs comfyui $@
}

function comfyui_exec {
    podman_exec comfyui comfyui $@
}

function comfyui_shell {
    podman_shell comfyui comfyui
}

function comfyui_is_running {
    podman_is_running comfyui
}

function comfyui_download_model {
    model_name=$1
    model_type=$2
    source_url=$3
    checksum=$4
    
    if [ -z $source_url ] || [ -z $model_name ] || [ -z $model_type ] ; then
        echo "Usage: $(basename $0) download_model <model_name> <model_type> <source_url> [<checksum>]"
        exit 1
    fi

    if [ ! -d ${_DATADIR_}/comfyui/models/$model_type ]; then
        log_err "model type $model_type does not exist"
        exit 1
    fi

    mkdir -p ${_DATADIR_}/comfyui/models/$model_type/$model_name
    downloader_tool_download $source_url ${_DATADIR_}/comfyui/models/$model_type/$model_name $checksum
}

function comfyui_download_custom_node {
    source_url=$1
    ref=$2
    
    if [ -z $source_url ] ; then
        echo "Usage: $(basename $0) download_node <source_url> [<ref>]"
        exit 1
    fi

    # Check if source_url is a git repo
    if [[ $source_url == *".git" ]]; then
        repo_name=$(basename $source_url .git)
        repo_dir=${_DATADIR_}/comfyui/custom_nodes/$repo_name
        if [ -d $repo_dir ]; then
            log_info "updating $repo_name"
            git -C $repo_dir pull
            git -C $repo_dir checkout $ref
        else
            log_info "cloning $repo_name"
            git clone --depth=1 --no-tags --recurse-submodules --shallow-submodules --branch $ref $source_url $repo_dir 
        fi
    else
        log_err "source_url must be a git repo"
        exit 1
    fi
}

comfyui_create_dirs
