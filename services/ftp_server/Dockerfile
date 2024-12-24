FROM alpine:3.20

ARG PROFTPD_VERSION=1.3.8c-r0

ENV ALLOW_OVERWRITE=on \
    ANONYMOUS_DISABLE=off \
    ANON_UPLOAD_ENABLE=DenyAll \
    FTP_UID=1000 \
    FTP_GID=1000 \
    LOCAL_UMASK=022 \
    MAX_CLIENTS=10 \
    MAX_INSTANCES=30 \
    PASV_ADDRESS= \
    PASV_MAX_PORT=30100 \
    PASV_MIN_PORT=30091 \
    SFTP_ENABLE=off \
    SFTP_PORT=2222 \
    SERVER_NAME=ProFTPD \
    TIMES_GMT=off \
    TZ=UTC \
    WRITE_ENABLE=AllowAll \
    FTP_USER=ftp_user \
    FTP_PASS=ftp_user

COPY proftpd.conf.j2 /etc/proftpd/proftpd.conf
COPY generate_user.py /usr/local/bin/
COPY entrypoint.sh /usr/local/bin/
RUN chmod 644 /etc/proftpd/proftpd.conf && \
    chmod +x /usr/local/bin/generate_user.py && \
    chmod +x /usr/local/bin/entrypoint.sh && \
    apk add --update \
    libcrypto3 \
    proftpd=$PROFTPD_VERSION \
    tzdata \
    proftpd-mod_sftp \
    openssh-keygen 

VOLUME /etc/proftpd/conf.d /etc/proftpd/modules.d /var/lib/ftp /etc/ssh
EXPOSE 21 $SFTP_PORT $PASV_MIN_PORT-$PASV_MAX_PORT

ENV USER_NAME=$FTP_USER
ENV USER_ROOT=/var/lib/ftp/$FTP_USER
USER root
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
