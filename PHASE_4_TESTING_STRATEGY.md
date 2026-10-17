# Phase 4: Docker Integration Testing Strategy

**Document**: Testing approach for Phase 4 Docker integration  
**Date**: October 16, 2026  
**Status**: Planning complete, Docker build in progress

---

## Overview

Phase 4 verifies integration between:
- **Phase 1**: Docker infrastructure (Dockerfiles, build scripts, container manager)
- **Phase 3**: CMake build system (toolchains, discovery modules)
- **Phase 2**: Source code (application, HAL, stubs)

---

## Testing Layers

### Layer 1: Docker Image Availability

**Objective**: Verify Docker images build successfully and are usable

**Tests**:
```bash
# Test 1.1: ARM image exists and runs
docker images | grep freertos-builder:arm
docker run --rm freertos-builder:arm bash -c "echo 'ARM image works'"

# Test 1.2: x86-64 image exists and runs  
docker images | grep freertos-builder:x86-64
docker run --rm freertos-builder:x86-64 bash -c "echo 'x86-64 image works'"
```

**Expected**: Both images appear in docker images and run successfully

### Layer 2: Build Environment

**Objective**: Verify Docker containers have required tools

**Tests**:
```bash
# Test 2.1: ARM container has toolchain
docker run --rm freertos-builder:arm \
  bash -c "arm-linux-gnueabihf-gcc --version && cmake --version"

# Test 2.2: x86-64 container has tools
docker run --rm freertos-builder:x86-64 \
  bash -c "gcc --version && cmake --version && veracode version"
```

**Expected**: All tools are present and functional

### Layer 3: Project Structure

**Objective**: Verify project files are visible in containers

**Tests**:
```bash
# Test 3.1: Source code visible
docker run --rm -v $PWD:/home/builder/project freertos-builder:arm \
  bash -c "ls -la /home/builder/project/src/ /home/builder/project/cmake/"

# Test 3.2: Cache directories visible
docker run --rm -v ~/.freertos-cache:/home/builder/.freertos-cache \
  freertos-builder:arm \
  bash -c "ls -la /home/builder/.freertos-cache/"
```

**Expected**: All directories and files visible in containers

### Layer 4: CMake Integration

**Objective**: Verify CMake configuration works inside containers

**Tests**:
```bash
# Test 4.1: x86-64 CMake configuration (no FreeRTOS needed)
docker run --rm \
  -v ~/.freertos-cache/downloads:/home/builder/.freertos-cache/downloads:ro \
  -v ~/.freertos-cache/build-cache-x86-64:/home/builder/build \
  -v $PWD:/home/builder/project \
  freertos-builder:x86-64 \
  bash -c "cd /home/builder/project && \
    mkdir -p build && cd build && \
    cmake .. -DCMAKE_TOOLCHAIN_FILE=../cmake/toolchains/x86-64.cmake"

# Test 4.2: Check CMake found stub headers
# (Will report: FreeRTOS found at freertos-kernel/, HAL found at hal/)
```

**Expected**: CMake configures successfully and finds FreeRTOS stubs and HAL

### Layer 5: Build Script Integration

**Objective**: Verify BUILD_MULTI_ARCH.sh works with Docker and CMake

**Tests**:
```bash
# Test 5.1: Build script initializes Docker
bash BUILD_MULTI_ARCH.sh x86-64 2>&1 | head -50
# Should show:
# - Docker image building (if not present)
# - Container starting
# - CMake configuration
# - Make execution

# Test 5.2: Verify output structure
ls -la freertos-output/
# Should have directory for x86-64 (even if empty due to no FreeRTOS)
```

**Expected**: Build script executes through Docker, CMake runs

### Layer 6: Container Lifecycle

**Objective**: Verify CONTAINER_MANAGER.sh works with Docker

**Tests**:
```bash
# Test 6.1: Start container
bash CONTAINER_MANAGER.sh x86-64 start
docker ps | grep freertos-builder-x86-64

# Test 6.2: Fix permissions
bash CONTAINER_MANAGER.sh x86-64 fix-permissions

# Test 6.3: Execute bash command
bash CONTAINER_MANAGER.sh x86-64 bash "echo 'Container works'"

# Test 6.4: Stop container
bash CONTAINER_MANAGER.sh x86-64 stop
docker ps | grep freertos-builder-x86-64  # Should be gone

# Test 6.5: Remove container
bash CONTAINER_MANAGER.sh x86-64 rm
```

