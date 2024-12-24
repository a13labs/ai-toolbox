if [ -n "$_BOOTSTRAP_INCLUDE_" ]; then
    return
fi

_BOOTSTRAP_INCLUDE_=1

if [ -f $HOME/.ai_toolboxrc ]; then
    source $HOME/.ai_toolboxrc
fi

_SCRIPTDIR_=$(realpath $(dirname $0))
_LIBDIR_=$(realpath $_SCRIPTDIR_/../lib)
_BUILDDIR_=$(realpath $_SCRIPTDIR_/../services)
_BINDIR_=$(realpath $_SCRIPTDIR_/../bin)

shopt -s expand_aliases

function include {
    local file=$1
    source $_LIBDIR_/$file
}

include core/config.sh
include core/utils.sh
include core/podman.sh
include core/log.sh

_DATADIR_=$(read_config ".data_dir" "$HOME/.ai_toolbox/cache")

log_debug "_DATADIR_: $_DATADIR_"
log_debug "_BUILDDIR_: $_BUILDDIR_"
log_debug "_LIBDIR_: $_LIBDIR_"

podman_network_setup ai_toolbox
validate_requirements
