# FreeRTOS Container Usage Guide

Step-by-step instructions for manual containerized builds and interactive development using CONTAINER_MANAGER.sh.

## Overview

The CONTAINER_MANAGER.sh script manages persistent Docker containers for interactive FreeRTOS development. Unlike the automated BUILD_MULTI_ARCH.sh scripts (which create ephemeral containers), persistent containers allow:

- Interactive shell access for incremental builds
- Manual cmake configure + make workflow
- Debugging and inspection of build artifacts
- Long-running development sessions without container restart

## Prerequisites

### Host Requirements

- Docker installed and running: `docker --version` (should be 20.10+)
- At least 20GB free disk space for caches and build artifacts
- bash shell
- Basic familiarity with CMake and GNU make

### First-Time Setup

1. **Build Docker images** (once per setup):
   ```bash
   docker build -t freertos-builder:arm .
   docker build --platform linux/amd64 -t freertos-builder:x86-64 -f Dockerfile.x86-64 .
   ```

2. **Create cache directories** (automatic, but can pre-create):
   ```bash
   mkdir -p ~/.freertos-cache/{downloads,build-cache-arm-cortex-m4,build-cache-arm-cortex-m7,build-cache-x86-64}
   ```

3. **Verify Docker image availability**:
   ```bash
   docker images | grep freertos-builder
   ```

## Quick Start

### 1. Start a Container

Start a persistent container for ARM Cortex-M4 development:

```bash
bash CONTAINER_MANAGER.sh arm-cortex-m4 start
```

**Output:**
```
✅ Container 'freertos-builder-arm-cortex-m4' started successfully
   Image: freertos-builder:arm
   Cache: ~/.freertos-cache/build-cache-arm-cortex-m4/
   Working dir: /home/builder/project
```

If the container already exists and is stopped, this command restarts it. If it's running, you'll see:
```
⚠️  Container 'freertos-builder-arm-cortex-m4' is already running
```

### 2. Fix Permissions (Run Once)

After starting the container, fix cache directory ownership so the non-root `builder` user can write:

```bash
bash CONTAINER_MANAGER.sh arm-cortex-m4 fix-permissions
```

**Output:**
```
✅ Permissions fixed for container 'freertos-builder-arm-cortex-m4'
   Cache directory: ~/.freertos-cache/build-cache-arm-cortex-m4/
   Owner: builder:builder
```

**Why needed:** Docker volumes are created with root ownership by default. The `builder` user inside the container needs write access to compile objects into the cache.

### 3. Enter Container Shell

Launch an interactive bash shell in the running container:

```bash
bash CONTAINER_MANAGER.sh arm-cortex-m4 shell
```

**Output:**
```
🔷 Entering container 'freertos-builder-arm-cortex-m4'
   Type 'exit' to leave the container
builder@abc12345:/home/builder/project$
```

You're now inside the container with full access to the project directory and build environment.

### 4. Build Inside Container

Once in the container shell:

```bash
# Navigate to project root
cd /home/builder/project

# Create build directory (if not present)
mkdir -p build
cd build

# Configure CMake for ARM Cortex-M4
cmake .. -DCMAKE_TOOLCHAIN_FILE=../cmake/toolchains/arm-cortex-m4.cmake

# Build with parallelism (one job per CPU core)
make -j$(nproc)

# Or build with limited parallelism (for low-memory systems)
make -j2

# Build single target (useful for incremental work)
make hello-world.elf
```

**Expected output:**
```
-- Configuring done
-- Generating done
-- Build files have been written to: /home/builder/project/build
[  5%] Building C object CMakeFiles/hello-world.dir/src/main.c.o
[ 10%] Building C object CMakeFiles/hello-world.dir/src/tasks/example_task.c.o
...
[100%] Linking C executable hello-world.elf
[100%] Built target hello-world
```

### 5. Exit Container

Leave the container shell without stopping it:

```bash
exit
```

The container continues running in the background. You can re-enter with `shell` command anytime.

### 6. Stop and Cleanup

When finished developing, clean up:

```bash
# Stop the running container (changes preserved)
bash CONTAINER_MANAGER.sh arm-cortex-m4 stop

# Remove the container completely (if done for now)
bash CONTAINER_MANAGER.sh arm-cortex-m4 rm
```