**Expected**: All container lifecycle operations work

### Layer 7: Caching Integration

**Objective**: Verify build caching works correctly

**Tests**:
```bash
# Test 7.1: Cache structure created
ls -la ~/.freertos-cache/
# Expected: downloads/, build-cache-x86-64/, build-cache-arm-cortex-a/

# Test 7.2: Build cache mounted correctly
docker run --rm \
  -v ~/.freertos-cache/build-cache-x86-64:/home/builder/build \
  freertos-builder:x86-64 \
  bash -c "ls -la /home/builder/build"
```

**Expected**: Cache directories exist and are accessible

### Layer 8: Multi-Architecture Support

**Objective**: Verify ARM and x86-64 builds use separate caches

**Tests**:
```bash
# Test 8.1: Different toolchains for different architectures
docker run --rm freertos-builder:arm \
  bash -c "ls /home/builder/project/cmake/toolchains/arm-cortex-a.cmake"

docker run --rm freertos-builder:x86-64 \
  bash -c "ls /home/builder/project/cmake/toolchains/x86-64.cmake"

# Test 8.2: Each uses its own cache
ls ~/.freertos-cache/build-cache-*/
# Should have separate directories for ARM and x86-64
```

**Expected**: Multi-architecture structure maintained

---

## Current Limitations (Expected to Pass)

✅ Docker images build successfully  
✅ CMake runs inside containers  
✅ Toolchain files are found  
✅ Volume mounting works  
✅ Build scripts execute  
✅ Container lifecycle works  
✅ Caching structure created  

---

## Blocked by Phase 9 (FreeRTOS Integration)

❌ Full compilation (needs FreeRTOS kernel source)  
❌ Linking (needs FreeRTOS libraries)  
❌ Binary generation (needs successful link)  
❌ Performance benchmarking (needs actual builds)  

These will be tested in Phase 9 after FreeRTOS kernel is integrated.

---

## Test Execution Plan

### Quick Validation (10 minutes)
```bash
# Just verify Docker works
docker images | grep freertos-builder
docker run --rm freertos-builder:x86-64 bash -c "cmake --version"
```

### Full Integration Test (30-45 minutes)
```bash
# Run all Layer 1-8 tests in order
# Document results in PHASE_4_COMPLETION_REPORT.md
```

### Extended Test (1-2 hours, requires Phase 9)
```bash
# After FreeRTOS kernel added
bash BUILD_MULTI_ARCH.sh x86-64  # Full build with compilation
bash BUILD_MULTI_ARCH.sh all     # Both architectures
```

---

## Success Metrics

| Metric | Target | Pass Criteria |
|--------|--------|---------------|
| Docker images build | Both | 2/2 images ready |
| CMake runs in container | Both | 0 errors in configure |
| Build scripts execute | Both | Scripts run without errors |
| Container lifecycle works | x86-64 | start/stop/shell all work |
| Caching initialized | x86-64 | Directories created, mounted |
| Volume mounting works | Both | Files visible in containers |
| Compilation (Phase 9+) | Both | 0 errors in gcc/g++ |

---

## Assumptions

1. ✅ Docker is installed and daemon running
2. ✅ Sufficient disk space for images and caches
3. ✅ Network access for Ubuntu package mirrors
4. ⏳ FreeRTOS kernel will be added in Phase 9
5. ✅ Source code from Phase 2 is complete
6. ✅ CMake configuration from Phase 3 is correct

---

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| Slow Docker build | Document time, run in background |
| Docker image too large | Monitor image size, optimize if needed |
| Volume mount permissions | Use CONTAINER_MANAGER.sh fix-permissions |
| Cache corruption | Clear and rebuild if needed |
| CMake fails in container | Debug with container shell |

---

## Next Steps

1. **Monitor Docker build completion** (10-15 min)
2. **Run Layer 1-2 tests** (5 min)
3. **Run Layer 3-8 tests** (30 min)
4. **Document results** (10 min)
5. **Create PHASE_4_COMPLETION_REPORT.md** (10 min)

---

**Status**: Ready to test once Docker images build  
**Total estimated time**: 1-2 hours for full validation  
**Blocker**: Waiting for Docker image build to complete
