if [ -n "$_FTP_SERVER_INCLUDE_" ]; then
    return
fi

_FTP_SERVER_INCLUDE_=1

if [ -z "$_BOOTSTRAP_INCLUDE_" ]; then
    echo "bootstrap.sh must be included before including this file"
    exit 1
fi

_FTP_SERVER_REPO_=$(read_config ".apps.ftp_server.repo" "a13labs/ftp_server")
_FTP_SERVER_VERSION_=$(read_config ".apps.ftp_server.version" "latest")
_FTP_USER_=$(read_config ".apps.ftp_server.user" "ftp_user")
_FTP_PASS_=$(read_config ".apps.ftp_server.pass" "ftp_pass")
_FTP_PORT_=$(read_config ".apps.ftp_server.port" "20021")
_FTP_PASV_PORTS_=($(read_config ".apps.ftp_server.pasv_ports" "30091-30100"))

_FTP_SERVER_IMAGE_=$_FTP_SERVER_REPO_:$_FTP_SERVER_VERSION_

function ftp_server_build {
    podman_build $_FTP_SERVER_IMAGE_ $_BUILDDIR_/ftp_server
    podman_build $_FTP_SERVER_IMAGE_ $_BUILDDIR_/ftp_server
    if [ $? -ne 0 ]; then
        log_err "failed to build/pull ftp server image"
        exit 1
    fi
}

function ftp_server_create {
    local target_folder=$1
    local ip_address=$(hostname -I | cut -d' ' -f1)
    if [ -z "$target_folder" ]; then
        log_err "target folder for ftp server not provided"
        exit 1
    fi
    ftp_server_build
    if ! podman container exists ftp_server; then
        log_info "creating ftp server container"
        podman container create --userns=keep-id --security-opt=label=disable \
                    -v $target_folder:/var/lib/ftp:Z \
                    -e PASV_ADDRESS=$ip_address \
                    -e FTP_USER=$_FTP_USER_ -e FTP_PASS=$_FTP_PASS_ \
                    --network ai_toolbox \
                    -p $_FTP_PORT_:21 \
                    -p $_FTP_PASV_PORTS_:30091-30100 \
                    ---name ftp_server $_FTP_SERVER_IMAGE_
        if [ $? -ne 0 ]; then
            log_err "failed to create ftp server container"
            exit 1
        fi
    fi
}

function ftp_server_start {
    podman_start ftp_server
}

function ftp_server_stop {
    podman_stop ftp_server
}

function ftp_server_clean {
    podman_clean $_FTP_SERVER_IMAGE_ ftp_server 
}

function ftp_server_run {
    local target_folder=$1
    ftp_server_create $target_folder
    ftp_server_start
}

function ftp_server_logs {
    podman_logs ftp_server $@
}

function ftp_server_exec {
    podman_exec ftp_server $@
}

function ftp_server_shell {
    podman_shell ftp_server
}

function ftp_server_is_running {
    podman_is_running ftp_server
}