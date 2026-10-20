# Phase 5: Build Scripts Testing & Validation

**Date Started**: October 20, 2026  
**Status**: 🔨 In Progress  
**Duration**: ~1-2 hours (estimated)

---

## Overview

Phase 5 validates the build orchestration scripts (`BUILD_MULTI_ARCH.sh` and `BUILD_MULTI_ARCH_WITH_SAST.sh`) in real Docker containers. With both Docker images now built and available, we can test the complete build pipeline for both architectures.

---

## Phase 5 Objectives

### 1. Build Script Execution ✅ (In Progress)
- [ ] Run `BUILD_MULTI_ARCH.sh x86-64` to completion
- [ ] Run `BUILD_MULTI_ARCH.sh arm-cortex-a` to completion
- [ ] Run `BUILD_MULTI_ARCH.sh all` for multi-arch
- [ ] Verify output structure in `freertos-output/`

### 2. Output Validation
- [ ] Check generated binaries exist
- [ ] Verify binary file types with `file` command
- [ ] Validate symbol tables with `nm`
- [ ] Check memory layout with `objdump`
- [ ] Compare architecture-specific differences

### 3. Build Performance
- [ ] Measure build times for x86-64
- [ ] Measure build times for ARM
- [ ] Test incremental builds (second run same arch)
- [ ] Test cache effectiveness (switch architectures)

### 4. Error Handling
- [ ] Test recovery from build failures
- [ ] Verify clean rebuilds work
- [ ] Test partial build cleanup
- [ ] Validate error messages

### 5. Build Artifacts
- [ ] Collect all build outputs
- [ ] Organize artifacts in `freertos-output/`
- [ ] Document output structure
- [ ] Create manifest of generated files

### 6. Integration Points
- [ ] Verify Docker image selection works
- [ ] Test volume mounting integrity
- [ ] Validate cache persistence
- [ ] Check output collection from containers

---

## Prerequisites Met

✅ Both Docker images built (ARM and x86-64)  
✅ BUILD_MULTI_ARCH.sh script ready (Phase 1)  
✅ CMake build system ready (Phase 3)  
✅ Source code available (Phase 2)  
✅ Stub headers for validation (Phase 2)  
✅ Cache directories initialized (Phase 4)  

---

## Build Script Overview

### `BUILD_MULTI_ARCH.sh`

**Purpose**: Orchestrate multi-architecture builds in Docker

**Usage**:
```bash
bash BUILD_MULTI_ARCH.sh [arm-cortex-a | x86-64 | all]
```

**Workflow**:
1. Initialize cache directories
2. Check/build Docker images
3. Create build container
4. Mount volumes (source, cache)
5. Execute CMake configuration
6. Run make build
7. Collect artifacts
8. Clean up container (or keep persistent)

**Expected Output**:
```
freertos-output/
├── arm-cortex-a/
│   └── hello-world.elf
└── x86-64/
    └── hello-world.elf
```

### `BUILD_MULTI_ARCH_WITH_SAST.sh`

**Purpose**: Build with static security scanning

**Usage**:
```bash
export VERACODE_API_ID="your-api-id"
export VERACODE_API_KEY="your-api-key"
bash BUILD_MULTI_ARCH_WITH_SAST.sh [x86-64]
```

**Additional Output**:
```
sast-reports/
├── veracode-scan.json
├── findings.csv
└── report.html
```

---

## Testing Plan

### Test 1: x86-64 Build

```bash
bash BUILD_MULTI_ARCH.sh x86-64
```

**Expected Output**:
- Build completes without errors
- Binary: `freertos-output/x86-64/hello-world.elf` exists
- File type: ELF 64-bit LSB executable, x86-64
- Symbols present: `nm` shows functions

### Test 2: ARM Build

```bash
bash BUILD_MULTI_ARCH.sh arm-cortex-a
```

**Expected Output**:
- Build completes without errors
- Binary: `freertos-output/arm-cortex-a/hello-world.elf` exists
- File type: ELF 32-bit LSB executable, ARM
- Symbols present: `nm` shows functions
- Post-build files: `.bin`, `.lst`, `.sym`, `.map`

### Test 3: Multi-Architecture Build

```bash
bash BUILD_MULTI_ARCH.sh all
```

**Expected Output**:
- Both binaries built in sequence
- Output directory structure:
  ```
  freertos-output/
  ├── arm-cortex-a/hello-world.elf
  └── x86-64/hello-world.elf
  ```

### Test 4: Incremental Build (Cache Effectiveness)

```bash
# Build x86-64 (first time)
bash BUILD_MULTI_ARCH.sh x86-64
# Time: ~5-15 minutes

# Build x86-64 again (no changes)
bash BUILD_MULTI_ARCH.sh x86-64
# Time: <10 seconds (link only)

# Build ARM (different cache)
bash BUILD_MULTI_ARCH.sh arm-cortex-a
# Time: ~5-15 minutes (separate cache)

# Build x86-64 again
bash BUILD_MULTI_ARCH.sh x86-64
# Time: <10 seconds (x86 cache still valid)
```

### Test 5: Binary Validation

