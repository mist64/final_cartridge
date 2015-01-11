; ----------------------------------------------------------------
; wrappers for BASIC/KERNAL calls with cartridge ROM disabled
; ----------------------------------------------------------------

.include "kernal.i"
.include "persistent.i"

.global WA3BF
.global WA49F
.global WA560
.global WA663_E386
.global WA6C3
.global WA8F8
.global WAF08
.global WE159
.global WE16F
.global WE175
.global WE1D4
.global disable_rom_jmp_overflow_error
.global disable_rom_then_warm_start

.segment "wrappers"

WAF08:  lda     #>($AF08 - 1)
        pha
        lda     #<($AF08 - 1) ; SYNTAX ERROR
disable_rom_jmp:
        pha
        jmp     _disable_rom

disable_rom_jmp_overflow_error:
        lda     #>($B97E - 1) ; OVERFLOW ERROR
        pha
        lda     #<($B97E - 1)
        bne     disable_rom_jmp ; always

WA49F:  lda     #>($A49F - 1) ; used to be $A4A2 in 1988-05
        pha
        lda     #<($A49F - 1) ; input line
        bne     disable_rom_jmp ; always

; ??? unused?
        lda     #>($A7AE - 1)
        pha
        lda     #<($A7AE - 1) ; interpreter loop
        bne     disable_rom_jmp ; always

.global disable_rom_jmp_error
disable_rom_jmp_error:
        lda     #>($A437 - 1)
        pha
        lda     #<($A437 - 1) ; ERROR
        bne     disable_rom_jmp

WA6C3:  lda     #>($A6C3 - 1)
        pha
        lda     #<($A6C3 - 1) ; LIST worker code
        bne     disable_rom_jmp

.global disable_rom_then_warm_start
disable_rom_then_warm_start:
        lda     #>($E386 - 1) ; BASIC warm start
        pha
        lda     #<($E386 - 1)
        bne     disable_rom_jmp

WA8F8:  lda     #>($A8F8 - 1)
        pha
        lda     #<($A8F8 - 1) ; DATA
        bne     disable_rom_jmp

WA663_E386:
        ldx     #>($A663 - 1)
        ldy     #<($A663 - 1) ; CLR
        lda     #>($E386 - 1)
        pha
        lda     #<($E386 - 1) ; BASIC warm start
        bne     L98A3

WE16F:  ldx     #>($E16F - 1)
        ldy     #<($E16F - 1) ; LOAD
jsr_with_rom_disabled:
        lda     #>(_enable_rom - 1)
        pha
        lda     #<(_enable_rom - 1)
L98A3:  pha
        txa ; push X/Y address
        pha
        tya
        bne     disable_rom_jmp

WE1D4:  ldx     #>($E1D4 - 1)
        ldy     #<($E1D4 - 1) ; get args for LOAD/SAVE
        bne     jsr_with_rom_disabled

WE159:  ldx     #>($E159 - 1)
        ldy     #<($E159 - 1) ; SAVE
L98B3:  bne     jsr_with_rom_disabled

; ??? unused?
        ldx     #>($A579 - 1)
        ldy     #<($A579 - 1) ; tokenize
L98B9:  bne     jsr_with_rom_disabled

WA560:  ldx     #>($A560 - 1)
        ldy     #<($A560 - 1) ; line input
        bne     jsr_with_rom_disabled

WA3BF:  ldx     #>($A3BF - 1)
        ldy     #<($A3BF - 1) ; BASIC memory management
        bne     jsr_with_rom_disabled

WE175:  lda     #>($E175 - 1)
        pha
        lda     #<($E175 - 1) ; LOAD worker
        pha
        lda     #0
        jmp     _disable_rom

; ----------------------------------------------------------------
; junk - this is a copy of "new_load2"

        .byte   $DE
        sty     $93
        tya
        ldy     DEV
        cpy     #7
        beq     L98B3
        cpy     #8
        bcc     L98B9
        cpy     #10
        bcs     L98B9
        tay
        bne     L98B9
        lda     $B7
        beq     L98B9
        jsr     _load_bb_indy
        cmp     #$24
        beq     L98B9
        ldx     SECADDR
        cpx     #2
        beq     L98B9
        jsr     $A762 ; ???
        lda     #$60
        sta     SECADDR
        .byte $20
