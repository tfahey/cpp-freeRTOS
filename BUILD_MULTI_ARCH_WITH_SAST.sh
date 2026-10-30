#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}"
ARCH=${1:-all}
CACHE_DIR="${HOME}/.freertos-cache"
USE_PERSISTENT_CONTAINER="${USE_PERSISTENT_CONTAINER:-0}"

echo "========================================="
echo "Build + SAST Scanning"
echo "========================================="
echo "Architecture: $ARCH"
echo "Container mode: $([ "$USE_PERSISTENT_CONTAINER" = "1" ] && echo "persistent" || echo "ephemeral")"
echo ""

# Helper function to check if persistent container is running
check_persistent_container() {
    local arch=$1
    local container_name="freertos-builder-${arch}"
    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        return 0  # Container is running
    else
        return 1  # Container is not running
    fi
}

# Define SAST function BEFORE calling it
run_sast_scan() {
    local arch=$1
    local build_cache="${CACHE_DIR}/build-cache-${arch}"
    local container_name="freertos-builder-${arch}"

    echo ""
    echo "========================================="
    echo "Running SAST on x86-64..."
    echo "========================================="

    # Check container mode
    if [ "$USE_PERSISTENT_CONTAINER" = "1" ]; then
        if check_persistent_container "$arch"; then
            echo "📦 Using persistent container: $container_name"
            # Execute in persistent container
            docker exec -e VERACODE_API_ID -e VERACODE_API_KEY "$container_name" \
                bash -c "
                    source /opt/freertos-env.sh

                    # Rebuild with preprocessing enabled
                    cd build
                    echo 'Rebuilding with preprocessing enabled...'
                    cmake .. \
                        -DCMAKE_TOOLCHAIN_FILE=../cmake/toolchains/x86-64.cmake \
                        -DCMAKE_C_FLAGS='-save-temps=obj'
                    make -j\$(nproc)

                    # Verify preprocessed files exist
                    if ! find . -name '*.i' | grep -q .; then
                        echo 'WARNING: No preprocessed files found'
                    fi

                    # Create output directories
                    mkdir -p ../preprocessed-src
                    mkdir -p ../veracode-package

                    # Collect preprocessed source files
                    find . -name '*.i' -exec cp {} ../preprocessed-src/ \; 2>/dev/null || true

                    # Create veracode package (if veracode CLI available)
                    if command -v veracode &> /dev/null; then
                        veracode package \
                            --source ../build \
                            --target ../veracode-package \
                            --exclude '*.o,*.a' || true

                        # Upload if credentials provided
                        if [[ -n \"\${VERACODE_API_ID:-}\" ]] && [[ -n \"\${VERACODE_API_KEY:-}\" ]]; then
                            echo 'Uploading to Veracode...'
                            veracode scan upload \
                                --api-id \"\$VERACODE_API_ID\" \
                                --api-key \"\$VERACODE_API_KEY\" \
                                --source ../veracode-package/app.zip || true
                        else
                            echo 'Veracode credentials not set; skipping upload'
                        fi
                    else
                        echo 'Veracode CLI not available in container'
                    fi
                " || {
                echo "WARNING: SAST scanning in persistent container failed (non-fatal)"
            }
        else
            echo "❌ Persistent container $container_name is not running!"
            echo "   Start it with: bash CONTAINER_MANAGER.sh x86-64 start"
            echo ""
            echo "   Or use ephemeral containers (default):"
            echo "   bash BUILD_MULTI_ARCH_WITH_SAST.sh $ARCH"
            exit 1
        fi
    else
        # Use ephemeral container (default)
        echo "📦 Using ephemeral container"
        docker run --rm \
            -v "${CACHE_DIR}/downloads:/home/builder/.freertos-cache/downloads:ro" \
            -v "$build_cache:/home/builder/project/build" \
            -v "${PROJECT_DIR}:/home/builder/project" \
            -e VERACODE_API_ID="${VERACODE_API_ID:-}" \
            -e VERACODE_API_KEY="${VERACODE_API_KEY:-}" \
            -w /home/builder/project \
            freertos-builder:x86-64 \
            bash -c "
                source /opt/freertos-env.sh

                # Rebuild with preprocessing enabled
                cd build
                echo 'Rebuilding with preprocessing enabled...'
                cmake .. \
                    -DCMAKE_TOOLCHAIN_FILE=../cmake/toolchains/x86-64.cmake \
                    -DCMAKE_C_FLAGS='-save-temps=obj'
                make -j\$(nproc)

                # Verify preprocessed files exist
                if ! find . -name '*.i' | grep -q .; then
                    echo 'WARNING: No preprocessed files found'
                fi

                # Create output directories
                mkdir -p ../preprocessed-src
                mkdir -p ../veracode-package

                # Collect preprocessed source files
                find . -name '*.i' -exec cp {} ../preprocessed-src/ \; 2>/dev/null || true

                # Create veracode package (if veracode CLI available)
                if command -v veracode &> /dev/null; then
                    veracode package \
                        --source ../build \
                        --target ../veracode-package \
                        --exclude '*.o,*.a' || true

                    # Upload if credentials provided
                    if [[ -n \"\${VERACODE_API_ID:-}\" ]] && [[ -n \"\${VERACODE_API_KEY:-}\" ]]; then
                        echo 'Uploading to Veracode...'
                        veracode scan upload \
                            --api-id \"\$VERACODE_API_ID\" \
                            --api-key \"\$VERACODE_API_KEY\" \
                            --source ../veracode-package/app.zip || true
                    else
                        echo 'Veracode credentials not set; skipping upload'
                    fi
                else
                    echo 'Veracode CLI not available in container'
                fi
            " || {
            echo "WARNING: SAST scanning failed (non-fatal)"
        }
    fi
}

# Step 1: Run normal build
echo "Step 1: Building FreeRTOS..."
bash "${SCRIPT_DIR}/BUILD_MULTI_ARCH.sh" "$ARCH"

# Step 2: Run SAST on x86-64 only
echo ""
echo "Step 2: Running SAST analysis..."

if [[ "$ARCH" == "x86-64" || "$ARCH" == "all" ]]; then
    run_sast_scan "x86-64"
else
    echo "SAST only supported on x86-64 (Veracode CLI not available for ARM)"
fi

echo ""
echo "========================================="
echo "Build + SAST complete!"
echo "========================================="
echo "Outputs:"
echo "  Binaries:      ${PROJECT_DIR}/freertos-output/"
echo "  Preprocessed:  ${PROJECT_DIR}/preprocessed-src/"
echo "  Veracode pkg:  ${PROJECT_DIR}/veracode-package/"
echo "  SAST reports:  ${PROJECT_DIR}/sast-reports/"
echo ""
echo "Container modes:"
echo "  • Ephemeral (default):     bash BUILD_MULTI_ARCH_WITH_SAST.sh $ARCH"
echo "  • Persistent:              USE_PERSISTENT_CONTAINER=1 bash BUILD_MULTI_ARCH_WITH_SAST.sh $ARCH"
echo ""
echo "To use persistent containers:"
echo "  1. Start container:        bash CONTAINER_MANAGER.sh x86-64 start"
echo "  2. Run SAST build:         USE_PERSISTENT_CONTAINER=1 bash BUILD_MULTI_ARCH_WITH_SAST.sh x86-64"
echo "  3. Interactive shell:      bash CONTAINER_MANAGER.sh x86-64 shell"
echo "  4. Stop container:         bash CONTAINER_MANAGER.sh x86-64 stop"
