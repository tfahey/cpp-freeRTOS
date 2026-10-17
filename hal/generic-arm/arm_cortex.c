#include <stdint.h>
#include <string.h>
#include <stdio.h>

/* ===== FUNCTION PROTOTYPES ===== */
void vHAL_Init(void);
void vUART_Init(uint32_t baud_rate);
void vUART_SendByte(char byte);
void vUART_SendString(const char *str);
void vGPIO_Init(void);
void vGPIO_Set(uint32_t pin);
void vGPIO_Clear(uint32_t pin);
void vConfigureTickTimer(uint32_t frequency_hz);
void vTimerInterruptHandler(void);

/* ===== HAL INITIALIZATION ===== */

void vHAL_Init(void) {
    /* Cache initialization (minimal for simulator) */
    /* In real bare-metal, would enable I/D caches here */

    /* MMU initialization (stubbed for simulator) */
    /* Real implementation would set up page tables */

    /* Interrupt controller initialization (GIC) */
    /* Stubbed for simulator; real implementation configures GIC */

    /* Timer initialization */
    vConfigureTickTimer(1000);  /* 1000 Hz tick rate */
}

/* ===== UART IMPLEMENTATION ===== */

void vUART_Init(uint32_t baud_rate) {
    /* Platform-specific UART setup */
    /* For QEMU virt: typically uses PL011 at 0x09000000 */
    /* For real hardware: configure based on board */

    /* Configure baud rate, data bits, stop bits, parity */
    /* Enable UART */
    (void)baud_rate;  /* Suppress unused warning in simulator */
}

void vUART_SendByte(char byte) {
    /* Platform-specific byte transmission */
    /* Typically: poll UART status register, write to TX FIFO */

    /* For simulation/testing, use stdout */
    fputc((unsigned char)byte, stdout);
    fflush(stdout);
}

void vUART_SendString(const char *str) {
    if (str == NULL) {
        return;
    }

    while (*str) {
        vUART_SendByte(*str++);
        /* Small delay to avoid overwhelming receiver */
        for (volatile int i = 0; i < 100; i++);
    }
}

/* ===== GPIO IMPLEMENTATION ===== */

void vGPIO_Init(void) {
    /* Initialize GPIO controller */
    /* Enable GPIO block */
    /* Configure LED pins (if available) */
}

void vGPIO_Set(uint32_t pin) {
    /* Platform-specific GPIO set operation */
    (void)pin;  /* Suppress unused warning */
}

void vGPIO_Clear(uint32_t pin) {
    /* Platform-specific GPIO clear operation */
    (void)pin;  /* Suppress unused warning */
}

/* ===== TIMER IMPLEMENTATION ===== */

void vConfigureTickTimer(uint32_t frequency_hz) {
    /* Configure ARM generic timer or board-specific timer */
    /* Set timer frequency to match configTICK_RATE_HZ */
    (void)frequency_hz;  /* Suppress unused warning */
}

void vTimerInterruptHandler(void) {
    /* Acknowledge interrupt */
    /* Call FreeRTOS tick handler: xTaskIncrementTick() */
    /* Context switch if needed: vTaskSwitchContext() */

    /* This stub is called from assembly ISR */
    /* For x86-64 POSIX, this is not used */
}

/* ===== UTILITY FUNCTIONS ===== */

void log_message(const char *msg) {
    if (msg != NULL) {
        vUART_SendString(msg);
        vUART_SendByte('\n');
    }
}

void log_int(const char *label, int32_t value) {
    if (label != NULL) {
        vUART_SendString(label);
        vUART_SendString(": ");

        /* Simple integer to string conversion */
        if (value < 0) {
            vUART_SendByte('-');
            value = -value;
        }

        /* Handle zero case */
        if (value == 0) {
            vUART_SendByte('0');
        } else {
            /* Print digits */
            char buffer[16];
            int idx = 0;
            int32_t temp = value;

            while (temp > 0) {
                buffer[idx++] = '0' + (temp % 10);
                temp /= 10;
            }

            /* Print in reverse */
            while (idx > 0) {
                vUART_SendByte(buffer[--idx]);
            }
        }

        vUART_SendByte('\n');
    }
}
