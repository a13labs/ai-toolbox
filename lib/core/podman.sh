if [ -n "$_PODMAN_INCLUDE_" ]; then
    return
fi

_PODMAN_INCLUDE_=1

if [ -z "$_BOOTSTRAP_INCLUDE_" ]; then
    echo "bootstrap.sh must be included before including this file"
    exit 1
fi

function podman_network_setup {
    if ! podman network exists $1; then
        echo "Creating $1 network"
        podman network create $1 > /dev/null
    fi
}

function podman_network_clean {
    if ! podman network exists $1; then
        echo "$1 network not found"
    else
        echo "Removing $1 network"
        podman network rm $1 > /dev/null
    fi
}

function podman_image_exists {
    podman image exists $1 > /dev/null
}

function podman_container_exists {
    podman container exists $1 > /dev/null
}

function podman_build {
    local image=$1
    local path=$2
    if [ -z "$image" ]; then
        log_debug "image name not provided"
        exit 1
    fi
    if [ -z "$path" ]; then
        log_debug "path not provided"
        exit 1
    fi
    if ! [ -f $path/Dockerfile ]; then
        log_debug "dockerfile not found in $path"
        exit 1
    fi
    shift 2
    case $1 in
        --pull)
            log_info "Pulling $image"
            podman pull $image
            ;;
        --no-cache)
            log_info "Building $image without cache"
            podman build --no-cache --tag $image $path
            ;;
        --ignore-existing)
            log_info "Ignoring existing $image"
            podman build --force-rm --tag $image $path
            ;;
        --force)
            log_info "Forcing rebuild of $image"
            podman rmi $image
            podman build --force-rm --tag $image $path
            ;;
        *)
            if podman_image_exists $image; then
                log_debug "$image already exists"
                return
            fi
            log_info "Building $image"
            podman build --force-rm --tag $image $path
            ;;
    esac
}

function podman_clean {
    local image=$1
    local container=$2
    if [ -n "$container" ]; then
        if ! podman container exists $container; then
            log_info "$container container not running"
        else
            log_info "removing $container container"
            podman rm $container
            if [ $? -ne 0 ]; then
                log_err "failed to remove $container container"
            fi
        fi
    fi
    if [ -z "$image" ]; then
        log_info "image name not provided"
    else
        if ! podman image exists $image; then
            log_info "$image image not found"
        else
            log_info "removing $image image"
            podman rmi $image
            if [ $? -ne 0 ]; then
                log_err "failed to remove $image image"
            fi
        fi
    fi
}

function podman_stop {
    local container=$1
    if ! podman container exists $container; then
        log_info "$container container not running"
    else
        log_info "stopping $container container"
        podman stop $container > /dev/null
    fi
}

function podman_start {
    local container=$1
    log_info "starting $container container"
    podman start $container > /dev/null
}

function podman_exec {
    local container=$1
    shift
    if ! podman container exists $container; then
        log_err "$container container not running"
        exit 1
    fi
    log_debug "executing in $container container, command: $@"
    podman exec -it $container $@
}

function podman_logs {
    local container=$1
    local follow=$2
    if ! podman container exists $container; then
        log_err "$container container not running"
        exit 1
    fi
    if [ -n "$follow" ] && [ "$follow" == "-f" ]; then
        podman logs -f $container
    else
        podman logs $container
    fi
}

function podman_shell {
    local container=$1
    local shell=${2:-/bin/bash}
    if ! podman container exists $container; then
        log_err "$container container not running"
        exit 1
    fi
    log_debug "executing shell in $container container"
    podman exec -it $container $shell
}

function podman_is_running {
    local container=$1
    if podman container exists $container; then
        local status=$(podman inspect --format '{{.State.Status}}' $container)
        if [ "$status" == "running" ]; then
            return 0
        fi
    fi

    return 1
}