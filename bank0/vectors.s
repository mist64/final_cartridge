; ----------------------------------------------------------------
; Vectors
; ----------------------------------------------------------------
; This is put right after the cartridge's "cbm80" header and
; contains jump table, which is mostly used from other banks.

.include "../core/kernal.i"
.include "persistent.i"

; from init
.import entry
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
.import perform_operation_for_desktop

.segment "vectors"

.assert * = $8009, error, "vectors must be at $8009!"

.global jentry
jentry:
        jmp     entry

; this vector is called from other banks
        jmp     perform_operation_for_desktop

.global jfast_format
jfast_format: ; monitor calls this
        jmp     fast_format

; these vectors are called from other banks
        jmp     init_read_disk_name
        jmp     init_write_bam
        jmp     init_vectors_jmp_bank_2
        jmp     go_basic
        jmp     print_screen
        jmp     init_load_and_basic_vectors
