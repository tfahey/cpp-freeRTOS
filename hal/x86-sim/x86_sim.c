#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

/* ===== x86-64 POSIX SIMULATION HAL ===== */

/*
 * This file provides HAL stub implementations for x86-64 Linux targets.
 * It allows FreeRTOS to run on Linux via POSIX thread emulation.
 * Real hardware functions are stubbed/simplified for testing.
 */

/* ===== UART IMPLEMENTATION (POSIX STUBS) ===== */

void vUART_Init(uint32_t baud_rate) {
    /* POSIX simulation: stdout is already initialized */
    (void)baud_rate;  /* Suppress unused parameter warning */
}

void vUART_SendByte(char byte) {
    /* Use stdout for simulation */
    fputc((unsigned char)byte, stdout);
    fflush(stdout);
}

void vUART_SendString(const char *str) {
    if (str == NULL) {
        return;
    }

    while (*str) {
        vUART_SendByte(*str++);
    }
}

/* ===== GPIO IMPLEMENTATION (POSIX STUBS) ===== */

void vGPIO_Init(void) {
    /* GPIO not applicable to x86-64 simulation */
    /* In real hardware, this would initialize GPIO controller */
}

void vGPIO_Set(uint32_t pin) {
    /* Stub for simulation */
    (void)pin;
}

void vGPIO_Clear(uint32_t pin) {
    /* Stub for simulation */
    (void)pin;
}

/* ===== TIMER IMPLEMENTATION (POSIX STUBS) ===== */

void vConfigureTickTimer(uint32_t frequency_hz) {
    /*
     * Timer configuration is handled by FreeRTOS POSIX port
     * This stub is provided for API compatibility
     */
    (void)frequency_hz;
}

void vTimerInterruptHandler(void) {
    /*
     * On POSIX systems, the FreeRTOS port uses signals or threads
     * for timer interrupts instead of actual ISR handlers.
     * This stub maintains API compatibility.
     */
}

/* ===== SYSTEM INITIALIZATION ===== */

void vHAL_Init(void) {
    /* Initialize all hardware subsystems */
    vUART_Init(115200);
    vGPIO_Init();
    vConfigureTickTimer(1000);
}

/* ===== UTILITY FUNCTIONS ===== */

void log_message(const char *msg) {
    if (msg != NULL) {
        printf("%s\n", msg);
        fflush(stdout);
    }
}

void log_int(const char *label, int32_t value) {
    if (label != NULL) {
        printf("%s: %ld\n", label, (long)value);
        fflush(stdout);
    }
}
