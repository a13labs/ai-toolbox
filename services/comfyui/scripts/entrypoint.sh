#!/bin/bash

set -e

echo "########################################"
echo "[INFO] Starting ComfyUI..."
echo "########################################"

export PATH="${PATH}:/home/worker/.local/bin"
export PYTHONPYCACHEPREFIX="/home/worker/.cache/pycache"

cd /home/worker

exec /usr/bin/env python3 ./ComfyUI/main.py --listen --port 8188 ${CLI_ARGS}
