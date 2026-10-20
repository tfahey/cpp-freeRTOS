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

// CPU clock frequency (used for timing calculations)
#define configCPU_CLOCK_HZ                          1000000

// FreeRTOS v11 requires: either use 16-bit ticks or specify TICK_TYPE_WIDTH_IN_BITS
// Use 32-bit tick type for better performance on 32/64-bit systems
#define configTICK_TYPE_WIDTH_IN_BITS               TICK_TYPE_WIDTH_32_BITS

// Use tick hook for periodic monitoring
#define configUSE_TICK_HOOK                         0

// Use malloc failed hook
#define configUSE_MALLOC_FAILED_HOOK                0

// Use idle hook
#define configUSE_IDLE_HOOK                         0

// Idle task should yield to equal priority tasks
#define configIDLE_SHOULD_YIELD                     1

// Task name length
#define configMAX_TASK_NAME_LEN                     16

// Preemption/time slicing configuration
#define configUSE_TIME_SLICING                      0

// Port optimized task selection
#define configUSE_PORT_OPTIMISED_TASK_SELECTION     0

// Tickless idle mode
#define configUSE_TICKLESS_IDLE                     0

/* ===== SYNCHRONIZATION ===== */

// Enable mutex support
#define configUSE_MUTEXES                           1

// Enable counting semaphores
#define configUSE_COUNTING_SEMAPHORES               1

// Enable binary semaphores
#define configUSE_BINARY_SEMAPHORE                  1

// Enable event groups
#define configUSE_EVENT_GROUPS                      1

// Enable stream buffers
#define configUSE_STREAM_BUFFERS                    1

/* ===== DEBUGGING & ERROR CHECKING ===== */

// Stack overflow detection (1 = task end, 2 = task stack)
#define configCHECK_FOR_STACK_OVERFLOW              1

// Track task statistics
#define configGENERATE_RUN_TIME_STATS               0

// Use trace macros for debugging
#define configUSE_TRACE_FACILITY                    0

// Use list data integrity check bytes
#define configUSE_LIST_DATA_INTEGRITY_CHECK_BYTES   0

// Newlib reentrancy support
#define configUSE_NEWLIB_REENTRANT                  0

/* ===== APPLICATION TASK CONFIGURATION ===== */

// Logging task priority
#define LOGGING_TASK_PRIORITY                       2

// Logging task stack size
#define LOGGING_TASK_STACK_SIZE                     256

// Logging task period (milliseconds)
#define LOGGING_TASK_PERIOD_MS                      1000

// Example task 1 priority
#define EXAMPLE_TASK_1_PRIORITY                     1

// Example task 1 stack size
#define EXAMPLE_TASK_1_STACK_SIZE                   256

/* ===== MEMORY ALLOCATION ===== */

// Memory allocation scheme - dynamic allocation
#define configSUPPORT_DYNAMIC_ALLOCATION            1

// Support static allocation
#define configSUPPORT_STATIC_ALLOCATION             1

// Application allocated heap
#define configAPPLICATION_ALLOCATED_HEAP            0

// Stack allocation from separate heap
#define configSTACK_ALLOCATION_FROM_SEPARATE_HEAP   0

// Enable heap protector for bounds checking
#define configENABLE_HEAP_PROTECTOR                 0

// Clear memory on free
#define configHEAP_CLEAR_MEMORY_ON_FREE             1

// Stats buffer max length
#define configSTATS_BUFFER_MAX_LENGTH               0xFFFF

/* ===== TIMERS AND SOFTWARE TIMERS ===== */

// Enable software timers
#define configUSE_TIMERS                            1

// Timer task priority
#define configTIMER_TASK_PRIORITY                   (configMAX_PRIORITIES - 1)

// Timer task stack size (in words)
#define configTIMER_TASK_STACK_DEPTH                256

// Timer task queue length
#define configTIMER_QUEUE_LENGTH                    10

