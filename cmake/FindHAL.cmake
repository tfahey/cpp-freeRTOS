# FindHAL.cmake - Hardware Abstraction Layer Discovery Module
#
# This module locates board-specific HAL sources and configures them for compilation.
#
# Variables set by this module:
#   HAL_FOUND           - True if HAL found
#   HAL_DIR             - Root directory of HAL sources
#   HAL_BOARD_PATH      - Board-specific HAL directory
#   HAL_INCLUDE_DIRS    - Include directories for HAL
#   HAL                 - Object library target for compilation

# ===== LOCATE HAL DIRECTORY =====
if(NOT HAL_DIR)
    find_path(HAL_DIR
        NAMES generic-arm x86-sim
        PATHS
            ${CMAKE_CURRENT_SOURCE_DIR}/hal
            /opt/hal
            $ENV{HAL_DIR}
        DOC "HAL root directory"
    )
endif()

if(NOT HAL_DIR)
    message(FATAL_ERROR
        "HAL directory not found.\n"
        "Please ensure hal/ exists in the project root, or set HAL_DIR.\n"
        "  -DHAL_DIR=/path/to/hal"
    )
endif()

message(STATUS "HAL root: ${HAL_DIR}")

# ===== DETERMINE BOARD TARGET =====
if(NOT HAL_BOARD_TARGET)
    message(FATAL_ERROR
        "HAL_BOARD_TARGET must be set in toolchain file.\n"
        "Example: set(HAL_BOARD_TARGET \"generic-arm\")"
    )
endif()

set(HAL_BOARD_PATH "${HAL_DIR}/${HAL_BOARD_TARGET}")

if(NOT EXISTS "${HAL_BOARD_PATH}")
    message(FATAL_ERROR
        "HAL board directory not found at ${HAL_BOARD_PATH}\n"
        "Check HAL_BOARD_TARGET setting in toolchain file."
    )
endif()

message(STATUS "HAL board: ${HAL_BOARD_TARGET}")
message(STATUS "HAL board path: ${HAL_BOARD_PATH}")

# ===== COLLECT HAL SOURCE FILES =====
file(GLOB HAL_C_SOURCES "${HAL_BOARD_PATH}/*.c")
file(GLOB HAL_ASM_SOURCES "${HAL_BOARD_PATH}/*.s")
file(GLOB HAL_HEADERS "${HAL_BOARD_PATH}/*.h")

list(APPEND HAL_SOURCES ${HAL_C_SOURCES} ${HAL_ASM_SOURCES})

message(STATUS "HAL C sources: ${HAL_C_SOURCES}")
message(STATUS "HAL ASM sources: ${HAL_ASM_SOURCES}")
message(STATUS "HAL headers: ${HAL_HEADERS}")

# ===== CREATE HAL LIBRARY OBJECT =====
add_library(HAL OBJECT ${HAL_SOURCES})

# ===== SET INCLUDE DIRECTORIES =====
target_include_directories(HAL PUBLIC
    ${HAL_DIR}
    ${HAL_BOARD_PATH}
)

# ===== BOARD-SPECIFIC COMPILER DEFINITIONS =====
if(HAL_BOARD_TARGET MATCHES "generic-arm")
    target_compile_definitions(HAL PRIVATE
        -DBOARD_GENERIC_ARM
        -DARM_CORTEX_A9
    )
    message(STATUS "Board: Generic ARM Cortex-A")

elseif(HAL_BOARD_TARGET MATCHES "x86-sim")
    target_compile_definitions(HAL PRIVATE
        -DBOARD_X86_SIM
    )
    message(STATUS "Board: x86-64 POSIX Simulation")

else()
    message(WARNING "Unknown HAL board target: ${HAL_BOARD_TARGET}")
endif()

# ===== COMPILER FLAGS FOR HAL =====
target_compile_options(HAL PRIVATE
    -Wall
    -Wextra
)

# ===== EXPORT VARIABLES FOR PARENT PROJECT =====
set(HAL_INCLUDE_DIRS
    ${HAL_DIR}
    ${HAL_BOARD_PATH}
    CACHE STRING "HAL include directories"
)

set(HAL_FOUND TRUE CACHE BOOL "HAL found")

message(STATUS "HAL configured successfully")
