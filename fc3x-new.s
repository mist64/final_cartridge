; da65 V2.14 - Git d112322
; Created:    2014-12-28 14:46:58
; Input file: fc3x.bin
; Page:       1


        .setcpu "6502"

CHRGET          := $0073
CHRGOT          := $0079
L819F           := $819F
L81FE           := $81FE
L8315           := $8315
L8B54           := $8B54
L8C02           := $8C02
L9229           := $9229
L922A           := $922A
L9511           := $9511
L9881           := $9881
L9900           := $9900
L9903           := $9903
LA161           := $A161
LA19C           := $A19C
LA1C5           := $A1C5
LA1CB           := $A1CB
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
LE37B           := $E37B
LE422           := $E422
LEB42           := $EB42
LEB48           := $EB48

.segment        "fc3x": absolute

LDE00:  .byte   $40

jmp_bank:
        sta     LDFFF
        rts

enable_rom: ; $DE05
        pha
        lda     #$40 ; bank 0
LDE08:  sta     LDFFF
        pla
        rts

        sty     $01

disable_rom: ; $DE0F
        pha
        lda     #$70 ; no ROM at $8000; BASIC at $A000
        bne     LDE08
        jsr     disable_rom
        jmp     LE37B

LDE1A:  ora     #$07
        sta     $01
        bne     enable_rom
        tay
        tay
        lda     $01
        pha
        jsr     LDE1A
        jsr     L9900
LDE2B:  tax
        pla
        sta     $01
        txa
        ldx     $AE
        jmp     disable_rom

        lda     $01
        pha
        jsr     LDE1A
        jsr     L9903
        jmp     LDE2B

        lda     $01
        jsr     LDE1A
        jmp     L81FE

        jsr     enable_rom
        jmp     L8C02

        jsr     enable_rom
        jmp     L819F

        lda     $02A7
        beq     LDE5D
        jmp     LEB42

LDE5D:  jsr     enable_rom
        jmp     L9229

        sta     $01
        lda     ($AC),y
        inc     $01
        inc     $01
        rts

        dec     $01
        lda     ($BB),y
        inc     $01
        rts

        jsr     _CHRGET
        jsr     L8315
        jsr     disable_rom
        jmp     LA7AE

        jsr     disable_rom
        jmp     LA7EF ; execute BASIC statement

        jsr     disable_rom
        jsr     LBD7E ; add A to FAC
        jmp     enable_rom

        jsr     disable_rom
        jmp     LAE8D ; get element in expression

        jsr     disable_rom
        jsr     LAD8A ; FRMNUM eval expression, make sure it's numeric
        jsr     LB7F7 ; GETADR convert FAC into 16 bit int
        jmp     enable_rom

        jsr     enable_rom
        jsr     L8B54
        jmp     L9881

        jsr     disable_rom
        jmp     LEB48 ; evaluate SHIFT/CTRL/C=

        jsr     disable_rom
        jsr     LA96B ; get line number
        jmp     enable_rom

        jsr     disable_rom
        jsr     LAB47 ; print character
        jmp     enable_rom

        jsr     disable_rom
        jsr     LA68E ; set TXTPTR to start of program
        jmp     enable_rom

        jsr     disable_rom
        jsr     LA82C ; check for STOP
        jmp     enable_rom

        jsr     disable_rom
        jsr     LA533 ; rebuild BASIC line chaining
        beq     LDEE1
        jsr     disable_rom
        jsr     LE257 ; get string from BASIC line, set filename
LDEE1:  jmp     enable_rom

        jsr     disable_rom
        jsr     LBC49 ; FLOAT UNSIGNED VALUE IN FAC+1,2
        jsr     LBDDD ; convert FAC to ASCII
        jmp     enable_rom

        jsr     disable_rom
        jsr     LB395 ; convert A/Y to float
        jmp     LDEFF

        jsr     disable_rom
        jsr     LBBA6 ; convert $22/$23 to FAC
LDEFF:  iny
        jsr     LBDD7 ; print FAC
        jmp     enable_rom

        jsr     disable_rom
        jsr     LBDCD ; print A/X as integer
        jmp     enable_rom

        jsr     disable_rom
        jsr     LA613 ; search for BASIC line
        php
        jsr     enable_rom
        plp
        rts

_CHRGET: ; $DF1B
        jsr     disable_rom
        jsr     CHRGET
LDF21:  php
        jsr     enable_rom
        plp
        rts

_CHRGOT: ; $DF27
        jsr     disable_rom
        jsr     CHRGOT
        jmp     LDF21

_lda_5a_indy: ; $DF30
        jsr     disable_rom
        lda     ($5A),y
        jmp     enable_rom

_lda_5f_indy: ; $DF38
        jsr     disable_rom
        lda     ($5F),y
        jmp     enable_rom

_lda_ae_indx: ; $DF40
        jsr     disable_rom
        lda     ($AE,x)
        jmp     enable_rom

_lda_7a_indy: ; $DF48
        jsr     disable_rom
        lda     ($7A),y
        jmp     enable_rom

_lda_7a_indx: ; DF50
        jsr     disable_rom
        lda     ($7A,x)
        jmp     enable_rom

_lda_22_indy: ; $DF58
        jsr     disable_rom
        lda     ($22),y
        jmp     enable_rom

_lda_8b_indy: ; $DF60
        jsr     disable_rom
        lda     ($8B),y
        jmp     enable_rom

_detokenize: ; $DF68
        jsr     disable_rom
        jmp     LA724 ; detokenize

_list: ; $DF6E
        jsr     disable_rom
        jmp     LA6F3 ; part of LIST

; $DF74
        jsr     disable_rom
        jsr     LE422 ; print c64 banner
        jsr     enable_rom
        jmp     L9511

        .addr   L922A

        jsr     LE422 ; print c64 banner
        jsr     enable_rom
        jmp     L922A

        iny
        jmp     LBDD7; print FAC

;padding
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF

; calls into banks 0+1
        jsr     enable_rom
        jsr     LA161
        jmp     disable_rom

        jsr     enable_rom
        jmp     LA19C

        jsr     enable_rom
        jmp     LA1C5

        jsr     enable_rom
        jmp     LA1CB

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

; End of "fc3x" segment
.code

