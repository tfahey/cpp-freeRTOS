cmake_minimum_required(VERSION 3.15)
project(FreeRTOS_HelloWorld C ASM)

set(PROJECT_VERSION 1.0.0)
set(PROJECT_DESCRIPTION "FreeRTOS Multi-Architecture Hello World")

# ===== C LANGUAGE STANDARD =====
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wextra -Werror")

# ===== TOOLCHAIN VALIDATION =====
if(NOT CMAKE_TOOLCHAIN_FILE)
    message(FATAL_ERROR "CMAKE_TOOLCHAIN_FILE must be specified.
    Example: -DCMAKE_TOOLCHAIN_FILE=cmake/toolchains/arm-cortex-a.cmake")
endif()

message(STATUS "Toolchain: ${CMAKE_TOOLCHAIN_FILE}")

# ===== ARCHITECTURE-SPECIFIC COMPILER FLAGS =====
if(CMAKE_SYSTEM_PROCESSOR MATCHES "ARM")
    message(STATUS "Building for ARM architecture")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -march=armv7-a -mfpu=neon -mthumb")
    add_compile_definitions(__ARM_ARCH)
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64")
    message(STATUS "Building for x86-64 architecture")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -m64 -pthread")
    add_compile_definitions(__X86_64__)
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
)

set(ASM_FILES
    hal/generic-arm/startup_cortex.s
)

# ===== CREATE EXECUTABLE =====
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
    message(STATUS "Linker script: ${LINKER_SCRIPT}")
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
message(STATUS "")
message(STATUS "=== Build Configuration ===")
message(STATUS "Project: ${PROJECT_NAME} v${PROJECT_VERSION}")
message(STATUS "Processor: ${CMAKE_SYSTEM_PROCESSOR}")
message(STATUS "Compiler: ${CMAKE_C_COMPILER}")
message(STATUS "C Flags: ${CMAKE_C_FLAGS}")
message(STATUS "Executable: ${CMAKE_CURRENT_BINARY_DIR}/hello-world.elf")
message(STATUS "============================")
message(STATUS "")
