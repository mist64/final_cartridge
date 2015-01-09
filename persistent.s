.include "fc3.i"
.include "desktop_helper.i"
.include "speeder.i"

CHRGET          := $0073
CHRGOT          := $0079

; ----------------------------------------------------------------
; I/O Area ROM
; ----------------------------------------------------------------

.segment        "romio"

LDE00:  .byte   $40

.global _jmp_bank
_jmp_bank:
        sta     $DFFF
        rts

.global _enable_rom
_enable_rom: ; $DE05
        pha
        lda     #$40 ; bank 0
LDE08:  sta     $DFFF
        pla
        rts

.global _disable_rom_set_01
_disable_rom_set_01:; $DE0D
        sty     $01
.global _disable_rom
_disable_rom: ; $DE0F
        pha
        lda     #$70 ; no ROM at $8000; BASIC at $A000
        bne     LDE08

.global _basic_warm_start
_basic_warm_start: ; $DE14
        jsr     _disable_rom
        jmp     $E37B ; BASIC warm start (NMI)

enable_all_roms:  
        ora     #$07
        sta     $01
        bne     _enable_rom

.global _new_load
_new_load: ; $DE20
        tay
        tay
        lda     $01
        pha
        jsr     enable_all_roms
        jsr     new_load
LDE2B:  tax
        pla
        sta     $01
        txa
        ldx     $AE
        jmp     _disable_rom

.global _new_save
_new_save: ; $DE35
        lda     $01
        pha
        jsr     enable_all_roms
        jsr     new_save
        jmp     LDE2B

.global _new_mainloop
_new_mainloop: ; $DE41
        lda     $01
        jsr     enable_all_roms
        jmp     new_mainloop

.global _new_detokenize
_new_detokenize: ; $DE49
        jsr     _enable_rom
        jmp     new_detokenize

.global _new_expression
_new_expression: ; $DE4F
        jsr     _enable_rom
        jmp     new_expression

.global _kbd_handler
_kbd_handler:
        lda     $02A7
        beq     LDE5D
        jmp     $EB42 ; LDA #$7F : STA $DC00 : RTS

LDE5D:  lda     $A000
        jmp     LDF80

.global _load_ac_indy
_load_ac_indy: ; $DE63
        sta     $01
        lda     ($AC),y
        inc     $01
        inc     $01
        rts

.global _load_bb_indy
_load_bb_indy: ; $DE6C
        dec     $01
        lda     ($BB),y
        inc     $01
        rts

.global _new_execute
_new_execute: ; $DE73
        jsr     _CHRGET
        jsr     new_execute
        jsr     _disable_rom
        jmp     $A7AE ; CLEAR

.global _execute_statement
_execute_statement: ; $DE7F
        jsr     _disable_rom
        jmp     $A7EF ; execute BASIC statement

.global _add_A_to_FAC
_add_A_to_FAC: ; $DE85
        jsr     _disable_rom
        jsr     $BD7E ; add A to FAC
        jmp     _enable_rom

.global _get_element_in_expression
_get_element_in_expression: ; $DE8E
        jsr     _disable_rom
        jmp     $AE8D ; get element in expression

.global _get_int
_get_int: ; $DE94
        jsr     _disable_rom
        jsr     $AD8A ; FRMNUM eval expression, make sure it's numeric
        jsr     $B7F7 ; GETADR convert FAC into 16 bit int
        jmp     _enable_rom

.global _new_warmstart
_new_warmstart:
        jsr     _enable_rom
        jsr     reset_warmstart
        jmp     disable_rom_then_warm_start

.global _evaluate_modifier
_evaluate_modifier: ; $DEA9
        jsr     _disable_rom
        jmp     $EB48 ; evaluate SHIFT/CTRL/C=

.global _get_line_number
_get_line_number: ; $DEAF
        jsr     _disable_rom
        jsr     $A96B ; get line number
        jmp     _enable_rom

.global _basic_bsout
_basic_bsout: ; $DEB8
        jsr     _disable_rom
        jsr     $AB47 ; print character
        jmp     _enable_rom

.global _set_txtptr_to_start
_set_txtptr_to_start: ; $DEC1
        jsr     _disable_rom
        jsr     $A68E ; set TXTPTR to start of program
        jmp     _enable_rom

.global _check_for_stop
_check_for_stop: ; $DECA
        jsr     _disable_rom
        jsr     $A82C ; check for STOP
        jmp     _enable_rom

.global _relink
_relink: ; $DED3
        jsr     _disable_rom
        jsr     $A533 ; rebuild BASIC line chaining
        beq     LDEE1 ; branch always?

.global _get_filename
_get_filename: ; $DEDB
        jsr     _disable_rom
        jsr     $E257 ; get string from BASIC line, set filename
LDEE1:  jmp     _enable_rom

