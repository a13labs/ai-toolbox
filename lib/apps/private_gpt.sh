if [ -n "$_PRIVATE_GPT_INCLUDE_" ]; then
    return
fi

_PRIVATE_GPT_INCLUDE_=1

if [ -z "$_BOOTSTRAP_INCLUDE_" ]; then
    echo "bootstrap.sh must be included before including this file"
    exit 1
fi

_PRIVATE_GPT_REPO_=$(read_config ".apps.private_gpt.repo" "a13labs/private_gpt")
_PRIVATE_GPT_VERSION_=$(read_config ".apps.private_gpt.version" "latest")
_PRIVATE_GPT_PORT_=$(read_config ".apps.private_gpt.port" "8080")

_PRIVATE_GPT_IMAGE_=$_PRIVATE_GPT_REPO_:$_PRIVATE_GPT_VERSION_

function private_gpt_create_dirs {
    log_debug "creating private_gpt directories"
    mkdir -p ${_DATADIR_}/private_gpt/local_data
    mkdir -p ${_DATADIR_}/private_gpt/models
}

function private_gpt_build {
    podman_build $_PRIVATE_GPT_IMAGE_ $_BUILDDIR_/private_gpt $@
    if [ $? -ne 0 ]; then
        log_err "failed to build/pull private_gpt image"
        exit 1
    fi
}

function private_gpt_create {
    private_gpt_build
    if ! podman container exists private_gpt; then
        log_info "creating private_gpt container"
        podman container create --userns=keep-id --security-opt=label=disable \
                    -v ${_DATADIR_}/private_gpt/local_data:/home/worker/app/local_data:Z \
                    -v ${_DATADIR_}/private_gpt/models:/home/worker/app/models:Z \
                    -p 0.0.0.0:$_PRIVATE_GPT_PORT_:8080 \
                    --network ai_toolbox \
                    --name private_gpt $_PRIVATE_GPT_IMAGE_
        if [ $? -ne 0 ]; then
            log_err "failed to create private_gpt container"
            exit 1
        fi
    fi
}

function private_gpt_start {
    podman_start private_gpt
}

function private_gpt_stop {
    podman_stop private_gpt
}

function private_gpt_clean {
    podman_clean $_PRIVATE_GPT_IMAGE_ private_gpt
}

function private_gpt_run {
    private_gpt_create
    private_gpt_start
}

function private_gpt_logs {
    podman_logs private_gpt $@
}

function private_gpt_exec {
    podman_exec private_gpt $@
}

function private_gpt_shell {
    podman_shell private_gpt
}

function private_gpt_is_running {
    podman_is_running private_gpt
}

private_gpt_create_dirs