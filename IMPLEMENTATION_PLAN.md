# FreeRTOS Multi-Architecture "Hello World" Implementation Plan

**Date Created**: October 15, 2026  
**Project**: FreeRTOS Multi-Architecture Build System  
**Scope**: Simple "hello world" application for arm64 and x86-64 Linux targets  
**Estimated Duration**: 4-5 weeks (sequential, single developer)

---

## Executive Summary

This document outlines the step-by-step implementation of a production-grade FreeRTOS "hello world" application with support for both arm64 (Cortex-A Linux target) and x86-64 architectures. The project will be containerized using Docker for reproducible builds, use CMake for cross-platform configuration, implement per-architecture build caching, and integrate Veracode SAST scanning for security analysis.

### Key Objectives

1. Create a simple FreeRTOS application that demonstrates multi-task programming
2. Containerize the build environment for reproducibility across machines
3. Implement efficient build caching to minimize rebuild time when switching architectures
4. Support both arm64 (Cortex-A, Linux target) and x86-64 (testing/CI)
5. Integrate security scanning (Veracode SAST) for vulnerability detection
6. Provide interactive development workflows via persistent containers

### Success Criteria

- Multi-architecture builds complete successfully for both arm-cortex-a and x86-64
- Build caching functional: second build completes in < 5 minutes
- Docker containers operational with interactive shell access
- SAST scanning integrated and operational on x86-64
- Output binaries verified with correct architecture via `file` command
- Comprehensive documentation for developers and operators

---

## Phase 1: Foundation & Project Structure (Week 1)

### 1.1 Objective

Create all necessary directories and establish the baseline file organization that supports multi-architecture builds with caching and SAST integration.

### 1.2 Initialize Repository Structure

#### 1.2.1 Core Source Directory Structure

Create `src/` with the following subdirectories and files:

```
src/
├── main.c                          # FreeRTOS application entry point
├── config/
│   └── FreeRTOSConfig.h            # FreeRTOS kernel tuning parameters
├── tasks/
│   ├── example_task.c              # Multi-task implementation
│   └── example_task.h              # Task declarations
└── drivers/
    ├── uart.c                      # UART HAL wrapper (placeholder)
    ├── gpio.c                      # GPIO HAL wrapper (placeholder)
    └── uart.h                      # UART headers
```

#### 1.2.2 CMake Build Infrastructure

Create `cmake/` with cross-compilation configuration:

```
cmake/
├── CMakeLists.txt                  # Root CMake configuration (in project root)
├── toolchains/
│   ├── arm-cortex-a.cmake          # ARM Cortex-A cross-compiler config
│   └── x86-64.cmake                # x86-64 native compiler config
├── FindFreeRTOS.cmake              # FreeRTOS discovery module
└── FindHAL.cmake                   # HAL discovery module
```

#### 1.2.3 Hardware Abstraction Layer (HAL)

Create `hal/` for board-specific code:

```
hal/
├── generic-arm/                    # Generic bare-metal ARM (Cortex-A target)
│   ├── arm_cortex.c                # ARM initialization
│   ├── startup_cortex.s            # Startup assembly (Thumb-2)
│   └── arm_memory.ld               # Linker script for ARM memory layout
└── x86-sim/                        # x86-64 POSIX simulation (optional)
    └── x86_sim.c                   # POSIX simulation stubs
```

#### 1.2.4 FreeRTOS Integration

Create `freertos-kernel/` placeholder:

```
freertos-kernel/
└── .gitkeep                        # Placeholder; will hold FreeRTOS source
```

**Note**: FreeRTOS will be populated in Phase 9 either as:
- **Vendored**: Entire FreeRTOS directory committed to repo
- **Git Submodule**: FreeRTOS as external dependency (recommended)

#### 1.2.5 Docker Infrastructure

Create Docker containerization files in project root:

```
├── Dockerfile                      # Base image with ARM toolchains
├── Dockerfile.x86-64               # x86-64 variant for testing + Veracode CLI
└── freertos-env.sh                 # Environment setup script for containers
```

#### 1.2.6 Build Automation Scripts

Create build orchestration scripts in project root:

```
├── BUILD_MULTI_ARCH.sh             # Multi-architecture build script
├── BUILD_MULTI_ARCH_WITH_SAST.sh   # Build + SAST scanning script
└── CONTAINER_MANAGER.sh            # Persistent container lifecycle management
```

#### 1.2.7 Generated Output Directories

Create `.gitignore` entries for generated directories:

```
# Build artifacts
freertos-output/
build/
*.elf
*.bin
*.map
*.lst

# Build caches (user's home)
.freertos-cache/

# Preprocessed source (SAST)
preprocessed-src/
*.i
*.ii

# Veracode packaging
veracode-package/

# Security reports
sast-reports/

# IDE and build tools
CMakeCache.txt
CMakeFiles/
cmake_install.cmake
Makefile
```

### 1.3 Deliverables for Phase 1

- Complete directory skeleton with all subdirectories created
- Empty placeholder files for source code and CMake modules
- `.gitignore` configured for build artifacts and caches
- **Total files created**: ~15-20 placeholder/configuration files

---

## Phase 2: Source Code Implementation (Week 1.5)

### 2.1 Objective

Implement the FreeRTOS application code, HAL abstractions, and board-specific initialization.

### 2.2 FreeRTOS Application Code

#### 2.2.1 File: `src/main.c` (80-100 lines)

**Purpose**: Application entry point that initializes FreeRTOS and creates tasks.

**Content outline**:

```c
#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"
#include "semphr.h"

// HAL includes
#include "hal/uart.h"
#include "hal/gpio.h"

// Task includes
#include "tasks/example_task.h"

// Logging function (UART-based on ARM, stdout on x86-64)
void log_message(const char *msg) {
    #ifdef __ARM_ARCH
    vUART_SendString(msg);
    #else
    printf("%s\n", msg);
    #endif
}

// Stack overflow hook
void vApplicationStackOverflowHook(TaskHandle_t xTask, char *pcTaskName) {
    log_message("ERROR: Stack overflow detected!");
    while (1);
}

// Memory allocation failure hook
void vApplicationMallocFailedHook(void) {
    log_message("ERROR: Memory allocation failed!");
    while (1);
}

// Tick hook (optional, for heartbeat/monitoring)
void vApplicationTickHook(void) {
    // Called every tick; use sparingly to avoid overhead
}

int main(void) {
    // Initialize hardware
    #ifdef __ARM_ARCH
    vHAL_Init();
    vUART_Init(115200);
    vGPIO_Init();
    #endif
    
    log_message("FreeRTOS Hello World starting...");
    
    // Create application tasks
    xCreateExampleTasks();
    
    log_message("Starting FreeRTOS scheduler...");
    
    // Start scheduler
    vTaskStartScheduler();
    
    // Should never reach here
    log_message("ERROR: Scheduler exited!");
    while (1);
    
    return 0;
}
```

**Key considerations**:
- Conditional compilation for ARM vs. x86-64 (POSIX)
- Hardware initialization only for ARM targets
- Error hooks for stack overflow and memory failure
- Simple logging via UART (ARM) or stdout (x86-64)

---

#### 2.2.2 File: `src/config/FreeRTOSConfig.h` (60-80 lines)

**Purpose**: FreeRTOS kernel tuning configuration file.

**Content outline**:

```c
#ifndef FREERTOS_CONFIG_H
#define FREERTOS_CONFIG_H

/* ===== CORE KERNEL CONFIGURATION ===== */

// Preemptive scheduling enabled
#define configUSE_PREEMPTION                        1

// Maximum number of task priority levels
#define configMAX_PRIORITIES                        5

// Minimal stack size (words; minimum = 60 words for safety)
#define configMINIMAL_STACK_SIZE                    128

// Total heap size in bytes (32 KB for testing)
#define configTOTAL_HEAP_SIZE                       (32 * 1024)

// Tick rate in Hz (1000 Hz = 1 ms per tick)
#define configTICK_RATE_HZ                          1000

// System clock frequency (used for timing calculations)
#define configSYSTEM_CLOCK_HZ                       1000000

/* ===== SYNCHRONIZATION ===== */

// Enable mutex support
#define configUSE_MUTEXES                           1

// Enable counting semaphores
#define configUSE_COUNTING_SEMAPHORES               1

/* ===== DEBUGGING & ERROR CHECKING ===== */

// Runtime assertion checks
#define configASSERT(x)                             do { if (!(x)) { \
                                                        log_message("ASSERT FAILED: " #x); \
                                                        taskDISABLE_INTERRUPTS(); \
                                                        for(;;); \
                                                    } } while(0)

// Stack overflow detection (1 = task end, 2 = task stack)
#define configCHECK_FOR_STACK_OVERFLOW              1

// Track task statistics
#define configGENERATE_RUN_TIME_STATS               0

/* ===== TASK-SPECIFIC CONFIGURATION ===== */

// Logging task priority
#define LOGGING_TASK_PRIORITY                       2

// Logging task stack size
#define LOGGING_TASK_STACK_SIZE                     512

// Logging task period (milliseconds)
#define LOGGING_TASK_PERIOD_MS                      1000

// Example task 1 priority
#define EXAMPLE_TASK_1_PRIORITY                     1

// Example task 1 stack size
#define EXAMPLE_TASK_1_STACK_SIZE                   256

#endif // FREERTOS_CONFIG_H
```