## Typical Development Workflow

### Scenario 1: Single-Architecture Incremental Development

Editing and building for one target repeatedly:

```bash
# Session start
bash CONTAINER_MANAGER.sh arm-cortex-m4 start
bash CONTAINER_MANAGER.sh arm-cortex-m4 fix-permissions
bash CONTAINER_MANAGER.sh arm-cortex-m4 shell

# Inside container
cd /home/builder/project
mkdir -p build && cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=../cmake/toolchains/arm-cortex-m4.cmake
make

# Edit src/main.c on host (in separate terminal)
# Back in container shell:
make              # Incremental rebuild (~1-2 sec)

# Edit src/tasks/example_task.c on host
make              # Recompile only changed file (~1-2 sec)

# When satisfied
exit

# Session end
bash CONTAINER_MANAGER.sh arm-cortex-m4 stop
```

**Time breakdown:**
- Initial `cmake ..`: ~2 sec
- Initial `make`: ~30 sec (compiles kernel + HAL + app)
- Incremental `make` after editing one file: ~2 sec

### Scenario 2: Multi-Architecture Testing

Build for different architectures, testing each:

```bash
# Start M4 container
bash CONTAINER_MANAGER.sh arm-cortex-m4 start
bash CONTAINER_MANAGER.sh arm-cortex-m4 fix-permissions

# Build for M4
bash CONTAINER_MANAGER.sh arm-cortex-m4 bash "cd /home/builder/project/build && cmake .. -DCMAKE_TOOLCHAIN_FILE=../cmake/toolchains/arm-cortex-m4.cmake && make"
cp freertos-output/arm-cortex-m4/hello-world.elf /tmp/hello-m4.elf

# Stop M4 container
bash CONTAINER_MANAGER.sh arm-cortex-m4 stop

# Start M7 container (different architecture, separate cache)
bash CONTAINER_MANAGER.sh arm-cortex-m7 start
bash CONTAINER_MANAGER.sh arm-cortex-m7 fix-permissions

# Build for M7 (recompiles FreeRTOS for M7, uses different cache)
bash CONTAINER_MANAGER.sh arm-cortex-m7 bash "cd /home/builder/project/build && cmake .. -DCMAKE_TOOLCHAIN_FILE=../cmake/toolchains/arm-cortex-m7.cmake && make"
cp freertos-output/arm-cortex-m7/hello-world.elf /tmp/hello-m7.elf

# Compare binaries
file /tmp/hello-m4.elf /tmp/hello-m7.elf
```

### Scenario 3: Debugging Build Issues

Container provides full shell access for investigation:

```bash
bash CONTAINER_MANAGER.sh arm-cortex-m4 shell

# Inside container:
cd /home/builder/project/build

# Check CMake generated files
cat CMakeCache.txt | grep TOOLCHAIN

# Inspect compiler
arm-none-eabi-gcc --version

# Check FreeRTOS discovery
ls -la ../freertos-kernel/Source/

# Verbose make output
make VERBOSE=1

# Clean and rebuild (removes all objects, forces full recompile)
make clean
make -j$(nproc)

# Inspect generated binaries
arm-none-eabi-objdump -h hello-world.elf   # Show sections
arm-none-eabi-nm hello-world.elf           # Show symbols

exit
```

### Scenario 4: Running Commands Without Shell

Execute build commands without entering interactive shell:

```bash
# Build without entering shell
bash CONTAINER_MANAGER.sh arm-cortex-m4 bash "cd build && make -j4"

# Run tests
bash CONTAINER_MANAGER.sh x86-64 bash "cd build && make test"

# Generate assembly listing
bash CONTAINER_MANAGER.sh arm-cortex-m4 bash "arm-none-eabi-objdump -S build/hello-world.elf > /tmp/disasm.txt"

# Copy disassembly to host
cat /tmp/disasm.txt
```

## Container Management Commands

### start

**Create and start a persistent container**

```bash
bash CONTAINER_MANAGER.sh {arch} start
```

**Example:**
```bash
bash CONTAINER_MANAGER.sh arm-cortex-m4 start
bash CONTAINER_MANAGER.sh x86-64 start
```

**Behavior:**
- If container doesn't exist: creates it
- If container exists but is stopped: starts it
- If container is running: prints status (no action)

### shell

