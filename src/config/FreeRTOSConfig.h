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

// Use tick hook for periodic monitoring
#define configUSE_TICK_HOOK                         0

// Use malloc failed hook
#define configUSE_MALLOC_FAILED_HOOK                1

// Use idle hook
#define configUSE_IDLE_HOOK                         0

/* ===== SYNCHRONIZATION ===== */

// Enable mutex support
#define configUSE_MUTEXES                           1

// Enable counting semaphores
#define configUSE_COUNTING_SEMAPHORES               1

// Enable binary semaphores
#define configUSE_BINARY_SEMAPHORE                  1

/* ===== DEBUGGING & ERROR CHECKING ===== */

// Stack overflow detection (1 = task end, 2 = task stack)
#define configCHECK_FOR_STACK_OVERFLOW              1

// Track task statistics
#define configGENERATE_RUN_TIME_STATS               0

// Use trace macros for debugging
#define configUSE_TRACE_FACILITY                    0

// Enable queue registry for debugging
#define configQUEUE_REGISTRY_SIZE                   8

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

/* ===== ADVANCED CONFIGURATION ===== */

// Memory allocation scheme
#define configSUPPORT_DYNAMIC_ALLOCATION            1

// Support static allocation
#define configSUPPORT_STATIC_ALLOCATION             0

// Heap allocation size
#define configAPPLICATION_ALLOCATED_HEAP            0

// Max task name length
#define configMAX_TASK_NAME_LEN                     16

// Max co-routine priority
#define configMAX_CO_ROUTINE_PRIORITIES             2

// Timer task priority
#define configTIMER_TASK_PRIORITY                   (configMAX_PRIORITIES - 1)

// Timer task stack size
#define configTIMER_TASK_STACK_DEPTH                512

// Timer task queue length
#define configTIMER_QUEUE_LENGTH                    10

// Enable timers
#define configUSE_TIMERS                            1

/* ===== ASSERTIONS ===== */

#include <stdio.h>
#include <string.h>

// Runtime assertion checks (macro definition)
#define configASSERT(x) \
    do { \
        if (!(x)) { \
            printf("ASSERT FAILED: %s:%d\n", __FILE__, __LINE__); \
            fflush(stdout); \
            taskDISABLE_INTERRUPTS(); \
            for (;;); \
        } \
    } while (0)

/* ===== FEATURE ENABLEMENT ===== */

// Enable suspended task delete
#define configUSE_TASK_NOTIFICATIONS                1

// Enable list macro wrappers
#define configUSE_LIST_DATA_INTEGRITY_CHECK_BYTES   0

// ARM MPU support (if needed)
#define configUSE_MPU_WRAPPERS                      0

#endif // FREERTOS_CONFIG_H
