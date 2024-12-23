if [ -z "$SCRIPTDIR" ]; then
    SCRIPTDIR=$(realpath $(dirname $0))
fi

DATADIR=${OLLAMA_DATA_DIR:-$(realpath $SCRIPTDIR/../data)}
BUILDDIR=$(realpath $SCRIPTDIR/../services)
