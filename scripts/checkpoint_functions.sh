#!/bin/bash

# checkpoint_functions.sh ||||||| Build checkpoint system for Android FFmpeg builds

# Initialize checkpoint system
init_checkpoints() {
    local arch="$1"
    local api_level="$2"

    CHECKPOINT_DIR="${ROOT_DIR}/build/checkpoints"
    CHECKPOINT_FILE="${CHECKPOINT_DIR}/${arch}_api${api_level}.checkpoint"
    CONFIG_HASH_FILE="${CHECKPOINT_DIR}/${arch}_api${api_level}.config_hash"

    mkdir -p "$CHECKPOINT_DIR"

    # Check configuration changes
    if config_changed "$arch" "$api_level"; then
        echo "Configuration changed. Starting fresh build"
    fi

    # Display checkpoint status
    if [[ -f "$CHECKPOINT_FILE" ]]; then
        completed_steps=$(wc -l < "$CHECKPOINT_FILE")
        echo "Found existing checkpoint with $completed_steps completed steps"
        echo "Resuming build............"
    else
        echo "Starting fresh build"
    fi
}

# Function to generate config hash
generate_config_hash() {
    local arch="$1"
    local api_level="$2"
    local config_string="${arch}_${api_level}_${FFMPEG_STATIC}_${ANDROID_NDK_ROOT}"
    echo -n "$config_string" | md5sum | cut -d' ' -f1
}

# Function to check if configuration has changed
config_changed() {
    local arch="$1"
    local api_level="$2"
    local current_hash=$(generate_config_hash "$arch" "$api_level")
    local stored_hash=""

    if [[ -f "$CONFIG_HASH_FILE" ]]; then
        stored_hash=$(cat "$CONFIG_HASH_FILE")
    fi

    if [[ "$current_hash" != "$stored_hash" ]]; then
        echo "$current_hash" > "$CONFIG_HASH_FILE"
        rm -f "$CHECKPOINT_FILE"
        return 0 # Config changed
    fi

    return 1
}

mark_completed() {
    local step_name="$1"
    echo "$step_name" >> "$CHECKPOINT_FILE"
}

is_completed() {
    local step_name="$1"
    if [[ -f "$CHECKPOINT_FILE" ]] && grep -q "^$step_name$" "$CHECKPOINT_FILE"; then
        return 0 # Already completed
    fi
    return 1 # Not completed
}

run_step() {
    local step_name="$1"
    local step_function="$2"

    if is_completed "$step_name"; then
        echo "Skipping $step_name (already completed)"
        return 0
    fi

    echo "Building $step_name..."
    if $step_function; then
        mark_completed "$step_name"
    else
        echo "Failed to build $step_name"
        exit 1
    fi
}

reset_checkpoints() {
    rm -f "$CHECKPOINT_FILE" "$CONFIG_HASH_FILE"
    echo "Checkpoints reset. Next build will start from beginning"
}

# Function to show checkpoint status
show_checkpoint_status() {
    if [[ -f "$CHECKPOINT_FILE" ]]; then
        echo "Completed build steps:"
        cat "$CHECKPOINT_FILE"
    else
        echo "No checkpoint file found"
    fi
}