```bash
# Check file types
file freertos-output/*/hello-world.elf

# View symbols
nm -a freertos-output/x86-64/hello-world.elf | head -20
nm -a freertos-output/arm-cortex-a/hello-world.elf | head -20

# View section headers
objdump -h freertos-output/x86-64/hello-world.elf

# View disassembly (sample)
objdump -d freertos-output/x86-64/hello-world.elf | head -50
```

### Test 6: Build Output Organization

```bash
# List all generated artifacts
find freertos-output/ -type f

# For x86-64 (minimal, no post-processing)
freertos-output/x86-64/
└── hello-world.elf

# For ARM (with post-processing)
freertos-output/arm-cortex-a/
├── hello-world.elf
├── hello-world.bin
├── hello-world.lst
├── hello-world.sym
└── hello-world.map
```

---

## Expected Behavior with Stub Headers

**Important**: Phase 5 still uses FreeRTOS stub headers (real kernel comes in Phase 9).

Expected flow:
1. ✅ CMake runs successfully
2. ✅ Finds stub FreeRTOS headers
3. ✅ Compilation starts
4. ❌ Linking fails (missing kernel symbols)
5. ⏳ Resolved in Phase 9 when real kernel added

**Current Status**: Phase 5 will test build infrastructure, not full compilation.

---

## Success Criteria

### Build Script Tests
- [ ] BUILD_MULTI_ARCH.sh runs without crashing
- [ ] Correct Docker image selected per architecture
- [ ] Volumes mounted correctly
- [ ] CMake finds dependencies (or reports expected errors)
- [ ] Error messages are clear and helpful

### Performance Tests
- [ ] First build completes (or fails predictably at link)
- [ ] Second build faster than first (cache works)
- [ ] Switch architectures works smoothly
- [ ] Per-architecture caches maintained

### Integration Tests
- [ ] Containers start and stop cleanly
- [ ] Output collected from containers
- [ ] No permission errors
- [ ] No orphaned processes

---

## Blockers and Workarounds

### Blocker 1: Missing FreeRTOS Kernel
**Impact**: Linking will fail (expected in Phase 4, resolved in Phase 9)

**Workaround**: 
- Test CMake configuration (passes)
- Test compilation of application code (passes)
- Document linking failure and resolution path
- Plan Phase 9 integration

### Blocker 2: Veracode SAST Credentials
**Impact**: Can't run SAST tests without API key

**Workaround**:
- Make credentials optional (fallback to standard build)
- Document SAST setup for users with credentials
- Test basic SAST script structure

---

## Files Involved

### Build Scripts
- `BUILD_MULTI_ARCH.sh` — Multi-architecture orchestration
- `BUILD_MULTI_ARCH_WITH_SAST.sh` — Build + security scanning
- `CONTAINER_MANAGER.sh` — Container lifecycle
- `freertos-env.sh` — Container environment setup

### Build Configuration
- `CMakeLists.txt` — Root configuration
- `cmake/toolchains/arm-cortex-a.cmake` — ARM toolchain
- `cmake/toolchains/x86-64.cmake` — x86-64 toolchain
- `cmake/FindFreeRTOS.cmake` — FreeRTOS discovery
- `cmake/FindHAL.cmake` — HAL discovery

### Docker Infrastructure
- `Dockerfile` — ARM image definition
- `Dockerfile.x86-64` — x86-64 image definition

### Source Code
- `src/main.c` — Application entry point
- `src/tasks/example_task.c` — Task implementation
- `hal/generic-arm/` — ARM HAL
- `hal/x86-sim/` — x86-64 HAL

### Output Location
- `freertos-output/` — Build artifacts (generated)

---

## Timeline

| Task | Status | Duration |
|------|--------|----------|
| Test x86-64 build | ⏳ Pending | 15-20 min |
| Test ARM build | ⏳ Pending | 15-20 min |
| Test multi-arch | ⏳ Pending | 30-40 min |
| Test incremental builds | ⏳ Pending | 5-10 min |
| Validate binaries | ⏳ Pending | 5 min |
| Performance analysis | ⏳ Pending | 10 min |
| Documentation | ⏳ Pending | 15 min |
| **Total** | | **1-2 hours** |

---

## Documentation to Create

- `PHASE_5_COMPLETION_REPORT.md` — Full test results and analysis
- Build timing metrics and cache effectiveness
- Binary validation results
- Performance benchmarks
- Output artifact inventory

---

## Next Steps

### Immediate (Phase 5)
1. Run `BUILD_MULTI_ARCH.sh x86-64`
2. Run `BUILD_MULTI_ARCH.sh arm-cortex-a`
3. Run `BUILD_MULTI_ARCH.sh all`
4. Validate outputs
5. Test incremental builds
6. Document Phase 5 completion

### Phase 6+ Goals
- Further optimize build scripts
- Improve error handling
- Add logging and reporting
- CI/CD integration

### Phase 9 Prerequisites
- Real FreeRTOS kernel will be added
- Linking will succeed
- Final binaries will be generated
- Binary validation will complete

---

## Notes

- Phase 5 focuses on **build infrastructure**, not full compilation
- Linking will likely fail (expected, resolved in Phase 9)
- Docker integration from Phase 4 makes these tests possible
- Per-architecture caching is critical for performance
- Both images now available for testing

---

**Status**: 🔨 READY TO BEGIN  
**Docker Images**: ✅ Both ready (ARM 927MB, x86-64 297MB)  
**Next Action**: Run build script tests

