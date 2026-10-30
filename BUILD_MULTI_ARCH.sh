#!/bin/bash
set -e  # Exit on error

# ===== CONFIGURATION =====
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}"
CACHE_DIR="${HOME}/.freertos-cache"

# Architecture validation
VALID_ARCHS=(arm-cortex-m4 arm-cortex-m7 arm-cortex-a x86-64 all)
ARCH=${1:-all}

# ===== FUNCTIONS =====

print_usage() {
    echo "Usage: $0 {arm-cortex-m4 | arm-cortex-m7 | arm-cortex-a | x86-64 | all}"
    echo ""
    echo "Examples:"
    echo "  $0 arm-cortex-a           # Build for ARM Cortex-A"
    echo "  $0 x86-64                 # Build for x86-64"
    echo "  $0 all                    # Build all architectures"
}

validate_arch() {
    for valid_arch in "${VALID_ARCHS[@]}"; do
        if [[ "$ARCH" == "$valid_arch" ]]; then
            return 0
        fi
    done

    echo "ERROR: Invalid architecture: $ARCH"
    print_usage
    exit 1
}

init_cache_directories() {
    echo "Initializing cache directories..."
    mkdir -p "${CACHE_DIR}"/{downloads,build-cache-arm-cortex-m4,build-cache-arm-cortex-m7,build-cache-arm-cortex-a,build-cache-x86-64}
    chmod 755 "${CACHE_DIR}"
}

build_docker_image() {
    local dockerfile=$1
    local tag=$2

    echo "Checking Docker image: $tag"

    if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${tag}$"; then
        echo "  ✓ Image $tag already exists"
    else
        echo "  Building $tag from $dockerfile..."
        docker build -t "$tag" -f "$dockerfile" "${PROJECT_DIR}" || {
            echo "ERROR: Failed to build Docker image $tag"
            return 1
        }
    fi
}

build_architecture() {
    local arch=$1
    local docker_image=$2
    local toolchain_file=$3
    local build_cache=$4

    echo ""
    echo "========================================="
    echo "Building for architecture: $arch"
    echo "========================================="
    echo "Docker image: $docker_image"
    echo "Toolchain: $toolchain_file"
    echo "Build cache: $build_cache"
    echo ""

    # Pre-create build cache with correct permissions
    mkdir -p "$build_cache"
    chmod 755 "$build_cache"

    # Run build inside container
    # Use absolute paths for CMake toolchain to ensure proper detection
    local abs_toolchain="/home/builder/project/${toolchain_file}"

    docker run --rm \
        -v "${CACHE_DIR}/downloads:/home/builder/.freertos-cache/downloads:ro" \
        -v "$build_cache:/home/builder/project/build" \
        -v "${PROJECT_DIR}:/home/builder/project" \
        -w /home/builder/project \
        --memory=14g \
        "$docker_image" \
        bash -c "
            source /opt/freertos-env.sh
            mkdir -p build
            cd build
            rm -f CMakeCache.txt
            cmake /home/builder/project -DCMAKE_TOOLCHAIN_FILE=${abs_toolchain}
            make -j\$(nproc)
        " || {
        echo "ERROR: Build failed for $arch"
        return 1
    }

    # Collect output
    echo ""
    echo "Collecting output binaries..."
    mkdir -p "${PROJECT_DIR}/freertos-output/${arch}"

    # Copy main binary
    if [[ -f "${build_cache}/hello-world.elf" ]]; then
        cp "${build_cache}/hello-world.elf" "${PROJECT_DIR}/freertos-output/${arch}/"
        echo "  ✓ hello-world.elf"
    fi

    # Copy secondary outputs (if generated)
    [[ -f "${build_cache}/hello-world.bin" ]] && \
        cp "${build_cache}/hello-world.bin" "${PROJECT_DIR}/freertos-output/${arch}/"
    [[ -f "${build_cache}/hello-world.lst" ]] && \
        cp "${build_cache}/hello-world.lst" "${PROJECT_DIR}/freertos-output/${arch}/"
    [[ -f "${build_cache}/hello-world.map" ]] && \
        cp "${build_cache}/hello-world.map" "${PROJECT_DIR}/freertos-output/${arch}/"

    echo "✓ Build complete for $arch"
}

# ===== MAIN LOGIC =====

validate_arch
init_cache_directories

# Build Docker images (skip if already exist)
build_docker_image "Dockerfile" "freertos-builder:arm"
build_docker_image "Dockerfile.x86-64" "freertos-builder:x86-64"

# Execute architecture-specific builds
case "$ARCH" in
    arm-cortex-a)
        build_architecture "arm-cortex-a" "freertos-builder:arm" \
            "cmake/toolchains/arm-cortex-a.cmake" \
            "${CACHE_DIR}/build-cache-arm-cortex-a"
        ;;
    x86-64)
        build_architecture "x86-64" "freertos-builder:x86-64" \
            "cmake/toolchains/x86-64.cmake" \
            "${CACHE_DIR}/build-cache-x86-64"
        ;;
    all)
        build_architecture "arm-cortex-a" "freertos-builder:arm" \
            "cmake/toolchains/arm-cortex-a.cmake" \
            "${CACHE_DIR}/build-cache-arm-cortex-a" || true

        build_architecture "x86-64" "freertos-builder:x86-64" \
            "cmake/toolchains/x86-64.cmake" \
            "${CACHE_DIR}/build-cache-x86-64" || true
        ;;
esac

echo ""
echo "========================================="
echo "Build complete!"
echo "========================================="
echo "Output location: ${PROJECT_DIR}/freertos-output/"
echo ""
find "${PROJECT_DIR}/freertos-output/" -name "hello-world.elf" 2>/dev/null | while read file; do
    echo "  ✓ $file"
done || echo "  (No binaries found yet - ensure FreeRTOS kernel is present)"
