# FindFreeRTOS.cmake - FreeRTOS Kernel Discovery Module
#
# This module locates the FreeRTOS kernel source and configures it for compilation.
#
# Variables set by this module:
#   FREERTOS_FOUND         - True if FreeRTOS found
#   FREERTOS_DIR           - Root directory of FreeRTOS kernel
#   FREERTOS_PORT_PATH     - Platform-specific port directory
#   FREERTOS_INCLUDE_DIRS  - Include directories for FreeRTOS
#   FreeRTOS               - Object library target for compilation

# ===== LOCATE FREERTOS DIRECTORY =====
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
    message(FATAL_ERROR
        "FreeRTOS kernel directory not found.\n"
        "Please ensure freertos-kernel/ exists in the project root, or set FREERTOS_DIR.\n"
        "  -DFREERTOS_DIR=/path/to/freertos-kernel"
    )
endif()

message(STATUS "FreeRTOS kernel: ${FREERTOS_DIR}")

# ===== VALIDATE FREERTOS DIRECTORY =====
if(NOT EXISTS "${FREERTOS_DIR}/Source/FreeRTOS.h")
    message(FATAL_ERROR
        "FreeRTOS header not found at ${FREERTOS_DIR}/Source/FreeRTOS.h\n"
        "Check that FREERTOS_DIR points to a valid FreeRTOS kernel directory."
    )
endif()

# ===== DETERMINE PORTABLE PORT DIRECTORY =====
if(NOT FREERTOS_PORT_DIR)
    message(FATAL_ERROR
        "FREERTOS_PORT_DIR must be set in toolchain file.\n"
        "Example: set(FREERTOS_PORT_DIR \"Source/portable/GCC/ARM_CA\")"
    )
endif()

set(FREERTOS_PORT_PATH "${FREERTOS_DIR}/${FREERTOS_PORT_DIR}")

if(NOT EXISTS "${FREERTOS_PORT_PATH}")
    message(FATAL_ERROR
        "FreeRTOS port not found at ${FREERTOS_PORT_PATH}\n"
        "Check FREERTOS_PORT_DIR setting in toolchain file."
    )
endif()

message(STATUS "FreeRTOS port: ${FREERTOS_PORT_PATH}")

# ===== COLLECT FREERTOS SOURCE FILES =====
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

# Add port-specific C sources
file(GLOB FREERTOS_PORT_SOURCES "${FREERTOS_PORT_PATH}/*.c")
list(APPEND FREERTOS_SOURCES ${FREERTOS_PORT_SOURCES})

# Add port-specific assembly sources
file(GLOB FREERTOS_PORT_ASM "${FREERTOS_PORT_PATH}/*.s")
list(APPEND FREERTOS_SOURCES ${FREERTOS_PORT_ASM})

message(STATUS "FreeRTOS sources: ${FREERTOS_SOURCES}")

# ===== CREATE FREERTOS LIBRARY OBJECT =====
add_library(FreeRTOS OBJECT ${FREERTOS_SOURCES})

# ===== SET INCLUDE DIRECTORIES =====
target_include_directories(FreeRTOS PUBLIC
    ${FREERTOS_DIR}/Source/include
    ${FREERTOS_PORT_PATH}
)

# ===== COMPILER FLAGS FOR FREERTOS =====
target_compile_options(FreeRTOS PRIVATE
    -Wall
    -Wextra
)

# ===== EXPORT VARIABLES FOR PARENT PROJECT =====
set(FREERTOS_INCLUDE_DIRS
    ${FREERTOS_DIR}/Source/include
    ${FREERTOS_PORT_PATH}
    CACHE STRING "FreeRTOS include directories"
)

set(FREERTOS_FOUND TRUE CACHE BOOL "FreeRTOS found")

message(STATUS "FreeRTOS configured successfully")
