if [ -n "$_OLLAMA_INCLUDE_" ]; then
    return
fi

_OLLAMA_INCLUDE_=1

if [ -z "$_BOOTSTRAP_INCLUDE_" ]; then
    echo "bootstrap.sh must be included before including this file"
    exit 1
fi

_OLLAMA_REPO_=$(read_config ".apps.ollama.repo" "a13labs/ollama")
_OLLAMA_VERSION_=$(read_config ".apps.ollama.version" "latest")
_OLLAMA_NVIDIA_VISIBLE_DEVICES_=$(read_config ".apps.ollama.nvidia_visible_devices" ${NVIDIA_VISIBLE_DEVICES:-"all"})
_OLLAMA_PORT_=$(read_config ".apps.ollama.port" "11434")
_OLLAMA_IMAGE_=$_OLLAMA_REPO_:$_OLLAMA_VERSION_

function ollama_create_dirs {
    log_debug "creating ollama directories"
    mkdir -p $_DATADIR_/ollama
}

function ollama_build {
    podman_build $_OLLAMA_IMAGE_ $_BUILDDIR_/ollama $@
    if [ $? -ne 0 ]; then
        log_err "Failed to build/pull ollama image"
        exit 1
    fi
}

function ollama_create {
    ollama_build
    if ! podman container exists ollama; then
        log_info "creating ollama container"
        podman container create --userns=keep-id --security-opt=label=disable \
                        -v ${_DATADIR_}/ollama:/home/worker/.ollama:Z \
                        -p 0.0.0.0:$_OLLAMA_PORT_:11434 \
                        --network ai_toolbox \
                        --device nvidia.com/gpu=$_OLLAMA_NVIDIA_VISIBLE_DEVICES_ \
                        --name ollama $_OLLAMA_IMAGE_
        if [ $? -ne 0 ]; then
            log_err "Failed to create ollama container"
            exit 1
        fi
    fi
}

function ollama_start {
    podman_start ollama
}

function ollama_stop {
    podman_stop ollama
}

function ollama_clean {
    podman_clean $_OLLAMA_IMAGE_ ollama 
}

function ollama_run {
    ollama_create
    ollama_start
}

function ollama_logs {
    podman_logs ollama $@
}

function ollama_exec {
    podman_exec ollama ollama $@ 
}

function ollama_shell {
    podman_shell ollama ollama
}

function ollama_is_running {
    podman_is_running ollama
}

ollama_create_dirs