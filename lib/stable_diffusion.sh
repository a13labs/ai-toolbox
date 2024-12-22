STABLE_DIFFUSION_WEBUI_IMAGE="localhost/stable-diffusion-webui:latest"

function stable_diffusion_webui_build {
    if ! podman image exists $STABLE_DIFFUSION_WEBUI_IMAGE; then
        echo "Building stable_diffusion_webui"
        podman build --force-rm --tag $STABLE_DIFFUSION_WEBUI_IMAGE $1
    fi
}

function stable_diffusion_webui_create_dirs {
    mkdir -p ${DATADIR}/stable_diffusion/.cache 
    mkdir -p ${DATADIR}/stable_diffusion/embeddings 
    mkdir -p ${DATADIR}/stable_diffusion/config 
    mkdir -p ${DATADIR}/stable_diffusion/models
    mkdir -p ${DATADIR}/stable_diffusion/output
}

function stable_diffusion_webui_create {
    
    if ! podman container exists stable_diffusion_webui; then
        echo "Creating stable_diffusion_webui container"
        podman container create --userns=keep-id \
                    -v ${DATADIR}/stable_diffusion:/data:U \
                    -v ${DATADIR}/stable_diffusion/output:/output:U \
                    -e CLI_ARGS="--allow-code --enable-insecure-extension-access --api" \
                    -p 0.0.0.0:7860:7860 --network stable_diffusion \
                    --device nvidia.com/gpu=all --security-opt=label=disable \
                    --name stable_diffusion_webui $STABLE_DIFFUSION_WEBUI_IMAGE
        if [ $? -ne 0 ]; then
            echo "Failed to create stable_diffusion_webui container"
            exit 1
        fi
    fi
}

function stable_diffusion_webui_start {
    echo "Starting stable_diffusion_webui container"
    podman start stable_diffusion_webui
}

function stable_diffusion_webui_stop {
    if ! podman container exists stable_diffusion_webui; then
        echo "stable_diffusion_webui container not running"
    else
        echo "Stopping stable_diffusion_webui container"
        podman stop stable_diffusion_webui
    fi
}

function stable_diffusion_webui_clean {
    if ! podman container exists stable_diffusion_webui; then
        echo "stable_diffusion_webui container not running"
    else
        echo "Removing stable_diffusion_webui container"
        podman rm stable_diffusion_webui
    fi
}

function stable_diffusion_webui_log {
    echo "Viewing logs for stable_diffusion_webui container"
    podman logs $1 stable_diffusion_webui
}
