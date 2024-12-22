COMFY_IMAGE="localhost/comfy:latest"

function comfy_build {
    echo "Building comfy"
    podman build --force-rm --tag $COMFY_IMAGE $DOCKERDIR
}

function comfy_create {
    mkdir -p ${DATADIR}/comfy/local_data
    mkdir -p ${DATADIR}/comfy/models
    
    if ! podman container exists comfy; then
        echo "Creating comfy container"
        podman container create --name comfy \
                    -v ${DATADIR}/comfy/data:/data \
                    -v ${DATADIR}/comfy/output:/output \
                    -e CLI_ARGS="" \
                    -p 0.0.0.0:7860:7860 --network stable_diffusion \
                    --device nvidia.com/gpu=all --security-opt=label=disable \
                    -name comfy $COMFY_IMAGE
        if [ $? -ne 0 ]; then
            echo "Failed to create comfy container"
            exit 1
        fi
    fi
}

function comfy_start {
    echo "Starting comfy container"
    podman start comfy
}

function comfy_stop {
    if ! podman container exists comfy; then
        echo "comfy container not running"
    else
        echo "Stopping comfy container"
        podman stop comfy
    fi
}

function comfy_clean {
    if ! podman container exists comfy; then
        echo "comfy container not running"
    else
        echo "Removing comfy container"
        podman rm comfy
    fi
}

function comfy_run {

    if ! podman image exists $COMFY_IMAGE; then
        comfy_build
    fi
    
    comfy_create
    comfy_start
}