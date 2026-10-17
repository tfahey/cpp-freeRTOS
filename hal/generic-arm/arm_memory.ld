/* ARM Cortex-A Memory Layout (QEMU virt platform) */

MEMORY
{
    RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 256M
}

SECTIONS
{
    /* Text section (code) */
    .text :
    {
        *(.vectors)
        *(.text*)
        *(.rodata*)
    } > RAM

    /* Initialized data section */
    .data :
    {
        _data_start = .;
        *(.data*)
        _data_end = .;
    } > RAM

    /* Uninitialized data section (BSS) */
    .bss (NOLOAD) :
    {
        _bss_start = .;
        *(.bss*)
        *(COMMON)
        _bss_end = .;
    } > RAM

    /* Heap (grows upward) */
    .heap (NOLOAD) :
    {
        _heap_start = .;
        . = . + 32K;
        _heap_end = .;
    } > RAM

    /* Stack (grows downward) */
    .stack (NOLOAD) :
    {
        . = ALIGN(16);
        _stack_end = .;
        . = . + 64K;
        _stack_top = .;
    } > RAM

    /* Discard DWARF debug sections */
    /DISCARD/ :
    {
        *(.note.GNU-stack)
        *(.ARM.exidx)
        *(.ARM.extab)
    }
}
