#include "FreeRTOS.h"
#include "task.h"
#include "FreeRTOSConfig.h"
#include "example_task.h"
#include <stdio.h>
#include <string.h>
#include <stdint.h>

/* ===== GLOBAL STATE ===== */

/* Task execution counters */
static volatile uint32_t g_task_counter[3] = {0};

/* Task handles for reference (optional) */
static TaskHandle_t g_task_handles[3] = {NULL, NULL, NULL};

/* ===== TASK IMPLEMENTATION ===== */

void vExampleTask(void *pvParameters) {
    uint32_t task_id = (uintptr_t)pvParameters;
    TickType_t last_wake_time = xTaskGetTickCount();

    /* Validate task ID */
    if (task_id >= 3) {
        return;
    }

    while (1) {
        /* Increment execution counter */
        g_task_counter[task_id]++;

        /* Log task execution */
        #ifdef __linux__
        /* x86-64 POSIX simulation */
        printf("Task %u running (count=%u)\n", (unsigned)task_id, (unsigned)g_task_counter[task_id]);
        #else
        /* ARM bare-metal - use logging functions */
        char buffer[64];
        snprintf(buffer, sizeof(buffer),
                 "Task %u running (count=%u)",
                 (unsigned)task_id, (unsigned)g_task_counter[task_id]);
        /* Note: log_message function defined in HAL */
        extern void log_message(const char *msg);
        log_message(buffer);
        #endif

        /* Periodic delay: 1000 ms (1 second) */
        vTaskDelayUntil(&last_wake_time, pdMS_TO_TICKS(1000));
    }
}

/* ===== TASK CREATION ===== */

void xCreateExampleTasks(void) {
    BaseType_t status;

    /* Task 1: Low priority, logs every 1 second */
    status = xTaskCreate(
        vExampleTask,                       /* Task function */
        "Task_1",                           /* Task name for debugging */
        EXAMPLE_TASK_1_STACK_SIZE,          /* Stack size (words) */
        (void *)0,                          /* Task ID as parameter */
        EXAMPLE_TASK_1_PRIORITY,            /* Priority (1 = low) */
        &g_task_handles[0]                  /* Task handle */
    );

    if (status != pdPASS) {
        #ifdef __linux__
        printf("ERROR: Failed to create Task 1\n");
        #else
        extern void log_message(const char *msg);
        log_message("ERROR: Failed to create Task 1");
        #endif
    }

    /* Task 2: Low priority, logs every 1 second */
    status = xTaskCreate(
        vExampleTask,
        "Task_2",
        EXAMPLE_TASK_1_STACK_SIZE,
        (void *)1,
        EXAMPLE_TASK_1_PRIORITY,
        &g_task_handles[1]
    );

    if (status != pdPASS) {
        #ifdef __linux__
        printf("ERROR: Failed to create Task 2\n");
        #else
        extern void log_message(const char *msg);
        log_message("ERROR: Failed to create Task 2");
        #endif
    }

    /* Task 3: Medium priority, logs every 1 second */
    status = xTaskCreate(
        vExampleTask,
        "Task_3",
        EXAMPLE_TASK_1_STACK_SIZE,
        (void *)2,
        LOGGING_TASK_PRIORITY,              /* Priority (2 = medium) */
        &g_task_handles[2]
    );

    if (status != pdPASS) {
        #ifdef __linux__
        printf("ERROR: Failed to create Task 3\n");
        #else
        extern void log_message(const char *msg);
        log_message("ERROR: Failed to create Task 3");
        #endif
    }
}

/* ===== TASK STATISTICS ===== */

void vGetTaskStats(uint32_t task_id, TaskStats_t *stats) {
    if (stats != NULL && task_id < 3) {
        stats->task_id = task_id;
        stats->execution_count = g_task_counter[task_id];
        stats->total_run_time_ms = (stats->execution_count * 1000);
    }
}
