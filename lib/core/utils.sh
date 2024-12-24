if [ -n "$_UTILS_INCLUDE_" ]; then
    return
fi

_UTILS_INCLUDE_=1

if [ -z "$_BOOTSTRAP_INCLUDE_" ]; then
    echo "bootstrap.sh must be included before including this file"
    exit 1
fi

function validate_requirements {
    if ! command -v podman &> /dev/null; then
        log_err "podman is required to run"
        exit 1
    fi
    if ! command -v jq &> /dev/null; then
        log_err "jq is required to run"
        exit 1
    fi
    if ! command -v nvidia-smi &> /dev/null; then
        log_err "nvidia-smi is required to run"
        exit 1
    fi

    if [ ! -f /etc/cdi/nvidia.yaml ]; then
        log_info "generating nvidia-container-toolkit configuration"
        sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
    fi
    log_debug "nvidia-container-toolkit configuration: %s" $(cat /etc/cdi/nvidia.yaml)

    # Check if nvidia-container-toolkit is installed and configured
    podman run --rm --device nvidia.com/gpu=all --security-opt=label=disable ubuntu nvidia-smi > /dev/null
    if [ $? -ne 0 ]; then
        GPU_COUNT=$(podman run --rm --device nvidia.com/gpu=all --security-opt=label=disable ubuntu nvidia-smi --query-gpu=count --format=csv,noheader | tail -n 1)
        log_debug "GPU_COUNT: %s" $GPU_COUNT
        if [ $GPU_COUNT -eq 0 ]; then
            log_err "no NVIDIA GPUs found, please check your configuration."
            exit 1
        fi
    fi
}
