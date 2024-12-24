if [ -n "$_TRELLIS_INCLUDE_" ]; then
    return
fi

_TRELLIS_INCLUDE_=1

if [ -z "$_BOOTSTRAP_INCLUDE_" ]; then
    echo "bootstrap.sh must be included before including this file"
    exit 1
fi

_TRELLIS_REPO_=$(read_config ".apps.trellis.repo" "a13labs/trellis")
_TRELLIS_VERSION_=$(read_config ".apps.trellis.version" "latest")
_TRELLIS_NV_VISIBLE_DEVICES_=$(read_config ".apps.trellis.nvidia_visible_devices" ${NVIDIA_VISIBLE_DEVICES:-"all"})
_TRELLIS_PORT_=$(read_config ".apps.trellis.port" "8082")
_TRELLIS_IMAGE_=$_TRELLIS_REPO_:$_TRELLIS_VERSION_

function trellis_create_dirs {
    log_debug "Creating trellis directories"
    mkdir -p ${_DATADIR_}/trellis/cache 
}

function trellis_build {
    podman_build $_TRELLIS_IMAGE_ $_BUILDDIR_/trellis $@
    if [ $? -ne 0 ]; then
        log_err "failed to build/pull trellis image"
        exit 1
    fi
}

function trellis_create {
    trellis_build    
    if ! podman container exists trellis; then
        log_info "creating trellis container"
        podman container create --userns=keep-id --security-opt=label=disable \
                    -v ${_DATADIR_}/trellis/cache:/home/worker/.cache:Z \
                    -p 0.0.0.0:$_TRELLIS_PORT_:7860 \
                    --network ai_toolbox \
                    --device nvidia.com/gpu=$_TRELLIS_NV_VISIBLE_DEVICES_ \
                    --name trellis $_TRELLIS_IMAGE_
        if [ $? -ne 0 ]; then
            log_err "failed to create trellis container"
            exit 1
        fi
    fi
}

function trellis_start {
    podman_start trellis
}

function trellis_stop {
    podman_stop trellis
}

function trellis_clean {
    podman_clean $_TRELLIS_IMAGE_ trellis
}

function trellis_run {
    trellis_create
    trellis_start
}

function trellis_logs {
    podman_logs trellis $@
}

function trellis_exec {
    podman_exec trellis trellis $@
}

function trellis_shell {
    podman_shell trellis trellis
}

function trellis_is_running {
    podman_is_running trellis
}

trellis_create_dirs