/* ===== ADVANCED KERNEL CONFIGURATION ===== */

// Task notification array entries
#define configTASK_NOTIFICATION_ARRAY_ENTRIES       1

// Queue registry size (for debugger support)
#define configQUEUE_REGISTRY_SIZE                   0

// Enable backward compatibility
#define configENABLE_BACKWARD_COMPATIBILITY         0

// Max co-routine priority
#define configMAX_CO_ROUTINE_PRIORITIES             2

// Number of thread local storage pointers per task
#define configNUM_THREAD_LOCAL_STORAGE_POINTERS     0

// Use mini list item optimization
#define configUSE_MINI_LIST_ITEM                    1

// Stack depth type
#define configSTACK_DEPTH_TYPE                      size_t

// Message buffer length type
#define configMESSAGE_BUFFER_LENGTH_TYPE            size_t

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

/* ===== HOOK AND CALLBACK FUNCTIONS ===== */

// Enable idle hook
#define configUSE_IDLE_HOOK                         0

// Enable tick hook
#define configUSE_TICK_HOOK                         0

// Enable malloc failed hook
#define configUSE_MALLOC_FAILED_HOOK                0

// Enable daemon task startup hook
#define configUSE_DAEMON_TASK_STARTUP_HOOK          0

// Stream buffer completed callbacks
#define configUSE_SB_COMPLETED_CALLBACK             0

/* ===== INTERRUPT PRIORITY CONFIGURATION ===== */

// Number of unique interrupt priorities supported (ARM GIC)
#define configUNIQUE_INTERRUPT_PRIORITIES           32

// Kernel interrupt priority (ARM Cortex-A/M)
#define configKERNEL_INTERRUPT_PRIORITY             20

// Max system call interrupt priority (must be > UNIQUEintPriorities / 2)
#define configMAX_SYSCALL_INTERRUPT_PRIORITY        18

// Max API call interrupt priority (must be > UNIQUE / 2, typically same as above)
#define configMAX_API_CALL_INTERRUPT_PRIORITY       18

/* ===== ARM CORTEX-A GIC CONFIGURATION ===== */

// ARM Generic Interrupt Controller base address (GICv2 typical address)
#define configINTERRUPT_CONTROLLER_BASE_ADDRESS     0xF8F00000UL

// CPU interface offset within GIC
#define configINTERRUPT_CONTROLLER_CPU_INTERFACE_OFFSET  0x1000UL

/* ===== ARM CORTEX-A TIMER CONFIGURATION ===== */

// ARM Cortex-A tick interrupt setup (placeholder for HAL integration)
// In production, this would initialize the timer interrupt at the HAL level
#define configSETUP_TICK_INTERRUPT()                \
    do {                                            \
        /* HAL initializes generic timer */         \
    } while (0)

// ARM Cortex-A tick interrupt clear
#define configCLEAR_TICK_INTERRUPT()

/* ===== FEATURE ENABLEMENT ===== */

// Enable task notifications
#define configUSE_TASK_NOTIFICATIONS                1

// ARM MPU support (for protected mode tasks, if needed)
#define configUSE_MPU_WRAPPERS                      0

/* ===== INCLUDE SPECIFIC FUNCTION IMPLEMENTATIONS ===== */

// Include xTaskDelayUntil function
#define INCLUDE_xTaskDelayUntil                     1

// Include vTaskDelay function
#define INCLUDE_vTaskDelay                          1

// Include xTaskGetSchedulerState function
#define INCLUDE_xTaskGetSchedulerState              1

// Include vTaskSuspend function
#define INCLUDE_vTaskSuspend                        1

// Include uxTaskGetStackHighWaterMark function
#define INCLUDE_uxTaskGetStackHighWaterMark         1

// Include xTaskAbortDelay function
#define INCLUDE_xTaskAbortDelay                     1

#endif // FREERTOS_CONFIG_H
