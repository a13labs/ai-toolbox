FROM opensuse/tumbleweed:latest

# Note: GCC for InsightFace;
#       FFmpeg for video (pip[imageio-ffmpeg] will use system FFmpeg instead of bundled).
# Note: CMake may use different version of Python. Using 'update-alternatives' to ensure default version.
RUN --mount=type=cache,target=/var/cache/zypp \
    set -eu \
    && zypper addrepo --check --refresh --priority 90 \
    'https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/Essentials/' packman-essentials \
    && zypper --gpg-auto-import-keys \
    install --no-confirm \
    python311 python311-pip python311-wheel python311-setuptools \
    python311-devel python311-Cython gcc-c++ python311-py-build-cmake \
    python311-numpy1 python311-opencv \
    python311-ffmpeg-python ffmpeg x264 x265 \
    python311-dbm \
    google-noto-sans-fonts google-noto-sans-cjk-fonts google-noto-coloremoji-fonts \
    shadow git aria2 \
    Mesa-libGL1 libgthread-2_0-0 \
    && rm /usr/lib64/python3.11/EXTERNALLY-MANAGED \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 100

# Fix for libs (.so files)
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}\
    :/usr/local/lib64/python3.11/site-packages/torch/lib\
    :/usr/local/lib/python3.11/site-packages/nvidia/cuda_cupti/lib\
    :/usr/local/lib/python3.11/site-packages/nvidia/cuda_runtime/lib\
    :/usr/local/lib/python3.11/site-packages/nvidia/cudnn/lib\
    :/usr/local/lib/python3.11/site-packages/nvidia/cufft/lib"

# More libs (not necessary, just in case)
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}\
    :/usr/local/lib/python3.11/site-packages/nvidia/cublas/lib\
    :/usr/local/lib/python3.11/site-packages/nvidia/cuda_nvrtc/lib\
    :/usr/local/lib/python3.11/site-packages/nvidia/curand/lib\
    :/usr/local/lib/python3.11/site-packages/nvidia/cusolver/lib\
    :/usr/local/lib/python3.11/site-packages/nvidia/cusparse/lib\
    :/usr/local/lib/python3.11/site-packages/nvidia/nccl/lib\
    :/usr/local/lib/python3.11/site-packages/nvidia/nvjitlink/lib\
    :/usr/local/lib/python3.11/site-packages/nvidia/nvtx/lib"

# Define the User ID (UID) for the non-root user
# UID 100 is chosen to avoid conflicts with existing system users
ARG UID=1000

# Define the Group ID (GID) for the non-root user
# GID 65534 is often used for the 'nogroup' or 'nobody' group
ARG GID=1000

# Create a low-privilege user
RUN printf 'CREATE_MAIL_SPOOL=no' >> /etc/default/useradd \
    && mkdir -p /home/worker /home/scripts \
    && groupadd --gid ${GID} worker \
    && useradd --uid ${UID} --gid ${GID} -d /home/worker worker \
    && chown worker:worker /home/worker /home/scripts


USER worker:worker
WORKDIR /home/worker

RUN pip install --upgrade pip wheel setuptools  && \
    rm -rf /home/worker/.cache/pip

# Install xFormers (stable version, will specify PyTorch version),
# and Torchvision + Torchaudio (will downgrade to match xFormers' PyTorch version).
# Break down the steps, so we have more but smaller image layers.

ARG PIP_INDEX_URL="https://download.pytorch.org/whl/cu121"
ARG PIP_EXTRA_INDEX_URL="https://pypi.org/simple"

RUN pip install xformers torch torchvision torchaudio && \
    rm -rf /home/worker/.cache/pip

ARG PIP_INDEX_URL=
ARG PIP_EXTRA_INDEX_URL=

# Dependencies for frequently-used
# (Do this firstly so PIP won't be solving too many deps at one time)
RUN pip install \
    -r https://raw.githubusercontent.com/comfyanonymous/ComfyUI/master/requirements.txt \
    -r https://raw.githubusercontent.com/crystian/ComfyUI-Crystools/main/requirements.txt \
    -r https://raw.githubusercontent.com/cubiq/ComfyUI_essentials/main/requirements.txt \
    -r https://raw.githubusercontent.com/Fannovel16/comfyui_controlnet_aux/main/requirements.txt \
    -r https://raw.githubusercontent.com/jags111/efficiency-nodes-comfyui/main/requirements.txt \
    -r https://raw.githubusercontent.com/ltdrdata/ComfyUI-Impact-Pack/Main/requirements.txt \
    -r https://raw.githubusercontent.com/ltdrdata/ComfyUI-Impact-Subpack/main/requirements.txt \
    -r https://raw.githubusercontent.com/ltdrdata/ComfyUI-Inspire-Pack/main/requirements.txt \
    -r https://raw.githubusercontent.com/ltdrdata/ComfyUI-Manager/main/requirements.txt && \
    rm -rf /home/worker/.cache/pip

RUN pip install \
    -r https://raw.githubusercontent.com/cubiq/ComfyUI_FaceAnalysis/main/requirements.txt \
    -r https://raw.githubusercontent.com/cubiq/ComfyUI_InstantID/main/requirements.txt \
    -r https://raw.githubusercontent.com/Fannovel16/ComfyUI-Frame-Interpolation/main/requirements-no-cupy.txt \
    cupy-cuda12x \
    -r https://raw.githubusercontent.com/FizzleDorf/ComfyUI_FizzNodes/main/requirements.txt \
    -r https://raw.githubusercontent.com/kijai/ComfyUI-KJNodes/main/requirements.txt \
    -r https://raw.githubusercontent.com/melMass/comfy_mtb/main/requirements.txt \
    -r https://raw.githubusercontent.com/MrForExample/ComfyUI-3D-Pack/main/requirements.txt \
    -r https://raw.githubusercontent.com/storyicon/comfyui_segment_anything/main/requirements.txt \
    -r https://raw.githubusercontent.com/ZHO-ZHO-ZHO/ComfyUI-InstantID/main/requirements.txt \
    compel lark torchdiffeq fairscale \
    python-ffmpeg  && \
    rm -rf /home/worker/.cache/pip

ARG COMFYUI_VERSION="v0.3.10"
RUN git clone https://github.com/comfyanonymous/ComfyUI.git && \
    cd ComfyUI && \
    git reset --hard ${COMFYUI_VERSION} 

COPY --chown=worker:worker scripts/. /home/scripts/

EXPOSE 8188
ENV CLI_ARGS=""
CMD ["bash","/home/scripts/entrypoint.sh"]
