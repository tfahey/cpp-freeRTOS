# FreeRTOS Build Infrastructure

Detailed technical documentation for the multi-architecture containerized build system.

## Architecture Overview

This build infrastructure is designed to support embedded systems development across multiple ARM architectures using FreeRTOS as the RTOS kernel. The system combines Docker containerization for reproducible builds, CMake for cross-platform build configuration, and persistent architecture-specific caching to minimize rebuild time when switching between targets.

### Core Design Principles

1. **Isolation via Containerization**: All build dependencies (ARM toolchains, FreeRTOS kernel, HALs, CMake) exist only in Docker images, never on the host system
2. **Per-Architecture Caching**: Each target architecture maintains a separate build cache at `~/.freertos-cache/build-cache-{arch}/` to avoid cache invalidation when switching targets
3. **Shared Download Cache**: A single `~/.freertos-cache/downloads/` directory stores FreeRTOS kernel and HAL source downloads shared across all architectures
4. **Credential Security**: API credentials (Veracode) are passed via environment variables at runtime using `-e` flags; they never persist to image or container filesystem
5. **Reproducibility**: Pinned toolchain versions, deterministic CMake configuration, and locked dependency versions ensure identical builds across machines and time

## Directory Structure

```
freertos-project/
├── src/                          # Application source code
│   ├── main.c                    # Entry point with FreeRTOS initialization
│   ├── config/
│   │   └── FreeRTOSConfig.h      # FreeRTOS tuning parameters
│   ├── tasks/
│   │   ├── example_task.c        # Example multi-task app
│   │   └── example_task.h
│   └── drivers/                  # HAL abstraction wrappers
│       ├── uart.c
│       └── gpio.c
├── freertos-kernel/              # FreeRTOS kernel source (vendored or submodule)
│   ├── Source/
│   ├── Demo/
│   └── License/
├── hal/                          # Hardware Abstraction Layers
│   ├── stm32h7/                  # STM32H7 HAL (CubeMX-based)
│   │   ├── stm32h7xx_hal.c
│   │   ├── startup_stm32h7xx.s
│   │   └── STM32H743ZITx_FLASH.ld
│   ├── nxp-imx/                  # NXP i.MX HAL (MCUXpresso-based)
│   │   ├── imx_hal.c
│   │   ├── startup_imx.s
│   │   └── imx_memory.ld
│   └── generic-arm/              # Generic bare-metal ARM
│       ├── arm_cortex.c
│       └── arm_memory.ld
├── cmake/                        # Build configuration
│   ├── CMakeLists.txt            # Root CMake configuration
│   ├── toolchains/               # Cross-compiler configurations
│   │   ├── arm-cortex-m4.cmake
│   │   ├── arm-cortex-m7.cmake
│   │   ├── arm-cortex-a.cmake
│   │   └── x86-64.cmake
│   ├── FindFreeRTOS.cmake        # FreeRTOS discovery module
│   └── FindHAL.cmake             # HAL discovery module
├── build/                        # Build output (generated in-container)
│   ├── CMakeCache.txt
│   ├── hello-world.elf           # Output binary
│   └── hello-world.bin           # Binary format
├── Dockerfile                    # Base image (ARM toolchain)
├── Dockerfile.x86-64             # x86-64 variant for testing/CI
├── BUILD_MULTI_ARCH.sh           # Build orchestration script
├── BUILD_MULTI_ARCH_WITH_SAST.sh # Build + security scanning
├── CONTAINER_MANAGER.sh          # Container lifecycle
└── README.md                     # Quick start guide
```

## Build System Design

### CMake Configuration

The build system uses CMake as the cross-platform meta-build tool. CMake handles:
- Compiler selection (arm-none-eabi-gcc for Cortex-M, arm-linux-gnueabihf for Cortex-A, gcc for x86-64)
- Architecture-specific compiler flags (optimization levels, CPU variants, FPU settings)
- FreeRTOS kernel and HAL dependency discovery
- Linker script selection based on target board
- Automated preprocessed source generation for SAST scanning

### Toolchain Files

