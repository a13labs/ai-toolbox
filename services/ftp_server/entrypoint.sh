#!/bin/sh -e

if [ ! -f /etc/timezone ] && [ ! -z "$TZ" ]; then
  # At first startup, set timezone
  cp /usr/share/zoneinfo/$TZ /etc/localtime
  echo $TZ >/etc/timezone
fi

if [ -z "$PASV_ADDRESS" ]; then
  echo "** This container will not run without setting for PASV_ADDRESS **"
  sleep 10
  exit 1
fi

if [ "$SFTP_ENABLE" = "on" ]; then
  mkdir -p /etc/ssh
  test -f /etc/ssh/ssh_host_rsa_key   || ssh-keygen -m PEM -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa -b 2048
  test -f /etc/ssh/ssh_host_dsa_key   || ssh-keygen -m PEM -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa -b 1024
  test -f /etc/ssh/ssh_host_ecdsa_key || ssh-keygen -m PEM -f /etc/ssh/ssh_host_ecdsa_key -N '' -t ecdsa -b 521

  sed -i -e "/^Port/s/^/#/" /etc/proftpd/proftpd.conf
  
  sed -i \
      -e "s/^#\(  SFTPEngine on\)/\1/" \
      -e "s/^#\(  Port 2222.*\)/  Port $SFTP_PORT/" \
      -e "s/^#\(  SFTPCompression delayed\)/\1/" \
      -e "s/^#\(  SFTPHostKey\)/\1/" \
      /etc/proftpd/conf.d/sftp.conf
fi

if [ "$ANONYMOUS_DISABLE" = "on" ]; then
  sed -i '/<Anonymous/,/<\/Anonymous>/d' /etc/proftpd/proftpd.conf
else
  sed -i \
      -e "s:{{ ANONYMOUS_DISABLE }}:$ANONYMOUS_DISABLE:" \
      -e "s:{{ ANON_UPLOAD_ENABLE }}:$ANON_UPLOAD_ENABLE:" \
      /etc/proftpd/proftpd.conf
fi

mkdir -p /run/proftpd && chown proftpd /run/proftpd/

sed -i \
    -e "s:{{ ALLOW_OVERWRITE }}:$ALLOW_OVERWRITE:" \
    -e "s:{{ LOCAL_UMASK }}:$LOCAL_UMASK:" \
    -e "s:{{ MAX_CLIENTS }}:$MAX_CLIENTS:" \
    -e "s:{{ MAX_INSTANCES }}:$MAX_INSTANCES:" \
    -e "s:{{ PASV_ADDRESS }}:$PASV_ADDRESS:" \
    -e "s:{{ PASV_MAX_PORT }}:$PASV_MAX_PORT:" \
    -e "s:{{ PASV_MIN_PORT }}:$PASV_MIN_PORT:" \
    -e "s+{{ SERVER_NAME }}+$SERVER_NAME+" \
    -e "s:{{ TIMES_GMT }}:$TIMES_GMT:" \
    -e "s:{{ WRITE_ENABLE }}:$WRITE_ENABLE:" \
    -e "s:{{ USER_NAME }}:$USER_NAME:" \
    -e "s:{{ USER_ROOT }}:$USER_ROOT:" \
    /etc/proftpd/proftpd.conf

# Add default user
addgroup -g $FTP_GID -S $FTP_USER
adduser -h /var/lib/ftp -G $FTP_USER -D -H -u $FTP_UID $FTP_USER 
echo "$FTP_USER:$FTP_PASS" | chpasswd

exec proftpd --nodaemon -c /etc/proftpd/proftpd.conf