**Key settings**:
- Preemptive scheduling for responsive task switching
- 1000 Hz tick rate (1 ms resolution)
- 32 KB heap (suitable for embedded testing)
- Mutex and semaphore support for synchronization
- Stack overflow detection enabled
- Minimal stack validation

---

#### 2.2.3 File: `src/tasks/example_task.h` (15-20 lines)

**Purpose**: Task declarations and public interface.

**Content**:

```c
#ifndef EXAMPLE_TASK_H
#define EXAMPLE_TASK_H

#include "FreeRTOS.h"
#include "task.h"

// Task function
void vExampleTask(void *pvParameters);

// Task creation function (creates all example tasks)
void xCreateExampleTasks(void);

// Task statistics structure (optional)
typedef struct {
    uint32_t task_id;
    uint32_t execution_count;
    uint32_t total_run_time_ms;
} TaskStats_t;

#endif // EXAMPLE_TASK_H
```

---

#### 2.2.4 File: `src/tasks/example_task.c` (60-80 lines)

**Purpose**: Implement multi-task application demonstrating FreeRTOS basics.

**Content outline**:

```c
#include "FreeRTOS.h"
#include "task.h"
#include "example_task.h"

// Global task statistics
static volatile uint32_t g_task_counter[3] = {0};

// Task function: logging task that runs periodically
void vExampleTask(void *pvParameters) {
    uint32_t task_id = (uint32_t)pvParameters;
    TickType_t last_wake_time = xTaskGetTickCount();
    
    while (1) {
        // Increment counter
        g_task_counter[task_id]++;
        
        // Log message (platform-specific)
        #ifdef __ARM_ARCH
        char buffer[64];
        snprintf(buffer, sizeof(buffer), 
                 "Task %lu running (count=%lu)", 
                 task_id, g_task_counter[task_id]);
        log_message(buffer);
        #else
        printf("Task %lu running (count=%lu)\n", 
               task_id, g_task_counter[task_id]);
        #endif
        
        // Delay: 1000 ms (periodic task)
        vTaskDelayUntil(&last_wake_time, pdMS_TO_TICKS(1000));
    }
}

// Create all example tasks
void xCreateExampleTasks(void) {
    // Task 1: Low priority, logs every 1 second
    xTaskCreate(
        vExampleTask,                       // Task function
        "Task_1",                           // Task name
        EXAMPLE_TASK_1_STACK_SIZE,          // Stack size
        (void *)0,                          // Task ID as parameter
        EXAMPLE_TASK_1_PRIORITY,            // Priority (1 = low)
        NULL                                // Task handle (not needed)
    );
    
    // Task 2: Low priority, logs every 1 second
    xTaskCreate(
        vExampleTask,
        "Task_2",
        EXAMPLE_TASK_1_STACK_SIZE,
        (void *)1,
        EXAMPLE_TASK_1_PRIORITY,
        NULL
    );
    
    // Task 3: Medium priority, logs every 1 second
    xTaskCreate(
        vExampleTask,
        "Task_3",
        EXAMPLE_TASK_1_STACK_SIZE,
        (void *)2,
        LOGGING_TASK_PRIORITY,              // Priority (2 = medium)
        NULL
    );
}
```

**Key features**:
- Three example tasks at varying priorities
- Periodic task using `vTaskDelayUntil()` for consistent timing
- Task counters to track execution
- Platform-specific logging (UART on ARM, stdout on x86-64)
- Demonstrates basic task creation and priority-based scheduling

---

### 2.3 Hardware Abstraction Layer (HAL)

#### 2.3.1 File: `hal/generic-arm/arm_cortex.c` (100-150 lines)

**Purpose**: ARM-specific hardware initialization and drivers.

**Content outline**:

```c
#include <stdint.h>
#include <string.h>

// ARM generic timer base address (QEMU virt platform)
#define ARM_TIMER_BASE 0x08000000

// HAL initialization
void vHAL_Init(void) {
    // Cache initialization (minimal for simulator)
    // In real bare-metal, would enable I/D caches here
    
    // MMU initialization (stubbed for simulator)
    // Real implementation would set up page tables
    
    // Interrupt controller initialization (GIC)
    // Stubbed for simulator; real implementation configures GIC
}

// UART initialization (serial port for logging)
void vUART_Init(uint32_t baud_rate) {
    // Platform-specific UART setup
    // For QEMU virt: typically uses PL011 at 0x09000000
    // For real hardware: configure based on board
    
    // Configure baud rate, data bits, stop bits, parity
    // Enable UART
}

// Send single byte via UART
void vUART_SendByte(char byte) {
    // Platform-specific byte transmission
    // Typically: poll UART status register, write to TX FIFO
}

// Send string via UART
void vUART_SendString(const char *str) {
    while (*str) {
        vUART_SendByte(*str++);
        // Add small delay to avoid overwhelming receiver
        for (volatile int i = 0; i < 1000; i++);
    }
}

// GPIO initialization
void vGPIO_Init(void) {
    // Initialize GPIO controller
    // Enable GPIO block
    // Configure LED pins (if available)
}

// GPIO set (LED on)
void vGPIO_Set(uint32_t pin) {
    // Platform-specific GPIO set operation
}

// GPIO clear (LED off)
void vGPIO_Clear(uint32_t pin) {
    // Platform-specific GPIO clear operation
}

// Generic timer initialization (for FreeRTOS tick)
void vConfigureTickTimer(uint32_t frequency_hz) {
    // Configure ARM generic timer or board-specific timer
    // Set timer frequency to match configTICK_RATE_HZ
}

// Timer interrupt handler
void vTimerInterruptHandler(void) {
    // Acknowledge interrupt
    // Call FreeRTOS tick handler: xTaskIncrementTick()
    // Context switch if needed: vTaskSwitchContext()
}
```

**Key considerations**:
- Stubs for QEMU virt platform (commonly used for testing)
- Real implementation would configure actual hardware
- UART for logging (critical for debugging)
- GPIO for LED indicators (optional)
- Timer configuration for FreeRTOS tick generation

---

#### 2.3.2 File: `hal/generic-arm/startup_cortex.s` (60-80 lines)

**Purpose**: ARM assembly startup code and exception handlers.

**Content outline (ARM Thumb-2 assembly)**:

```asm
.syntax unified
.cpu cortex-a9
.thumb

// Vector table for ARM Cortex-A
.section .vectors, "ax"
.align 2
.global _vectors
_vectors:
    ldr pc, =_reset_handler        // Reset
    ldr pc, =_undefined_handler    // Undefined instruction
    ldr pc, =_swi_handler          // Software interrupt
    ldr pc, =_prefetch_handler     // Prefetch abort
    ldr pc, =_data_abort_handler   // Data abort
    nop                            // Reserved
    ldr pc, =_irq_handler          // IRQ
    ldr pc, =_fiq_handler          // FIQ

// Reset handler
.section .text
.align 2
.global _reset_handler
.thumb_func
_reset_handler:
    // Initialize stack pointer
    ldr sp, =_stack_top
    
    // Initialize BSS section (zero uninitialized data)
    ldr r0, =_bss_start
    ldr r1, =_bss_end
    mov r2, #0
bss_loop:
    cmp r0, r1
    strne r2, [r0], #4
    bne bss_loop
    
    // Copy data section from ROM to RAM (if needed)
    // ldr r0, =_data_start_rom
    // ldr r1, =_data_start_ram
    // ldr r2, =_data_end_ram
    // copy_loop:
    //     cmp r1, r2
    //     ldrne r3, [r0], #4
    //     strne r3, [r1], #4
    //     bne copy_loop
    
    // Call main()
    bl main
    
    // Infinite loop (should not return)
    b .

// Exception handlers (stubs)
.thumb_func
_undefined_handler:
    b .

.thumb_func
_swi_handler:
    b .

.thumb_func
_prefetch_handler:
    b .

.thumb_func
_data_abort_handler:
    b .

.thumb_func
_irq_handler:
    // Save context
    push {r0-r12, lr}
    // Call timer/interrupt handler
    bl vTimerInterruptHandler
    // Restore context
    pop {r0-r12, pc}

.thumb_func
_fiq_handler:
    b .

// Stack and heap symbols (linked by linker script)
.extern _stack_top
.extern _bss_start
.extern _bss_end
```

**Key features**:
- Minimal vector table for ARM Cortex-A
- BSS initialization (zero uninitialized data)
- Simple exception handlers (stubs for most)
- IRQ handler linked to FreeRTOS tick
- Assembly-only startup (no C runtime overhead)

---

#### 2.3.3 File: `hal/generic-arm/arm_memory.ld` (40-60 lines)

**Purpose**: Linker script defining ARM memory layout.

**Content outline**:

```linker
/* ARM Cortex-A Memory Layout (QEMU virt platform) */

MEMORY
{
    RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 256M
}

SECTIONS
{
    /* Text section (code) */
    .text :
    {
        *(.vectors)
        *(.text*)
        *(.rodata*)
    } > RAM

    /* Initialized data section */
    .data :
    {
        _data_start = .;
        *(.data*)
        _data_end = .;
    } > RAM

    /* Uninitialized data section (BSS) */
    .bss (NOLOAD) :
    {
        _bss_start = .;
        *(.bss*)
        *(COMMON)
        _bss_end = .;
    } > RAM

    /* Heap (grows upward) */
    .heap (NOLOAD) :
    {
        _heap_start = .;
        . = . + 32K;
        _heap_end = .;
    } > RAM

    /* Stack (grows downward) */
    .stack (NOLOAD) :
    {
        . = ALIGN(16);
        _stack_end = .;
        . = . + 64K;
        _stack_top = .;
    } > RAM

    /* Discard DWARF debug sections */
    /DISCARD/ :
    {
        *(.note.GNU-stack)
        *(.ARM.exidx)
        *(.ARM.extab)
    }
}
```