Each architecture has a corresponding CMake toolchain file that sets:
- CMAKE_C_COMPILER, CMAKE_CXX_COMPILER
- CMAKE_SYSTEM_NAME (Generic for bare-metal, Linux for Linux targets)
- CMAKE_SYSTEM_PROCESSOR (ARM, AARCH64, x86_64)
- CMAKE_C_FLAGS (optimization, CPU tuning, FP settings)
- CMAKE_EXE_LINKER_FLAGS (linker scripts, memory layout)
- FreeRTOS port selection (e.g., `FreeRTOS/Source/portable/GCC/ARM_CM4_MPU/`)

Example: `cmake/toolchains/arm-cortex-m4.cmake`
```cmake
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR ARM)
set(CMAKE_C_COMPILER arm-none-eabi-gcc)
set(CMAKE_C_FLAGS "-mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mthumb -O2")
set(FREERTOS_PORT_DIR "FreeRTOS/Source/portable/GCC/ARM_CM4_MPU")
```

### FreeRTOS Integration

FreeRTOS is included as either:
1. **Vendored source**: Entire FreeRTOS directory committed to repo (simpler, heavier)
2. **Git submodule**: FreeRTOS as external dependency, updated independently

CMake's FindFreeRTOS.cmake module:
- Locates kernel source at `freertos-kernel/Source/`
- Compiles portable port based on FREERTOS_PORT_DIR
- Discovers headers from `FreeRTOSConfig.h` in `src/config/`
- Links kernel library to application

### HAL Integration

FindHAL.cmake discovers board-specific hardware drivers:
- Compiles HAL source from `hal/{board}/` directory
- Links HAL library to application
- Provides board-specific compiler flags (e.g., STM32H743xx for STM32H7)

## Docker Image Architecture

### Dockerfile (Base - ARM Toolchains)

Used for all ARM architectures (Cortex-M4, M7, A).

```dockerfile
FROM ubuntu:22.04

# Install ARM cross-compiler toolchain
RUN apt-get update && apt-get install -y \
    gcc-arm-none-eabi \
    gcc-arm-linux-gnueabihf \
    cmake \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create builder user (non-root)
RUN useradd -m -s /bin/bash builder

# Setup environment
ENV PATH="/opt/toolchain/bin:${PATH}"
COPY freertos-env.sh /opt/
RUN chmod +x /opt/freertos-env.sh

WORKDIR /home/builder/project
USER builder
```

**Key points:**
- Non-root `builder` user avoids permission issues during development
- ARM toolchains pre-installed: `arm-none-eabi-gcc` (bare-metal), `arm-linux-gnueabihf` (Linux targets)
- CMake version from Ubuntu repos (22.04 includes CMake 3.22+)
- No Veracode CLI (ARM platform not supported)

### Dockerfile.x86-64 (x86-64 Variant)

Used for testing, CI, and SAST scanning on x86-64 architecture.

```dockerfile
FROM ubuntu:22.04

# Install native and cross-compiler toolchains
RUN apt-get update && apt-get install -y \
    gcc \
    cmake \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Veracode CLI for SAST packaging
RUN curl -fsS https://tools.veracode.com/veracode-cli/install | sh

# Create builder user
RUN useradd -m -s /bin/bash builder

ENV PATH="/opt/toolchain/bin:${PATH}"
COPY freertos-env.sh /opt/
RUN chmod +x /opt/freertos-env.sh

WORKDIR /home/builder/project
USER builder
```

**Key points:**
- Native gcc for x86-64 builds
- Veracode CLI included (only x86-64 is supported)
- Same non-root user setup
- Same environment initialization

### freertos-env.sh

Shell script sourced in containers to set up environment:
- Adds toolchains to PATH
- Sets FreeRTOS_DIR
- Defines HAL_DIR for discovery
- Exports CMAKE_TOOLCHAIN_FILE

## Caching Strategy

### Problem

Building FreeRTOS from scratch for a new architecture takes 15-20 minutes:
- Download and extract FreeRTOS kernel
- Compile ARM cross-compiler (if not pre-installed)
- Compile FreeRTOS kernel for architecture
- Compile HAL drivers
- Compile application

