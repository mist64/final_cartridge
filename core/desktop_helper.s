; ----------------------------------------------------------------
; Helper code called from Desktop
; ----------------------------------------------------------------
; Desktop doesn't know about drives or printers, so it calls into
; this library code using cross-bank calls. It also calls this to
; start a program in BASIC mode.

.include "kernal.i"
.include "persistent.i"

; from basic
.import pow10lo
.import pow10hi
.import send_drive_command
.import print_msg
.import messages
.import a_ready

; from init
.import init_basic_vectors
.import init_load_save_vectors

; fom drive
.import cmd_channel_listen
.import command_channel_talk
.import listen_second
.import talk_second

; from format
.import init_read_disk_name
.import unlisten_e2

; from printer
.import set_io_vectors
.import set_io_vectors_with_hidden_rom

.global load_and_run_program
.global perform_operation_for_desktop

.segment "desktop_helper"

reset_load_and_run:
        sei
        lda     #<$EA31
        sta     $0314
        lda     #>$EA31
        sta     $0315
        jsr     init_load_save_vectors
        jsr     init_basic_vectors
        cli
        jsr     $E3BF ; init BASIC, print banner
        jmp     _print_banner_load_and_run

; file name at $0200
load_and_run_program:
        ldx     #<(a_ready - messages) ; ("<" necessary as a compiler hint)
        jsr     print_msg ; print "READY."
        ldx     #$FB
        txs
        lda     #$80
        sta     $9D ; direct mode
        ldy     #$FF
        sty     $3A ; direct mode
        iny
        sty     $0A
        sty     FNADR
        sty     $02A8
        lda     #1 ; secondary address
        sta     SA
        lda     #>$0200
        sta     FNADR + 1 ; read filename from $0200
        sta     TXTPTR + 1
L9533:  lda     (FNADR),y
        sta     $C000,y
        beq     L953D
        iny
        bne     L9533
L953D:  sty     $B7
        lda     #$C0
        sta     FNADR + 1 ; file name pointer high (fn at $C000)
        lda     #'R'
        sta     KEYD
        lda     #'U'
        sta     KEYD + 1
        lda     #'N'
        sta     KEYD + 2
        lda     #$0D ; CR
        sta     KEYD + 3
        lda     #4 ; number of characters in kbd buffer
        sta     NDX
        jmp     $E16F ; LOAD

perform_operation_for_desktop:
        tya
        pha ; bank to return to
        cpx     #1
        beq     read_directory
        cpx     #2
        beq     send_drive_command_at_0200
        cpx     #3
        beq     read_cmd_channel
        cpx     #4
        beq     read_disk_name
        cpx     #5
        beq     reset_load_and_run
        jmp     L969A ; second half of operations (XXX why?)

; reads zero terminated disk name to $0200
read_disk_name:
        jsr     cmd_channel_listen
        bmi     zero_terminate ; XXX X is undefined here
        jsr     UNLSTN
        ldx     #0
        jsr     init_read_disk_name
        bne     zero_terminate
        lda     #$62
        jsr     talk_second
        ldx     #0
L958D:  jsr     IECIN
        cmp     #$A0 ; terminator
        beq     L959C
        sta     $0200,x
        inx
        cpx     #$10 ; max 16 characters
        bne     L958D
L959C:  jsr     UNTALK
        jsr     unlisten_e2
        jmp     zero_terminate

read_cmd_channel:
        jsr     cmd_channel_listen
        bmi     jmp_bank_from_stack
        jsr     UNLSTN
        jsr     command_channel_talk
        lda     ST
        bmi     jmp_bank_from_stack
        ldx     #0
L95B6:  jsr     IECIN
        cmp     #$0D ; CR
        beq     L95C3
        sta     $0200,x ; read command channel
        inx
        bne     L95B6
L95C3:  jsr     UNTALK
zero_terminate:
        lda     #0
        sta     $0200,x ; zero terminate
jmp_bank_from_stack:
        pla
        jmp     _jmp_bank

send_drive_command_at_0200:
        jsr     cmd_channel_listen
        bmi     jmp_bank_from_stack
        lda     #<$0200
        sta     TXTPTR
        lda     #>$0200
        sta     TXTPTR + 1
        jsr     send_drive_command
        jmp     jmp_bank_from_stack

; reads the drive's directory, decoding it into binary format
read_directory:
        lda     #$F0
        jsr     listen_second
        bmi     jmp_bank_from_stack
        lda     #'$'
        jsr     IECOUT
        jsr     UNLSTN
        lda     #$60
        sta     SA
        jsr     talk_second
        ldx     #6
L95FA:  jsr     iecin_or_ret
        dex
        bne     L95FA ; skip 6 bytes
        beq     L9612
L9602:  jsr     iecin_or_ret
        jsr     iecin_or_ret
        jsr     iecin_or_ret
        tax
        jsr     iecin_or_ret
        jsr     decode_decimal
L9612:  jsr     iecin_or_ret
        cmp     #'"'
        bne     L9612 ; skip until quote
L9619:  jsr     iecin_or_ret
        cmp     #'"'
        beq     L9626
        jsr     store_directory_byte
        jmp     L9619 ; loop

L9626:  jsr     terminate_directory_name
L9629:  jsr     iecin_or_ret
        cmp     #0
        bne     L9629
        beq     L9602 ; always; loop

iecin_or_ret:
        jsr     IECIN
        ldy     ST
        bne     L963A
        rts

L963A:  pla
        pla
        jsr     terminate_directory_name
        jsr     $F646 ; close file
        jmp     jmp_bank_from_stack

decode_decimal:
        stx     $C1
        sta     $C2
        lda     #$31
        sta     $C3
        ldx     #4
L964F:  dec     $C3
L9651:  lda     #$2F
        sta     $C4
        sec
        ldy     $C1
        .byte   $2C
L9659:  sta     $C2
        sty     $C1
        inc     $C4
        tya
        sbc     pow10lo,x
        tay
        lda     $C2
        sbc     pow10hi,x
        bcs     L9659
        lda     $C4
        cmp     $C3
        beq     L9676
        jsr     store_directory_byte
        dec     $C3
L9676:  dex
        beq     L964F
        bpl     L9651
        jmp     terminate_directory_name ; XXX redundant

terminate_directory_name:
        lda     #0
store_directory_byte:
        sty     $AE
        ldy     #0
        sta     ($AC),y
        inc     $AC
        bne     L968C
        inc     $AD
L968C:  ldy     $AE
        rts

disk_operation_fallback:
        lda     #<($FF92 - 1)
        pha
        lda     #>($FF92 - 1) ; ???
        pha
        lda     #$43
        jmp     _jmp_bank ; bank 3

L969A:  cpx     #11
        beq     set_printer_output
        cpx     #12
        beq     print_character
        cpx     #13
        beq     reset_printer_output
        jsr     disk_operation_fallback
        jmp     jmp_bank_from_stack

reset_printer_output:
        lda     #$0D ; CR
        jsr     BSOUT
        jsr     CLALL
        lda     #1
        jsr     CLOSE
        jsr     set_io_vectors_with_hidden_rom
        jmp     jmp_bank_from_stack

set_printer_output:
        jsr     set_io_vectors
        lda     #1 ; LA
        ldy     #7 ; secondary address
        ldx     #4 ; printer
        jsr     SETLFS
        lda     #0
        jsr     SETNAM
        jsr     OPEN
        ldx     #1
        jsr     CKOUT
        jmp     jmp_bank_from_stack

print_character:
        lda     $0200
        jsr     BSOUT
        jmp     jmp_bank_from_stack