**Key features**:
- 256 MB RAM starting at 0x80000000 (QEMU virt memory map)
- Clear section organization (text, data, BSS, heap, stack)
- Stack grows downward, heap grows upward
- Symbol definitions for runtime use (_stack_top, _heap_start, etc.)

---

### 2.4 Deliverables for Phase 2

- **7 source files created**:
  - src/main.c (application entry point)
  - src/config/FreeRTOSConfig.h (kernel config)
  - src/tasks/example_task.h (task declarations)
  - src/tasks/example_task.c (task implementation)
  - hal/generic-arm/arm_cortex.c (ARM HAL)
  - hal/generic-arm/startup_cortex.s (ARM assembly)
  - hal/generic-arm/arm_memory.ld (linker script)

- **Total lines of code**: ~500-600 lines
- **Functionality**: Basic FreeRTOS app with multi-task scheduling, HAL abstraction, and ARM initialization

---

## Phase 3: CMake Build System (Week 2)

### 3.1 Objective

Implement CMake cross-compilation infrastructure supporting multiple architectures with automatic toolchain selection and dependency discovery.

### 3.2 Root CMakeLists.txt

#### File: `CMakeLists.txt` (120-150 lines)

**Purpose**: Main build configuration orchestrating compilation for all targets.

**Content outline**:

```cmake
cmake_minimum_required(VERSION 3.15)
project(FreeRTOS_HelloWorld C ASM)

set(PROJECT_VERSION 1.0.0)
set(PROJECT_DESCRIPTION "FreeRTOS Multi-Architecture Hello World")

# C language standard
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wextra -Werror")

# ===== TOOLCHAIN VALIDATION =====
if(NOT CMAKE_TOOLCHAIN_FILE)
    message(FATAL_ERROR "CMAKE_TOOLCHAIN_FILE must be specified. "
                        "Use: -DCMAKE_TOOLCHAIN_FILE=cmake/toolchains/arm-cortex-a.cmake")
endif()

# ===== ARCHITECTURE-SPECIFIC COMPILER FLAGS =====
if(CMAKE_SYSTEM_PROCESSOR MATCHES "ARM")
    message(STATUS "Building for ARM architecture")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -march=armv7-a -mfpu=neon -mthumb")
    add_definitions(-D__ARM_ARCH)
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64")
    message(STATUS "Building for x86-64 architecture")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -m64")
    add_definitions(-D__X86_64__)
endif()

# ===== CMAKE MODULE PATH =====
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# ===== FIND DEPENDENCIES =====
find_package(FreeRTOS REQUIRED)
find_package(HAL REQUIRED)

message(STATUS "FreeRTOS found at: ${FREERTOS_DIR}")
message(STATUS "HAL found at: ${HAL_DIR}")

# ===== SOURCE FILES =====
set(SOURCE_FILES
    src/main.c
    src/tasks/example_task.c
    src/drivers/uart.c
    src/drivers/gpio.c
)

set(ASM_FILES
    hal/generic-arm/startup_cortex.s
)

# ===== EXECUTABLE TARGET =====
add_executable(hello-world.elf
    ${SOURCE_FILES}
    ${ASM_FILES}
    $<TARGET_OBJECTS:FreeRTOS>
    $<TARGET_OBJECTS:HAL>
)

# ===== INCLUDE DIRECTORIES =====
target_include_directories(hello-world.elf PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/src/config
    ${CMAKE_CURRENT_SOURCE_DIR}/src/tasks
    ${CMAKE_CURRENT_SOURCE_DIR}/hal
    ${FREERTOS_INCLUDE_DIRS}
    ${HAL_INCLUDE_DIRS}
)

# ===== LINKER CONFIGURATION =====
if(CMAKE_SYSTEM_PROCESSOR MATCHES "ARM")
    set(LINKER_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/hal/generic-arm/arm_memory.ld")
    target_link_options(hello-world.elf PRIVATE
        -T${LINKER_SCRIPT}
        --gc-sections
        -Wl,-Map=${CMAKE_CURRENT_BINARY_DIR}/hello-world.map
    )
endif()

# ===== POST-BUILD COMMANDS (ARM only) =====
if(CMAKE_SYSTEM_PROCESSOR MATCHES "ARM")
    add_custom_command(TARGET hello-world.elf POST_BUILD
        COMMAND ${CMAKE_C_COMPILER_PREFIX}objcopy -O binary 
                hello-world.elf hello-world.bin
        COMMAND ${CMAKE_C_COMPILER_PREFIX}objdump -S hello-world.elf > hello-world.lst
        COMMAND ${CMAKE_C_COMPILER_PREFIX}nm hello-world.elf > hello-world.sym
        COMMENT "Generating binary, listing, and symbol files"
    )
endif()

# ===== BUILD SUMMARY =====
message(STATUS "=== Build Configuration ===")
message(STATUS "Processor: ${CMAKE_SYSTEM_PROCESSOR}")
message(STATUS "Compiler: ${CMAKE_C_COMPILER}")
message(STATUS "C Flags: ${CMAKE_C_FLAGS}")
message(STATUS "Executable: ${CMAKE_CURRENT_BINARY_DIR}/hello-world.elf")
```

**Key features**:
- Enforces toolchain file requirement (prevents misconfiguration)
- Architecture-specific compiler flags
- CMake module path setup for custom Find* scripts
- Object library composition (FreeRTOS + HAL)
- Linker script management for ARM targets
- Post-build binary generation and listing

---

### 3.3 Toolchain Files

#### 3.3.1 File: `cmake/toolchains/arm-cortex-a.cmake` (15-20 lines)

**Purpose**: Cross-compiler configuration for ARM Cortex-A bare-metal Linux target.

**Content**:

```cmake
# ARM Cortex-A Cross-Compilation Toolchain

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR ARM)

# Compiler selection
set(CMAKE_C_COMPILER arm-linux-gnueabihf-gcc)
set(CMAKE_CXX_COMPILER arm-linux-gnueabihf-g++)
set(CMAKE_ASM_COMPILER arm-linux-gnueabihf-gcc)

# Compiler prefix for tools (objcopy, objdump, nm, etc.)
set(CMAKE_C_COMPILER_PREFIX arm-linux-gnueabihf-)

# Architecture-specific flags
set(CMAKE_C_FLAGS "-march=armv7-a -mfpu=neon -mthumb -mcpu=cortex-a9 -O2")
set(CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS}")
set(CMAKE_ASM_FLAGS "-march=armv7-a -mthumb -mcpu=cortex-a9")

# Linker flags
set(CMAKE_EXE_LINKER_FLAGS "-Wl,--gc-sections -Wl,-z,relro")

# FreeRTOS port selection
set(FREERTOS_PORT_DIR "Source/portable/GCC/ARM_CA")

# HAL board target
set(HAL_BOARD_TARGET generic-arm)

# Skip compiler check (cross-compilation doesn't run test executables)
set(CMAKE_C_COMPILER_WORKS TRUE)

# Prevent CMake from trying to run test programs
set(CMAKE_SYSTEM_NAME Generic)
```

**Key settings**:
- `arm-linux-gnueabihf-gcc`: ARMv7-A hard-float toolchain
- `-march=armv7-a`: ARM v7-A instruction set
- `-mfpu=neon`: NEON SIMD support
- `-mthumb`: Thumb-2 instruction set (more compact)
- FreeRTOS port: `ARM_CA` (Cortex-A)
- HAL target: `generic-arm`

---

#### 3.3.2 File: `cmake/toolchains/x86-64.cmake` (15-20 lines)

**Purpose**: Native x86-64 compiler configuration for testing/CI.

**Content**:

```cmake
# x86-64 Native Compilation Toolchain

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

# Compiler selection (native)
set(CMAKE_C_COMPILER gcc)
set(CMAKE_CXX_COMPILER g++)
set(CMAKE_ASM_COMPILER gcc)

# Compiler flags
set(CMAKE_C_FLAGS "-m64 -O2 -pthread -fPIE")
set(CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS}")

# Linker flags
set(CMAKE_EXE_LINKER_FLAGS "-pthread -pie")

# FreeRTOS port selection (POSIX simulation for testing)
set(FREERTOS_PORT_DIR "Source/portable/GCC/posix")

# HAL board target (x86 simulation)
set(HAL_BOARD_TARGET x86-sim)

# For x86-64, we run the test programs
set(CMAKE_C_COMPILER_WORKS TRUE)

# Preprocessing for SAST (optional, set by build script)
# set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -save-temps=obj")
```

**Key settings**:
- `gcc`: Native compiler
- `-m64`: 64-bit x86 compilation
- `-pthread`: Thread support (FreeRTOS POSIX port uses pthreads)
- FreeRTOS port: `posix` (POSIX simulation on Linux)
- HAL target: `x86-sim` (stub implementation)
- `-save-temps=obj`: Can be added for SAST preprocessing

---

### 3.4 CMake Modules

#### 3.4.1 File: `cmake/FindFreeRTOS.cmake` (80-100 lines)

**Purpose**: Locate and configure FreeRTOS kernel for build.

**Content outline**:

