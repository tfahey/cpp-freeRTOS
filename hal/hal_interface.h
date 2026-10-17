#ifndef HAL_INTERFACE_H
#define HAL_INTERFACE_H

#include <stdint.h>

/* ===== HAL ABSTRACTION INTERFACE ===== */

/*
 * This header defines the hardware abstraction layer interface
 * that is implemented differently for each target platform.
 *
 * Platform implementations:
 * - ARM Cortex-A: hal/generic-arm/arm_cortex.c
 * - x86-64 POSIX: Stubs provided below
 */

/* ===== UART FUNCTIONS ===== */

/*
 * vUART_Init: Initialize UART for serial communication
 * Parameters: baud_rate - Serial baud rate (e.g., 115200)
 */
void vUART_Init(uint32_t baud_rate);

/*
 * vUART_SendByte: Send single byte via UART
 * Parameters: byte - Character to transmit
 */
void vUART_SendByte(char byte);

/*
 * vUART_SendString: Send null-terminated string via UART
 * Parameters: str - Pointer to string (must be null-terminated)
 */
void vUART_SendString(const char *str);

/* ===== GPIO FUNCTIONS ===== */

/*
 * vGPIO_Init: Initialize GPIO controller
 */
void vGPIO_Init(void);

/*
 * vGPIO_Set: Set GPIO pin high (LED on)
 * Parameters: pin - GPIO pin number
 */
void vGPIO_Set(uint32_t pin);

/*
 * vGPIO_Clear: Set GPIO pin low (LED off)
 * Parameters: pin - GPIO pin number
 */
void vGPIO_Clear(uint32_t pin);

/* ===== TIMER FUNCTIONS ===== */

/*
 * vConfigureTickTimer: Configure system timer for FreeRTOS tick
 * Parameters: frequency_hz - Desired tick frequency (e.g., 1000 Hz)
 */
void vConfigureTickTimer(uint32_t frequency_hz);

/*
 * vTimerInterruptHandler: FreeRTOS tick ISR handler
 * Called from assembly interrupt handler
 */
void vTimerInterruptHandler(void);

/* ===== SYSTEM INITIALIZATION ===== */

/*
 * vHAL_Init: Initialize all hardware subsystems
 * - Enables caches (if applicable)
 * - Initializes interrupt controller
 * - Sets up timers
 */
void vHAL_Init(void);

/* ===== UTILITY FUNCTIONS ===== */

/*
 * log_message: Platform-agnostic logging function
 * Uses UART on ARM, stdout on x86-64
 * Parameters: msg - Message to log (null-terminated)
 */
void log_message(const char *msg);

/*
 * log_int: Log integer value
 * Parameters:
 *   label - Label string
 *   value - Integer value to log
 */
void log_int(const char *label, int32_t value);

#endif /* HAL_INTERFACE_H */
