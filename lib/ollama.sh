if [ -z "$DATADIR" ]; then
    echo "DATADIR is not set"
    exit 1
fi

OLLAMA_IMAGE=${OLLAMA_IMAGE:-"ollama/ollama:latest"}

function ollama_create_dirs {
    mkdir -p $DATADIR/ollama
}

function ollama_create {
    if ! podman container exists ollama; then
        echo "Creating ollama container"
        podman container create -v ${DATADIR}/ollama:/root/.ollama \
                        -p 0.0.0.0:11434:11434 --network private_gpt \
                        --device nvidia.com/gpu=all --security-opt=label=disable \
                        --name ollama $OLLAMA_IMAGE
        if [ $? -ne 0 ]; then
            echo "Failed to create ollama container"
            exit 1
        fi
    fi
}

function ollama_start {
    echo "Starting ollama container"
    podman start ollama
}

function ollama_stop {
     if ! podman container exists ollama; then
        echo "ollama container not running"
    else
        echo "Stopping ollama container"
        podman stop ollama
    fi
}

function ollama_clean {
    if ! podman container exists ollama; then
        echo "ollama container not running"
    else
        echo "Removing ollama container"
        podman rm ollama
    fi
}

function ollama_pull {
    echo "Downloading model $1"
    podman exec -it ollama ollama pull $1
}

function ollama_run {
    ollama_create
    ollama_start
}

function ollama_list {
    echo "Listing models"
    podman exec -it ollama ollama list
}

function ollama_log {
    echo "Viewing logs for ollama container"
    podman logs $1 ollama
}