```cmake
# FindFreeRTOS.cmake - FreeRTOS Kernel Discovery Module

# If FREERTOS_DIR not set, search for it
if(NOT FREERTOS_DIR)
    find_path(FREERTOS_DIR
        NAMES Source/FreeRTOS.h
        PATHS
            ${CMAKE_CURRENT_SOURCE_DIR}/freertos-kernel
            /opt/freertos-kernel
            $ENV{FREERTOS_DIR}
        DOC "FreeRTOS kernel root directory"
    )
endif()

if(NOT FREERTOS_DIR)
    message(FATAL_ERROR "FreeRTOS kernel directory not found. "
                        "Set FREERTOS_DIR or ensure freertos-kernel/ exists.")
endif()

# Validate FreeRTOS directory structure
if(NOT EXISTS "${FREERTOS_DIR}/Source/FreeRTOS.h")
    message(FATAL_ERROR "FreeRTOS header not found at ${FREERTOS_DIR}/Source/FreeRTOS.h")
endif()

# Determine FreeRTOS port directory based on FREERTOS_PORT_DIR
if(NOT FREERTOS_PORT_DIR)
    message(FATAL_ERROR "FREERTOS_PORT_DIR must be set in toolchain file "
                        "(e.g., 'Source/portable/GCC/ARM_CA')")
endif()

set(FREERTOS_PORT_PATH "${FREERTOS_DIR}/${FREERTOS_PORT_DIR}")

if(NOT EXISTS "${FREERTOS_PORT_PATH}")
    message(FATAL_ERROR "FreeRTOS port not found at ${FREERTOS_PORT_PATH}")
endif()

# FreeRTOS source files
set(FREERTOS_SOURCES
    ${FREERTOS_DIR}/Source/croutine.c
    ${FREERTOS_DIR}/Source/event_groups.c
    ${FREERTOS_DIR}/Source/list.c
    ${FREERTOS_DIR}/Source/queue.c
    ${FREERTOS_DIR}/Source/stream_buffer.c
    ${FREERTOS_DIR}/Source/tasks.c
    ${FREERTOS_DIR}/Source/timers.c
    ${FREERTOS_DIR}/Source/portable/MemMang/heap_4.c
)

# Port-specific sources
file(GLOB FREERTOS_PORT_SOURCES "${FREERTOS_PORT_PATH}/*.c")
file(GLOB FREERTOS_PORT_ASM "${FREERTOS_PORT_PATH}/*.s")

list(APPEND FREERTOS_SOURCES ${FREERTOS_PORT_SOURCES} ${FREERTOS_PORT_ASM})

# Create FreeRTOS library object
add_library(FreeRTOS OBJECT ${FREERTOS_SOURCES})

# Set include directories
target_include_directories(FreeRTOS PUBLIC
    ${FREERTOS_DIR}/Source/include
    ${FREERTOS_PORT_PATH}
)

# Compiler flags for FreeRTOS
target_compile_options(FreeRTOS PRIVATE -Wall -Wextra)

# Export variables
set(FREERTOS_INCLUDE_DIRS
    ${FREERTOS_DIR}/Source/include
    ${FREERTOS_PORT_PATH}
    CACHE STRING "FreeRTOS include directories"
)

set(FREERTOS_FOUND TRUE CACHE BOOL "FreeRTOS found")

message(STATUS "FreeRTOS kernel: ${FREERTOS_DIR}")
message(STATUS "FreeRTOS port: ${FREERTOS_PORT_PATH}")
```

**Key functionality**:
- Search for FreeRTOS kernel directory
- Validate directory structure
- Compile core FreeRTOS sources + port-specific code
- Export include directories
- Set compiler flags

---

#### 3.4.2 File: `cmake/FindHAL.cmake` (80-100 lines)

**Purpose**: Locate and configure board-specific HAL.

**Content outline**:

```cmake
# FindHAL.cmake - Hardware Abstraction Layer Discovery Module

# If HAL_DIR not set, search for it
if(NOT HAL_DIR)
    find_path(HAL_DIR
        NAMES generic-arm
        PATHS
            ${CMAKE_CURRENT_SOURCE_DIR}/hal
            /opt/hal
            $ENV{HAL_DIR}
        DOC "HAL root directory"
    )
endif()

if(NOT HAL_DIR)
    message(FATAL_ERROR "HAL directory not found. "
                        "Set HAL_DIR or ensure hal/ exists.")
endif()

# Determine board target from toolchain
if(NOT HAL_BOARD_TARGET)
    message(FATAL_ERROR "HAL_BOARD_TARGET must be set in toolchain file "
                        "(e.g., 'generic-arm', 'x86-sim')")
endif()

set(HAL_BOARD_PATH "${HAL_DIR}/${HAL_BOARD_TARGET}")

if(NOT EXISTS "${HAL_BOARD_PATH}")
    message(FATAL_ERROR "HAL board not found at ${HAL_BOARD_PATH}")
endif()

# Collect HAL source files
file(GLOB HAL_C_SOURCES "${HAL_BOARD_PATH}/*.c")
file(GLOB HAL_ASM_SOURCES "${HAL_BOARD_PATH}/*.s")
file(GLOB HAL_HEADERS "${HAL_BOARD_PATH}/*.h")

list(APPEND HAL_SOURCES ${HAL_C_SOURCES} ${HAL_ASM_SOURCES})

# Create HAL library object
add_library(HAL OBJECT ${HAL_SOURCES})

# Set include directories
target_include_directories(HAL PUBLIC
    ${HAL_DIR}
    ${HAL_BOARD_PATH}
)

# Board-specific compiler flags
if(HAL_BOARD_TARGET MATCHES "generic-arm")
    target_compile_definitions(HAL PRIVATE
        -DBOARD_GENERIC_ARM
        -DARM_CORTEX_A9
    )
elseif(HAL_BOARD_TARGET MATCHES "x86-sim")
    target_compile_definitions(HAL PRIVATE
        -DBOARD_X86_SIM
    )
endif()

# Export variables
set(HAL_INCLUDE_DIRS
    ${HAL_DIR}
    ${HAL_BOARD_PATH}
    CACHE STRING "HAL include directories"
)

set(HAL_FOUND TRUE CACHE BOOL "HAL found")

message(STATUS "HAL root: ${HAL_DIR}")
message(STATUS "HAL board: ${HAL_BOARD_TARGET} (${HAL_BOARD_PATH})")
```

**Key functionality**:
- Discover HAL board directory
- Collect C and assembly sources
- Create object library
- Set board-specific compiler definitions
- Export include directories

---

### 3.5 Deliverables for Phase 3

- **4 CMake configuration files**:
  - CMakeLists.txt (root)
  - cmake/toolchains/arm-cortex-a.cmake
  - cmake/toolchains/x86-64.cmake
  - cmake/FindFreeRTOS.cmake
  - cmake/FindHAL.cmake

- **Total lines of CMake code**: ~300-350 lines
- **Functionality**: Cross-platform build system supporting ARM and x86-64 with automatic dependency discovery

---

## Phase 4: Docker Infrastructure (Week 2.5)

### 4.1 Objective

Create Docker container images that provide isolated, reproducible build environments with all necessary toolchains.

### 4.2 Docker Images

#### 4.2.1 File: `Dockerfile` (30-40 lines)

**Purpose**: Container image with ARM cross-compilers for both Cortex-M and Cortex-A bare-metal development.

**Content**:

```dockerfile
FROM ubuntu:22.04

LABEL maintainer="FreeRTOS Build Team"
LABEL description="FreeRTOS multi-architecture build environment"

# Set non-interactive mode to avoid prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# ===== INSTALL DEPENDENCIES =====
RUN apt-get update && apt-get install -y \
    # ARM cross-compilers
    gcc-arm-none-eabi \
    gcc-arm-linux-gnueabihf \
    binutils-arm-none-eabi \
    binutils-arm-linux-gnueabihf \
    \
    # Build tools
    cmake \
    build-essential \
    make \
    autoconf \
    automake \
    libtool \
    \
    # Development utilities
    git \
    curl \
    wget \
    ca-certificates \
    \
    # Diagnostics
    file \
    gdb-arm-none-eabi \
    \
    && rm -rf /var/lib/apt/lists/*

# ===== CREATE NON-ROOT USER =====
RUN useradd -m -s /bin/bash -u 1000 builder && \
    mkdir -p /home/builder/project && \
    chown -R builder:builder /home/builder

# ===== SETUP ENVIRONMENT =====
COPY freertos-env.sh /opt/
RUN chmod +x /opt/freertos-env.sh

# Set working directory
WORKDIR /home/builder/project

# Switch to non-root user
USER builder

# ===== DEFAULT COMMAND =====
CMD ["/bin/bash"]
```

**Key features**:
- Based on Ubuntu 22.04 LTS (stable, widely supported)
- ARM cross-compilers pre-installed
- CMake and build tools included
- Non-root `builder` user (permissions isolation)
- Environment setup script ready
- GDB debugger available for troubleshooting

---

#### 4.2.2 File: `Dockerfile.x86-64` (35-45 lines)

**Purpose**: Container with native GCC and Veracode CLI for testing and SAST.

**Content**:

