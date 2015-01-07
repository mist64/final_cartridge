; da65 V2.14 - Git d112322
; Created:    2014-12-28 14:46:58
; Input file: fc3x.bin
; Page:       1


        .setcpu "6502"

CHRGET          := $0073
CHRGOT          := $0079
new_expression  := $819F
new_mainloop    := $81FE
new_execute     := $8315
L8B54           := $8B54
new_detokenize  := $8C02
L9229           := $9229
L922A           := $922A
L94C9           := $94C9
L9511           := $9511
L9881           := $9881
new_load        := $9900
new_save        := $9903
new_ckout       := $A161
new_bsout       := $A19C
new_clall       := $A1C5
new_clrch       := $A1CB
LA533           := $A533
LA613           := $A613
LA68E           := $A68E
LA6F3           := $A6F3
LA724           := $A724
LA7AE           := $A7AE
LA7EF           := $A7EF
LA82C           := $A82C
LA96B           := $A96B
LAB47           := $AB47
LAD8A           := $AD8A
LAE8D           := $AE8D
LB395           := $B395
LB7F7           := $B7F7
LBBA6           := $BBA6
LBC49           := $BC49
LBD7E           := $BD7E
LBDCD           := $BDCD
LBDD7           := $BDD7
LBDDD           := $BDDD
LE257           := $E257
LE37B           := $E37B ; BASIC warm start (NMI)
LE422           := $E422
LEB48           := $EB48

.segment        "romio": absolute

LDE00:  .byte   $40

_jmp_bank:
        sta     LDFFF
        rts

_enable_rom: ; $DE05
        pha
        lda     #$40 ; bank 0
LDE08:  sta     LDFFF
        pla
        rts

_disable_rom_set_01:; $DE0D
        sty     $01
_disable_rom: ; $DE0F
        pha
        lda     #$70 ; no ROM at $8000; BASIC at $A000
        bne     LDE08

_basic_warm_start: ; $DE14
        jsr     _disable_rom
        jmp     LE37B ; BASIC warm start (NMI)

enable_all_roms:  
        ora     #$07
        sta     $01
        bne     _enable_rom

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

_new_save: ; $DE35
        lda     $01
        pha
        jsr     enable_all_roms
        jsr     new_save
        jmp     LDE2B

_new_mainloop: ; $DE41
        lda     $01
        jsr     enable_all_roms
        jmp     new_mainloop

_new_detokenize: ; $DE49
        jsr     _enable_rom
        jmp     new_detokenize

_new_expression: ; $DE4F
        jsr     _enable_rom
        jmp     new_expression

        lda     $02A7
        beq     LDE5D
        jmp     $EB42 ; LDA #$7F : STA $DC00 : RTS

LDE5D:  lda     $A000
        jmp     LDF80

_load_ac_indy: ; $DE63
        sta     $01
        lda     ($AC),y
        inc     $01
        inc     $01
        rts

_load_bb_indy: ; $DE6C
        dec     $01
        lda     ($BB),y
        inc     $01
        rts

_new_execute: ; $DE73
        jsr     _CHRGET
        jsr     new_execute
        jsr     _disable_rom
        jmp     LA7AE

_execute_statement: ; $DE7F
        jsr     _disable_rom
        jmp     LA7EF ; execute BASIC statement

_add_A_to_FAC: ; $DE85
        jsr     _disable_rom
        jsr     LBD7E ; add A to FAC
        jmp     _enable_rom

_get_element_in_expression: ; $DE8E
        jsr     _disable_rom
        jmp     LAE8D ; get element in expression

_get_int: ; $DE94
        jsr     _disable_rom
        jsr     LAD8A ; FRMNUM eval expression, make sure it's numeric
        jsr     LB7F7 ; GETADR convert FAC into 16 bit int
        jmp     _enable_rom

_new_warmstart:
        jsr     _enable_rom
        jsr     L8B54
        jmp     L9881

_evaluate_modifier: ; $DEA9
        jsr     _disable_rom
        jmp     LEB48 ; evaluate SHIFT/CTRL/C=

_get_line_number: ; $DEAF
        jsr     _disable_rom
        jsr     LA96B ; get line number
        jmp     _enable_rom

_basic_bsout: ; $DEB8
        jsr     _disable_rom
        jsr     LAB47 ; print character
        jmp     _enable_rom

