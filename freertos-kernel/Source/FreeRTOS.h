/*
 * FreeRTOS.h - Core FreeRTOS header (stub for compilation)
 *
 * This is a minimal stub header to allow syntax checking before
 * the full FreeRTOS kernel is integrated in Phase 9.
 *
 * When Phase 9 integrates the real FreeRTOS kernel, this file
 * will be replaced with the actual kernel header.
 */

#ifndef FREERTOS_H
#define FREERTOS_H

#include <stdint.h>
#include <stddef.h>

/* FreeRTOS version stub */
#define tskKERNEL_VERSION_MAJOR 11
#define tskKERNEL_VERSION_MINOR 0
#define tskKERNEL_VERSION_BUILD 1

/* Common type definitions */
typedef uint32_t TickType_t;
typedef void * TaskHandle_t;
typedef uint32_t BaseType_t;
typedef uint32_t UBaseType_t;

/* Return codes */
#define pdPASS   (BaseType_t) 1
#define pdFAIL   (BaseType_t) 0
#define pdTRUE   (BaseType_t) 1
#define pdFALSE  (BaseType_t) 0

/* Common macros */
#define portMAX_DELAY (~(TickType_t)0)
#define portTICK_TYPE_IS_ATOMIC 1

/* Utility macros */
#define pdMS_TO_TICKS(ms) ((ms * 1000) / 1000)

/* Task priority values */
#define tskIDLE_PRIORITY 0
#define tskMAX_PRIORITIES 5

/* Scheduler control functions (stubs) */
void vTaskStartScheduler(void);
void vTaskEndScheduler(void);
void vTaskSuspendAll(void);
BaseType_t xTaskResumeAll(void);

/* Task information */
TickType_t xTaskGetTickCount(void);
uint32_t uxTaskGetNumberOfTasks(void);

/* Interrupt management (stubs) */
#define taskDISABLE_INTERRUPTS() \
    do { } while (0)

#define taskENABLE_INTERRUPTS() \
    do { } while (0)

#define taskENTER_CRITICAL() \
    do { } while (0)

#define taskEXIT_CRITICAL() \
    do { } while (0)

#endif /* FREERTOS_H */