When switching architectures (e.g., STM32H7 to NXP i.MX), a unified cache causes complete cache invalidation because object files for M4 cannot be reused for M7, and linker scripts differ per board.

### Solution

Per-architecture build caches maintain object files and compiled libraries separately:

```
~/.freertos-cache/
├── downloads/                    # Shared across architectures
│   ├── freertos-kernel.tar.gz    # Downloaded once
│   └── nxp-imx-hal.tar.gz
├── build-cache-arm-cortex-m4/    # M4-specific objects
│   ├── FreeRTOS/
│   │   └── kernel.a              # Compiled kernel
│   ├── hal/
│   │   └── stm32h7.a
│   └── CMakeFiles/
├── build-cache-arm-cortex-m7/    # M7-specific objects (NOT reused from M4)
│   ├── FreeRTOS/
│   │   └── kernel.a              # Re-compiled for M7
│   ├── hal/
│   │   └── nxp-imx.a
│   └── CMakeFiles/
└── build-cache-x86-64/           # x86-64 for testing
    ├── FreeRTOS/
    │   └── kernel.a              # Simulated FreeRTOS for x86
    └── CMakeFiles/
```

### Docker Volume Mounts

Each build script mounts:
1. **Shared downloads** (read-only): `-v ~/.freertos-cache/downloads:/home/builder/.freertos-cache/downloads:ro`
2. **Architecture-specific cache** (read-write): `-v ~/.freertos-cache/build-cache-{arch}:/home/builder/build`

CMake is configured to use the per-architecture build directory, ensuring objects compile to the right cache.

### Build Performance

| Scenario | Time | Reason |
|---|---|---|
| First build (any arch) | 15-20 min | Downloads FreeRTOS, compiles kernel + HAL + app |
| Same arch, source unchanged | 2-5 min | Reuses all objects, linker only |
| Same arch, edit one source file | 1-2 min | Recompile 1 object, relink |
| Switch arch (M4→M7) | 5-15 min | Reuses downloads, recompiles kernel + HAL for new arch |
| x86 after ARM build | 5-15 min | Separate cache, but downloads still shared |

## Build Scripts

### BUILD_MULTI_ARCH.sh

Entry point for building FreeRTOS for one or more architectures.

**Signature:**
```bash
bash BUILD_MULTI_ARCH.sh {arm-cortex-m4 | arm-cortex-m7 | arm-cortex-a | x86-64 | all}
```

**Flow:**
1. Validate architecture argument
2. Create `~/.freertos-cache/` directories if missing
3. Build Docker image (skip if already built)
4. For each architecture:
   a. Pre-create per-architecture cache directory with proper ownership
   b. Run docker run with:
      - Volume mount for shared downloads
      - Volume mount for per-architecture build cache
      - Memory limit (14GB to prevent OOM on GCC)
      - Working directory `/home/builder/project`
   c. Execute inside container:
      - `cd build && cmake .. -DCMAKE_TOOLCHAIN_FILE=../cmake/toolchains/{arch}.cmake`
      - `make -j$(nproc)` (parallel compilation)
   d. Copy output binary to `freertos-output/{arch}/hello-world.elf`

