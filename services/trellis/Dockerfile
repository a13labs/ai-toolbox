# Use CUDA base image
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}
# Set CUDA architecture flags
ENV TORCH_CUDA_ARCH_LIST="7.0;7.5;8.0;8.6+PTX"
ENV FORCE_CUDA=1

# Install system dependencies
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y \
    python3.10 \
    python3.10-dev \
    python3-pip \
    wget \
    git \
    ninja-build \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.10 as default
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1 && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1

ARG UID=1000
ARG GID=1000
RUN groupadd --system --gid ${GID} worker && \
    adduser --system --gid ${GID} --uid ${UID} --home /home/worker worker

WORKDIR /home/worker
USER worker

# Install PyTorch
RUN pip install torch==2.4.0 torchvision==0.19.0 --index-url https://download.pytorch.org/whl/cu118 && \
    rm -rf /home/worker/.cache/pip

# Install basic dependencies
RUN pip install pillow imageio imageio-ffmpeg tqdm easydict opencv-python-headless \
    scipy ninja rembg onnxruntime trimesh xatlas pyvista pymeshfix igraph transformers plyfile && \
    rm -rf /home/worker/.cache/pip

# Install xformers
RUN pip install xformers==0.0.27.post2 --index-url https://download.pytorch.org/whl/cu118 && \
    rm -rf /home/worker/.cache/pip

# Install flash-attention
RUN pip install flash-attn && \
    rm -rf /home/worker/.cache/pip

# Install kaolin
RUN pip install kaolin -f https://nvidia-kaolin.s3.us-east-2.amazonaws.com/torch-2.4.0_cu121.html && \
    rm -rf /home/worker/.cache/pip

# Install nvdiffrast
RUN mkdir -p /tmp/extensions && \
    git clone https://github.com/NVlabs/nvdiffrast.git /tmp/extensions/nvdiffrast && \
    pip install /tmp/extensions/nvdiffrast && \
    rm -rf /tmp/extensions && \
    rm -rf /home/worker/.cache/pip

# Install diffoctreerast
RUN mkdir -p /tmp/extensions && \
    git clone --recurse-submodules https://github.com/JeffreyXiang/diffoctreerast.git /tmp/extensions/diffoctreerast && \
    pip install /tmp/extensions/diffoctreerast && \
    rm -rf /tmp/extensions && \
    rm -rf /home/worker/.cache/pip

# Install mip-splatting
RUN mkdir -p /tmp/extensions && \
    git clone https://github.com/autonomousvision/mip-splatting.git /tmp/extensions/mip-splatting && \
    pip install /tmp/extensions/mip-splatting/submodules/diff-gaussian-rasterization/ && \
    rm -rf /tmp/extensions && \
    rm -rf /home/worker/.cache/pip

# Install spconv
RUN pip install spconv-cu118 && \
    rm -rf /home/worker/.cache/pip

# Install demo dependencies
RUN pip install gradio==4.44.1 gradio_litmodel3d==0.0.1 && \
    rm -rf /home/worker/.cache/pip

# Install TRELLIS and utils3d (Ugly hack to get the right version)
RUN git clone --recurse-submodules https://github.com/0lento/TRELLIS.git /tmp/trellis && \
    mv /tmp/trellis/* /home/worker/ && \
    mv /tmp/trellis/.[!.]* /home/worker/ && \
    git clone https://github.com/EasternJournalist/utils3d.git /tmp/utils3d &&  \
    cd /tmp/utils3d && \
    git checkout 9a4eb15e4021b67b12c460c7057d642626897ec8 && \
    cd /home/worker && \
    mv /tmp/utils3d/utils3d /home/worker/ && \
    rm -rf /tmp/trellis && \
    rm -rf /tmp/utils3d 

EXPOSE 7860
ENV GRADIO_SERVER_NAME="0.0.0.0"
ENTRYPOINT [ "python3", "app.py" ]
