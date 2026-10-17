# FreeRTOS Multi-Architecture Build Project

A containerized multi-architecture build system for FreeRTOS embedded applications with integrated security scanning and architecture-specific caching.

## Project Overview

This project demonstrates a production-grade FreeRTOS build infrastructure that:

- **Builds for multiple architectures**: ARM Cortex-M4 (STM32), ARM Cortex-M7 (NXP), ARM Cortex-A (bare-metal), x86 (testing/simulation)
- **Uses Docker containers**: Isolated build environments with ARM toolchains, no host dependencies
- **Implements persistent caching**: Per-architecture build caches avoid complete rebuilds when switching targets
- **Integrates security scanning**: Static analysis (SAST) of C code to detect vulnerabilities before deployment
- **Provides manual testing interface**: Container manager for interactive development and debugging

## Architecture

```
FreeRTOS Project Root
├── src/
│   ├── main.c              # Application entry point
│   ├── config/
│   │   └── FreeRTOSConfig.h    # FreeRTOS configuration
│   └── tasks/
│       └── example_task.c  # Example FreeRTOS task
├── CMakeLists.txt          # Build configuration
├── Dockerfile              # Base image (ARM toolchain)
├── Dockerfile.x86-64       # x86-64 variant for testing
├── BUILD_MULTI_ARCH.sh     # Multi-architecture build script
├── BUILD_MULTI_ARCH_WITH_SAST.sh  # Build + security scanning
├── CONTAINER_MANAGER.sh    # Container lifecycle management
├── .freertos-cache/        # Persistent build caches (generated)
│   ├── downloads/          # Shared FreeRTOS/HAL downloads
│   ├── build-cache-arm-cortex-m4/
│   ├── build-cache-arm-cortex-m7/
│   └── build-cache-x86-64/
└── freertos-output/        # Build artifacts (generated)
    ├── arm-cortex-m4/hello-world.elf
    ├── arm-cortex-m7/hello-world.elf
    └── x86-64/hello-world.elf
```

## Supported Architectures

| Architecture | Target Board | Toolchain | Docker Image | Use Case |
|---|---|---|---|---|
| `arm-cortex-m4` | STM32H7 | `arm-none-eabi-gcc` | Dockerfile | Microcontroller |
| `arm-cortex-m7` | NXP i.MX | `arm-none-eabi-gcc` | Dockerfile | Industrial |
| `arm-cortex-a` | Bare-metal ARM | `arm-linux-gnueabihf-gcc` | Dockerfile | Single-board |
| `x86-64` | x86 Linux | `gcc` (native) | Dockerfile.x86-64 | Testing/CI |

## Quick Start

### Prerequisites

- Docker (with buildx for multi-architecture)
- git
- bash
- (Optional) ARM toolchain for native compilation

### 1. Build Docker Images

```bash
# Build for ARM targets (base image, default)
docker build -t freertos-builder:arm .

# Build for x86-64 testing
docker build --platform linux/amd64 -t freertos-builder:x86-64 -f Dockerfile.x86-64 .
```

### 2. Build for Single Architecture

```bash
# Build for ARM Cortex-M4
bash BUILD_MULTI_ARCH.sh arm-cortex-m4

# Build for x86-64
bash BUILD_MULTI_ARCH.sh x86-64

# Build for all architectures
bash BUILD_MULTI_ARCH.sh all
```

Output binaries appear in `freertos-output/`:
```
freertos-output/
├── arm-cortex-m4/hello-world.elf
├── arm-cortex-m7/hello-world.elf
└── x86-64/hello-world.elf
```

### 3. Build with Security Scanning

```bash
# Requires Veracode API credentials
export VERACODE_API_ID="your-id"
export VERACODE_API_KEY="your-key"

# Build + SAST scan
bash BUILD_MULTI_ARCH_WITH_SAST.sh x86-64
```

### 4. Interactive Development

```bash
# Start a persistent container for manual exploration
bash CONTAINER_MANAGER.sh arm-cortex-m4 start
bash CONTAINER_MANAGER.sh arm-cortex-m4 shell

# Inside container:
cd /home/builder/project
source /opt/freertos-env.sh  # Sets PATH, toolchain
cmake -B build -DCMAKE_TOOLCHAIN_FILE=arm-cortex-m4.cmake
make -C build
```

## Build Caching Strategy

Each architecture maintains its own build cache:

- **First build (any architecture)**: ~15-20 minutes (downloads toolchain, dependencies, compiles everything)
- **Subsequent builds (same architecture)**: ~2-5 minutes (reuses cached objects)
- **Switch architectures**: ~2-5 minutes (uses respective cache, downloads stay shared)

Caches are stored in `~/.freertos-cache/`:
```
.freertos-cache/
├── downloads/              # Shared (FreeRTOS kernel, HALs)
├── build-cache-arm-cortex-m4/    # ARM M4 object files, libs
├── build-cache-arm-cortex-m7/    # ARM M7 object files, libs
└── build-cache-x86-64/           # x86 object files, libs
```

## Build Scripts

