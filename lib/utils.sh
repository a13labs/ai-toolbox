function validate_requirements {
    if ! command -v podman &> /dev/null; then
        echo "podman is required to run this script"
        exit 1
    fi
    if ! command -v jq &> /dev/null; then
        echo "jq is required to run this script"
        exit 1
    fi
    if ! command -v nvidia-smi &> /dev/null; then
        echo "nvidia-smi is required to run this script"
        exit 1
    fi

    if [ ! -f /etc/cdi/nvidia.yaml ]; then
        echo "Generating nvidia-container-toolkit configuration"
        sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
    fi
    # Check if nvidia-container-toolkit is installed and configured
    podman run --rm --device nvidia.com/gpu=all --security-opt=label=disable ubuntu nvidia-smi > /dev/null
    if [ $? -ne 0 ]; then
        GPU_COUNT=$(podman run --rm --device nvidia.com/gpu=all --security-opt=label=disable ubuntu nvidia-smi --query-gpu=count --format=csv,noheader)
        if [ $GPU_COUNT -eq 0 ]; then
            echo "No NVidia GPUs found"
            exit 1
        fi
    fi
}

function podman_network_setup {
    if ! podman network exists $1; then
        echo "Creating $1 network"
        podman network create $1
    fi
}

function podman_network_clean {
    if ! podman network exists $1; then
        echo "$1 network not found"
    else
        echo "Removing $1 network"
        podman network rm $1
    fi
}

function podman_image_exists {
    podman image exists $1
}

function podman_container_exists {
    podman container exists $1
}

function podman_build {
    echo "Building $1"
    podman build --force-rm --tag $1 $2
}
