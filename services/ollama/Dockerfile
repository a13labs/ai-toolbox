FROM ollama/ollama:0.5.4

ARG UID=1000
ARG GID=1000
RUN groupadd --system --gid ${GID} worker && \
    adduser --system --gid ${GID} --uid ${UID} --home /home/worker worker

WORKDIR /home/worker
USER worker
ENTRYPOINT ["/bin/ollama"]
CMD ["serve"]