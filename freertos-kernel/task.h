/*
 * task.h - FreeRTOS task management (stub for compilation)
 *
 * This is a minimal stub header to allow syntax checking before
 * the full FreeRTOS kernel is integrated in Phase 9.
 */

#ifndef TASK_H
#define TASK_H

#include "FreeRTOS.h"

/* Task creation */
BaseType_t xTaskCreate(
    void (*pxTaskCode)(void *),
    const char * const pcName,
    uint32_t usStackDepth,
    void * const pvParameters,
    UBaseType_t uxPriority,
    TaskHandle_t * const pxCreatedTask
);

/* Task control */
void vTaskDelete(TaskHandle_t xTaskToDelete);
void vTaskDelay(TickType_t xTicksToDelay);
void vTaskDelayUntil(TickType_t * const pxPreviousWakeTime, TickType_t xTimeIncrement);
void vTaskPrioritySet(TaskHandle_t xTask, UBaseType_t uxNewPriority);
UBaseType_t uxTaskPriorityGet(TaskHandle_t xTask);
void vTaskSuspend(TaskHandle_t xTaskToSuspend);
void vTaskResume(TaskHandle_t xTaskToResume);

/* Task information */
TaskHandle_t xTaskGetCurrentTaskHandle(void);
const char *pcTaskGetName(TaskHandle_t xTaskToQuery);
BaseType_t xTaskGetTaskInfo(TaskHandle_t xTask, void *pxTaskInfo, BaseType_t xGetFreeStackSpace, BaseType_t xTaskState);

/* Task hooks (weak symbols - can be overridden by application) */
void vApplicationStackOverflowHook(TaskHandle_t xTask, char *pcTaskName) __attribute__((weak));
void vApplicationTickHook(void) __attribute__((weak));
void vApplicationIdleHook(void) __attribute__((weak));
void vApplicationMallocFailedHook(void) __attribute__((weak));

#endif /* TASK_H */
