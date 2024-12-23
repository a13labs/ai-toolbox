if [ -z "$DATADIR" ] || [ -z "$BUILDDIR" ]; then
    echo "DATADIR or BUILDDIR must be set"
    exit 1
fi

FTP_SERVER_IMAGE=${FTP_SERVER_IMAGE:-"localhost/ftp_server:latest"}
FTP_USER=${FTP_USER:-"ftp_user"}
FTP_PASS=${FTP_PASS:-"ftp_user"}

function ftp_server_build {
    if ! podman image exists $FTP_SERVER_IMAGE; then
        echo "Building ftp_server"
        podman build --force-rm --build-arg FTP_USER=$FTP_USER --build-arg FTP_PASS=$FTP_PASS --tag $FTP_SERVER_IMAGE $BUILDDIR/ftp_server
    fi
}

function ftp_server_create {
    TARGET_FOLDER=$1
    if [ -z "$TARGET_FOLDER" ]; then
        echo "TARGET_FOLDER must be set"
        exit 1
    fi
    IP_ADDRESS=$(hostname -I | cut -d' ' -f1)
    if ! podman container exists ftp_server; then
        echo "Creating ftp_server container"
        podman container create --userns=keep-id -v $TARGET_FOLDER:/var/lib/ftp:Z \
                    -e PASV_ADDRESS=$IP_ADDRESS \
                    -p 20021:21 -p 30091-30100:30091-30100 \
                    --security-opt=label=disable --name ftp_server $FTP_SERVER_IMAGE
        if [ $? -ne 0 ]; then
            echo "Failed to create ftp_server container"
            exit 1
        fi
    fi
}

function ftp_server_start {
    echo "Starting ftp_server container"
    podman start ftp_server
}

function ftp_server_stop {
    if ! podman container exists ftp_server; then
        echo "ftp_server container not running"
    else
        echo "Stopping ftp_server container"
        podman stop ftp_server
    fi
}

function ftp_server_clean {
    if ! podman container exists ftp_server; then
        echo "ftp_server container not running"
    else
        echo "Removing ftp_server container"
        podman rm ftp_server
    fi
}
