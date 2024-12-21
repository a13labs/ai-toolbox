#!/bin/bash

# Build ollama (CUDA) and run it with podman for a specific LLM model
# Requires podman, nvidia-container-toolkit, jq and python3

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

function setup_podman_network {
    if ! podman network exists private_gpt; then
        echo "Creating ollprivate_gptama network"
        podman network create private_gpt
    fi
}

function run_ollama {

    if ! podman container exists ollama; then
        echo "Creating ollama container"
        podman container create --name ollama -v $(pwd)/data/ollama:/root/.ollama \
                        -p 0.0.0.0:11434:11434 --network private_gpt \
                        --device nvidia.com/gpu=all --security-opt=label=disable \
                        --name ollama ollama/ollama
        if [ $? -ne 0 ]; then
            echo "Failed to create ollama container"
            exit 1
        fi
    fi

    mkdir -p data/ollama

    echo "Starting ollama container"
    podman start ollama

    if [ ! -d data/ollama/models/manifests/registry.ollama.ai/library/mistral ]; then
        echo "Downloading required mistral model"
        podman exec -it ollama ollama pull mistral
    fi

    if [ ! -d data/ollama/models/manifests/registry.ollama.ai/library/nomic-embed-text ]; then
        echo "Downloading required mistral nomic-embed-text"
        podman exec -it ollama ollama pull nomic-embed-text
    fi    
}

function run_private_gpt {

    IMAGE="localhost/private_gpt:latest"

    if ! podman image exists $IMAGE; then
        echo "Building private_gpt"
        podman build --force-rm --tag $IMAGE .
    fi

    mkdir -p data/private_gpt/local_data
    mkdir -p data/private_gpt/models
    
    if ! podman container exists private_gpt; then
        echo "Creating private_gpt container"
        podman container create --name private_gpt \
                    -v $(pwd)/data/private_gpt/local_data:/app/local_data \
                    -v $(pwd)/data/private_gpt/models:/app/models \
                    -p 0.0.0.0:8080:8080 --network private_gpt \
                    --security-opt=label=disable --name private_gpt $IMAGE
        if [ $? -ne 0 ]; then
            echo "Failed to create private_gpt container"
            exit 1
        fi
    fi

    echo "Starting private_gpt container"
    podman start private_gpt
}

function start_action {
    setup_podman_network
    run_ollama
    run_private_gpt
}

function stop_action {
    if ! podman container exists ollama; then
        echo "ollama container not running"
    else
        echo "Stopping ollama container"
        podman stop ollama
    fi

    if ! podman container exists private_gpt; then
        echo "private_gpt container not running"
    else
        echo "Stopping private_gpt container"
        podman stop private_gpt
    fi
}

function clean_action {
    if ! podman container exists ollama; then
        echo "ollama container not running"
    else
        echo "Removing ollama container"
        podman rm ollama
    fi

    if ! podman container exists private_gpt; then
        echo "private_gpt container not running"
    else
        echo "Removing private_gpt container"
        podman rm private_gpt
    fi

    if ! podman network exists private_gpt; then
        echo "private_gpt network not found"
    else
        echo "Removing private_gpt network"
        podman network rm private_gpt
    fi
}

ACTION=$1

if [ -z $ACTION ]; then
    echo "Usage: $0 [start|stop|clean]"
    exit 1
fi

validate_requirements

case $ACTION in
    start)
        start_action
        ;;
    stop)
        stop_action
        ;;
    clean)
        stop_action
        clean_action
        ;;
    *)
        echo "Usage: $0 [start|stop|clean]"
        exit 1
        ;;
esac

exit 0