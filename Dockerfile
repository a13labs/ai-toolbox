### IMPORTANT, THIS IMAGE CAN ONLY BE RUN IN LINUX DOCKER
### You will run into a segfault in mac
FROM python:3.11.6-slim-bookworm as base

# Install poetry
RUN pip install pipx
RUN python3 -m pipx ensurepath
RUN pipx install poetry
ENV PATH="/root/.local/bin:$PATH"
ENV PATH=".venv/bin/:$PATH"

# Dependencies to build llama-cpp
RUN apt update && apt install -y \
    libopenblas-dev\
    ninja-build\
    build-essential\
    pkg-config\
    wget git

# https://python-poetry.org/docs/configuration/#virtualenvsin-project
ENV POETRY_VIRTUALENVS_IN_PROJECT=true

FROM base as dependencies
WORKDIR /app
RUN git clone --depth 1 https://github.com/zylon-ai/private-gpt.git .

RUN poetry install --extras "ui llms-ollama embeddings-ollama vector-stores-qdrant"

FROM base as app

ENV PYTHONUNBUFFERED=1
ENV PORT=8080
EXPOSE 8080

# Prepare a non-root user
WORKDIR /app

RUN mkdir local_data && mkdir models
COPY --from=dependencies /app/.venv/ .venv
COPY --from=dependencies /app/private_gpt/ private_gpt
COPY --from=dependencies /app/fern/ fern
COPY --from=dependencies /app/*.yaml /app/*.md ./
COPY --from=dependencies /app/scripts/ scripts
COPY settings-ollama.yaml /app/settings-ollama.yaml

ENV PYTHONPATH="$PYTHONPATH:/app/private_gpt/"
ENV PGPT_PROFILES=ollama 

ENTRYPOINT python -m private_gpt