```dockerfile
FROM ubuntu:22.04

LABEL maintainer="FreeRTOS Build Team"
LABEL description="FreeRTOS x86-64 build and SAST scanning environment"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# ===== INSTALL DEPENDENCIES =====
RUN apt-get update && apt-get install -y \
    # Native compiler
    gcc \
    g++ \
    binutils \
    \
    # Build tools
    cmake \
    build-essential \
    make \
    autoconf \
    automake \
    libtool \
    \
    # Development utilities
    git \
    curl \
    wget \
    ca-certificates \
    \
    # SAST scanning
    jq \
    python3 \
    python3-pip \
    \
    # Diagnostics
    file \
    gdb \
    \
    && rm -rf /var/lib/apt/lists/*

# ===== INSTALL VERACODE CLI =====
RUN curl -fsS https://tools.veracode.com/veracode-cli/install | sh || true

# ===== CREATE NON-ROOT USER =====
RUN useradd -m -s /bin/bash -u 1000 builder && \
    mkdir -p /home/builder/project && \
    chown -R builder:builder /home/builder

# ===== SETUP ENVIRONMENT =====
COPY freertos-env.sh /opt/
RUN chmod +x /opt/freertos-env.sh

WORKDIR /home/builder/project

USER builder

CMD ["/bin/bash"]
```

**Key differences from base Dockerfile**:
- Native `gcc`/`g++` instead of ARM cross-compilers
- Veracode CLI installation for SAST packaging
- Python 3 for scripting support
- Otherwise identical non-root user setup

**Note**: Veracode CLI only available for x86-64 (architectural limitation)

---

### 4.3 Environment Setup Script

#### 4.3.1 File: `freertos-env.sh` (25-30 lines)

**Purpose**: Configure environment variables inside container for build process.

**Content**:

```bash
#!/bin/bash

# FreeRTOS Build Environment Setup
# Source this script inside container to configure paths and variables

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
echo "========================================="
echo "FreeRTOS Build Environment Initialized"
echo "========================================="
echo "FREERTOS_DIR:       ${FREERTOS_DIR}"
echo "HAL_DIR:            ${HAL_DIR}"
echo "FREERTOS_CACHE_DIR: ${FREERTOS_CACHE_DIR}"
echo "Parallel jobs:      ${MAKE_JOBS}"
echo "========================================="

# Enable error checking in build scripts
set -euo pipefail
```

**Key configuration**:
- Toolchain paths
- FreeRTOS and HAL locations
- Cache directory setup
- Build optimization flags
- Optional Veracode credentials (passed at runtime)
- Parallelism detection
- Error checking

---

### 4.4 Deliverables for Phase 4

- **3 Docker/environment files**:
  - Dockerfile (ARM)
  - Dockerfile.x86-64 (x86-64 + Veracode)
  - freertos-env.sh (environment setup)

- **Functionality**: Reproducible, isolated build environments for both ARM and x86-64 platforms

---

## Phase 5: Build Scripts (Week 3)

### 5.1 Objective

Create orchestration scripts that manage multi-architecture builds, caching, and container lifecycle.

### 5.2 Multi-Architecture Build Script

#### 5.2.1 File: `BUILD_MULTI_ARCH.sh` (100-120 lines)

**Purpose**: Master build script supporting all target architectures with caching strategy.

**Content outline**:

```bash
#!/bin/bash
set -e  # Exit on error

# ===== CONFIGURATION =====
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}"
CACHE_DIR="${HOME}/.freertos-cache"

# Architecture validation
VALID_ARCHS=(arm-cortex-m4 arm-cortex-m7 arm-cortex-a x86-64 all)
ARCH=${1:-all}

# ===== FUNCTIONS =====

print_usage() {
    echo "Usage: $0 {arm-cortex-m4 | arm-cortex-m7 | arm-cortex-a | x86-64 | all}"
    echo ""
    echo "Examples:"
    echo "  $0 arm-cortex-a           # Build for ARM Cortex-A"
    echo "  $0 x86-64                 # Build for x86-64"
    echo "  $0 all                    # Build all architectures"
}

validate_arch() {
    for valid_arch in "${VALID_ARCHS[@]}"; do
        if [[ "$ARCH" == "$valid_arch" ]]; then
            return 0
        fi
    done
    
    echo "ERROR: Invalid architecture: $ARCH"
    print_usage
    exit 1
}

init_cache_directories() {
    echo "Initializing cache directories..."
    mkdir -p "${CACHE_DIR}"/{downloads,build-cache-arm-cortex-m4,build-cache-arm-cortex-m7,build-cache-arm-cortex-a,build-cache-x86-64}
    chmod 755 "${CACHE_DIR}"
}

build_docker_image() {
    local dockerfile=$1
    local tag=$2
    
    echo "Building Docker image: $tag"
    
    if docker images | grep -q "^${tag%:*}.*${tag##*:}"; then
        echo "  ✓ Image $tag already exists"
    else
        echo "  Building $tag from $dockerfile..."
        docker build -t "$tag" -f "$dockerfile" "${PROJECT_DIR}" || {
            echo "ERROR: Failed to build Docker image $tag"
            return 1
        }
    fi
}

build_architecture() {
    local arch=$1
    local docker_image=$2
    local toolchain_file=$3
    local build_cache=$4
    
    echo ""
    echo "========================================="
    echo "Building for architecture: $arch"
    echo "========================================="
    echo "Docker image: $docker_image"
    echo "Toolchain: $toolchain_file"
    echo "Build cache: $build_cache"
    echo ""
    
    # Pre-create build cache with correct permissions
    mkdir -p "$build_cache"
    chmod 755 "$build_cache"
    
    # Run build inside container
    docker run --rm \
        -v "${CACHE_DIR}/downloads:/home/builder/.freertos-cache/downloads:ro" \
        -v "$build_cache:/home/builder/build" \
        -v "${PROJECT_DIR}:/home/builder/project" \
        -w /home/builder/project \
        --memory=14g \
        "$docker_image" \
        bash -c "
            source /opt/freertos-env.sh
            mkdir -p build
            cd build
            cmake .. -DCMAKE_TOOLCHAIN_FILE=${toolchain_file}
            make -j\$(nproc)
        " || {
        echo "ERROR: Build failed for $arch"
        return 1
    }
    
    # Collect output
    echo "Collecting output binaries..."
    mkdir -p "${PROJECT_DIR}/freertos-output/${arch}"
    
    # Copy main binary
    if [[ -f "${build_cache}/hello-world.elf" ]]; then
        cp "${build_cache}/hello-world.elf" "${PROJECT_DIR}/freertos-output/${arch}/"
        echo "  ✓ hello-world.elf"
    fi
    
    # Copy secondary outputs (if generated)
    [[ -f "${build_cache}/hello-world.bin" ]] && \
        cp "${build_cache}/hello-world.bin" "${PROJECT_DIR}/freertos-output/${arch}/"
    [[ -f "${build_cache}/hello-world.lst" ]] && \
        cp "${build_cache}/hello-world.lst" "${PROJECT_DIR}/freertos-output/${arch}/"
    [[ -f "${build_cache}/hello-world.map" ]] && \
        cp "${build_cache}/hello-world.map" "${PROJECT_DIR}/freertos-output/${arch}/"
    
    echo "✓ Build complete for $arch"
}

# ===== MAIN LOGIC =====

validate_arch
init_cache_directories

# Build Docker images (skip if already exist)
build_docker_image "Dockerfile" "freertos-builder:arm"
build_docker_image "Dockerfile.x86-64" "freertos-builder:x86-64"

# Execute architecture-specific builds
case "$ARCH" in
    arm-cortex-a)
        build_architecture "arm-cortex-a" "freertos-builder:arm" \
            "cmake/toolchains/arm-cortex-a.cmake" \
            "${CACHE_DIR}/build-cache-arm-cortex-a"
        ;;
    x86-64)
        build_architecture "x86-64" "freertos-builder:x86-64" \
            "cmake/toolchains/x86-64.cmake" \
            "${CACHE_DIR}/build-cache-x86-64"
        ;;
    all)
        build_architecture "arm-cortex-a" "freertos-builder:arm" \
            "cmake/toolchains/arm-cortex-a.cmake" \
            "${CACHE_DIR}/build-cache-arm-cortex-a" || true
        
        build_architecture "x86-64" "freertos-builder:x86-64" \
            "cmake/toolchains/x86-64.cmake" \
            "${CACHE_DIR}/build-cache-x86-64" || true
        ;;
esac

echo ""
echo "========================================="
echo "Build complete!"
echo "========================================="
echo "Output location: ${PROJECT_DIR}/freertos-output/"
echo ""
find "${PROJECT_DIR}/freertos-output/" -name "hello-world.elf" 2>/dev/null | while read file; do
    echo "  ✓ $file ($(file "$file" | cut -d: -f2))"
done
```

**Key features**:
- Per-architecture Docker image selection
- Persistent cache mounting (separate per architecture)
- Memory limit (14GB) to prevent OOM during GCC compilation
- Parallel make (`-j$(nproc)`)
- Error handling and validation
- Output collection to `freertos-output/{arch}/`
- Build summary with file verification

---

### 5.3 Build + SAST Integration Script

#### 5.3.1 File: `BUILD_MULTI_ARCH_WITH_SAST.sh` (80-100 lines)

**Purpose**: Orchestrate build with Veracode SAST scanning integration.

**Content outline**:

```bash
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
        -e VERACODE_API_ID \
        -e VERACODE_API_KEY \
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
            
            # Package for Veracode
            echo 'Packaging for Veracode...'
            mkdir -p ../veracode-package
            
            # Collect preprocessed source files
            find . -name '*.i' -exec cp {} ../preprocessed-src/ \; || true
            
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
```