### BUILD_MULTI_ARCH.sh
- **Purpose**: Build for specified architecture(s)
- **Input**: `arm-cortex-m4 | arm-cortex-m7 | arm-cortex-a | x86-64 | all`
- **Output**: ELF binaries in `freertos-output/`
- **Features**: Persistent caching, Docker containerization, memory optimization

### BUILD_MULTI_ARCH_WITH_SAST.sh
- **Purpose**: Build + run static analysis security testing
- **Input**: Same as BUILD_MULTI_ARCH.sh + Veracode credentials (optional)
- **Output**: ELF binaries + SAST reports
- **Features**: Same as above + Veracode packaging + upload/scan (if credentials provided)

### CONTAINER_MANAGER.sh
- **Purpose**: Manage persistent Docker containers for interactive work
- **Commands**: `start | shell | stop | rm | status | fix-permissions | bash [cmd]`
- **Use**: Manual debugging, incremental development, container inspection

## Documentation Files

- **README.md** (this file) — Project overview and quick start
- **BUILD_INFRASTRUCTURE.md** — Detailed build system architecture and strategy
- **CONTAINER_USAGE.md** — Step-by-step guide for manual container testing and debugging
- **SECURITY_SCANNING.md** — Security vulnerability testing and SAST configuration

## Repository Structure

```
.
├── src/                    # FreeRTOS application source code
├── freertos-kernel/        # FreeRTOS core (git submodule or vendored)
├── hal/                    # Hardware abstraction layer per board
│   ├── stm32h7/
│   ├── nxp-imx/
│   └── generic-arm/
├── cmake/                  # CMake build configuration
│   ├── toolchains/         # Platform-specific toolchain files
│   ├── FindFreeRTOS.cmake  # FreeRTOS discovery module
│   └── FindHAL.cmake       # HAL discovery module
├── CMakeLists.txt          # Root CMake configuration
├── Dockerfile              # ARM toolchain (base)
├── Dockerfile.x86-64       # x86-64 variant
├── BUILD_MULTI_ARCH.sh     # Multi-architecture build script
├── BUILD_MULTI_ARCH_WITH_SAST.sh  # Build + SAST
├── CONTAINER_MANAGER.sh    # Container management
└── README.md               # This file
```

## Development Workflow

### Making Changes

1. Edit source code in `src/` directory
2. Start a container for your architecture:
   ```bash
   bash CONTAINER_MANAGER.sh arm-cortex-m4 start
   bash CONTAINER_MANAGER.sh arm-cortex-m4 shell
   ```
3. Build incrementally:
   ```bash
   cd /home/builder/project/build
   cmake .. -DBOARD=STM32H7
   make
   ```
4. Test the binary (depends on your testing method)
5. Commit changes when satisfied

### Running SAST

Before committing security-critical changes:

```bash
export VERACODE_API_ID="your-id"
export VERACODE_API_KEY="your-key"
bash BUILD_MULTI_ARCH_WITH_SAST.sh arm-cortex-m4
```

Review reports in `sast-reports/` before pushing.

## Common Commands

```bash
# Full multi-architecture build
bash BUILD_MULTI_ARCH.sh all

# Build specific architecture
bash BUILD_MULTI_ARCH.sh arm-cortex-m4

# Build + security scan
bash BUILD_MULTI_ARCH_WITH_SAST.sh x86-64

# Interactive shell for debugging
bash CONTAINER_MANAGER.sh arm-cortex-m4 start
bash CONTAINER_MANAGER.sh arm-cortex-m4 shell

# Fix container permissions (run once after container start)
bash CONTAINER_MANAGER.sh arm-cortex-m4 fix-permissions

# Run command in container without shell
bash CONTAINER_MANAGER.sh arm-cortex-m4 bash "make -C build clean"

# Clean up container
bash CONTAINER_MANAGER.sh arm-cortex-m4 stop
bash CONTAINER_MANAGER.sh arm-cortex-m4 rm
```

## Troubleshooting

### Build fails with "Toolchain not found"
Ensure the Docker image was built:
```bash
docker build -t freertos-builder:arm .
```

### Permission errors in container
Run permission fix after starting:
```bash
bash CONTAINER_MANAGER.sh arm-cortex-m4 fix-permissions
```

### Slow build on first run
Expected — first build downloads and compiles everything (~15-20 min). Subsequent builds reuse the cache (~2-5 min).

### Container won't start
Check if it's already running:
```bash
docker ps | grep freertos-builder
```

Stop and remove if stuck:
```bash
bash CONTAINER_MANAGER.sh arm-cortex-m4 stop
bash CONTAINER_MANAGER.sh arm-cortex-m4 rm
bash CONTAINER_MANAGER.sh arm-cortex-m4 start
```

### SAST scanning shows "no artifacts"
Ensure the build completed successfully before running SAST. Check build logs for errors.

## Next Steps

1. Read **BUILD_INFRASTRUCTURE.md** for detailed architecture and caching strategy
2. Read **CONTAINER_USAGE.md** for step-by-step manual testing workflow
3. Read **SECURITY_SCANNING.md** for SAST configuration and vulnerability testing
4. Start building: `bash BUILD_MULTI_ARCH.sh arm-cortex-m4`
