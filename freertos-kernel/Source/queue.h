/*
 * queue.h - FreeRTOS queue management (stub for compilation)
 *
 * This is a minimal stub header to allow syntax checking before
 * the full FreeRTOS kernel is integrated in Phase 9.
 */

#ifndef QUEUE_H
#define QUEUE_H

#include "FreeRTOS.h"

/* Queue handle type */
typedef void * QueueHandle_t;

/* Queue creation and deletion */
QueueHandle_t xQueueCreate(UBaseType_t uxQueueLength, UBaseType_t uxItemSize);
QueueHandle_t xQueueCreateStatic(UBaseType_t uxQueueLength, UBaseType_t uxItemSize, uint8_t *pucQueueStorageBuffer, void *pxStaticQueue);
void vQueueDelete(QueueHandle_t xQueue);

/* Queue operations */
BaseType_t xQueueSend(QueueHandle_t xQueue, const void * const pvItemToQueue, TickType_t xTicksToWait);
BaseType_t xQueueReceive(QueueHandle_t xQueue, void * const pvBuffer, TickType_t xTicksToWait);
UBaseType_t uxQueueMessagesWaiting(QueueHandle_t xQueue);

#endif /* QUEUE_H */