**Launch interactive bash shell in running container**

```bash
bash CONTAINER_MANAGER.sh {arch} shell
```

**Example:**
```bash
bash CONTAINER_MANAGER.sh arm-cortex-m4 shell
```

**Requirements:** Container must be running (use `start` first if needed)

### bash

**Execute command in container without shell interaction**

```bash
bash CONTAINER_MANAGER.sh {arch} bash "{command}"
```

**Examples:**
```bash
# Single command
bash CONTAINER_MANAGER.sh arm-cortex-m4 bash "ls -la"

# Multi-command (use && to chain)
bash CONTAINER_MANAGER.sh arm-cortex-m4 bash "cd build && make -j4 && echo 'Build complete'"

# Command with pipes
bash CONTAINER_MANAGER.sh arm-cortex-m4 bash "find . -name '*.o' | wc -l"
```

### stop

**Stop running container (preserves state and changes)**

```bash
bash CONTAINER_MANAGER.sh {arch} stop
```

**Example:**
```bash
bash CONTAINER_MANAGER.sh arm-cortex-m4 stop
```

**Effect:** Container stops but is not deleted. Restart with `start` command.

### rm

**Delete container completely (removes all changes)**

```bash
bash CONTAINER_MANAGER.sh {arch} rm
```

**Example:**
```bash
bash CONTAINER_MANAGER.sh arm-cortex-m4 rm
```

**⚠️ Warning:** This deletes the container but NOT the cached build artifacts in `~/.freertos-cache/build-cache-{arch}/`. Those persist across container lifecycles.

### status

**Check if container is running**

```bash
bash CONTAINER_MANAGER.sh {arch} status
```

**Example:**
```bash
bash CONTAINER_MANAGER.sh arm-cortex-m4 status
```

**Output:** `running` or `stopped`

### fix-permissions

**Fix cache directory ownership for non-root user**

```bash
bash CONTAINER_MANAGER.sh {arch} fix-permissions
```

**Example:**
```bash
bash CONTAINER_MANAGER.sh arm-cortex-m4 fix-permissions
```

**When needed:** Run once after `start`, or if you get permission errors during builds.

## Environment Variables

### Container Environment (Inside Container)

These variables are automatically set inside the container:

| Variable | Value | Purpose |
|---|---|---|
| `FREERTOS_DIR` | `/home/builder/freertos-kernel/` | FreeRTOS kernel location |
| `HAL_DIR` | `/home/builder/hal/` | Hardware abstraction layer |
| `PATH` | Includes toolchain bin | Compiler in PATH |

### Host Environment (Before Calling CONTAINER_MANAGER.sh)

You can set these on the host before invoking container commands:

```bash
# Veracode credentials (optional, for SAST scanning)
export VERACODE_API_ID="your-id"
export VERACODE_API_KEY="your-key"

# CONTAINER_MANAGER.sh will pass them to container via -e flags
bash CONTAINER_MANAGER.sh x86-64 shell
```

Inside the container, the credentials will be available:
```bash
# Inside container shell
echo $VERACODE_API_ID    # Shows your-id
echo $VERACODE_API_KEY   # Shows your-key
```

## Troubleshooting

### Container Won't Start

**Error:** `Error response from daemon: No such image: freertos-builder:arm`

**Solution:** Build Docker image first
```bash
docker build -t freertos-builder:arm .
```

### Permission Denied Errors

**Error:** `Permission denied: /home/builder/.freertos-cache/build-cache-arm-cortex-m4/`

**Cause:** Docker volume has root ownership

**Solution:** Run fix-permissions
```bash
bash CONTAINER_MANAGER.sh arm-cortex-m4 fix-permissions
```

### Container is Stuck

**Symptom:** Container started but won't respond to commands

**Solution:** Force remove and restart
```bash
docker rm -f freertos-builder-arm-cortex-m4
bash CONTAINER_MANAGER.sh arm-cortex-m4 start
bash CONTAINER_MANAGER.sh arm-cortex-m4 fix-permissions
```

### CMake: Could Not Find FreeRTOS

**Error:** `Could not find FreeRTOS`

**Cause:** FreeRTOS kernel not in expected location

**Solution:** Verify inside container
```bash
bash CONTAINER_MANAGER.sh arm-cortex-m4 shell
ls -la freertos-kernel/Source/
ls -la cmake/FindFreeRTOS.cmake
```

