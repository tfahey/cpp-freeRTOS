#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}"
CACHE_DIR="${HOME}/.freertos-cache"

# Parse arguments
ARCH=${1:-}
COMMAND=${2:-}
CMD_ARGS=${3:-}

if [[ -z "$ARCH" ]] || [[ -z "$COMMAND" ]]; then
    echo "Usage: $0 {arch} {command} [args]"
    echo ""
    echo "Architectures: arm-cortex-m4, arm-cortex-m7, arm-cortex-a, x86-64"
    echo ""
    echo "Commands:"
    echo "  start              - Create and start persistent container"
    echo "  shell              - Launch interactive bash in running container"
    echo "  bash \"cmd\"       - Execute command in container"
    echo "  stop               - Stop running container (preserves state)"
    echo "  rm                 - Delete container (loses state)"
    echo "  status             - Check if container is running"
    echo "  fix-permissions    - Fix cache directory ownership"
    echo ""
    echo "Examples:"
    echo "  $0 arm-cortex-a start"
    echo "  $0 arm-cortex-a shell"
    echo "  $0 x86-64 bash 'cmake .. && make'"
    echo "  $0 arm-cortex-a stop"
    exit 1
fi

# Determine Docker image based on architecture
if [[ "$ARCH" == "x86-64" ]]; then
    DOCKER_IMAGE="freertos-builder:x86-64"
    BUILD_CACHE="${CACHE_DIR}/build-cache-x86-64"
else
    DOCKER_IMAGE="freertos-builder:arm"
    BUILD_CACHE="${CACHE_DIR}/build-cache-${ARCH}"
fi

CONTAINER_NAME="freertos-builder-${ARCH}"

# ===== COMMAND IMPLEMENTATIONS =====

cmd_start() {
    echo "Starting container: $CONTAINER_NAME"

    # Check if already running
    if docker ps | grep -q "$CONTAINER_NAME"; then
        echo "✓ Container $CONTAINER_NAME is already running"
        return 0
    fi

    # Check if exists but stopped
    if docker ps -a | grep -q "$CONTAINER_NAME"; then
        echo "Restarting stopped container..."
        docker start "$CONTAINER_NAME"
        echo "✓ Container restarted"
        return 0
    fi

    # Create new container
    echo "Creating new container..."
    mkdir -p "$BUILD_CACHE"
    chmod 755 "$BUILD_CACHE"

    docker run -d \
        --name "$CONTAINER_NAME" \
        --hostname "$CONTAINER_NAME" \
        -v "${CACHE_DIR}/downloads:/home/builder/.freertos-cache/downloads:ro" \
        -v "$BUILD_CACHE:/home/builder/build" \
        -v "${PROJECT_DIR}:/home/builder/project" \
        -e VERACODE_API_ID="${VERACODE_API_ID:-}" \
        -e VERACODE_API_KEY="${VERACODE_API_KEY:-}" \
        -w /home/builder/project \
        "$DOCKER_IMAGE" \
        sleep infinity

    echo "✓ Container started"
    echo "  Image: $DOCKER_IMAGE"
    echo "  Cache: $BUILD_CACHE"
    echo "  Project: ${PROJECT_DIR}"
}

cmd_shell() {
    echo "Entering container shell: $CONTAINER_NAME"
    echo "(type 'exit' to leave)"
    docker exec -it "$CONTAINER_NAME" bash
}

cmd_bash() {
    docker exec "$CONTAINER_NAME" bash -c "$CMD_ARGS"
}

cmd_stop() {
    echo "Stopping container: $CONTAINER_NAME"
    docker stop "$CONTAINER_NAME" || true
    echo "✓ Container stopped (changes preserved)"
}

cmd_rm() {
    echo "Removing container: $CONTAINER_NAME"
    docker rm "$CONTAINER_NAME" || true
    echo "✓ Container removed (cache directory preserved)"
}

cmd_status() {
    if docker ps | grep -q "$CONTAINER_NAME"; then
        echo "✓ $CONTAINER_NAME is running"
    elif docker ps -a | grep -q "$CONTAINER_NAME"; then
        echo "⊘ $CONTAINER_NAME is stopped"
    else
        echo "✗ $CONTAINER_NAME does not exist"
    fi
}

cmd_fix_permissions() {
    echo "Fixing cache directory permissions..."
    docker exec "$CONTAINER_NAME" \
        chown -R builder:builder ~/.freertos-cache/ || true
    docker exec "$CONTAINER_NAME" \
        chmod -R u+rwX ~/.freertos-cache/ || true
    echo "✓ Permissions fixed"
}

# ===== MAIN DISPATCH =====

case "$COMMAND" in
    start)
        cmd_start
        ;;
    shell)
        cmd_shell
        ;;
    bash)
        cmd_bash
        ;;
    stop)
        cmd_stop
        ;;
    rm)
        cmd_rm
        ;;
    status)
        cmd_status
        ;;
    fix-permissions)
        cmd_fix_permissions
        ;;
    *)
        echo "ERROR: Unknown command: $COMMAND"
        exit 1
        ;;
esac
