#!/bin/bash

# FreeRTOS Build Environment Setup
# Source this script inside container to configure paths and variables

set -euo pipefail

# ===== TOOLCHAIN PATHS =====
export PATH="/opt/toolchain/bin:${PATH}"

# ===== FREERTOS CONFIGURATION =====
export FREERTOS_DIR="${HOME}/freertos-kernel"
export HAL_DIR="${HOME}/hal"

# ===== CACHE PATHS =====
export FREERTOS_CACHE_DIR="${HOME}/.freertos-cache"
export FREERTOS_DOWNLOADS="${FREERTOS_CACHE_DIR}/downloads"

# ===== BUILD OPTIMIZATION =====
export CFLAGS="${CFLAGS:-"-O2 -Wall -Wextra"}"
export CXXFLAGS="${CXXFLAGS:-"-O2 -Wall -Wextra"}"
export LDFLAGS="${LDFLAGS:-""}"

# ===== CMAKE CONFIGURATION =====
export CMAKE_VERBOSE_MAKEFILE=OFF
export CMAKE_COLOR_MAKEFILE=ON

# ===== OPTIONAL: VERACODE CONFIGURATION =====
# These are passed from host via docker run -e flags
# export VERACODE_API_ID
# export VERACODE_API_KEY

# ===== PARALLELISM =====
export MAKE_JOBS=$(nproc)

# ===== INFORMATIONAL OUTPUT =====
cat << 'EOF'
=========================================
FreeRTOS Build Environment Initialized
=========================================
EOF

echo "FREERTOS_DIR:       ${FREERTOS_DIR}"
echo "HAL_DIR:            ${HAL_DIR}"
echo "FREERTOS_CACHE_DIR: ${FREERTOS_CACHE_DIR}"
echo "Parallel jobs:      ${MAKE_JOBS}"

cat << 'EOF'
=========================================
EOF