### Build is Slow

**Scenario:** First build is slow (expected), but incremental builds are also slow

**Cause:** Build cache may be on slow storage, or make is not caching properly

**Solutions:**
```bash
# Check cache location
bash CONTAINER_MANAGER.sh arm-cortex-m4 bash "df ~/.freertos-cache/build-cache-arm-cortex-m4/"

# Check for stale objects
bash CONTAINER_MANAGER.sh arm-cortex-m4 bash "find build -name '*.o' -type f -mtime +7"

# Clean and rebuild if suspects objects are corrupted
bash CONTAINER_MANAGER.sh arm-cortex-m4 shell
cd build
rm -rf *
cmake ..
make
```

### Out of Memory (OOM) Kill

**Error:** `Killed (signal terminated program cc1plus)`

**Cause:** Container hit memory limit during parallel compilation

**Solution:** Reduce parallelism
```bash
bash CONTAINER_MANAGER.sh arm-cortex-m4 shell
cd build
make -j2    # Reduce to 2 jobs instead of all cores
```

## Advanced Usage

### Inspecting Container Internals

```bash
# List all containers
docker ps -a | grep freertos-builder

# View container logs
docker logs freertos-builder-arm-cortex-m4

# Inspect container configuration
docker inspect freertos-builder-arm-cortex-m4

# View running processes inside container
docker top freertos-builder-arm-cortex-m4
```

### Copying Files Between Host and Container

```bash
# Copy file FROM host TO container
docker cp /tmp/myconfig.h freertos-builder-arm-cortex-m4:/home/builder/project/src/

# Copy file FROM container TO host
docker cp freertos-builder-arm-cortex-m4:/home/builder/project/build/hello-world.elf /tmp/

# Verify copy succeeded
ls -la /tmp/hello-world.elf
```

### Mounting Additional Volumes

For advanced use, manually add volumes to container. Example: mount a USB device for testing:

```bash
docker run -d --name freertos-builder-arm-cortex-m4 \
  -v ~/.freertos-cache/downloads:/home/builder/.freertos-cache/downloads:ro \
  -v ~/.freertos-cache/build-cache-arm-cortex-m4:/home/builder/build \
  -v /dev/ttyUSB0:/dev/ttyUSB0 \  # Serial port
  -v /Volumes/JTAG:/mnt/jtag:ro \  # JTAG device mount
  -w /home/builder/project \
  freertos-builder:arm
```

### Running Tests in Container

```bash
# If you have unit tests that run in x86-64 simulator
bash CONTAINER_MANAGER.sh x86-64 start
bash CONTAINER_MANAGER.sh x86-64 fix-permissions

bash CONTAINER_MANAGER.sh x86-64 shell
cd build
make test         # Run test suite
ctest --output-on-failure
```

## Performance Tips

### Incremental Builds Are Key

Instead of rebuilding everything:
```bash
# ❌ Slow: Full rebuild
make clean
make -j$(nproc)

# ✅ Fast: Incremental rebuild
make -j$(nproc)  # Only recompiles changed files
```

### Keep Container Running Between Sessions

```bash
# Don't do this repeatedly:
bash CONTAINER_MANAGER.sh arm-cortex-m4 start
bash CONTAINER_MANAGER.sh arm-cortex-m4 shell
bash CONTAINER_MANAGER.sh arm-cortex-m4 stop

# Instead:
bash CONTAINER_MANAGER.sh arm-cortex-m4 start    # One time
bash CONTAINER_MANAGER.sh arm-cortex-m4 shell    # Each dev session
# ... work ...
exit
# Container stays running for next session
bash CONTAINER_MANAGER.sh arm-cortex-m4 shell    # Restart shell, container still running
```

### Parallel Make with Core Count

```bash
# Inside container:
nproc                 # Shows available cores
make -j$(nproc)       # Use all cores (default)
make -j2              # If you need to limit to 2 cores
make -j1              # Fully sequential (for debugging)
```

## Next Steps

1. Review **BUILD_INFRASTRUCTURE.md** for deep technical details
2. Read **SECURITY_SCANNING.md** for SAST configuration
3. Check **README.md** for automated build workflows (BUILD_MULTI_ARCH.sh)
