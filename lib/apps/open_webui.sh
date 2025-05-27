if [ -n "$_OPEN_WEBUI_INCLUDE_" ]; then
    return
fi

_OPEN_WEBUI_INCLUDE_=1

if [ -z "$_BOOTSTRAP_INCLUDE_" ]; then
    echo "bootstrap.sh must be included before including this file"
    exit 1
fi

_OPEN_WEBUI_REPO_=$(read_config ".apps.open_webui.repo" "a13labs/open_webui")
_OPEN_WEBUI_VERSION_=$(read_config ".apps.open_webui.version" "latest")
_OPEN_WEBUI_PORT_=$(read_config ".apps.open_webui.port" "8080")

_OPEN_WEBUI_IMAGE_=$_OPEN_WEBUI_REPO_:$_OPEN_WEBUI_VERSION_

function open_webui_create_dirs {
    log_debug "creating open_webui directories"
    mkdir -p ${_DATADIR_}/open_webui/local_data
    mkdir -p ${_DATADIR_}/open_webui/models
}

function open_webui_build {
    podman_build $_OPEN_WEBUI_IMAGE_ $_BUILDDIR_/open_webui $@
    if [ $? -ne 0 ]; then
        log_err "failed to build/pull open_webui image"
        exit 1
    fi
}

function open_webui_create {
    open_webui_build
    if ! podman container exists open_webui; then
        log_info "creating open_webui container"
        podman container create --userns=keep-id --security-opt=label=disable \
                    -v ${_DATADIR_}/open_webui/local_data:/home/worker/app/local_data:Z \
                    -v ${_DATADIR_}/open_webui/models:/home/worker/app/models:Z \
                    -p 0.0.0.0:$_OPEN_WEBUI_PORT_:8080 \
                    --network ai_toolbox \
                    --name open_webui $_OPEN_WEBUI_IMAGE_
        if [ $? -ne 0 ]; then
            log_err "failed to create open_webui container"
            exit 1
        fi
    fi
}

function open_webui_start {
    podman_start open_webui
}

function open_webui_stop {
    podman_stop open_webui
}

function open_webui_clean {
    podman_clean $_OPEN_WEBUI_IMAGE_ open_webui
}

function open_webui_run {
    open_webui_create
    open_webui_start
}

function open_webui_logs {
    podman_logs open_webui $@
}

function open_webui_exec {
    podman_exec open_webui $@
}

function open_webui_shell {
    podman_shell open_webui
}

function open_webui_is_running {
    podman_is_running open_webui
}

open_webui_create_dirs