# ARM Cortex-A Cross-Compilation Toolchain
# Target: Bare-metal ARM Linux (Cortex-A)

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR ARM)

# ===== COMPILER SELECTION =====
set(CMAKE_C_COMPILER arm-linux-gnueabihf-gcc)
set(CMAKE_CXX_COMPILER arm-linux-gnueabihf-g++)
set(CMAKE_ASM_COMPILER arm-linux-gnueabihf-gcc)

# Tool prefix for objcopy, objdump, nm, etc.
set(CMAKE_C_COMPILER_PREFIX arm-linux-gnueabihf-)

# ===== COMPILER FLAGS =====
# -march=armv7-a: ARM v7-A instruction set (32-bit)
# -mfpu=neon: NEON SIMD support
# -mthumb: Thumb-2 instruction set (more compact)
# -mcpu=cortex-a9: Specific CPU optimization
# -O2: Optimization level
set(CMAKE_C_FLAGS "-march=armv7-a -mfpu=neon -mthumb -mcpu=cortex-a9 -O2")
set(CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS}")
set(CMAKE_ASM_FLAGS "-march=armv7-a -mthumb -mcpu=cortex-a9")

# ===== LINKER FLAGS =====
# --gc-sections: Remove unused sections to reduce binary size
# -z relro: Read-only after relocation (security)
set(CMAKE_EXE_LINKER_FLAGS "-Wl,--gc-sections -Wl,-z,relro")

# ===== FREERTOS CONFIGURATION =====
# FreeRTOS portable port for ARM Cortex-A
set(FREERTOS_PORT_DIR "Source/portable/GCC/ARM_CA")

# ===== HAL CONFIGURATION =====
# Target board/platform
set(HAL_BOARD_TARGET generic-arm)

# ===== COMPILER CHECKS =====
# Skip compiler check for cross-compilation (can't run test executables)
set(CMAKE_C_COMPILER_WORKS TRUE)
set(CMAKE_CXX_COMPILER_WORKS TRUE)
set(CMAKE_ASM_COMPILER_WORKS TRUE)

# ===== SEARCH PATHS =====
# Don't search for programs/libraries on host system
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
