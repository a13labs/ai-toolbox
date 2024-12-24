if [ -n "$_LOG_INCLUDE_" ]; then
    return
fi

_LOG_INCLUDE_=1

# Color codes
COLOR_INFO="\033[1;34m"  # Blue
COLOR_WARN="\033[1;33m"  # Yellow
COLOR_ERR="\033[1;31m"   # Red
COLOR_DEBUG="\033[1;32m" # Green
COLOR_RESET="\033[0m"    # Reset
_LOG_LEVEL_=$(read_config ".log_level" 2)

log_info() {
    local format="$1"
    shift
    printf "${COLOR_INFO}[INFO] ${format}${COLOR_RESET}\n" "$@"
}

log_warn() {
    if [ "$_LOG_LEVEL_" -lt 1 ]; then
        return
    fi
    local format="$1"
    shift
    printf "${COLOR_WARN}[WARN] ${format}${COLOR_RESET}\n" "$@"
}

log_err() {
    if [ "$_LOG_LEVEL_" -lt 2 ]; then
        return
    fi
    local format="$1"
    shift
    printf "${COLOR_ERR}[ERROR] ${format}${COLOR_RESET}\n" "$@"
}

log_debug() {
    if [ "$_LOG_LEVEL_" -lt 3 ]; then
        return
    fi
    local format="$1"
    shift
    printf "${COLOR_DEBUG}[DEBUG] ${format}${COLOR_RESET}\n" "$@"
}