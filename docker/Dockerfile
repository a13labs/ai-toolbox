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
WORKDIR /home/worker/app
RUN git clone --depth 1 https://github.com/a13labs/private-gpt .

ARG POETRY_EXTRAS="ui llms-ollama embeddings-ollama vector-stores-qdrant"
RUN poetry install --no-root --extras "${POETRY_EXTRAS}"
FROM base as app

ENV PYTHONUNBUFFERED=1
ENV PORT=8080
EXPOSE 8080

# Prepare a non-root user
# More info about how to configure UIDs and GIDs in Docker:
# https://github.com/systemd/systemd/blob/main/docs/UIDS-GIDS.md

# Define the User ID (UID) for the non-root user
# UID 100 is chosen to avoid conflicts with existing system users
ARG UID=1000

# Define the Group ID (GID) for the non-root user
# GID 65534 is often used for the 'nogroup' or 'nobody' group
ARG GID=1000

RUN groupadd --system --gid ${GID} worker
RUN adduser --system --gid ${GID} --uid ${UID} --home /home/worker worker
WORKDIR /home/worker/app

RUN chown worker /home/worker/app
RUN mkdir local_data && chown worker local_data
RUN mkdir models && chown worker models
COPY --from=dependencies /home/worker/app/.venv/ .venv
COPY --from=dependencies /home/worker/app/private_gpt/ private_gpt
COPY --from=dependencies /home/worker/app/fern/ fern
COPY --from=dependencies /home/worker/app/*.yaml /home/worker/app/*.md ./
COPY --from=dependencies /home/worker/app/scripts/ scripts
COPY settings-ollama.yaml /home/worker/app/settings-ollama.yaml

ENV PYTHONPATH="$PYTHONPATH:/home/worker/app/private_gpt/"
ENV PGPT_PROFILES=ollama 

ENTRYPOINT python -m private_gpt