**Key features:**
- Error handling for each architecture (one failure doesn't block others in `all` mode)
- Automatic cache directory creation with correct permissions
- Memory tuning (14GB) prevents OOM kills during GCC compilation
- Parallel make (`-j`) uses all CPU cores

### BUILD_MULTI_ARCH_WITH_SAST.sh

Same as BUILD_MULTI_ARCH.sh, but also runs Veracode SAST packaging and optional upload/scan.

**Additional flow:**
1. Execute BUILD_MULTI_ARCH.sh for specified architecture
2. If build succeeds:
   a. Inside container, run `veracode package` on build artifacts
   b. Generate `veracode.json` config in veracode-package directory
   c. If VERACODE_API_ID and VERACODE_API_KEY are set in environment:
      - Run `veracode scan upload` to Veracode cloud
      - Poll scan results
      - Download report
   d. Otherwise:
      - Generate local SAST report (no upload)

**Credential handling:**
- Pass VERACODE_API_ID and VERACODE_API_KEY via docker run `-e` flags
- Credentials exist only in container memory, never written to disk
- Enabled by: `export VERACODE_API_ID="..."; export VERACODE_API_KEY="..."`

### CONTAINER_MANAGER.sh

Manage persistent Docker containers for interactive development and debugging.

**Signature:**
```bash
bash CONTAINER_MANAGER.sh {arm-cortex-m4|arm-cortex-m7|arm-cortex-a|x86-64} {start|shell|stop|rm|status|fix-permissions|bash <cmd>}
```

**Commands:**
- `start`: Create and start persistent container (named `freertos-builder-{arch}`)
- `shell`: Launch interactive bash in running container
- `bash "cmd"`: Execute command in container without entering shell
- `stop`: Stop container (retains changes)
- `rm`: Delete container (loses changes)
- `status`: Show running status
- `fix-permissions`: Correct ownership of cache directories (run once after `start`)

**Container Features:**
- Named containers persist across shell sessions
- Architecture parameter selects correct Docker image and cache directory
- Credentials passed via `-e` if environment variables are set
- `/home/builder/project` is container's working directory
- Mounts per-architecture cache for incremental builds

## Supported Architectures

### ARM Cortex-M4 (STM32H7)

**Toolchain:** `arm-none-eabi-gcc` (bare-metal)  
**Use case:** Microcontroller with STM32H7 HAL  
**Linker script:** `hal/stm32h7/STM32H743ZITx_FLASH.ld`  
**FreeRTOS port:** `FreeRTOS/Source/portable/GCC/ARM_CM4_MPU/`  
**Key flags:**
- `-mcpu=cortex-m4` (CPU selection)
- `-mfpu=fpv4-sp-d16` (floating-point unit)
- `-mthumb` (Thumb-2 instruction set)

**Build time:** First ~15 min, incremental ~2 min

### ARM Cortex-M7 (NXP i.MX)

**Toolchain:** `arm-none-eabi-gcc` (bare-metal)  
**Use case:** Industrial microcontroller with NXP MCUXpresso HAL  
**Linker script:** `hal/nxp-imx/imx_memory.ld`  
**FreeRTOS port:** `FreeRTOS/Source/portable/GCC/ARM_CM7_MPU/`  
**Key flags:**
- `-mcpu=cortex-m7` (CPU selection)
- `-mfpu=fpv5-d16` (enhanced floating-point unit)
- `-mthumb`

**Build time:** First ~15 min, incremental ~2 min  
**Note:** Cannot reuse M4 cache; M7 has different instruction set and FPU

### ARM Cortex-A (Bare-Metal)

**Toolchain:** `arm-linux-gnueabihf-gcc` (bare-metal ARM Linux)  
**Use case:** Single-board computers, testing, simulation  
**Linker script:** `hal/generic-arm/arm_memory.ld`  
**FreeRTOS port:** `FreeRTOS/Source/portable/GCC/ARM_CA/`  
**Key flags:**
- `-march=armv7-a` (ARM v7-A instruction set)
- `-mfpu=neon` (SIMD)

**Build time:** First ~15 min, incremental ~2 min

### x86-64 (Linux, Testing/CI)

**Toolchain:** `gcc` (native)  
**Use case:** CI/CD, unit testing, local development  
**Linker script:** Standard Linux ELF  
**FreeRTOS port:** `FreeRTOS/Source/portable/GCC/posix/` (simulated on Linux)  
**Key flags:**
- `-m64` (64-bit)
- `-O2` (optimization)

**Build time:** First ~5 min, incremental ~1 min  
**Note:** Uses POSIX emulation of FreeRTOS, not for embedded deployment

## Environment Variables

### Build-Time Variables

| Variable | Default | Usage |
|---|---|---|
| `FREERTOS_DIR` | `/home/builder/freertos-kernel/` | FreeRTOS kernel location |
| `HAL_DIR` | `/home/builder/hal/` | Hardware abstraction layer location |
| `CMAKE_TOOLCHAIN_FILE` | Set per-architecture | CMake cross-compiler config |
| `BOARD_TARGET` | Derived from architecture | Board-specific config |

### Veracode Scanning Variables

| Variable | Required | Usage |
|---|---|---|
| `VERACODE_API_ID` | No (optional) | Veracode account ID for upload/scan |
| `VERACODE_API_KEY` | No (optional) | Veracode account key for upload/scan |

**Security note:** Never commit API credentials. Use environment-only setup:
```bash
export VERACODE_API_ID="..."
export VERACODE_API_KEY="..."
bash BUILD_MULTI_ARCH_WITH_SAST.sh x86-64
```

## Troubleshooting

### Docker Image Not Found

**Error:** `Cannot find image freertos-builder:arm`

**Solution:** Build Docker image first
```bash
docker build -t freertos-builder:arm .
docker build --platform linux/amd64 -t freertos-builder:x86-64 -f Dockerfile.x86-64 .
```

### OOM Kill During Compilation

**Error:** `Killed (signal terminated program cc1plus)`

**Cause:** GCC cross-compiler requires significant memory (>7GB per parallel job)

**Solution:** Already handled — BUILD_MULTI_ARCH.sh sets `--memory=14g` on docker run

### Permission Denied on Cache Directory

**Error:** `permission denied: /home/builder/.freertos-cache/build-cache-arm-cortex-m4/`

**Cause:** Docker volume created with root ownership, but container runs as `builder` user

**Solution:** Run permission fix in container
```bash
bash CONTAINER_MANAGER.sh arm-cortex-m4 fix-permissions
```

Or manually:
```bash
sudo chown -R $(id -u):$(id -g) ~/.freertos-cache/
sudo chmod -R u+rwX ~/.freertos-cache/
```

### Build Fails with "Toolchain Not Found"

**Error:** `arm-none-eabi-gcc: command not found`

**Cause:** Docker image not built or toolchain not installed

**Solution:** Rebuild Docker image
```bash
docker build --no-cache -t freertos-builder:arm .
```

### CMake Configure Step Fails

**Error:** `Could not find FreeRTOS` or `Could not find HAL`

**Cause:** FindFreeRTOS.cmake or FindHAL.cmake cannot locate source

**Solution:** Verify directory structure:
```bash
ls -la freertos-kernel/Source/
ls -la hal/{board}/
```

## Performance Tuning

### Memory Usage

- **Docker memory limit:** 14GB (prevents OOM on GCC)
- **Adjust for low-memory systems:** Set `--memory=10g` in build script
- **Parallel make:** `-j$(nproc)` uses all cores; reduce with `-j2` for limited RAM

### Build Parallelism

- **Default:** `make -j$(nproc)` (one job per CPU core)
- **Reduce for lower RAM:** `make -j2`
- **Disable parallelism:** `make -j1`

### Incremental Builds

- **Fastest:** Edit only one `.c` file, recompile
- **Faster:** Touch CMakeLists.txt, forces reconfigure but reuses objects
- **Slower:** `rm -rf build/*` in container, forces full rebuild

### Download Caching

- First run downloads FreeRTOS (~10MB) and HALs (~5-20MB each)
- Subsequent runs use cached downloads
- To force re-download: `rm ~/.freertos-cache/downloads/*`

## Git Integration

### Submodule Strategy

For FreeRTOS as a submodule:
```bash
git submodule add https://github.com/FreeRTOS/FreeRTOS-Kernel freertos-kernel
git submodule update --init --recursive
```

### Vendored Strategy

For FreeRTOS as committed source:
```bash
# Extract FreeRTOS into freertos-kernel/
git add freertos-kernel/
git commit -m "Add FreeRTOS kernel v11.0.1"
```

**Trade-offs:**
- Submodule: Lighter repo, easy updates, breaks on submodule changes
- Vendored: Heavier repo, locked version, simpler onboarding

## Next Steps

1. Read **CONTAINER_USAGE.md** for manual container workflows
2. Read **SECURITY_SCANNING.md** for SAST configuration
3. Review CMake files in `cmake/toolchains/` for architecture-specific tuning
4. Examine `Dockerfile` and `Dockerfile.x86-64` for toolchain version pinning
