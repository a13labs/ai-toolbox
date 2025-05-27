FROM bash:alpine3.19

RUN apk update && apk add parallel aria2 wget curl jq
COPY entrypoint.sh /usr/bin/entrypoint.sh
COPY hfd /usr/bin/hfd
RUN chmod +x /usr/bin/entrypoint.sh /usr/bin/hfd

# Prepare a non-root user
# More info about how to configure UIDs and GIDs in Docker:
# https://github.com/systemd/systemd/blob/main/docs/UIDS-GIDS.md

# Define the User ID (UID) for the non-root user
# UID 100 is chosen to avoid conflicts with existing system users
ARG UID=1000

# Define the Group ID (GID) for the non-root user
# GID 65534 is often used for the 'nogroup' or 'nobody' group
ARG GID=1000

RUN addgroup -S worker -g ${GID} && adduser -S worker -G worker -u ${UID} -h /home/worker
USER worker
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
