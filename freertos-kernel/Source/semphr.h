/*
 * semphr.h - FreeRTOS semaphore management (stub for compilation)
 *
 * This is a minimal stub header to allow syntax checking before
 * the full FreeRTOS kernel is integrated in Phase 9.
 */

#ifndef SEMPHR_H
#define SEMPHR_H

#include "FreeRTOS.h"
#include "queue.h"

/* Semaphore handle type */
typedef QueueHandle_t SemaphoreHandle_t;

/* Mutex handle type */
typedef QueueHandle_t MutexHandle_t;

/* Semaphore creation and deletion */
SemaphoreHandle_t xSemaphoreCreateBinary(void);
SemaphoreHandle_t xSemaphoreCreateCounting(UBaseType_t uxMaxCount, UBaseType_t uxInitialCount);
MutexHandle_t xSemaphoreCreateMutex(void);
void vSemaphoreDelete(SemaphoreHandle_t xSemaphore);

/* Semaphore operations */
BaseType_t xSemaphoreTake(SemaphoreHandle_t xSemaphore, TickType_t xTicksToWait);
BaseType_t xSemaphoreGive(SemaphoreHandle_t xSemaphore);
BaseType_t xSemaphoreTakeFromISR(SemaphoreHandle_t xSemaphore, BaseType_t * const pxHigherPriorityTaskWoken);
BaseType_t xSemaphoreGiveFromISR(SemaphoreHandle_t xSemaphore, BaseType_t * const pxHigherPriorityTaskWoken);

#endif /* SEMPHR_H */
