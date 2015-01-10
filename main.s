; ----------------------------------------------------------------
; $A000 Vectors
; ----------------------------------------------------------------

.include "kernal.i"
.include "persistent.i"

; from init
.import entry2
.import go_basic
.import init_load_and_basic_vectors
.import init_vectors_jmp_bank_2

; from format
.import fast_format
.import init_read_disk_name
.import init_write_bam

; from editor
.import print_screen

; from desktop_helper
.import perform_desktop_disk_operation

.segment "A000_vectors"

        .addr   entry ; FC3 entry
        .addr   $FE5E ; default cartridge soft reset entry point
        .byte   $C3,$C2,$CD,"80" ; 'cbm80'

entry:  jmp     entry2

; this vector is called from other banks
        jmp     perform_desktop_disk_operation

.global do_fast_format
do_fast_format: ; monitor calls this
        jmp     fast_format

; this vector is called from other banks
        jmp     init_read_disk_name
        jmp     init_write_bam
        jmp     init_vectors_jmp_bank_2
        jmp     go_basic
        jmp     print_screen
        jmp     init_load_and_basic_vectors
