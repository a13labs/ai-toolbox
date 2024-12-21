PRIVATE_GPT_IMAGE="localhost/private_gpt:latest"

function private_gpt_build {
    echo "Building private_gpt"
    podman build --force-rm --tag $PRIVATE_GPT_IMAGE $DOCKERDIR
}

function private_gpt_create {
    mkdir -p ${DATADIR}/private_gpt/local_data
    mkdir -p ${DATADIR}/private_gpt/models
    
    if ! podman container exists private_gpt; then
        echo "Creating private_gpt container"
        podman container create --name private_gpt \
                    -v ${DATADIR}/private_gpt/local_data:/home/worker/app/local_data \
                    -v ${DATADIR}/private_gpt/models:/home/worker/app/models \
                    -p 0.0.0.0:8080:8080 --network private_gpt \
                    --security-opt=label=disable --name private_gpt $PRIVATE_GPT_IMAGE
        if [ $? -ne 0 ]; then
            echo "Failed to create private_gpt container"
            exit 1
        fi
    fi
}

function private_gpt_create_console {
    mkdir -p ${DATADIR}/private_gpt/local_data
    mkdir -p ${DATADIR}/private_gpt/models
    
    if ! podman container exists private_gpt; then
        echo "Creating private_gpt container"
        podman container create --name private_gpt \
                    -v ${DATADIR}/private_gpt/local_data:/home/worker/app/local_data \
                    -v ${DATADIR}/private_gpt/models:/home/worker/app/models \
                    -p 0.0.0.0:8080:8080 --network private_gpt \
                    -it --entrypoint /bin/bash \
                    --security-opt=label=disable --name private_gpt $PRIVATE_GPT_IMAGE
        if [ $? -ne 0 ]; then
            echo "Failed to create private_gpt container"
            exit 1
        fi
    fi
}

function private_gpt_start {
    echo "Starting private_gpt container"
    podman start private_gpt
}

function private_gpt_stop {
    if ! podman container exists private_gpt; then
        echo "private_gpt container not running"
    else
        echo "Stopping private_gpt container"
        podman stop private_gpt
    fi
}

function private_gpt_console {
    if podman container exists private_gpt; then
        private_gpt_stop
        private_gpt_clean
    fi
    private_gpt_create_console
    podman start private_gpt
    podman exec -it private_gpt /bin/bash
    private_gpt_stop
    private_gpt_clean
}

function private_gpt_clean {
    if ! podman container exists private_gpt; then
        echo "private_gpt container not running"
    else
        echo "Removing private_gpt container"
        podman rm private_gpt
    fi
}

function private_gpt_run {

    if ! podman image exists $PRIVATE_GPT_IMAGE; then
        private_gpt_build
    fi
    
    private_gpt_create
    private_gpt_start
}