_set_txtptr_to_start: ; $DEC1
        jsr     _disable_rom
        jsr     LA68E ; set TXTPTR to start of program
        jmp     _enable_rom

_check_for_stop: ; $DECA
        jsr     _disable_rom
        jsr     LA82C ; check for STOP
        jmp     _enable_rom

_relink: ; $DED3
        jsr     _disable_rom
        jsr     LA533 ; rebuild BASIC line chaining
        beq     LDEE1 ; branch always?

_get_filename: ; $DEDB
        jsr     _disable_rom
        jsr     LE257 ; get string from BASIC line, set filename
LDEE1:  jmp     _enable_rom

_int_to_ascii: ; $DEE4
        jsr     _disable_rom
        jsr     LBC49 ; FLOAT UNSIGNED VALUE IN FAC+1,2
        jsr     LBDDD ; convert FAC to ASCII
        jmp     _enable_rom

_ay_to_float: ; $DEF0
        jsr     _disable_rom
        jsr     LB395 ; convert A/Y to float
        jmp     LDEFF

_int_to_fac: ; $DEF9
        jsr     _disable_rom
        jsr     LBBA6 ; convert $22/$23 to FAC
LDEFF:  iny
        jsr     LBDD7 ; print FAC
        jmp     _enable_rom


_print_ax_int: ; $DF06
        jsr     _disable_rom
        jsr     LBDCD ; LINPRT print A/X as integer
        jmp     _enable_rom

_search_for_line: ; $DF0F
        jsr     _disable_rom
        jsr     LA613 ; search for BASIC line
        php
        jsr     _enable_rom
        plp
        rts

_CHRGET: ; $DF1B
        jsr     _disable_rom
        jsr     CHRGET
LDF21:  php
        jsr     _enable_rom
        plp
        rts

_CHRGOT: ; $DF27
        jsr     _disable_rom
        jsr     CHRGOT
        jmp     LDF21

_lda_5a_indy: ; $DF30
        jsr     _disable_rom
        lda     ($5A),y
        jmp     _enable_rom

_lda_5f_indy: ; $DF38
        jsr     _disable_rom
        lda     ($5F),y
        jmp     _enable_rom

_lda_ae_indx: ; $DF40
        jsr     _disable_rom
        lda     ($AE,x)
        jmp     _enable_rom

_lda_7a_indy: ; $DF48
        jsr     _disable_rom
        lda     ($7A),y
        jmp     _enable_rom

_lda_7a_indx: ; DF50
        jsr     _disable_rom
        lda     ($7A,x)
        jmp     _enable_rom

_lda_22_indy: ; $DF58
        jsr     _disable_rom
        lda     ($22),y
        jmp     _enable_rom

_lda_8b_indy: ; $DF60
        jsr     _disable_rom
        lda     ($8B),y
        jmp     _enable_rom

_detokenize: ; $DF68
        jsr     _disable_rom
        jmp     LA724 ; detokenize

_list: ; $DF6E
        jsr     _disable_rom
        jmp     LA6F3 ; part of LIST

_print_banner_jmp_9511: ; $DF74
        jsr     _disable_rom
        jsr     LE422 ; print c64 banner
        jsr     _enable_rom
        jmp     L9511

LDF80:  .addr   L94C9
        bne     LDF8A
        jsr     _enable_rom
        jmp     L9229

LDF8A:  jmp     LEB48

_new_tokenize: ; $DF8D
        jsr     _enable_rom
        .byte   $20,$53,$82,$4C,$0F,$DE,$FF,$FF

;padding
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

; calls into banks 0+1
_new_ckout: ; $DFC0
        jsr     _enable_rom
        jsr     new_ckout
        jmp     _disable_rom

_new_bsout: ; $DFC9
        jsr     _enable_rom
        jmp     new_bsout

_new_clall: ; $DFCF
        jsr     _enable_rom
        jmp     new_clall

_new_clrch: ; $DFD5
        jsr     _enable_rom
        jmp     new_clrch

; padding
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF

; unused?
        sei
        lda     #$42 ; bank 2 (Desktop, Freezer/Print)
        sta     LDFFF
        lda     LDE00 ; $40 ???
        pha
        lda     $A000 ; ???
        pha
        lda     #$41 ; bank 1 (Notepad, BASIC (Menu Bar))
        sta     LDFFF
; ???
        .byte   $3A,$2A,$FF,$FF
LDFFF:  .byte   $FF

.code