**Key features**:
- Reuses `BUILD_MULTI_ARCH.sh` for consistency
- Enables `-save-temps=obj` for preprocessed source generation
- Conditional credential passing (Veracode)
- SAST only runs on x86-64 (CLI not available for ARM)
- Optional upload to Veracode cloud
- Graceful handling of missing Veracode CLI

---

### 5.4 Container Lifecycle Management

#### 5.4.1 File: `CONTAINER_MANAGER.sh` (150-200 lines)

**Purpose**: Manage persistent Docker containers for interactive development.

**Content outline**:

```bash
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}"
CACHE_DIR="${HOME}/.freertos-cache"

# Parse arguments
ARCH=${1:-}
COMMAND=${2:-}
CMD_ARGS=${3:-}

if [[ -z "$ARCH" ]] || [[ -z "$COMMAND" ]]; then
    echo "Usage: $0 {arch} {command} [args]"
    echo ""
    echo "Architectures: arm-cortex-m4, arm-cortex-m7, arm-cortex-a, x86-64"
    echo ""
    echo "Commands:"
    echo "  start              - Create and start persistent container"
    echo "  shell              - Launch interactive bash in running container"
    echo "  bash \"cmd\"       - Execute command in container"
    echo "  stop               - Stop running container (preserves state)"
    echo "  rm                 - Delete container (loses state)"
    echo "  status             - Check if container is running"
    echo "  fix-permissions    - Fix cache directory ownership"
    echo ""
    echo "Examples:"
    echo "  $0 arm-cortex-a start"
    echo "  $0 arm-cortex-a shell"
    echo "  $0 x86-64 bash 'cmake .. && make'"
    echo "  $0 arm-cortex-a stop"
    exit 1
fi

# Determine Docker image based on architecture
if [[ "$ARCH" == "x86-64" ]]; then
    DOCKER_IMAGE="freertos-builder:x86-64"
    BUILD_CACHE="${CACHE_DIR}/build-cache-x86-64"
else
    DOCKER_IMAGE="freertos-builder:arm"
    BUILD_CACHE="${CACHE_DIR}/build-cache-${ARCH}"
fi

CONTAINER_NAME="freertos-builder-${ARCH}"

# ===== COMMAND IMPLEMENTATIONS =====

cmd_start() {
    echo "Starting container: $CONTAINER_NAME"
    
    # Check if already running
    if docker ps | grep -q "$CONTAINER_NAME"; then
        echo "✓ Container $CONTAINER_NAME is already running"
        return 0
    fi
    
    # Check if exists but stopped
    if docker ps -a | grep -q "$CONTAINER_NAME"; then
        echo "Restarting stopped container..."
        docker start "$CONTAINER_NAME"
        echo "✓ Container restarted"
        return 0
    fi
    
    # Create new container
    echo "Creating new container..."
    mkdir -p "$BUILD_CACHE"
    chmod 755 "$BUILD_CACHE"
    
    docker run -d \
        --name "$CONTAINER_NAME" \
        --hostname "$CONTAINER_NAME" \
        -v "${CACHE_DIR}/downloads:/home/builder/.freertos-cache/downloads:ro" \
        -v "$BUILD_CACHE:/home/builder/build" \
        -v "${PROJECT_DIR}:/home/builder/project" \
        -e VERACODE_API_ID="${VERACODE_API_ID:-}" \
        -e VERACODE_API_KEY="${VERACODE_API_KEY:-}" \
        -w /home/builder/project \
        "$DOCKER_IMAGE" \
        sleep infinity
    
    echo "✓ Container started"
    echo "  Image: $DOCKER_IMAGE"
    echo "  Cache: $BUILD_CACHE"
    echo "  Project: ${PROJECT_DIR}"
}

cmd_shell() {
    echo "Entering container shell: $CONTAINER_NAME"
    echo "(type 'exit' to leave)"
    docker exec -it "$CONTAINER_NAME" bash
}

cmd_bash() {
    docker exec "$CONTAINER_NAME" bash -c "$CMD_ARGS"
}

cmd_stop() {
    echo "Stopping container: $CONTAINER_NAME"
    docker stop "$CONTAINER_NAME" || true
    echo "✓ Container stopped (changes preserved)"
}

cmd_rm() {
    echo "Removing container: $CONTAINER_NAME"
    docker rm "$CONTAINER_NAME" || true
    echo "✓ Container removed (cache directory preserved)"
}

cmd_status() {
    if docker ps | grep -q "$CONTAINER_NAME"; then
        echo "✓ $CONTAINER_NAME is running"
    elif docker ps -a | grep -q "$CONTAINER_NAME"; then
        echo "⊘ $CONTAINER_NAME is stopped"
    else
        echo "✗ $CONTAINER_NAME does not exist"
    fi
}

cmd_fix_permissions() {
    echo "Fixing cache directory permissions..."
    docker exec "$CONTAINER_NAME" \
        chown -R builder:builder ~/.freertos-cache/ || true
    docker exec "$CONTAINER_NAME" \
        chmod -R u+rwX ~/.freertos-cache/ || true
    echo "✓ Permissions fixed"
}

# ===== MAIN DISPATCH =====

case "$COMMAND" in
    start)
        cmd_start
        ;;
    shell)
        cmd_shell
        ;;
    bash)
        cmd_bash
        ;;
    stop)
        cmd_stop
        ;;
    rm)
        cmd_rm
        ;;
    status)
        cmd_status
        ;;
    fix-permissions)
        cmd_fix_permissions
        ;;
    *)
        echo "ERROR: Unknown command: $COMMAND"
        exit 1
        ;;
esac
```

**Key commands**:
- **start**: Create and start persistent container
- **shell**: Interactive bash access
- **bash**: Execute command without shell
- **stop**: Stop container (preserves state)
- **rm**: Delete container (removes changes)
- **status**: Check running state
- **fix-permissions**: Correct cache ownership

---

### 5.5 Deliverables for Phase 5

- **3 build orchestration scripts**:
  - BUILD_MULTI_ARCH.sh (multi-architecture builds)
  - BUILD_MULTI_ARCH_WITH_SAST.sh (build + SAST)
  - CONTAINER_MANAGER.sh (container lifecycle)

- **Total lines of shell code**: ~300-350 lines
- **Functionality**: Automated multi-architecture builds, caching, container management, and SAST integration

---

## Phase 6: Build Caching Strategy (Week 3)

### 6.1 Objective

Implement efficient incremental build strategy to minimize rebuild time when switching architectures.

### 6.2 Cache Directory Structure

The caching strategy maintains:

```
~/.freertos-cache/
├── downloads/                      # Shared FreeRTOS kernel and HALs (downloaded once)
│   ├── freertos-kernel.tar.gz
│   └── hal-files/
│
├── build-cache-arm-cortex-a/       # ARM Cortex-A architecture-specific objects
│   ├── CMakeCache.txt
│   ├── CMakeFiles/
│   ├── FreeRTOS/
│   │   └── kernel.a                # Compiled kernel for ARM Cortex-A
│   ├── hal/
│   │   └── arm_cortex.o            # Compiled HAL objects
│   └── src/
│       └── *.o                     # Application objects (ARM)
│
└── build-cache-x86-64/             # x86-64 architecture-specific objects
    ├── CMakeCache.txt
    ├── CMakeFiles/
    ├── FreeRTOS/
    │   └── kernel.a                # Compiled kernel for x86-64
    ├── hal/
    │   └── x86_sim.o               # Compiled HAL objects
    └── src/
        └── *.o                     # Application objects (x86-64)
```

### 6.3 Cache Volume Mounts

In `BUILD_MULTI_ARCH.sh`:

```bash
# Shared downloads (read-only): downloaded once, used by all architectures
-v "${CACHE_DIR}/downloads:/home/builder/.freertos-cache/downloads:ro"

# Per-architecture cache (read-write): separate objects per architecture
-v "$build_cache:/home/builder/build"

# Project source (read-only): same source, compiled differently
-v "${PROJECT_DIR}:/home/builder/project"
```

**Key principle**: Per-architecture isolation prevents cache invalidation when switching targets.

### 6.4 Build Performance Benchmarks

Expected timeline (validated after implementation):

| Scenario | Time | Notes |
|----------|------|-------|
| First build (any arch) | 15-20 min | Downloads FreeRTOS kernel, compiles all sources |
| Same arch, source unchanged | 2-5 min | Reuses all cached objects, linker step only |
| Same arch, edit one source file | 1-2 min | Recompile one object, relink executable |
| Switch arch (A→x86) | 5-15 min | Reuses shared downloads, recompiles for new arch |
| All architectures (first time) | 30-45 min | Sequential builds with separate caches |

### 6.5 Cache Management

**View cache usage**:
```bash
du -sh ~/.freertos-cache/
du -sh ~/.freertos-cache/build-cache-*
```

**Clear specific architecture cache** (recompile):
```bash
rm -rf ~/.freertos-cache/build-cache-x86-64/
# Next build for x86-64 will recompile everything
```

**Clear downloads** (force re-fetch):
```bash
rm -rf ~/.freertos-cache/downloads/
# Next build downloads FreeRTOS and HALs again
```

---

## Phase 7: Integration & Testing (Week 3.5-4)

### 7.1 Objective

Validate that all components work together and meet performance requirements.

### 7.2 Build Validation

Create `test-build.sh` script:

```bash
#!/bin/bash
set -e

echo "========================================="
echo "FreeRTOS Build System Validation"
echo "========================================="

# Test 1: Build for ARM Cortex-A
echo ""
echo "Test 1: Building for ARM Cortex-A..."
bash BUILD_MULTI_ARCH.sh arm-cortex-a

# Verify ARM binary architecture
ARM_BINARY="freertos-output/arm-cortex-a/hello-world.elf"
echo "  Checking $ARM_BINARY..."
if file "$ARM_BINARY" | grep -q "ARM"; then
    echo "  ✓ ARM binary verified"
else
    echo "  ✗ ERROR: ARM binary has wrong architecture"
    exit 1
fi

# Test 2: Build for x86-64
echo ""
echo "Test 2: Building for x86-64..."
bash BUILD_MULTI_ARCH.sh x86-64

# Verify x86-64 binary architecture
X86_BINARY="freertos-output/x86-64/hello-world.elf"
echo "  Checking $X86_BINARY..."
if file "$X86_BINARY" | grep -q "x86-64"; then
    echo "  ✓ x86-64 binary verified"
else
    echo "  ✗ ERROR: x86-64 binary has wrong architecture"
    exit 1
fi

# Test 3: Incremental build (should be fast)
echo ""
echo "Test 3: Testing incremental build (no source changes)..."
START_TIME=$(date +%s)
bash BUILD_MULTI_ARCH.sh x86-64
END_TIME=$(date +%s)
BUILD_TIME=$((END_TIME - START_TIME))

if (( BUILD_TIME < 300 )); then  # < 5 minutes
    echo "  ✓ Incremental build fast ($BUILD_TIME seconds)"
else
    echo "  ⚠ Incremental build slow ($BUILD_TIME seconds)"
fi

# Test 4: Container lifecycle
echo ""
echo "Test 4: Testing container lifecycle..."
bash CONTAINER_MANAGER.sh arm-cortex-a start
bash CONTAINER_MANAGER.sh arm-cortex-a fix-permissions

# Test shell access
echo "  Testing shell access..."
bash CONTAINER_MANAGER.sh arm-cortex-a bash "echo 'Container accessible' "
echo "  ✓ Container shell working"

# Test build inside container
echo "  Testing build inside container..."
bash CONTAINER_MANAGER.sh arm-cortex-a bash \
    "cd /home/builder/project && mkdir -p build && cd build && cmake .. && make" > /dev/null

echo "  ✓ Container build working"

bash CONTAINER_MANAGER.sh arm-cortex-a stop
echo "  ✓ Container lifecycle working"

# Test 5: SAST scan
echo ""
echo "Test 5: Testing SAST scan..."
if command -v docker &> /dev/null; then
    if docker images | grep -q "freertos-builder:x86-64"; then
        echo "  Running SAST for x86-64..."
        bash BUILD_MULTI_ARCH_WITH_SAST.sh x86-64 || true
        echo "  ✓ SAST scan completed"
    fi
fi

echo ""
echo "========================================="
echo "All validation tests passed!"
echo "========================================="
```

### 7.3 Expected Test Results

All tests should pass:
- ✓ ARM binary compiles and has correct architecture
- ✓ x86-64 binary compiles and has correct architecture
- ✓ Incremental build < 5 minutes
- ✓ Container creation and lifecycle working
- ✓ Interactive shell access functional
- ✓ Build inside container functional
- ✓ SAST scan runs (with or without upload)

---

## Phase 8: Documentation & Automation (Week 4-5)

### 8.1 Files to Create/Update

**New documentation**:
- `IMPLEMENTATION_NOTES.md`: Architecture decisions, known limitations, tuning guide
- `TROUBLESHOOTING.md`: Common issues and solutions
- `.github/workflows/build.yml`: GitHub Actions CI/CD (optional)

**Update existing documentation**:
- `README.md`: Quick start with concrete examples
- `BUILD_INFRASTRUCTURE.md`: Align with actual implementation
- `CONTAINER_USAGE.md`: Update with actual container details

### 8.2 CI/CD Integration (GitHub Actions)

**File: `.github/workflows/build.yml`**

```yaml
name: Build and Test

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build all architectures
        run: bash BUILD_MULTI_ARCH.sh all
      
      - name: Upload binaries
        uses: actions/upload-artifact@v3
        with:
          name: freertos-binaries
          path: freertos-output/
      
      - name: SAST scan (x86-64)
        env:
          VERACODE_API_ID: ${{ secrets.VERACODE_API_ID }}
          VERACODE_API_KEY: ${{ secrets.VERACODE_API_KEY }}
        run: bash BUILD_MULTI_ARCH_WITH_SAST.sh x86-64
        continue-on-error: true
      
      - name: Upload SAST reports
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: sast-reports
          path: sast-reports/
```

---

## Phase 9: FreeRTOS Kernel Integration (Week 4)

### 9.1 Objective

Obtain FreeRTOS kernel source and integrate with build system.

### 9.2 Integration Options

#### Option A: Vendored (Recommended for Reproducibility)

```bash
# Download FreeRTOS v11.0.1
cd /tmp
wget https://github.com/FreeRTOS/FreeRTOS-Kernel/archive/refs/tags/v11.0.1.tar.gz
tar xzf v11.0.1.tar.gz

# Copy to project
cp -r FreeRTOS-Kernel-11.0.1 /path/to/project/freertos-kernel

# Commit to git
cd /path/to/project
git add freertos-kernel/
git commit -m "Add FreeRTOS kernel v11.0.1"
```

**Advantages**:
- Complete reproducibility
- No external dependencies
- Works offline

**Disadvantages**:
- Larger repository
- Manual updates

#### Option B: Git Submodule (Recommended for Maintainability)

```bash
# Add as submodule
git submodule add https://github.com/FreeRTOS/FreeRTOS-Kernel freertos-kernel
git submodule update --init --recursive

# Commit
git commit -m "Add FreeRTOS kernel as git submodule"
```

**Advantages**:
- Easy updates
- Smaller repository
- Tracks upstream changes

**Disadvantages**:
- Requires submodule maintenance
- Breaks if upstream changes API

### 9.3 Required FreeRTOS Ports

Ensure these ports are available in `freertos-kernel/Source/portable/`:

| Port | Architecture | Use |
|------|--------------|-----|
| `GCC/ARM_CA/` | ARM Cortex-A | Target for arm-cortex-a builds |
| `GCC/posix/` | POSIX (Linux) | Target for x86-64 builds |

If missing, either:
1. Download additional ports from FreeRTOS releases
2. Implement minimal port stubs

### 9.4 Validation

After integration:

```bash
# Verify FreeRTOS structure
ls -la freertos-kernel/Source/
ls -la freertos-kernel/Source/portable/GCC/

# Rebuild to verify integration
bash BUILD_MULTI_ARCH.sh all

# Check for FreeRTOS symbols
arm-linux-gnueabihf-nm freertos-output/arm-cortex-a/hello-world.elf | grep -i freertos
```

---

## Phase 10: Complete Implementation Checklist

### File Creation Checklist

- [ ] **Phase 1: Directory Structure**
  - [ ] `src/` subdirectories created
  - [ ] `cmake/` subdirectories created
  - [ ] `hal/generic-arm/` subdirectories created
  - [ ] `freertos-kernel/` placeholder created
  - [ ] `.gitignore` configured
  - [ ] Placeholder files created

- [ ] **Phase 2: Source Code**
  - [ ] `src/main.c` (80-100 lines)
  - [ ] `src/config/FreeRTOSConfig.h` (60-80 lines)
  - [ ] `src/tasks/example_task.h` (15-20 lines)
  - [ ] `src/tasks/example_task.c` (60-80 lines)
  - [ ] `hal/generic-arm/arm_cortex.c` (100-150 lines)
  - [ ] `hal/generic-arm/startup_cortex.s` (60-80 lines)
  - [ ] `hal/generic-arm/arm_memory.ld` (40-60 lines)

- [ ] **Phase 3: CMake Configuration**
  - [ ] `CMakeLists.txt` root (120-150 lines)
  - [ ] `cmake/toolchains/arm-cortex-a.cmake` (15-20 lines)
  - [ ] `cmake/toolchains/x86-64.cmake` (15-20 lines)
  - [ ] `cmake/FindFreeRTOS.cmake` (80-100 lines)
  - [ ] `cmake/FindHAL.cmake` (80-100 lines)

- [ ] **Phase 4: Docker Infrastructure**
  - [ ] `Dockerfile` (30-40 lines)
  - [ ] `Dockerfile.x86-64` (35-45 lines)
  - [ ] `freertos-env.sh` (25-30 lines)

- [ ] **Phase 5: Build Scripts**
  - [ ] `BUILD_MULTI_ARCH.sh` (100-120 lines)
  - [ ] `BUILD_MULTI_ARCH_WITH_SAST.sh` (80-100 lines)
  - [ ] `CONTAINER_MANAGER.sh` (150-200 lines)

- [ ] **Phase 8: Documentation**
  - [ ] `IMPLEMENTATION_NOTES.md`
  - [ ] `TROUBLESHOOTING.md`
  - [ ] `.github/workflows/build.yml` (optional)

### Build Validation Checklist

- [ ] ARM Cortex-A builds successfully
- [ ] x86-64 builds successfully
- [ ] Output binaries in `freertos-output/{arch}/`
- [ ] Binary architectures verified with `file` command
- [ ] Caching functional (incremental build < 5 min)
- [ ] Docker images built and available
- [ ] CONTAINER_MANAGER.sh commands work:
  - [ ] `start` creates container
  - [ ] `shell` provides interactive access
  - [ ] `bash` executes commands
  - [ ] `stop` stops container
  - [ ] `rm` removes container
  - [ ] `fix-permissions` corrects ownership
