#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}"
ARCH=${1:-all}
CACHE_DIR="${HOME}/.freertos-cache"

echo "========================================="
echo "Build + SAST Scanning"
echo "========================================="

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

run_sast_scan() {
    local arch=$1
    local build_cache="${CACHE_DIR}/build-cache-${arch}"

    echo ""
    echo "========================================="
    echo "Running SAST on x86-64..."
    echo "========================================="

    docker run --rm \
        -v "${CACHE_DIR}/downloads:/home/builder/.freertos-cache/downloads:ro" \
        -v "$build_cache:/home/builder/build" \
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
}

echo ""
echo "========================================="
echo "Build + SAST complete!"
echo "========================================="
echo "Outputs:"
echo "  Binaries:      ${PROJECT_DIR}/freertos-output/"
echo "  Preprocessed:  ${PROJECT_DIR}/preprocessed-src/"
echo "  Veracode pkg:  ${PROJECT_DIR}/veracode-package/"
echo "  SAST reports:  ${PROJECT_DIR}/sast-reports/"
