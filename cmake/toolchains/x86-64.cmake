# x86-64 Native Compilation Toolchain
# Target: Linux x86-64 (testing and CI)

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

# ===== COMPILER SELECTION =====
# Use native compiler (no cross-compilation)
set(CMAKE_C_COMPILER gcc)
set(CMAKE_CXX_COMPILER g++)
set(CMAKE_ASM_COMPILER gcc)

# No prefix needed for native compilation
set(CMAKE_C_COMPILER_PREFIX "")

# ===== COMPILER FLAGS =====
# -m64: 64-bit compilation
# -O2: Optimization level
# -pthread: POSIX thread support (FreeRTOS POSIX port uses pthreads)
# -fPIE: Position-independent executable (security)
set(CMAKE_C_FLAGS "-m64 -O2 -pthread -fPIE")
set(CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS}")

# ===== LINKER FLAGS =====
# -pthread: Link with pthread library
# -pie: Create position-independent executable
set(CMAKE_EXE_LINKER_FLAGS "-pthread -pie")

# ===== FREERTOS CONFIGURATION =====
# Use POSIX simulation of FreeRTOS for testing
set(FREERTOS_PORT_DIR "Source/portable/GCC/posix")

# ===== HAL CONFIGURATION =====
# x86-64 POSIX simulation target
set(HAL_BOARD_TARGET x86-sim)

# ===== COMPILER CHECKS =====
# Native compiler, tests can be executed
set(CMAKE_C_COMPILER_WORKS TRUE)
set(CMAKE_CXX_COMPILER_WORKS TRUE)
set(CMAKE_ASM_COMPILER_WORKS TRUE)

# ===== OPTIONAL: PREPROCESSING FOR SAST =====
# Uncomment to enable preprocessed source generation for static analysis
# set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -save-temps=obj")
