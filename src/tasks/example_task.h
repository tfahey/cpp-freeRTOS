#ifndef EXAMPLE_TASK_H
#define EXAMPLE_TASK_H

#include "FreeRTOS.h"
#include "task.h"

/* ===== TASK FUNCTION ===== */

/*
 * vExampleTask: Main example task function
 * Parameters: pvParameters - Task ID passed as parameter
 * Behavior: Logs execution count periodically
 */
void vExampleTask(void *pvParameters);

/* ===== TASK CREATION ===== */

/*
 * xCreateExampleTasks: Create all example tasks
 * Returns: pdPASS if successful, pdFAIL otherwise
 */
void xCreateExampleTasks(void);

/* ===== TASK STATISTICS STRUCTURE ===== */

typedef struct {
    uint32_t task_id;           /* Task identifier */
    uint32_t execution_count;   /* Number of times task has executed */
    uint32_t total_run_time_ms; /* Total runtime in milliseconds */
} TaskStats_t;

#endif /* EXAMPLE_TASK_H */
