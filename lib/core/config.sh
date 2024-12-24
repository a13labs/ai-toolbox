if [ -n "$_CONFIG_INCLUDE_" ]; then
    return
fi

if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Please install jq to use this script."
    exit 1
fi

_CONFIG_INCLUDE_=1

_CONFIG_FILE_=${AI_TOOL_BOX_CONFIG_FILE:-"$HOME/.ai_toolboxrc"}

# Function to read a setting from the config file
function read_config {
    local path="$1"
    if [ ! -f "$_CONFIG_FILE_" ] && [ -n "$2" ]; then
        echo "$2"
        return
    fi
    if [ -n "$2" ] && [ -z "$(jq "$path" "$_CONFIG_FILE_")" ]; then
        echo "$2"
        return
    fi
    jq -r "$path" "$_CONFIG_FILE_"
}

function read_config_1 {
    local path="$1"
    if [ -n "$2" ]; then
        if [ ! -f "$_CONFIG_FILE_" ]; then
            echo "$2"
        else
            jq -r "$path // \"$2\"" "$_CONFIG_FILE_"
        fi
        return
    fi
    jq -r "$path" "$_CONFIG_FILE_"
}


# Function to write a setting to the config file
function write_config {
    local path="$1"
    local value="$2"
    if [ ! -f "$_CONFIG_FILE_" ]; then
        echo "{}" > "$_CONFIG_FILE_"
    fi
    tmp_file=$(mktemp)
    jq "$path = \"$value\"" "$_CONFIG_FILE_" > "$tmp_file" && mv "$tmp_file" "$_CONFIG_FILE_"
}