.global _int_to_ascii
_int_to_ascii: ; $DEE4
        jsr     _disable_rom
        jsr     $BC49 ; FLOAT UNSIGNED VALUE IN FAC+1,2
        jsr     $BDDD ; convert FAC to ASCII
        jmp     _enable_rom

.global _ay_to_float
_ay_to_float: ; $DEF0
        jsr     _disable_rom
        jsr     $B395 ; convert A/Y to float
        jmp     LDEFF

.global _int_to_fac
_int_to_fac: ; $DEF9
        jsr     _disable_rom
        jsr     $BBA6 ; convert $22/$23 to FAC
LDEFF:  iny
        jsr     $BDD7 ; print FAC
        jmp     _enable_rom


.global _print_ax_int
_print_ax_int: ; $DF06
        jsr     _disable_rom
        jsr     $BDCD ; LINPRT print A/X as integer
        jmp     _enable_rom

.global _search_for_line
_search_for_line: ; $DF0F
        jsr     _disable_rom
        jsr     $A613 ; search for BASIC line
        php
        jsr     _enable_rom
        plp
        rts

.global _CHRGET
_CHRGET: ; $DF1B
        jsr     _disable_rom
        jsr     CHRGET
LDF21:  php
        jsr     _enable_rom
        plp
        rts

.global _CHRGOT
_CHRGOT: ; $DF27
        jsr     _disable_rom
        jsr     CHRGOT
        jmp     LDF21

.global _lda_5a_indy
_lda_5a_indy: ; $DF30
        jsr     _disable_rom
        lda     ($5A),y
        jmp     _enable_rom

.global _lda_5f_indy
_lda_5f_indy: ; $DF38
        jsr     _disable_rom
        lda     ($5F),y
        jmp     _enable_rom

.global _lda_ae_indx
_lda_ae_indx: ; $DF40
        jsr     _disable_rom
        lda     ($AE,x)
        jmp     _enable_rom

.global _lda_7a_indy
_lda_7a_indy: ; $DF48
        jsr     _disable_rom
        lda     ($7A),y
        jmp     _enable_rom

.global _lda_7a_indx
_lda_7a_indx: ; DF50
        jsr     _disable_rom
        lda     ($7A,x)
        jmp     _enable_rom

.global _lda_22_indy
_lda_22_indy: ; $DF58
        jsr     _disable_rom
        lda     ($22),y
        jmp     _enable_rom

.global _lda_8b_indy
_lda_8b_indy: ; $DF60
        jsr     _disable_rom
        lda     ($8B),y
        jmp     _enable_rom

_detokenize: ; $DF68
        jsr     _disable_rom
        jmp     $A724 ; detokenize

.global _list
_list: ; $DF6E
        jsr     _disable_rom
        jmp     $A6F3 ; part of LIST

.global _print_banner_load_and_run
_print_banner_load_and_run: ; $DF74
        jsr     _disable_rom
        jsr     $E422 ; print c64 banner
        jsr     _enable_rom
        jmp     load_and_run_program

LDF80:  cmp     #$94 ; contents of $A000 in BASIC ROM
        bne     LDF8A ; BASIC ROM not visible
        jsr     _enable_rom
        jmp     kbd_handler

LDF8A:  jmp     $EB48 ; default kdb vector

.global _new_tokenize
_new_tokenize: ; $DF8D
        jsr     _enable_rom
        jsr     new_tokenize
        jmp     _disable_rom

;padding
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF

; calls into banks 0+1
.global _new_ckout
_new_ckout: ; $DFC0
        jsr     _enable_rom
        jsr     new_ckout
        jmp     _disable_rom

.global _new_bsout
_new_bsout: ; $DFC9
        jsr     _enable_rom
        jmp     new_bsout

.global _new_clall
_new_clall: ; $DFCF
        jsr     _enable_rom
        jmp     new_clall

.global _new_clrch
_new_clrch: ; $DFD5
        jsr     _enable_rom
        jmp     new_clrch

; padding
        .byte   $FF,$FF,$FF,$FF,$FF

.global LDFE0
LDFE0: ; XXX BUG ???
        .byte   $FF,$FF,$FF ; ISC ($FFFF),X
        .byte   $FF,$FF,$FF ; ISC ($FFFF),X
        .byte   $FF,$FF     ; ISC ($78FF),X - consumes "SEI"

        sei
        lda     #$42 ; bank 2 (Desktop, Freezer/Print)
        sta     $DFFF
        lda     LDE00 ; $40 ???
        pha
        lda     $A000 ; ???
        pha
        lda     #$41 ; bank 1 (Notepad, BASIC (Menu Bar))
        sta     $DFFF

.global _a_colon_asterisk
_a_colon_asterisk:
        .byte   ':','*'
.global _a_colon_asterisk_end
_a_colon_asterisk_end:

; ----------------------------------------------------------------
; I/O Area ROM End
; ----------------------------------------------------------------
