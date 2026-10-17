#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"
#include "semphr.h"

/* HAL includes */
#include "hal_interface.h"
#include "tasks/example_task.h"

#include <stdio.h>
#include <string.h>

/* ===== CONFIGURATION ===== */

#define APP_STARTUP_DELAY_MS 100
#define APP_MAX_STARTUP_ATTEMPTS 3

/* ===== FORWARD DECLARATIONS ===== */

static void vApplicationIdleHook(void);
static void vApplicationTickHook(void);
static void vApplicationStackOverflowHook(TaskHandle_t xTask, char *pcTaskName);
static void vApplicationMallocFailedHook(void);

/* ===== LOGGING UTILITIES ===== */

void log_message(const char *msg) {
    if (msg != NULL) {
        #ifdef __linux__
        printf("%s\n", msg);
        #else
        vUART_SendString(msg);
        vUART_SendByte('\n');
        #endif
    }
}

void log_startup_msg(const char *msg) {
    log_message("========================================");
    log_message(msg);
    log_message("========================================");
}

/* ===== APPLICATION HOOKS ===== */

/*
 * vApplicationIdleHook: Called by idle task when no other tasks are ready
 * Use for low-priority background operations
 */
void vApplicationIdleHook(void) {
    /* Idle task hook */
    /* Can be used for background monitoring or sleep optimization */
}

/*
 * vApplicationTickHook: Called on every FreeRTOS tick
 * Warning: Keep this function SHORT to avoid blocking other tasks
 */
void vApplicationTickHook(void) {
    /* Tick hook - called every 1ms */
    /* Use sparingly; long execution blocks scheduler */
}

/*
 * vApplicationStackOverflowHook: Called when a task's stack overflows
 * This is a critical error and typically indicates a task is using too much stack
 */
void vApplicationStackOverflowHook(TaskHandle_t xTask, char *pcTaskName) {
    /* Disable interrupts to prevent further corruption */
    taskDISABLE_INTERRUPTS();

    log_message("ERROR: Stack overflow detected!");
    if (pcTaskName != NULL) {
        log_message("Task: ");
        log_message(pcTaskName);
    }

    /* Infinite loop - this is unrecoverable */
    while (1) {
        /* System deadlock - stack corrupted */
    }
}

/*
 * vApplicationMallocFailedHook: Called when pvPortMalloc fails
 * Indicates insufficient heap memory
 */
void vApplicationMallocFailedHook(void) {
    taskDISABLE_INTERRUPTS();

    log_message("ERROR: Memory allocation failed!");
    log_message("Insufficient heap memory");

    /* Infinite loop - this is unrecoverable */
    while (1) {
        /* System deadlock - out of memory */
    }
}

/* ===== APPLICATION INITIALIZATION ===== */

static void vApplicationInit(void) {
    log_startup_msg("FreeRTOS Hello World - Initializing");

    /* Initialize hardware abstraction layer */
    #ifdef __linux__
    printf("Initializing on Linux/x86-64 platform\n");
    #else
    vHAL_Init();
    vUART_Init(115200);
    vGPIO_Init();
    log_message("HAL initialized");
    log_message("UART ready at 115200 baud");
    #endif

    /* Initialize timers and interrupts */
    log_message("System initialization complete");
}

/* ===== MAIN APPLICATION ===== */

int main(void) {
    BaseType_t status;

    /* Initialize hardware and logging */
    vApplicationInit();

    log_message("");
    log_message("Creating FreeRTOS tasks...");

    /* Create application tasks */
    xCreateExampleTasks();

    log_message("Tasks created successfully");
    log_message("");
    log_startup_msg("Starting FreeRTOS Scheduler");

    /* Start the FreeRTOS scheduler */
    /* This function should never return in normal operation */
    vTaskStartScheduler();

    /* If we reach here, the scheduler has exited (critical error) */
    log_startup_msg("ERROR: Scheduler Exited!");

    /* Infinite loop - unrecoverable error */
    while (1) {
        /* System deadlock - scheduler should never exit */
    }

    /* Not reached */
    return 1;
}

/* ===== CONFIGURATION VALIDATION ===== */

/*
 * This section verifies that FreeRTOSConfig.h has all required settings
 */

#if !defined(configUSE_PREEMPTION)
    #error "configUSE_PREEMPTION must be defined in FreeRTOSConfig.h"
#endif

#if !defined(configTICK_RATE_HZ)
    #error "configTICK_RATE_HZ must be defined in FreeRTOSConfig.h"
#endif

#if !defined(configMAX_PRIORITIES)
    #error "configMAX_PRIORITIES must be defined in FreeRTOSConfig.h"
#endif

#if !defined(configMINIMAL_STACK_SIZE)
    #error "configMINIMAL_STACK_SIZE must be defined in FreeRTOSConfig.h"
#endif

#if !defined(configTOTAL_HEAP_SIZE)
    #error "configTOTAL_HEAP_SIZE must be defined in FreeRTOSConfig.h"
#endif
