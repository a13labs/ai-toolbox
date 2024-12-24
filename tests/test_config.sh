#!/bin/bash

export AI_TOOL_BOX_CONFIG_FILE=$(mktemp)

source $(realpath $(dirname $0)/../lib)/bootstrap.sh

function test_read_config {
    local test_key=".test_key"
    local expected_value="test_value"
    echo "{\"test_key\": \"$expected_value\"}" > "$_CONFIG_FILE_"
    local result=$(read_config "$test_key")
    if [ "$result" == "$expected_value" ]; then
        echo "test_read_config passed"
    else
        echo "test_read_config failed"
    fi
    rm "$_CONFIG_FILE_"
}

function test_read_with_default_value {
    local test_key=".test_key"
    local expected_value="test_value"
    local default_value="default_value"
    local result=$(read_config "$test_key" "$default_value")
    if [ "$result" == "$default_value" ]; then
        echo "test_read_with_default_value passed"
    else
        echo "test_read_with_default_value failed"
    fi
}


function test_write_config {
    local test_key=".test_key"
    local test_value="test_value"
    write_config "$test_key" "$test_value"
    local result=$(jq -r "$test_key" "$_CONFIG_FILE_")
    if [ "$result" == "$test_value" ]; then
        echo "test_write_config passed"
    else
        echo "test_write_config failed"
    fi
    rm "$_CONFIG_FILE_"
}

test_read_config
test_read_with_default_value
test_write_config
