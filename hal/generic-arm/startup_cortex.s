.syntax unified
.cpu cortex-a9
.thumb

/* Vector table for ARM Cortex-A */
.section .vectors, "ax"
.align 2
.global _vectors
_vectors:
    ldr pc, =_reset_handler        /* Reset */
    ldr pc, =_undefined_handler    /* Undefined instruction */
    ldr pc, =_swi_handler          /* Software interrupt */
    ldr pc, =_prefetch_handler     /* Prefetch abort */
    ldr pc, =_data_abort_handler   /* Data abort */
    nop                            /* Reserved */
    ldr pc, =_irq_handler          /* IRQ */
    ldr pc, =_fiq_handler          /* FIQ */

/* Reset handler */
.section .text
.align 2
.global _reset_handler
.thumb_func
_reset_handler:
    /* Initialize stack pointer */
    ldr sp, =_stack_top

    /* Initialize BSS section (zero uninitialized data) */
    ldr r0, =_bss_start
    ldr r1, =_bss_end
    mov r2, #0
bss_loop:
    cmp r0, r1
    strne r2, [r0], #4
    bne bss_loop

    /* Call main() */
    bl main

    /* Infinite loop (should not return) */
    b .

/* Exception handlers (stubs) */
.thumb_func
_undefined_handler:
    b .

.thumb_func
_swi_handler:
    b .

.thumb_func
_prefetch_handler:
    b .

.thumb_func
_data_abort_handler:
    b .

.thumb_func
_irq_handler:
    /* Save context */
    push {r0-r12, lr}
    /* Call timer/interrupt handler */
    bl vTimerInterruptHandler
    /* Restore context */
    pop {r0-r12, pc}

.thumb_func
_fiq_handler:
    b .

/* Stack and heap symbols (linked by linker script) */
.extern _stack_top
.extern _bss_start
.extern _bss_end