- [ ] SAST scan runs on x86-64
- [ ] Build system handles both cached and non-cached builds
- [ ] All error cases handled gracefully

### Documentation Validation

- [ ] README.md accurate and complete
- [ ] BUILD_INFRASTRUCTURE.md matches implementation
- [ ] CONTAINER_USAGE.md reflects actual commands
- [ ] SECURITY_SCANNING.md updated with SAST details
- [ ] IMPLEMENTATION_PLAN.md (this document) current
- [ ] Code comments clear and sufficient
- [ ] Architecture decisions documented

---

## Critical Dependencies & Blockers

### Build-Time Dependencies

1. **Docker**: Must be installed and running (≥ 20.10)
   - Verify: `docker --version`
   - Install: https://docs.docker.com/install/

2. **Bash**: All scripts written in bash (≥ 4.0)
   - Verify: `bash --version`

3. **ARM Toolchain**: Automatically installed in Docker container
   - Host machine does NOT need ARM toolchain

4. **CMake**: ≥ 3.15
   - Installed in Docker container
   - Verify in container: `cmake --version`

5. **GCC**: Native compiler on build machine
   - For x86-64 builds in Docker

6. **FreeRTOS Kernel**: Must be obtained before builds
   - Phase 9 deliverable
   - ~10-20 MB download

### Known Limitations

| Limitation | Impact | Mitigation |
|-----------|--------|-----------|
| **SAST x86-64 only** | Can't scan ARM binaries directly | Preprocess ARM builds, scan with x86-64 container |
| **Memory requirements** | GCC parallel compilation needs 14GB | Docker memory limit set; reduce `-j` if low RAM |
| **Permissions management** | Docker volumes created with root ownership | `fix-permissions` command provided |
| **Cache isolation** | Objects not reusable across architectures | Per-architecture caches designed from start |
| **Veracode CLI** | Only available for x86-64 | ARM builds preprocess only; scan separately |

### Potential Issues & Resolutions

| Issue | Cause | Resolution |
|-------|-------|-----------|
| **Docker image not found** | Image not built | `docker build -t freertos-builder:arm .` |
| **Permission denied on cache** | Docker volume root ownership | `bash CONTAINER_MANAGER.sh {arch} fix-permissions` |
| **Build fails: "Toolchain not found"** | Toolchain not installed in container | Rebuild Docker image: `docker build --no-cache -t freertos-builder:arm .` |
| **CMake "Could not find FreeRTOS"** | FreeRTOS kernel path incorrect | Verify `freertos-kernel/Source/` exists |
| **OOM kill during compilation** | Insufficient memory for parallel GCC | Reduce parallelism: `make -j2` |
| **SAST "No artifacts found"** | Preprocessed files not generated | Add `-save-temps=obj` to CMake flags |

---

## Implementation Timeline

### Week 1: Foundation & Source Code
- **Day 1-2**: Phase 1 (directory structure, 2-3 hours)
- **Day 3-5**: Phase 2 (source code, 10-12 hours)
- **Deliverable**: 7 source files, project skeleton functional

### Week 2: CMake & Docker
- **Day 1-3**: Phase 3 (CMake configuration, 8-10 hours)
- **Day 4-5**: Phase 4 (Docker infrastructure, 6-8 hours)
- **Deliverable**: Cross-platform build system, containerized environments

### Week 3: Build Scripts & Integration
- **Day 1-3**: Phase 5 (build scripts, 10-12 hours)
- **Day 4**: Phase 6 (caching strategy, 4-6 hours)
- **Day 5**: Phase 7 (integration testing, 6-8 hours)
- **Deliverable**: Functional multi-architecture builds with caching

### Week 4: FreeRTOS & Documentation
- **Day 1-2**: Phase 9 (FreeRTOS integration, 4-6 hours)
- **Day 3-5**: Phase 8 (documentation & CI/CD, 10-12 hours)
- **Deliverable**: Complete, documented system with CI/CD

### Overall: 4-5 Weeks
- **Total effort**: ~90-110 hours (distributed across 4 weeks)
- **Critical path**: Phases 1 → 2 → 3 → 5 → 9
- **Parallelizable**: Phases 3 & 4 can run concurrently with Phase 2

---

## Architecture & Design Decisions

### 1. Multi-Architecture Support: arm64 (Cortex-A Linux) + x86-64

**Decision**: Implement both ARM Cortex-A (production target) and x86-64 (testing platform).

**Rationale**:
- **arm64 (Cortex-A)**: Primary production target for embedded Linux systems
- **x86-64**: Testing and CI platform (POSIX FreeRTOS emulation)
- Demonstrates scalability to additional architectures in future

**Trade-offs**:
- ✅ Realistic production scenario
- ✅ Testing infrastructure built-in
- ❌ Requires separate toolchains and Docker images
- ❌ Per-architecture caching adds complexity

**Alternatives considered**:
- Cortex-M only: Too limited for Linux target
- x86-64 only: Misses embedded deployment scenario

---

### 2. Docker Containerization vs. Native Toolchains

**Decision**: All builds run inside Docker; host system has no compilation dependencies.

**Rationale**:
- Reproducible builds across machines
- Isolated dependency versions (no system contamination)
- Easy to scale to new architectures
- CI/CD friendly (container-based deployment)

**Trade-offs**:
- ✅ Reproducibility
- ✅ Isolation
- ✅ Scalability
- ❌ Docker overhead (~1-2 min per build)
- ❌ Requires Docker installation

**Alternatives considered**:
- Native cross-compiler installation: Risk of version conflicts, system contamination
- Remote build servers: Overkill for this scope

---

### 3. CMake as Build Meta-Tool

**Decision**: Use CMake for cross-platform build configuration.

**Rationale**:
- Industry standard for embedded C projects
- Native support for cross-compilation via toolchain files
- Automatic dependency discovery
- IDE integration (VS Code, CLion)

**Trade-offs**:
- ✅ Familiar to most embedded developers
- ✅ Powerful cross-compilation support
- ✅ IDE friendly
- ❌ Learning curve for custom modules

**Alternatives considered**:
- Raw Makefiles: Too verbose for cross-compilation
- Autotools: Overkill, harder to debug
- Bazel: Overkill for single executable

---

### 4. Per-Architecture Build Caching

**Decision**: Separate build caches per architecture in `~/.freertos-cache/build-cache-{arch}/`.

**Rationale**:
- Switching architectures doesn't invalidate cache
- Object files are architecture-specific (can't be reused)
- Shared downloads directory avoids redundant downloads
- Typical build: 15-20 min (first), 2-5 min (incremental)

**Trade-offs**:
- ✅ Fast incremental builds when switching targets
- ✅ Logical separation
- ❌ Disk space (separate caches per arch)
- ❌ Cache invalidation logic more complex

**Alternatives considered**:
- Single unified cache: Cache invalidation when switching archs (slow)
- No caching: Every build from scratch (very slow)

---

### 5. Veracode SAST Integration

**Decision**: Integrate Veracode SAST with optional cloud upload.

**Rationale**:
- Static analysis catches vulnerabilities early
- Critical for embedded systems (limited patching)
- Optional cloud upload (can analyze locally)
- x86-64 only (Veracode CLI limitation)

**Trade-offs**:
- ✅ Security validation
- ✅ Automated vulnerability detection
- ✅ Optional cloud integration
- ❌ x86-64 only (not ARM)
- ❌ Requires Veracode account

**Alternatives considered**:
- Manual code review: Not scalable
- Other SAST tools: Veracode chosen for embedded systems strength

---

## Success Criteria & Acceptance

### Minimum Viable Product (MVP)

✅ **Must Have**:
1. Multi-architecture builds work (arm64 + x86-64)
2. Build caching functional (incremental builds < 5 min)
3. Docker containerization complete
4. Build scripts operational
5. Documentation comprehensive

❌ **Must Not Have**:
1. Unsupported architectures
2. Manual host dependencies
3. Flaky or non-deterministic builds

### Nice to Have

✅ **Should Have**:
1. SAST integration (Veracode)
2. CI/CD automation (GitHub Actions)
3. Interactive container workflows
4. Comprehensive documentation
5. Troubleshooting guide

### Future Enhancements

🔮 **Could Have**:
1. Additional architectures (Cortex-M4, M7)
2. Cloud build integration (AWS CodeBuild, etc.)
3. Automated testing (unit tests, integration tests)
4. Performance profiling
5. Code coverage analysis
6. Formal validation for safety-critical systems

---

## Summary

This implementation plan provides a detailed roadmap for building a production-grade FreeRTOS multi-architecture build system. The phased approach allows for iterative implementation and validation at each stage. The focus on containerization, caching, and automation ensures reproducible, scalable builds that scale to additional architectures and platforms.

**Total estimated effort**: 4-5 weeks for a single developer or 2-3 weeks for a small team.

**Key success factors**:
1. **Docker mastery**: Understand container lifecycle and volume management
2. **CMake proficiency**: Cross-compilation toolchain configuration
3. **Bash scripting**: Build orchestration and automation
4. **Git workflow**: Submodule management if chosen for FreeRTOS integration
5. **Testing discipline**: Validate at each phase before moving to next

---

**Document Version**: 1.0  
**Last Updated**: October 15, 2026  
**Status**: Ready for Implementation
