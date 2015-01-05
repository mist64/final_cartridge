; da65 V2.14 - Git d112322
; Created:    2015-01-05 13:48:58
; Input file: fc3a.bin
; Page:       1

;   The Final Cartridge 3
;
;   - 4 16K ROM Banks at $8000/$a000 (=64K)
;
;        Bank 0:  BASIC, Monitor, Disk-Turbo
;        Bank 1:  Notepad, BASIC (Menu Bar)
;        Bank 2:  Desktop, Freezer/Print
;        Bank 3:  Freezer, Compression
;
;   - the cartridges uses the entire io1 and io2 range
;
;   - one register at $DFFF:
;
;    7      Hide this register (1 = hidden)
;    6      NMI line   (0 = low = active) *1)
;    5      GAME line  (0 = low = active) *2)
;    4      EXROM line (0 = low = active)
;    2-3    unassigned (usually set to 0)
;    0-1    number of bank to show at $8000
;
;    1) if either the freezer button is pressed, or bit 6 is 0, then
;       an NMI is generated
;
;    2) if the freezer button is pressed, GAME is also forced low
;
;    - the rest of io1/io2 contain a mirror of the last 2 pages of the
;      currently selected rom bank (also at $dfff, contrary to what some
;      other documents say)

        .setcpu "6502"

CHRGET          := $0073
L0100           := $0100
L0110           := $0110
L01B8           := $01B8
L045C           := $045C
L0463           := $0463
L04F6           := $04F6
L0582           := $0582
L0630           := $0630
LA000           := $A000
set_io_vectors_with_hidden_rom := $A004
set_io_vectors  := $A007
LA00A           := $A00A
LA612           := $A612
LA648           := $A648
LA659           := $A659
LA663           := $A663
LA691           := $A691
LA694           := $A694
LA6D5           := $A6D5
LA71B           := $A71B
LA762           := $A762
LA77E           := $A77E
LA784           := $A784
LA7A8           := $A7A8
LA7AE           := $A7AE
LA7C6           := $A7C6
LA851           := $A851
LA8FF           := $A8FF
LA9BB           := $A9BB
monitor         := $AB00
LC100           := $C100
LC194           := $C194
LC1E5           := $C1E5
LC1F3           := $C1F3
LC268           := $C268
LC8E8           := $C8E8
LD6D3           := $D6D3

_jmp_bank       := $DE01
_disable_rom_set_01 := $DE0D
_disable_rom    := $DE0F
_new_load       := $DE20
_new_save       := $DE35
_new_mainloop   := $DE41
_new_detokenize := $DE49
_new_expression := $DE4F
_load_ac_indy   := $DE63
_load_bb_indy   := $DE6C
_new_execute    := $DE73
_execute_statement := $DE7F
_add_A_to_FAC   := $DE85
_get_element_in_expression := $DE8E
_get_int        := $DE94
_evaluate_modifier := $DEA9
_get_line_number := $DEAF
_basic_bsout    := $DEB8
_set_txtptr_to_start := $DEC1
_check_for_stop := $DECA
_relink         := $DED3
_get_filename   := $DEDB
_int_to_ascii   := $DEE4
_ay_to_float    := $DEF0
_int_to_fac     := $DEF9
_print_ax_int   := $DF06
_search_for_line := $DF0F
_CHRGET         := $DF1B
_CHRGOT         := $DF27
_lda_5a_indy    := $DF30
_lda_5f_indy    := $DF38
_lda_ae_indx    := $DF40
_lda_7a_indy    := $DF48
_lda_7a_indx    := $DF50
_lda_22_indy    := $DF58
_lda_8b_indy    := $DF60
_list           := $DF6E
_print_banner_jmp_9511 := $DF74

LE16F           := $E16F
LE206           := $E206
LE34C           := $E34C
LE386           := $E386
LE3B3           := $E3B3
LE3BF           := $E3BF
LE453           := $E453
LE566           := $E566
LE56A           := $E56A
LE60A           := $E60A
LE716           := $E716
LE88C           := $E88C
LE9C8           := $E9C8
LE9F0           := $E9F0
LE9FF           := $E9FF
LEA18           := $EA18
LED09           := $ED09
LEDBE           := $EDBE
LEDC7           := $EDC7
LEE13           := $EE13
LEE40           := $EE40
LEE46           := $EE46
LF40B           := $F40B
LF418           := $F418
LF497           := $F497
LF530           := $F530
LF556           := $F556
LF5A9           := $F5A9
LF5ED           := $F5ED
LF636           := $F636
LF646           := $F646
LF6D0           := $F6D0
LF7E8           := $F7E8
LF99C           := $F99C
LFB8E           := $FB8E
LFCB1           := $FCB1
LFCDB           := $FCDB
LFD15           := $FD15
LFDA3           := $FDA3
LFDD3           := $FDD3
LFE00           := $FE00
LFE0E           := $FE0E
LFE2D           := $FE2D
LFE5E           := $FE5E
LFF5B           := $FF5B
CINT            := $FF81
IOINIT          := $FF84
RAMTAS          := $FF87
RESTOR          := $FF8A
VECTOR          := $FF8D
SETMSG          := $FF90
SECOND          := $FF93
TKSA            := $FF96
MEMTOP          := $FF99
MEMBOT          := $FF9C
SCNKEY          := $FF9F
SETTMO          := $FFA2
IECIN           := $FFA5
IECOUT          := $FFA8
UNTALK          := $FFAB
UNLSTN          := $FFAE
LISTEN          := $FFB1
TALK            := $FFB4
READST          := $FFB7
SETLFS          := $FFBA
SETNAM          := $FFBD
OPEN            := $FFC0
CLOSE           := $FFC3
CHKIN           := $FFC6
CKOUT           := $FFC9
CLRCH           := $FFCC
BASIN           := $FFCF
BSOUT           := $FFD2
LOAD            := $FFD5
SAVE            := $FFD8
SETTIM          := $FFDB
RDTIM           := $FFDE
STOP            := $FFE1
GETIN           := $FFE4
CLALL           := $FFE7
UDTIM           := $FFEA
SCREEN          := $FFED
PLOT            := $FFF0
IOBASE          := $FFF3

.segment        "fc3a": absolute

        .addr   entry ; FC3 entry
        .addr   LFE5E ; default cartridge soft reset entry point
        .byte   $C3,$C2,$CD,"80" ; 'cbm80'

entry:  jmp     entry2

        jmp     L955E

fast_format: ; $A00F
        jmp     fast_format2

        jmp     L96FB

        jmp     L971A

        jmp     L803B

        jmp     L80CE

        jmp     L9473

        jmp     init_basic_vectors

        jsr     set_io_vectors_with_hidden_rom
        lda     #$43 ; bank 2
        jmp     _jmp_bank

init_basic_vectors:
        jsr     init_load_save_vectors
L802F:  ldx     #$09
L8031:  lda     basic_vectors,x ; overwrite BASIC vectors
        sta     $0302,x
        dex
        bpl     L8031
        rts

L803B:  jsr     init_load_save_vectors
        jsr     L802F
        lda     #$BF
        pha
        lda     #$F9
        pha
        lda     #$42 ; bank 2
        jmp     _jmp_bank

entry2: 
        ; short-circuit startup, skipping memory test
        jsr     LFDA3 ; init I/O
        lda     $D011
        pha
        lda     $DC01
        pha
        lda     #$00 ; clear pages 0, 2, 3
        tay
L805A:  sta     $02,y
        sta     $0200,y
        sta     $0300,y
        iny
        bne     L805A
        ldx     #<$A000
        ldy     #>$A000
        jsr     LFE2D ; set memtop
        lda     #$08
        sta     $0282 ; start of BASIC $0800
        lda     #$04
        sta     $0288 ; start of screen RAM $0400
        lda     #<$033C
        sta     $B2
        lda     #>$033C
        sta     $B3 ; datasette buffer
        jsr     LFD15 ; init I/O (same as RESTOR)
        jsr     LFF5B ; video reset (same as CINT)
        jsr     LE453 ; assign $0300 BASIC vectors
        jsr     init_basic_vectors
        cli
        pla ; $ D
        tax
        pla
        cpx     #$7F ; $DC01 value
        beq     L80C4
        cpx     #$DF
        beq     go_desktop
        and     #$7F
        beq     go_desktop
        ldy     #$03
L809D:  lda     $CFFC,y
        cmp     mg87_signature,y
        bne     L80AA
        dey
        bpl     L809D
        bmi     go_desktop ; MG87 found
L80AA:  jmp     (LA000)

mg87_signature:
        .byte   "MG87"

go_desktop:
        lda     #$80
        sta     $02A8 ; unused
        jsr     LE3BF ; init BASIC, print banner
        lda     #>($8000 - 1)
        pha
        lda     #<($8000 - 1)
        pha
        lda     #$42 ; bank 2 + 3 $8000-BFFF
        jmp     _jmp_bank ; jump to desktop

L80C4:  ldx     #'M'
        cpx     $CFFC
        bne     L80CE
        dec     $CFFC ; destroy signature
L80CE:  ldx     #<$A000
        ldy     #>$A000
        jsr     LFE2D ; set MEMTOP
        lda     #>($E397 - 1)
        pha
        lda     #<($E397 - 1) ; BASIC start
        pha
        jmp     _disable_rom

load_save_vectors:
        .addr   _new_load       ; $0330 LOAD
        .addr   _new_save       ; $0332 SAVE
basic_vectors:
        .addr   _new_mainloop   ; $0302 IMAIN  BASIC direct mode
        .addr   $A57C           ; $0304 ICRNCH tokenization (original value!)
        .addr   _new_detokenize ; $0306 IQPLOP token decoder
        .addr   _new_execute    ; $0308 IGONE  execute instruction
        .addr   _new_expression ; $030A IEVAL  execute expression

; update the load and save vectors only if all hardware vectors are
; the KERNAL defaults
cond_init_load_save_vectors:
        ldy     #$1F
L80EE:  lda     $0314,y
        cmp     $FD30,y
        bne     L810F ; rts
        dey
        bpl     L80EE

init_load_save_vectors:
        jsr     set_io_vectors_with_hidden_rom
        ldy     #$03
L80FE:  lda     load_save_vectors,y ; overwrite LOAD and SAVE vectors
        sta     $0330,y
        dey
        bpl     L80FE
        lda     $02A6
        beq     L810F
        inc     $0330
L810F:  rts

L8110:  jsr     IECIN
        jsr     LE716
        cmp     #$0D
        bne     L8110
        jmp     UNTALK

L811D:  jsr     L8141
        jsr     IECIN
        tay
L8124:  jsr     IECIN
        cmp     #$0D
        bne     L8124
        jsr     UNTALK
        cpy     #$30
        rts

open_cmd_channel:
        lda     #$6F
L8133:  pha
        jsr     L8BC4
        jsr     LISTEN
        pla
        jsr     SECOND
        lda     $90
        rts

L8141:  lda     #$6F
L8143:  pha
        jsr     L8BC4
        jsr     TALK
        pla
        jmp     TKSA

m_w_and_m_e:
        sta     $C3
        sty     $C4
        ldy     #$00
L8154:  lda     #'W'
        jsr     send_m_dash
        tya
        jsr     IECOUT
        txa
        jsr     IECOUT
        lda     #' '
        jsr     IECOUT
L8166:  lda     ($C3),y
        jsr     IECOUT
        iny
        tya
        and     #$1F
        bne     L8166
        jsr     UNLSTN
        tya
        bne     L8154
        inc     $C4
        inx
        cpx     $93
        bcc     L8154
        lda     #'E'
send_m_dash:
        pha
        jsr     L8192
        lda     #'M'
        jsr     IECOUT
        lda     #'-'
        jsr     IECOUT
        pla
        jmp     IECOUT

L8192:  lda     #$6F
L8194:  jsr     L8133
        bmi     L819A
        rts

L819A:  ldx     #$05
        jmp     L9873

new_expression:
        lda     #$00
        sta     $0D
        jsr     _CHRGET
        cmp     #$24
        beq     L81B0
        jsr     _CHRGOT
        jmp     _get_element_in_expression

L81B0:  lda     #$00
        ldx     #$0A
L81B4:  sta     $5D,x
        dex
        bpl     L81B4
L81B9:  jsr     _CHRGET
        bcc     L81C4
        cmp     #$41
        bcc     L81DF
        sbc     #$08
L81C4:  sbc     #$2F
        cmp     #$10
        bcs     L81DF
        pha
        lda     $61
        beq     L81D8
        adc     #$04
        bcc     L81D6
        jmp     L985E

L81D6:  sta     $61
L81D8:  pla
        jsr     _add_A_to_FAC
        jmp     L81B9

L81DF:  clc
        jmp     _disable_rom

L81E3:  lda     #$16
        sta     $0326
        lda     #$E7
        sta     $0327
        rts

AUTO:   jsr     L85F1
        jsr     L8512
        jsr     L84ED
        pla
        pla
        lda     #$40
L81FB:  sta     $02A9

new_mainloop: ; $81FE
        jsr     L8C71
        jsr     cond_init_load_save_vectors
        jsr     L81E3
        jsr     L98BB
        stx     $7A ; chrget ptr
        sty     $7B
        jsr     set_io_vectors_with_hidden_rom
        jsr     L8C68
        jsr     CHRGET
        tax
        beq     L81FB
        ldx     $3A
        stx     $02AC
        ldx     #$FF
        stx     $3A
        bcc     L822B
        jsr     L8253
        jmp     _new_execute

L822B:  jsr     _get_line_number
        tax
        bne     L8234
        sta     $02A9
L8234:  bit     $02A9
        bvc     L824D
        clc
        lda     $14
        adc     $0336
        sta     $0334
        lda     $15
        adc     $0337
        sta     $0335
        jsr     L84ED
L824D:  jsr     L8253
        jmp     L9865

L8253:  ldx     $7A
        ldy     #$04
        sty     $0F
L8259:  lda     $0200,x
        bpl     L8265
        cmp     #$FF
        beq     L82B6
        inx
        bne     L8259
L8265:  cmp     #$20
        beq     L82B6
        sta     $08
        cmp     #$22
        beq     L82DB
        bit     $0F
        bvs     L82B6
        cmp     #$3F
        bne     L827B
        lda     #$99
        bne     L82B6
L827B:  cmp     #$30
        bcc     L8283
        cmp     #$3C
        bcc     L82B6
L8283:  sty     $71
        stx     $7A
        ldy     #$0A
        sty     $22
        ldy     #$86
        sty     $23
L828F:  ldy     #$00
        sty     $0B
        dex
L8294:  inx
        inc     $22
        bne     L829B
        inc     $23
L829B:  lda     $0200,x
        sec
        sbc     ($22),y
        beq     L8294
        cmp     #$80
        bne     L82E2
        ldy     $23
        cpy     #$A9
        bcs     L82B2
        lda     $0B
        adc     #$CC
        .byte   $2C
L82B2:  ora     $0B
L82B4:  ldy     $71
L82B6:  inx
        iny
        sta     $01FB,y
        lda     $01FB,y
        beq     L830B
        sec
        sbc     #$3A
        beq     L82C9
        cmp     #$49
        bne     L82CB
L82C9:  sta     $0F
L82CB:  sec
        sbc     #$55
        bne     L8259
        sta     $08
L82D2:  lda     $0200,x
        beq     L82B6
        cmp     $08
        beq     L82B6
L82DB:  iny
        sta     $01FB,y
        inx
        bne     L82D2
L82E2:  ldx     $7A
        inc     $0B
L82E6:  lda     ($22),y
        php
        inc     $22
        bne     L82EF
        inc     $23
L82EF:  plp
        bpl     L82E6
        lda     ($22),y
        bne     L829B
        lda     $23
        cmp     #$A9
        bcs     L8306
        lda     #$A9
        sta     $23
        lda     #$FF
        sta     $22
        bne     L828F
L8306:  lda     $0200,x
        bpl     L82B4
L830B:  sta     $01FD,y
        dec     $7B
        lda     #$FF
        sta     $7A
        rts

new_execute:
        beq     L8342
        ldx     $3A
        inx
        beq     L8327 ; direct mode
        ldx     $02AA
        beq     L8327
        jsr     L8345
        jsr     _CHRGOT
L8327:  cmp     #$CC ; first new token
        bcs     L832F
        sec
L832C:  jmp     _execute_statement

L832F:  cmp     #$E9 ; last new token + 1
        bcs     L832C
        sbc     #$CB
        asl     a
        tay
        lda     L8693+1,y
        pha
        lda     L8693,y
        pha
        jmp     _CHRGET

L8342:  jmp     _disable_rom

L8345:  lda     $D3
        pha
        lda     $D5
        pha
        lda     $D6
        pha
        lda     $D4
        pha
L8351:  lda     $028D
        lsr     a
        lsr     a
        bcs     L8351
        lsr     a
        bcc     L8369
        lda     #$02
        ldx     #$00
L835F:  iny
        bne     L835F
        inx
        bne     L835F
        sbc     #$01
        bne     L835F
L8369:  jsr     LE566
        jsr     L839D
        ldx     $B1
        jsr     LE88C
        ldy     $B0
        sty     $D3
        lda     ($D1),y
        eor     #$80
        sta     ($D1),y
        pla
        sta     $D4
        pla
        tax
        jsr     LE88C
        pla
        sta     $D5
        pla
        sta     $D3
L838C:  rts

HELP:   ldx     $3A
        inx
        bne     L839D
        lda     $7B
        cmp     #$02
        bne     L839D
        ldx     $02AC
        stx     $3A
L839D:  ldx     $3A
        stx     $15
        txa
        inx
        beq     L838C
        ldx     $39
        stx     $14
        jsr     _print_ax_int
        jsr     _search_for_line
        lda     $D3
        sta     $B0
        lda     $D6
        sta     $B1
        jsr     L83C8
L83BA:  lda     #$0D ; CR
        jsr     _basic_bsout
        bit     $13
        bpl     L838C
        lda     #$0A ; LF
        jmp     _basic_bsout

L83C8:  ldy     #$03
        sty     $49
        sty     $0F
        lda     #$20 ; ' '
        and     #$7F
L83D2:  jsr     _basic_bsout
        cmp     #$22
        bne     L83DF
        lda     $0F
        eor     #$80
        sta     $0F
L83DF:  iny
        ldx     $60
        tya
        clc
        adc     $5F
        bcc     L83E9
        inx
L83E9:  cmp     $7A
        bne     L83F9
        cpx     $7B
        bne     L83F9
        lda     $D3
        sta     $B0
        lda     $D6
        sta     $B1
L83F9:  jsr     _lda_5f_indy
        beq     L8404
        jsr     L8C11
        jmp     L83D2 ; loop

L8404:  lda     #$20
        ldy     $D3
L8408:  sta     ($D1),y
        cpy     $D5
        bcs     L8411
        iny
        bne     L8408
L8411:  rts

L8412:  stx     $C1
        sta     $C2
        lda     #$31
        sta     $C3
        ldx     #$04
L841C:  dec     $C3
L841E:  lda     #$2F
        sta     $C4
        sec
        ldy     $C1
        .byte   $2C
L8426:  sta     $C2
        sty     $C1
        inc     $C4
        tya
        sbc     L8449,x
        tay
        lda     $C2
        sbc     L844E,x
        bcs     L8426
        lda     $C4
        cmp     $C3
        beq     L8443
        jsr     _basic_bsout
        dec     $C3
L8443:  dex
        beq     L841C
        bpl     L841E
        rts

L8449:  .byte   $01,$0A,$64,$E8,$10
L844E:  .byte   $00,$00,$00,$03,$27
L8453:  lda     #$60
        jsr     L8143
        jsr     IECIN
        jsr     IECIN
L845E:  jsr     L84C8
        jsr     IECIN
        jsr     IECIN
        jsr     IECIN
        tax
        jsr     IECIN
        ldy     $90
        bne     L84C0
        jsr     L84DC
        jsr     L8412
        lda     #$20 ; ' '
        jsr     _basic_bsout
        ldx     #$18
L847F:  jsr     L84C8
        jsr     IECIN
L8485:  cmp     #$0D
        beq     L848D
        cmp     #$8D
        bne     L848F
L848D:  lda     #$1F
L848F:  ldy     $90
        bne     L84C0
        jsr     L84DC
        jsr     _basic_bsout
        inc     $D8
        jsr     GETIN
        cmp     #$03
        beq     L84C0
        cmp     #$20
        bne     L84AB
L84A6:  jsr     GETIN
        beq     L84A6
L84AB:  dex
        bpl     L847F
        jsr     L84C8
        jsr     IECIN
        bne     L8485
        jsr     L84DC
        lda     #$0D ; CR
        jsr     _basic_bsout
        bne     L845E
L84C0:  lda     #$E0
        jsr     L8143
        jmp     UNLSTN

L84C8:  lda     $9A
        cmp     #$03
        beq     L84DB
        bit     $DD0C
        bmi     L84DB
        jsr     UNLSTN
        lda     #$60
        jsr     L8143
L84DB:  rts

L84DC:  bit     $DD0C
        bmi     L84EC
        pha
        lda     $9A
        cmp     #$03
        beq     L84EB
        jsr     L8B19
L84EB:  pla
L84EC:  rts

L84ED:  lda     $0334
        ldy     $0335
        jsr     L8508
        ldy     #$00
L84F8:  iny
        lda     $FF,y
        php
        ora     #$20
        sta     $0276,y
        plp
        bne     L84F8
        sty     $C6
        rts

L8508:  sta     $63
        sty     $62
        ldx     #$90
        sec
        jmp     _int_to_ascii

L8512:  jsr     _CHRGOT
        beq     L8528
        ldy     #$00
        jsr     L858E
        beq     L8528
        cmp     #$2C
        bne     L852C
        jsr     _CHRGET
        jsr     L858E
L8528:  rts

        jmp     L985E

L852C:  jmp     L9855

L852F:  beq     L852C
L8531:  php
        ldy     #$00
        jsr     L85A0
        pha
        jsr     _search_for_line
        pla
        ldx     $AC
        stx     $AE
        ldx     $AD
        stx     $AF
        plp
        bne     L854B
        dec     $AF
        dec     $15
L854B:  tax
        beq     L8568
        cmp     #$3A
        beq     L8568
        cmp     #$AB
        bne     L852C
        jsr     _CHRGET
        php
        ldy     #$02
        jsr     L85A0
        bne     L852C
        plp
        bne     L8568
        dec     $15
        dec     $AF
L8568:  lda     $AE
        cmp     $AC
        lda     $AF
        sbc     $AD
        bcc     L852C
        lda     $5F
        sta     $7A
        lda     $60
        sta     $7B
        jsr     _search_for_line
        bcc     L858D
        ldy     #$00
        jsr     _lda_5f_indy
        tax
        iny
        jsr     _lda_5f_indy
        sta     $60
        stx     $5F
L858D:  rts

L858E:  jsr     _get_line_number
        lda     $14
        sta     $0334,y
        iny
        lda     $15
        sta     $0334,y
        iny
        jmp     _CHRGOT

L85A0:  jsr     _get_line_number
        ldx     $14
        stx     $AC,y
        ldx     $15
        stx     $AD,y
        jmp     _CHRGOT

L85AE:  lda     $0334
        sta     $AC
        lda     $0335
        sta     $AD
        jmp     _set_txtptr_to_start

L85BB:  jsr     L85BF
        tay
L85BF:  inc     $7A
        bne     L85C5
        inc     $7B
L85C5:  ldx     #$00
        jsr     _lda_7a_indx
        rts

L85CB:  clc
        lda     $AC
        adc     $0336
        sta     $AC
        lda     $AD
        adc     $0337
        sta     $AD
        bcs     L85DE
        cmp     #$FA
L85DE:  rts

L85DF:  jsr     L85BB
L85E2:  jsr     L85BF
        bne     L85E2
        rts

L85E8:  lda     $7A
        sta     $5A
        lda     $7B
        sta     $5B
        rts

L85F1:  ldx     #$03
L85F3:  lda     L8606,x
        sta     $0334,x
        dex
        bpl     L85F3
        rts

L85FD:  .byte   $9B,$8A,$A7,$89,$8D,$CB
L8603:  .byte   $AB,$A4,$2C
L8606:  .byte   $64,$00,$0A,$00,$FF

        .byte   "OF", 'F' + $80
        .byte   "AUT", 'O' + $80
        .byte   "DE", 'L' + $80
        .byte   "RENU", 'M' + $80
        .byte   "HEL", 'P' + $80
        .byte   "FIN", 'D' + $80
        .byte   "OL", 'D' + $80
        .byte   "DLOA", 'D' + $80
        .byte   "DVERIF", 'Y' + $80
        .byte   "DSAV", 'E' + $80
        .byte   "APPEN", 'D' + $80
        .byte   "DAPPEN", 'D' + $80
        .byte   "DO", 'S' + $80
        .byte   "KIL", 'L' + $80
        .byte   "MO", 'N' + $80
        .byte   "PDI", 'R' + $80
        .byte   "PLIS", 'T' + $80
        .byte   "BA", 'R' + $80
        .byte   "DESKTO", 'P' + $80
        .byte   "DUM", 'P' + $80
        .byte   "ARRA", 'Y' + $80
        .byte   "ME", 'M' + $80
        .byte   "TRAC", 'E' + $80
        .byte   "REPLAC", 'E' + $80
        .byte   "ORDE", 'R' + $80
        .byte   "PAC", 'K' + $80
        .byte   "UNPAC", 'K' + $80
        .byte   "MREA", 'D' + $80
        .byte   "MWRIT", 'E' + $80
        .byte 0

L8693:  .word   OFF-1
        .word   AUTO-1
        .word   DEL-1
        .word   RENUM-1
        .word   HELP-1
        .word   FIND-1
        .word   OLD-1
        .word   DLOAD-1
        .word   DVERIFY-1
        .word   DSAVE-1
        .word   APPEND-1
        .word   DAPPEND-1
        .word   DOS-1
        .word   KILL-1
        .word   MON-1
        .word   PDIR-1
        .word   PLIST-1
        .word   BAR-1
        .word   DESKTOP-1
        .word   DUMP-1
        .word   ARRAY-1
        .word   MEM-1
        .word   TRACE-1
        .word   REPLACE-1
        .word   ORDER-1
        .word   PACK-1
        .word   UNPACK-1
        .word   MREAD-1
        .word   MWRITE-1

MREAD:  jsr     _get_int
        jsr     L86EA
        jmp     L0110

MWRITE: jsr     _get_int
        jsr     L86EA
        lda     #$B2
        sta     $0116
        lda     #$14
        sta     $0118
        sei
        jmp     L0110

L86EA:  ldy     #$18
L86EC:  lda     L86F9,y
        sta     L0110,y
        dey
        bpl     L86EC
        ldy     #$C1
        sei
        rts

L86F9:  lda     #$34
        sta     $01
L86FD:  dey
        lda     ($14),y
        sta     ($B2),y
        cpy     #$00
        bne     L86FD
        lda     #$37
        sta     $01
        cli
        rts

DEL:    jsr     L852F
        ldy     #$00
L8711:  jsr     _lda_5f_indy
        sta     ($7A),y
        inc     $5F
        bne     L871C
        inc     $60
L871C:  jsr     L85BF
        lda     $5F
        cmp     $2D
        lda     $60
        sbc     $2E
        bcc     L8711
        lda     $7A
        sta     $2D
        lda     $7B
        sta     $2E
        jmp     L897D

L8734:  jmp     L985E

L8737:  jmp     L9855

RENUM:  jsr     L85F1
        jsr     L8512
        beq     L8749
        cmp     #$2C
        bne     L8737
        jsr     _CHRGET
L8749:  jsr     L8531
        ldx     #$03
L874E:  lda     $AC,x
        sta     $8B,x
        dex
        bpl     L874E
        jsr     L85AE
L8758:  jsr     L85BB
        beq     L8783
        jsr     L85BB
        jsr     L8FF9
        bcc     L877E
        lda     $AD
        sta     $15
        lda     $AC
        sta     $14
        jsr     L8FF9
        bcs     L8779
        jsr     _search_for_line
        bcc     L8779
        beq     L8734
L8779:  jsr     L85CB
        bcs     L8734
L877E:  jsr     L85DF
        beq     L8758
L8783:  jsr     L87B8
        jsr     L878C
        jmp     L8F7C

L878C:  jsr     L85AE
L878F:  jsr     L85BB
        beq     L87C0
        ldy     #$02
        jsr     _lda_7a_indy
        pha
        dey
        jsr     _lda_7a_indy
        tay
        pla
        jsr     L8FF9
        bcc     L87B3
        ldy     #$01
        lda     $AC
        sta     ($7A),y
        iny
        lda     $AD
        sta     ($7A),y
        jsr     L85CB
L87B3:  jsr     L85DF
        beq     L878F
L87B8:  jsr     L85AE
L87BB:  jsr     L85BB
        bne     L87C1
L87C0:  rts

L87C1:  jsr     L85BB
        lda     #$10
        sta     $C1
L87C8:  lda     #$10
        .byte   $2C
L87CB:  lda     #$20
        eor     $C1
        sta     $C1
L87D1:  jsr     _CHRGET
L87D4:  tax
        beq     L87BB
        cmp     #$22
        beq     L87C8
        ldy     $C1
        bne     L87D1
        cmp     #$8F
        beq     L87CB
        ldx     #$05
L87E5:  cmp     L85FD,x
        beq     L87EF
        dex
        bpl     L87E5
        bmi     L87D1
L87EF:  jsr     L85E8
        jsr     _CHRGET
L87F5:  ldx     #$02
L87F7:  cmp     L8603,x
        beq     L87EF
        dex
        bpl     L87F7
        jsr     _CHRGOT
        bcs     L87D4
        jsr     _get_line_number
        lda     $15
        ldy     $14
        jsr     L8FF9
        bcs     L881A
        jsr     L88B9
L8813:  jsr     _CHRGET
        bcc     L8813
        bcs     L87F5
L881A:  jsr     L85AE
L881D:  jsr     L85BB
        beq     L883A
        jsr     L85BB
        cmp     $15
        bne     L882D
        cpy     $14
        beq     L8840
L882D:  jsr     L8FF9
        bcc     L8835
        jsr     L85CB
L8835:  jsr     L85E2
        beq     L881D
L883A:  ldy     #$F9
        lda     #$FF
        bne     L8844
L8840:  ldy     $AD
        lda     $AC
L8844:  jsr     L8508
        jsr     L88B9
        ldx     #$01
        stx     $AF
        dex
        stx     $AE
        jsr     _CHRGET
L8854:  inc     $AE
        jsr     _lda_ae_indx
        beq     L8873
        bcc     L8862
        ldy     #$FF
        jsr     L8882
L8862:  jsr     _lda_ae_indx
        sta     ($7A,x)
        jsr     L85BF
        cmp     #$3A
        bcs     L8854
        jsr     LE3B3
        bpl     L8854
L8873:  jsr     _CHRGOT
        bcc     L887B
        jmp     L87F5

L887B:  ldy     #$01
        jsr     L8882
        beq     L8873
L8882:  lda     #$03
        sta     $15
        jsr     _lda_7a_indy
        bne     L888D
        inc     $15
L888D:  tax
        lda     $7A
        pha
        lda     $7B
        pha
        txa
        ldx     #$00
        iny
L8898:  sta     $14
        jsr     _lda_7a_indy
        pha
        lda     $14
        sta     ($7A,x)
        beq     L88A8
        lda     #$04
        sta     $15
L88A8:  jsr     L85BF
        pla
        dec     $15
        bne     L8898
        pla
        sta     $7B
        pla
        sta     $7A
        ldx     #$00
        rts

L88B9:  lda     $5A
        sta     $7A
        lda     $5B
        sta     $7B
        ldx     #$00
        rts

L88C4:  jmp     L9855

FIND:   ldy     #$00
        sty     $C2
        eor     #$22
        bne     L88D4
        jsr     L85BF
        ldy     #$22
L88D4:  sty     $C1
        jsr     L85E8
L88D9:  ldx     #$00
        stx     $C4
        beq     L88EB
L88DF:  cmp     #$2C
        bne     L88E6
        tya
        beq     L88FD
L88E6:  jsr     L85BF
        inc     $C4
L88EB:  jsr     _lda_7a_indx
        beq     L8903
        cmp     #$22
        bne     L88DF
        jsr     _CHRGET
        beq     L8904
        cmp     #$2C
        bne     L88C4
L88FD:  jsr     _CHRGET
        jmp     L8904

L8903:  sec
L8904:  jsr     L8531
        jsr     _set_txtptr_to_start
        bit     $C2
        bmi     L8912
        lda     $C4
        sta     $C3
L8912:  jsr     L85BB
        beq     L896F
        jsr     L85BB
        sta     $3A
        sty     $39
        cpy     $AC
        sbc     $AD
        bcc     L892E
        ldy     $AE
        cpy     $39
        lda     $AF
        sbc     $3A
        bcs     L8933
L892E:  jsr     L85E2
        beq     L8912
L8933:  lda     $C1
        sta     $9F
L8937:  ldy     #$00
        jsr     L85BF
        beq     L8912
        cmp     #$22
        bne     L8946
        eor     $9F
        sta     $9F
L8946:  lda     $9F
        bne     L8937
        ldx     $C3
L894C:  jsr     _lda_5a_indy
        sta     $02
        jsr     _lda_7a_indy
        cmp     $02
        bne     L8937
        iny
        dex
        bne     L894C
        jsr     _check_for_stop
        bit     $C2
        bpl     L8966
        jsr     L8F1F
L8966:  jsr     L839D
        bit     $C2
        bpl     L892E
        bmi     L8937
L896F:  bit     $C2
        bmi     L897D
        jmp     L9881

OLD:    bne     L89BC
        lda     #$08
        sta     $0802
L897D:  jsr     L8986
L8980:  ldx     #$FC
        txs
        jmp     L988F

L8986:  jsr     _relink
        clc
        lda     #$02
        adc     $22
        sta     $2D
        lda     #$00
        adc     $23
        sta     $2E
        rts

OFF:    bne     L89BC
        sei
        jsr     LFD15
        jsr     LE453
        jsr     cond_init_load_save_vectors
        cli
        jmp     L9881

KILL:   bne     L89BC
        sei
        jsr     LFD15
        jsr     LE453
        cli
        lda     #$E3
        pha
        lda     #$85
        pha
        lda     #$F0
        jmp     _jmp_bank

L89BC:  rts

MON:    bne     L89BC
        jmp     monitor

BAR:    tax
        lda     #$00
        cpx     #$CC
        beq     L89CB
        lda     #$80
L89CB:  sta     $02A8
        jmp     L9888

DESKTOP:
        bne     L89BC
        ldx     #$00
        jsr     L89EF
L89D8:  lda     $DC00
        and     $DC01
        and     #$10
        beq     L89EC
        jsr     GETIN
        beq     L89D8
        cmp     #$59
        beq     L89EC
        rts

L89EC:  jmp     go_desktop

L89EF:  lda     L89FB,x
        beq     L89FA
        jsr     LE716
        inx
        bne     L89EF
L89FA:  rts

L89FB:  .byte   "ARE YOU SURE (Y/N)?"


        .byte   $0D,$00,$0D,"READY.",$0D,$00

DLOAD:  
        lda     #$00 ; load flag
        .byte   $2C
DVERIFY:
        lda     #$01 ; verify flag
        sta     $0A
        jsr     L8BA4
        jmp     L989A

DSAVE:  jsr     L8BA7
        jmp     L98AF

DAPPEND:
        jsr     L8BA4
        jmp     L8A35

APPEND: jsr     L98A9
L8A35:  jsr     L8986
        lda     #$00
        sta     $B9
        ldx     $22
        ldy     $23
        jmp     L98C7

DOS:    cmp     #'"'
        beq     L8A5D ; DOS with a command
L8A47:  jsr     L8192
        jsr     UNLSTN
        jsr     L8141
        jsr     L8110
L8A53:  rts

L8A54:  and     #$0F
        sta     $BA
        bne     L8A5D
        jmp     L852C

L8A5D:  jsr     _CHRGET
        beq     L8A47
        cmp     #$24
        bne     L8A69
        jmp     L8B79

L8A69:  cmp     #$38
        beq     L8A54
        cmp     #$39
        beq     L8A54
        jsr     L8192
L8A74:  ldy     #$00
        jsr     _lda_7a_indy
        cmp     #'D'
        beq     L8A87
        cmp     #'F'
        bne     L8A84
        jsr     fast_format2
L8A84:  jmp     L8BE3

L8A87:  iny
        lda     ($7A),y
        cmp     #$3A
        bne     L8A84
        jsr     UNLSTN
        jsr     L96FB
        beq     L8A97
        rts

L8A97:  lda     #$62
        jsr     L8133
        ldy     #$02
L8A9E:  jsr     L8BDB
        beq     L8AB2
        cmp     #$2C
        beq     L8AB2
        jsr     IECOUT
        iny
        cpy     #$12
        bne     L8A9E
        jsr     L8BDB
L8AB2:  pha
        tya
        pha
L8AB5:  cpy     #$12
        beq     L8AC1
        lda     #$A0
        jsr     IECOUT
        iny
        bne     L8AB5
L8AC1:  pla
        tay
        pla
        cmp     #$2C
        bne     L8ADF
        lda     #$A0
        jsr     IECOUT
        jsr     IECOUT
        iny
        ldx     #$04
L8AD3:  jsr     L8BDB
        beq     L8ADF
        jsr     IECOUT
        iny
        dex
        bpl     L8AD3
L8ADF:  jsr     L8BF0
        jsr     L971A
        jsr     open_cmd_channel
        lda     #$49
        jsr     IECOUT
        jmp     UNLSTN

L8AF0:  cmp     #$2C
        bne     L8B04
        jsr     _CHRGET
        bcs     L8B3A
        jsr     _get_line_number
        lda     $15
        bne     L8B3A
        lda     $14
        bpl     L8B06
L8B04:  lda     #$FF
L8B06:  sta     $B9
        jsr     LA00A
        bcc     L8B35
        lda     $B9
        bpl     L8B13
        lda     #$00
L8B13:  and     #$0F
        ora     #$60
        sta     $B9
L8B19:  jsr     UNLSTN
        lda     #$00
        sta     $90
        lda     #$04
        jsr     LISTEN
        lda     $B9
        bpl     L8B2E
        jsr     LEDBE
        bne     L8B31
L8B2E:  jsr     SECOND
L8B31:  lda     $90
        cmp     #$80
L8B35:  lda     #$04
        sta     $9A
        rts

L8B3A:  jmp     L9855

PLIST:  jsr     L8AF0
        bcs     L8B6D
        lda     $2B
        ldx     $2C
        sta     $5F
        stx     $60
        lda     #$A0
        ldx     #$DE
        jsr     L8B66
        jmp     L987A

        jsr     set_io_vectors
        lda     #$0D
        jsr     BSOUT
        jsr     CLRCH
        jsr     set_io_vectors_with_hidden_rom
        lda     #$8B
        ldx     #$E3
L8B66:  sta     $0300
        stx     $0301
        rts

L8B6D:  lda     #$03
        sta     $9A
        jmp     L819A

PDIR:   jsr     L8AF0
        bcs     L8B6D
L8B79:  jsr     UNLSTN
        lda     #$F0
        jsr     L8194
        lda     $9A
        cmp     #$04
        bne     L8B92
        lda     #$24
        jsr     IECOUT
        jsr     UNLSTN
        jmp     L8B95

L8B92:  jsr     L8BE3
L8B95:  jsr     L8453
        jsr     set_io_vectors
        jsr     CLRCH
        jsr     set_io_vectors_with_hidden_rom
        jmp     L8A53

L8BA4:  lda     #$02
        .byte   $2C
L8BA7:  lda     #$00
        jsr     L8BAD
        rts

L8BAD:  jsr     L8BBD
        tax
        ldy     #$01
        jsr     SETLFS
        jsr     LE206
        jsr     _get_filename
        rts

L8BBD:  ldx     #$FB
        ldy     #$DF
        jsr     SETNAM
L8BC4:  lda     #$00
        sta     $90
        lda     #$08
        cmp     $BA
        bcc     L8BD1
L8BCE:  sta     $BA
L8BD0:  rts

L8BD1:  lda     #$09
        cmp     $BA
        bcs     L8BD0
        lda     #$08
        bne     L8BCE
L8BDB:  jsr     _lda_7a_indy
        beq     L8BE2
        cmp     #$22
L8BE2:  rts

L8BE3:  ldy     #$00
L8BE5:  jsr     L8BDB
        beq     L8BF0
        jsr     IECOUT
        iny
        bne     L8BE5
L8BF0:  cmp     #$22
        bne     L8BF5
        iny
L8BF5:  tya
        clc
        adc     $7A
        sta     $7A
        bcc     L8BFF
        inc     $7B
L8BFF:  jmp     UNLSTN

new_detokenize: ; $8C02
        tax
L8C03:  lda     $028D
        and     #$02
        bne     L8C03
        txa
        jsr     L8C11
        jmp     _list

L8C11:  cmp     #$E9
        bcs     L8C5F
        cmp     #$80
        bcc     L8C59
        bit     $0F
        bmi     L8C55
        cmp     #$CC
        bcc     L8C2B
        sbc     #$4C
        ldx     #$0B
        stx     $22
        ldx     #$86
        bne     L8C31
L8C2B:  ldx     #$00
        stx     $22
        ldx     #$AA
L8C31:  stx     $23
        tax
        sty     $49
        ldy     #$00
        asl     a
        beq     L8C4B
L8C3B:  dex
        bpl     L8C4A
L8C3E:  inc     $22
        bne     L8C44
        inc     $23
L8C44:  lda     ($22),y
        bpl     L8C3E
        bmi     L8C3B
L8C4A:  iny
L8C4B:  lda     ($22),y
        bmi     L8C62
        jsr     _basic_bsout
        jmp     L8C4A

L8C55:  cmp     #$8D
        beq     L8C5D
L8C59:  cmp     #$0D
        bne     L8C5F
L8C5D:  lda     #$1F
L8C5F:  inc     $D8
L8C61:  rts

L8C62:  ldy     $49
        and     #$7F
        bpl     L8C61
L8C68:  jsr     L8C92
        lda     #$48
        ldx     #$EB
        bne     L8C78
L8C71:  jsr     L8C89
        lda     #$55
        ldx     #$DE
L8C78:  sei
        sta     $028F
        stx     $0290
        lda     #$00
        sta     $02A7
        sta     $02AB
        cli
        rts

L8C89:  lda     #$EE
        ldx     #$DF
        bit     $02A8
        bmi     L8C96
L8C92:  lda     #$31
        ldx     #$EA
L8C96:  sei
        sta     $0314
        stx     $0315
        cli
L8C9E:  rts

DUMP:   bne     L8C9E
        lda     $2D
        ldy     $2E
L8CA5:  sta     $5F
        sty     $60
        cpy     $30
        bne     L8CAF
        cmp     $2F
L8CAF:  bcs     L8D06
        adc     #$02
        bcc     L8CB6
        iny
L8CB6:  sta     $22
        sty     $23
        jsr     _check_for_stop
        jsr     L8CE9
        lda     #$3D ; '='
        jsr     _basic_bsout
        txa
        bpl     L8CCE
        jsr     L8D12
        jmp     L8CDA

L8CCE:  tya
        bmi     L8CD7
        jsr     _int_to_fac
        jmp     L8CDA

L8CD7:  jsr     L8D21
L8CDA:  jsr     L83BA
        lda     $5F
        ldy     $60
        clc
        adc     #$07
        bcc     L8CA5
        iny
        bcs     L8CA5
L8CE9:  ldy     #$00
        jsr     _lda_5f_indy
        tax
        and     #$7F
        jsr     _basic_bsout
        iny
        jsr     _lda_5f_indy
        tay
        and     #$7F
        beq     L8D00
        jsr     _basic_bsout
L8D00:  txa
        bmi     L8D07
        tya
        bmi     L8D0A
L8D06:  rts

L8D07:  lda     #$25
        .byte   $2C
L8D0A:  lda     #$24
        .byte   $2C
L8D0D:  lda     #$22 ; '"'
        jmp     _basic_bsout

L8D12:  ldy     #$00
        jsr     _lda_22_indy
        tax
        iny
        jsr     _lda_22_indy
        tay
        txa
        jmp     _ay_to_float

L8D21:  jsr     L8D0D
        ldy     #$02
        jsr     _lda_22_indy
        sta     $25
        dey
        jsr     _lda_22_indy
        sta     $24
        dey
        jsr     _lda_22_indy
        sta     $26
        beq     L8D0D
        lda     $24
        sta     $22
        lda     $25
        sta     $23
L8D41:  jsr     _lda_22_indy
        jsr     _basic_bsout
        iny
        cpy     $26
        bne     L8D41
        beq     L8D0D

ARRAY:  bne     L8D06
        ldx     $30
        lda     $2F
L8D54:  sta     $5F
        stx     $60
        cpx     $32
        bne     L8D5E
        cmp     $31
L8D5E:  bcs     L8D06
        ldy     #$04
        adc     #$05
        bcc     L8D67
        inx
L8D67:  sta     $5A
        stx     $5B
        jsr     _check_for_stop
        jsr     _lda_5f_indy
        asl     a
        tay
        adc     $5A
        bcc     L8D78
        inx
L8D78:  sta     $C1
        stx     $C2
        dey
        sty     $C3
        lda     #$00
L8D81:  sta     $0205,y
        dey
        bpl     L8D81
        bmi     L8DC5
L8D89:  ldy     $C3
L8D8B:  dey
        sty     $C4
        tya
        tax
        inc     $0206,x
        bne     L8D98
        inc     $0205,x
L8D98:  jsr     _lda_5a_indy
        sta     $02
        lda     $0205,y
        cmp     $02
        bne     L8DAF
        iny
        jsr     _lda_5a_indy
        sta     $02
        lda     $0205,y
        cmp     $02
L8DAF:  bcc     L8DC5
        lda     #$00
        ldy     $C4
        sta     $0205,y
        sta     $0206,y
        dey
        bpl     L8D8B
        lda     $C1
        ldx     $C2
        jmp     L8D54

L8DC5:  jsr     L8CE9
        ldy     $C3
        lda     #$28 ; '('
L8DCC:  jsr     _basic_bsout
        lda     $0204,y
        ldx     $0205,y
        sty     $C4
        jsr     _print_ax_int
        lda     #$2C
        ldy     $C4
        dey
        dey
        bpl     L8DCC
        lda     #$29 ; ')'
        jsr     _basic_bsout
        lda     #$3D ; '='
        jsr     _basic_bsout
        lda     $C1
        ldx     $C2
        sta     $22
        stx     $23
        ldy     #$00
        jsr     _lda_5f_indy
        bpl     L8E02
        jsr     L8D12
        lda     #$02
        bne     L8E14
L8E02:  iny
        jsr     _lda_5f_indy
        bmi     L8E0F
        jsr     _int_to_fac
        lda     #$05
        bne     L8E14
L8E0F:  jsr     L8D21
        lda     #$03
L8E14:  clc
        adc     $C1
        sta     $C1
        bcc     L8E1D
        inc     $C2
L8E1D:  jsr     L83BA
        jmp     L8D89

L8E23:  rts

MEM:    bne     L8E23 ; rts
        ldy     #s_basic - s_basic
        lda     #$0C
        ldx     #$00
        jsr     print_string_and_int
        ldy     #s_program - s_basic
        lda     #$02
        ldx     #$00
        jsr     print_string_and_int
        ldy     #s_variables - s_basic
        lda     #$04
        ldx     #$02
        jsr     print_string_and_int
        ldy     #s_arrays - s_basic
        lda     #$06
        ldx     #$04
        jsr     print_string_and_int
        ldy     #s_strings - s_basic
        lda     #$0C
        ldx     #$08
        jsr     print_string_and_int
        ldy     #s_free - s_basic
        lda     #$08
        ldx     #$06
print_string_and_int:
        pha
        jsr     print_mem_string
        pla
        tay
        lda     $2B,y
        sec
        sbc     $2B,x
        sta     $C1
        lda     $2C,y
        sbc     $2C,x
        ldx     $C1
        ldy     #$0A
        sty     $D3
        jsr     _print_ax_int ; print number of bytes
        ldy     #$10 ; column of next character
        sty     $D3
        ldy     #s_bytes - s_basic ; print "BYTES"
print_mem_string:
        lda     s_basic,y
        beq     L8E86
        jsr     _basic_bsout
        iny
        bne     print_mem_string
L8E86:  rts

s_basic:
        .byte   $0D, "BASIC", 0
s_program:
        .byte   "PROGRAM", 0
s_variables:
        .byte   "VARIABLES", 0
s_arrays:
        .byte   "ARRAYS", 0
s_strings:
        .byte   "STRINGS", 0
s_free:
        .byte   "FREE", 0
s_bytes: .byte   "BYTES", $0D, 0

TRACE:  tax
        lda     $02AA
        cpx     #$CC
        beq     L8EC6
        ora     #$01
        .byte   $2C
L8EC6:  and     #$FE
        sta     $02AA
        jmp     L9888

L8ECE:  jmp     L852C

REPLACE:
        ldy     #$00
        eor     #$22
        bne     L8EDC
        jsr     L85BF
        ldy     #$22
L8EDC:  sty     $C1
        jsr     L85E8
        ldx     #$00
        stx     $C3
        beq     L8EF3
L8EE7:  cmp     #$2C
        bne     L8EEE
        tya
        beq     L8F03
L8EEE:  jsr     L85BF
        inc     $C3
L8EF3:  jsr     _lda_7a_indx
        beq     L8ECE
        cmp     #$22
        bne     L8EE7
        jsr     _CHRGET
        cmp     #$2C
        bne     L8ECE
L8F03:  tya
        beq     L8F0D
        jsr     _CHRGET
        cmp     #$22
        bne     L8ECE
L8F0D:  jsr     _CHRGET
        lda     $7A
        sta     $8B
        lda     $7B
        sta     $8C
        lda     #$80
        sta     $C2
        jmp     L88D9

L8F1F:  lda     $C3
        ldy     #$01
        sec
        sbc     $C4
        beq     L8F41
        bcs     L8F31
        eor     #$FF
        adc     #$01
        clc
        ldy     #$FF
L8F31:  sty     $60
        sta     $61
L8F35:  ldy     $60
        jsr     L8F65
        dec     $61
        bne     L8F35
        jsr     _relink
L8F41:  ldy     #$00
        ldx     $C4
        beq     L8F5C
L8F47:  jsr     _lda_8b_indy
        sta     ($7A),y
        iny
        dex
        bne     L8F47
        dey
        tya
        clc
        adc     $7A
        sta     $7A
        bcc     L8F5B
        inc     $7B
L8F5B:  rts

L8F5C:  lda     $7A
        bne     L8F62
        dec     $7B
L8F62:  dec     $7A
L8F64:  rts

L8F65:  lda     #$03
        sta     $15
        jsr     _lda_7a_indy
        bne     L8F77
        cpy     #$FF
        beq     L8F75
        inc     $15
        .byte   $2C
L8F75:  lda     #$01
L8F77:  jmp     L888D

ORDER:  bne     L8F64
L8F7C:  jsr     _relink
        jsr     _set_txtptr_to_start
        lda     #$00
        lda     $8B
        sta     $8C
L8F88:  jsr     L85BB
        beq     L8FF6
        jsr     L85BB
        sta     $15
        sty     $14
        cpy     $8B
        pha
        sbc     $8C
        pla
        bcs     L8FEC
        jsr     _search_for_line
        lda     $5F
        sta     $8D
        lda     $60
        sta     $8E
        sec
        lda     $7A
        sbc     #$03
        sta     $5A
        lda     $7B
        sbc     #$00
        sta     $5B
        ldy     #$00
L8FB6:  jsr     _lda_5a_indy
        sta     $033C,y
        iny
        cpy     #$05
        bcc     L8FB6
        cmp     #$00
        bne     L8FB6
        sty     $8F
        tya
        clc
        adc     $5A
        sta     $58
        lda     $5B
        adc     #$00
        sta     $59
        jsr     L98C1
        ldy     #$00
L8FD8:  lda     $033C,y
        sta     ($8D),y
        iny
        cpy     $8F
        bne     L8FD8
        jsr     _relink
        ldx     #$00
        stx     $033C
        beq     L8FF0
L8FEC:  sta     $8C
        sty     $8B
L8FF0:  jsr     L85E2
        jmp     L8F88

L8FF6:  jmp     L897D

L8FF9:  sty     $39
        sta     $3A
        cpy     $8B
        sbc     $8C
        bcc     L900B
        lda     $8D
        cmp     $39
        lda     $8E
        sbc     $3A
L900B:  rts

UNPACK: bne     L900B
        ldx     #$11
L9010:  lda     L918B,x
        cmp     $0801,x
        bne     L900B
        dex
        bpl     L9010
        ldx     #$05
L901D:  lda     L902F,x
        sta     $086B,x
        dex
        bpl     L901D
        lda     #$08
        pha
        lda     #$0C
        pha
        jmp     _disable_rom

L902F:  jsr     LA663
        jmp     LE386

L9035:  jmp     L8734

PACK:   bne     L900B
        lda     $2B
        cmp     $2D
        lda     $2C
        sbc     $2E
        bcs     L9035
        lda     $2E
        cmp     #$FE
        bcs     L9035
        ldx     #$FE
        txs
        lda     #$00
        tay
L9050:  sta     LFE00,y
        sta     $FF00,y
        iny
        bne     L9050
        sty     $AE
        sty     $AC
        sty     $AD
        lda     $2C
        sta     $AF
        ldy     $2B
        ldx     #$00
L9067:  lda     L90C6,x
        sta     L0100,x
        inx
        cpx     #$C5
        bne     L9067
        sei
        lda     #$34
        jsr     L0100
        ldy     #$00
L907A:  lda     L918B,y
        sta     $0801,y
        iny
        cpy     #$9E
        bne     L907A
        lda     $FF
        sta     $0848
        sta     $087E
        lda     $2B
        sta     $084C
        sta     $0892
        lda     $2C
        sta     $084D
        sta     $0893
        lda     $2D
        sta     $085B
        lda     $2E
        sta     $0861
        lda     $AE
        clc
        adc     #$01
        sta     $2D
        lda     $AF
        adc     #$00
        sta     $2E
        sec
        lda     #$9F
        sbc     $2D
        sta     $0813
        lda     #$08
        sbc     $2E
        sta     $0817
        jmp     L8980

L90C6:  sta     $01
L90C8:  lda     ($AE),y
        tax
        inc     LFE00,x
        bne     L90D3
        inc     $FF00,x
L90D3:  iny
        bne     L90D8
        inc     $AF
L90D8:  cpy     $2D
        lda     $AF
        sbc     $2E
        bcc     L90C8
        ldx     #$00
        ldy     #$01
L90E4:  lda     $FF00,x
        cmp     $FF00,y
        bcc     L90F8
        bne     L90F6
        lda     LFE00,x
        cmp     LFE00,y
        bcc     L90F8
L90F6:  tya
        tax
L90F8:  iny
        bne     L90E4
        stx     $FF
        lda     $2D
        sta     $AE
        lda     $2E
        sta     $AF
L9105:  lda     $AC
        bne     L910B
        dec     $AD
L910B:  dec     $AC
        lda     $AE
        bne     L9113
        dec     $AF
L9113:  dec     $AE
        lda     ($AE),y
        sta     ($AC),y
        lda     $2B
        cmp     $AE
        lda     $2C
        sbc     $AF
        bcc     L9105
        lda     #$9F
        sta     $AE
        lda     #$08
        sta     $AF
        jsr     L01B8
L912E:  sta     ($AE),y
        cmp     $FF
        beq     L9169
L9134:  cpx     #$00
        beq     L9179
        jsr     L01B8
        cpx     #$00
        beq     L9143
        cmp     ($AE),y
        beq     L9153
L9143:  cpy     #$04
        bcs     L9159
L9147:  inc     $AE
        bne     L914D
        inc     $AF
L914D:  dey
        bpl     L9147
        iny
        beq     L912E
L9153:  iny
        sta     ($AE),y
        bne     L9134
        dey
L9159:  pha
        tya
        ldy     #$01
        sta     ($AE),y
        dey
        lda     $FF
        sta     ($AE),y
        pla
        ldy     #$02
        bne     L9147
L9169:  iny
        lda     #$00
        sta     ($AE),y
        cpx     #$00
        beq     L9175
        jsr     L01B8
L9175:  ldy     #$01
        bne     L9147
L9179:  lda     #$37
        sta     $01
        rts

        ldx     #$00
        lda     ($AC,x)
        inc     $AC
        bne     L9188
        inc     $AD
L9188:  ldx     $AD
        rts

L918B:  .byte   $0B,$08,$C3,$07,$9E,$32,$30,$36
        .byte   $31,$00,$00,$00
        sei
        lda     #$34
        sta     $01
        lda     #$00
        sta     $AE
        lda     #$00
        sta     $AF
L91A4:  dec     $2E
        dec     $0825
        ldy     #$00
L91AB:  lda     ($2D),y
        sta     $00,y
        dey
        bne     L91AB
        lda     $2E
        cmp     #$07
        bne     L91A4
        ldx     #$61
        txs
L91BC:  lda     $083D,x
        pha
        dex
        bpl     L91BC
        txs
        jmp     L0100

        ldx     #$00
L91C9:  lda     ($AE),y
L91CB:  inc     $AE
        bne     L91D1
        inc     $AF
L91D1:  cmp     #$00
        beq     L91FB
L91D5:  sta     $1000,x
        inx
        bne     L91DE
        inc     L0110
L91DE:  lda     $AE
        ora     $AF
        bne     L91C9
        lda     #$00
        sta     $2D
        sta     $AE
        lda     #$00
        sta     $2E
        sta     $AF
        lda     #$37
        sta     $01
        cli
        jsr     LA659
        jmp     LA7AE

L91FB:  lda     ($AE),y
        inc     $AE
        bne     L9203
        inc     $AF
L9203:  cmp     #$00
        bne     L920B
        lda     #$00
        bne     L91D5
L920B:  sta     $FF
        lda     ($AE),y
        ldy     L0110
        sty     $0156
        ldy     $FF
        iny
L9218:  dey
        beq     L91CB
        sta     $1000,x
        inx
        bne     L9218
        inc     L0110
        inc     $0156
        bne     L9218
L9229: ; <- jmp from $DE60
        lda     $CC
        bne     L927C
        ldy     $CB
        lda     ($F5),y
        cmp     #$03
        bne     L923A
        jsr     L9460
        beq     L927C
L923A:  ldx     $028D
        cpx     #$04
        beq     L9247
        cpx     #$02
        bcc     L9282
        bcs     L927C
L9247:  cmp     #$13
        bne     L925D
        jsr     L93B4
        ldy     #$00
        sty     $D3
        ldy     #$18
        jsr     LE56A
        jsr     L9460
        jmp     L92C5

L925D:  cmp     #$14
        bne     L926A
        jsr     L93B4
        jsr     L9469
        jmp     L92C5

L926A:  cmp     #$0D
        bne     L927C
        jsr     L93B4
        inc     $02A7
        inc     $CC
        jsr     L9473
        jmp     L92CC

L927C:  jmp     _evaluate_modifier

L927F:  jmp     _disable_rom

L9282:  cmp     #$11
        beq     L92DD
        pha
        lda     #$00
        sta     $02AB
        pla
        sec
        sbc     #$85
        bcc     L927C
        cmp     #$04
        bcs     L927C
        cpy     $C5
        beq     L927F
        sty     $C5
        txa
        sta     $028E
        asl     a
        asl     a
        adc     ($F5),y
        sbc     #$84
        ldx     #$00
        tay
        beq     L92B7
L92AB:  lda     fkey_strings,x
        beq     L92B3
        inx
        bne     L92AB
L92B3:  inx
        dey
        bne     L92AB
L92B7:  lda     fkey_strings,x
        sta     $0277,y
        beq     L92C3
        inx
        iny
        bne     L92B7
L92C3:  sty     $C6
L92C5:  lda     #$7F
        sta     $DC00
        bne     L927F
L92CC:  sei
        lsr     $02A7
        lsr     $CC
        jmp     L92C5

L92D5:  lsr     $02A7
        lsr     $CC
        jmp     L927C

L92DD:  inc     $02A7
        inc     $CC
        txa
        and     #$01
        bne     L9342
        lda     $D6
        cmp     #$18
        bne     L92D5
        jsr     L93B4
        bit     $02AB
        bmi     L9312
        ldx     #$19
L92F7:  dex
        bmi     L92D5
        lda     $D9,x
        bpl     L92F7
        jsr     L93C1
        bcs     L92F7
        inc     $14
        bne     L9309
        inc     $15
L9309:  jsr     _search_for_line
        bcs     L9322
        beq     L92D5
        bcc     L9322
L9312:  ldy     #$00
        jsr     _lda_5f_indy
        tax
        iny
        jsr     _lda_5f_indy
        beq     L92D5
        stx     $5F
        sta     $60
L9322:  lda     #$8D
        jsr     LE716
        jsr     L9448
        lda     #$80
        sta     $02AB
        ldy     $D3
        beq     L933A
L9333:  cpy     #$28
        beq     L933A
        dey
        bne     L9333
L933A:  sty     $D3
        lda     #$18
        sta     $D6
        bne     L92CC
L9342:  lda     $D6
        bne     L92D5
        jsr     L93B4
        bit     $02AB
        bvs     L9361
        ldx     #$FF
L9350:  inx
        cpx     #$19
        beq     L9372
        lda     $D9,x
        bpl     L9350
        jsr     L93C1
        bcs     L9350
        jsr     _search_for_line
L9361:  lda     $5F
        ldx     $60
        cmp     $2B
        bne     L9375
        cpx     $2C
        bne     L9375
        lda     #$00
        sta     $02AB
L9372:  jmp     L92D5

L9375:  sta     $7A
        dex
        stx     $7B
        ldy     #$FF
L937C:  iny
        jsr     _lda_7a_indy
L9380:  tax
        bne     L937C
        iny
        jsr     _lda_7a_indy
        cmp     $5F
        bne     L9380
        iny
        jsr     _lda_7a_indy
        cmp     $60
        bne     L9380
        dey
        tya
        clc
        adc     $7A
        sta     $5F
        lda     $7B
        adc     #$00
        sta     $60
        jsr     L9416
        jsr     LE566
        jsr     L9448
        jsr     LE566
        lda     #$40
        sta     $02AB
        jmp     L92CC

L93B4:  lsr     $CF
        bcc     L93C0
        ldy     $CE
        ldx     $0287
        jsr     LEA18
L93C0:  rts

L93C1:  ldy     $ECF0,x
        sty     $7A
        and     #$03
        ora     $0288
        sta     $7B
        ldy     #$00
        jsr     _lda_7a_indy
        cmp     #$3A
        bcs     L9415
        sbc     #$2F
        sec
        sbc     #$D0
        bcs     L9415
        ldy     #$00
        sty     $14
        sty     $15
L93E3:  sbc     #$2F
        sta     $07
        lda     $15
        sta     $22
        cmp     #$19
        bcs     L9415
        lda     $14
        asl     a
        rol     $22
        asl     a
        rol     $22
        adc     $14
        sta     $14
        lda     $22
        adc     $15
        sta     $15
        asl     $14
        rol     $15
        lda     $14
        adc     $07
        sta     $14
        bcc     L940F
        inc     $15
L940F:  jsr     _CHRGET
        bcc     L93E3
        clc
L9415:  rts

L9416:  inc     $0292
        ldx     #$19
L941B:  dex
        beq     L942D
        jsr     LE9F0
        lda     $ECEF,x
        sta     $AC
        lda     $D8,x
        jsr     LE9C8
        bmi     L941B
L942D:  jsr     LE9FF
        ldx     #$17
L9432:  lda     $DA,x
        and     #$7F
        ldy     $D9,x
        bpl     L943C
        ora     #$80
L943C:  sta     $DA,x
        dex
        bpl     L9432
        lda     $D9
        ora     #$80
        sta     $D9
        rts

L9448:  ldy     #$01
        sty     $0F
        jsr     _lda_5f_indy
        beq     L9469
        iny
        jsr     _lda_5f_indy
        tax
        iny
        jsr     _lda_5f_indy
        jsr     L8412
        jsr     L83C8
L9460:  lda     #$00
        sta     $D4
        sta     $D8
        sta     $C7
        rts

L9469:  jsr     L8404
        bcs     L9460
L946E:  lda     #$03
        sta     $9A
        rts

L9473:  lda     #$07
        jsr     L8B06
        bcs     L946E
        jsr     set_io_vectors
        ldy     #$00
        sty     $AC
        lda     $0288
        sta     $AD
        ldx     #$19
L9488:  lda     #$0D
        jsr     BSOUT
        ldy     #$00
L948F:  lda     ($AC),y
        sta     $D7
        and     #$3F
        asl     $D7
        bit     $D7
        bpl     L949D
        ora     #$80
L949D:  bvs     L94A1
        ora     #$40
L94A1:  jsr     BSOUT
        iny
        cpy     #$28
        bne     L948F
        tya
        clc
        adc     $AC
        sta     $AC
        bcc     L94B3
        inc     $AD
L94B3:  dex
        bne     L9488
        lda     #$0D
        jsr     BSOUT
        jsr     CLRCH
        jmp     set_io_vectors_with_hidden_rom

fkey_strings:
        .byte   $8D, "LIST:", $0D, 0
        .byte   $8D, "RUN:", $0D, 0
        .byte   "DLOAD", $0D, 0
        .byte   $8D, $93, "DOS",'"', "$",$0D, 0
        .byte   $8D, "M", 'O' + $80, ":", $0D, 0
        .byte   $8D, "OLD:", $0D, 0
        .byte   "DSAVE", '"', 0
        .byte   "DOS", '"', 0

L94F9:  sei
        lda     #$31
        sta     $0314
        lda     #$EA
        sta     $0315
        jsr     init_load_save_vectors
        jsr     L802F
        cli
        jsr     LE3BF
        jmp     _print_banner_jmp_9511

L9511:
        ldx     #$15
        jsr     L89EF
        ldx     #$FB
        txs
        lda     #$80
        sta     $9D
        ldy     #$FF
        sty     $3A
        iny
        sty     $0A
        sty     $BB
        sty     $02A8
        lda     #$01
        sta     $B9
        lda     #$02
        sta     $BC
        sta     $7B
L9533:  lda     ($BB),y
        sta     $C000,y
        beq     L953D
        iny
        bne     L9533
L953D:  sty     $B7
        lda     #$C0
        sta     $BC
        lda     #$52
        sta     $0277
        lda     #$55
        sta     $0278
        lda     #$4E
        sta     $0279
        lda     #$0D
        sta     $027A
        lda     #$04
        sta     $C6
        jmp     LE16F

L955E:  tya
        pha
        cpx     #$01
        beq     L95E2
        cpx     #$02
        beq     L95CF
        cpx     #$03
        beq     L95A5
        cpx     #$04
        beq     L9577
        cpx     #$05
        beq     L94F9
        jmp     L969A

L9577:  jsr     open_cmd_channel
        bmi     L95C6
        jsr     UNLSTN
        ldx     #$00
        jsr     L96FB
        bne     L95C6
        lda     #$62
        jsr     L8143
        ldx     #$00
L958D:  jsr     IECIN
        cmp     #$A0
        beq     L959C
        sta     $0200,x
        inx
        cpx     #$10
        bne     L958D
L959C:  jsr     UNTALK
        jsr     L971F
        jmp     L95C6

L95A5:  jsr     open_cmd_channel
        bmi     L95CB
        jsr     UNLSTN
        jsr     L8141
        lda     $90
        bmi     L95CB
        ldx     #$00
L95B6:  jsr     IECIN
        cmp     #$0D
        beq     L95C3
        sta     $0200,x
        inx
        bne     L95B6
L95C3:  jsr     UNTALK
L95C6:  lda     #$00
        sta     $0200,x
L95CB:  pla
        jmp     _jmp_bank

L95CF:  jsr     open_cmd_channel
        bmi     L95CB
        lda     #$00
        sta     $7A
        lda     #$02
        sta     $7B
        jsr     L8A74
        jmp     L95CB

L95E2:  lda     #$F0
        jsr     L8133
        bmi     L95CB
        lda     #$24
        jsr     IECOUT
        jsr     UNLSTN
        lda     #$60
        sta     $B9
        jsr     L8143
        ldx     #$06
L95FA:  jsr     L9632
        dex
        bne     L95FA
        beq     L9612
L9602:  jsr     L9632
        jsr     L9632
        jsr     L9632
        tax
        jsr     L9632
        jsr     L9645
L9612:  jsr     L9632
        cmp     #$22
        bne     L9612
L9619:  jsr     L9632
        cmp     #$22
        beq     L9626
        jsr     L9680
        jmp     L9619

L9626:  jsr     L967E
L9629:  jsr     L9632
        cmp     #$00
        bne     L9629
        beq     L9602
L9632:  jsr     IECIN
        ldy     $90
        bne     L963A
        rts

L963A:  pla
        pla
        jsr     L967E
        jsr     LF646
        jmp     L95CB

L9645:  stx     $C1
        sta     $C2
        lda     #$31
        sta     $C3
        ldx     #$04
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
        sbc     L8449,x
        tay
        lda     $C2
        sbc     L844E,x
        bcs     L9659
        lda     $C4
        cmp     $C3
        beq     L9676
        jsr     L9680
        dec     $C3
L9676:  dex
        beq     L964F
        bpl     L9651
        jmp     L967E

L967E:  lda     #$00
L9680:  sty     $AE
        ldy     #$00
        sta     ($AC),y
        inc     $AC
        bne     L968C
        inc     $AD
L968C:  ldy     $AE
        rts

L968F:  lda     #$91
        pha
        lda     #$FF
        pha
        lda     #$43
        jmp     _jmp_bank ; bank 3

L969A:  cpx     #$0B
        beq     L96BF
        cpx     #$0C
        beq     L96DB
        cpx     #$0D
        beq     L96AC
        jsr     L968F
        jmp     L95CB

L96AC:  lda     #$0D
        jsr     BSOUT
        jsr     CLALL
        lda     #$01
        jsr     CLOSE
        jsr     set_io_vectors_with_hidden_rom
        jmp     L95CB

L96BF:  jsr     set_io_vectors
        lda     #$01
        ldy     #$07
        ldx     #$04
        jsr     SETLFS
        lda     #$00
        jsr     SETNAM
        jsr     OPEN
        ldx     #$01
        jsr     CKOUT
        jmp     L95CB

L96DB:  lda     $0200
        jsr     BSOUT
        jmp     L95CB

fast_format2:
        lda     #$05
        sta     $93 ; times $20 bytes
        lda     #<fast_format_drive_code
        ldy     #>fast_format_drive_code
        ldx     #$04 ; page 4
        jsr     m_w_and_m_e
        lda     #$03
        jsr     IECOUT
        lda     #$04
        jmp     IECOUT

L96FB:  lda     #$F2
        jsr     L8133
        lda     #$23
        jsr     IECOUT
        jsr     UNLSTN
        ldy     #$00
        jsr     send_drive_cmd
        jsr     L811D
        bne     L971F
        ldy     #drive_cmd_bp - drive_cmds
        jsr     send_drive_cmd
        lda     #$00
        rts

L971A:  ldy     #drive_cmd_u2 - drive_cmds
        jsr     send_drive_cmd
L971F:  lda     #$E2
        jsr     L8133
        jsr     UNLSTN
        lda     #$01
        rts

send_drive_cmd:
        jsr     open_cmd_channel
L972D:  lda     drive_cmds,y
        beq     L9738
        jsr     IECOUT
        iny
        bne     L972D
L9738:  jmp     UNLSTN

drive_cmds:
drive_cmd_u1:
        .byte   "U1:2 0 18 0", 0
drive_cmd_bp:
        .byte   "B-P 2 144", 0
drive_cmd_u2:
        .byte   "U2:2 0 18 0", 0

fast_format_drive_code:
        jmp     L0463

        jsr     LC1E5
        bne     L9768
        jmp     LC1F3

L9768:  sty     $027A
        lda     #$A0
        jsr     LC268
        jsr     LC100
        ldy     $027B
        cpy     $0274
        bne     L977E
        jmp     LEE46

L977E:  lda     $0200,y
        sta     $12
        lda     $0201,y
        sta     $13
        ldx     #$78
L978A:  lda     $FC35,x
        sta     $062F,x
        dex
        bne     L978A
        lda     #$60
        sta     $06A8
        lda     #$01
        sta     $80
        sta     $51
        jsr     LD6D3
        lda     $22
        bne     L97AA
        lda     #$C0
        jsr     L045C
L97AA:  lda     #$E0
        jsr     L045C
        cmp     #$02
        bcc     L97B6
        jmp     LC8E8

L97B6:  jmp     LEE40

        sta     $01
L97BB:  lda     $01
        bmi     L97BB
        rts

        lda     $51
        cmp     ($32),y
        beq     L97CB
        sta     ($32),y
        jmp     LF99C

L97CB:  ldx     #$04
L97CD:  cmp     $FED7,x
        beq     L97D7
        dex
        bcs     L97CD
        bcc     L9838
L97D7:  jsr     LFE0E
        lda     #$FF
        sta     $1C01
L97DF:  bvc     L97DF
        clv
        inx
        cpx     #$05
        bcc     L97DF
        jsr     LFE00
L97EA:  lda     $1C00
        bpl     L97FD
        bvc     L97EA
        clv
        inx
        bne     L97EA
        iny
        bpl     L97EA
L97F8:  lda     #$03
        jmp     LFDD3

L97FD:  sty     $C0
        stx     $C1
        ldx     $43
        ldy     #$00
        tya
L9806:  clc
        adc     #$64
        bcc     L980C
        iny
L980C:  iny
        dex
        bne     L9806
        eor     #$FF
        sec
        adc     $C1
        bcs     L9819
        dec     $C0
L9819:  tax
        tya
        eor     #$FF
        sec
        adc     $C0
        bcc     L97F8
        tay
        txa
        ldx     #$00
L9826:  sec
        sbc     $43
        bcs     L982E
        dey
        bmi     L9831
L982E:  inx
        bne     L9826
L9831:  stx     $0626
        cpx     #$04
        bcc     L97F8
L9838:  jsr     L0630
        lda     $1C0C
        and     #$1F
        ora     #$C0
        sta     $1C0C
        dec     $1C03
        ldx     #$55
        stx     $1C01
L984D:  bvc     L984D
        inx
        bne     L984D
        jmp     LFCB1

L9855:  lda     #$AF
        pha
        lda     #$07
L985A:  pha
        jmp     _disable_rom

L985E:  lda     #$B9
        pha
        lda     #$7D
        bne     L985A
L9865:  lda     #$A4
        pha
        lda     #$A1
        bne     L985A
        lda     #$A7
        pha
        lda     #$AD
        bne     L985A
L9873:  lda     #$A4
        pha
        lda     #$36
        bne     L985A
L987A:  lda     #$A6
        pha
        lda     #$C2
        bne     L985A
L9881:  lda     #$E3
        pha
        lda     #$85
        bne     L985A
L9888:  lda     #$A8
        pha
        lda     #$F7
        bne     L985A
L988F:  ldx     #$A6
        ldy     #$62
        lda     #$E3
        pha
        lda     #$85
        bne     L98A3
L989A:  ldx     #$E1
        ldy     #$6E
L989E:  lda     #$DE
        pha
        lda     #$04
L98A3:  pha
        txa
        pha
        tya
        bne     L985A
L98A9:  ldx     #$E1
        ldy     #$D3
        bne     L989E
L98AF:  ldx     #$E1
        ldy     #$58
L98B3:  bne     L989E
        ldx     #$A5
        ldy     #$78
L98B9:  bne     L989E
L98BB:  ldx     #$A5
        ldy     #$5F
        bne     L989E
L98C1:  ldx     #$A3
        ldy     #$BE
        bne     L989E
L98C7:  lda     #$E1
        pha
        lda     #$74
        pha
        lda     #$00
        jmp     _disable_rom

        .byte   $DE,$84,$93
        tya
        ldy     $BA
        cpy     #$07
        beq     L98B3
        cpy     #$08
        bcc     L98B9
        cpy     #$0A
        bcs     L98B9
        tay
        bne     L98B9
        lda     $B7
        beq     L98B9
        jsr     _load_bb_indy
        cmp     #$24
        beq     L98B9
        ldx     $B9
        cpx     #$02
        beq     L98B9
        jsr     LA762
        lda     #$60
        sta     $B9
        .byte $20

new_load: ; $9900
	jmp new_load2
new_save: ; $9903
	jmp new_save2

L9906:  pha
L9907:  bit     $DD00
        bpl     L9907
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        tax
L9911:  lda     $D012
        cmp     #$31
        bcc     L991E
        and     #$06
        cmp     #$02
        beq     L9911
L991E:  lda     #$07
        sta     $DD00
        lda     L994B,x
        nop
        nop
        sta     $DD00
        lsr     a
        lsr     a
        and     #$F7
        sta     $DD00
        pla
        and     #$0F
        tax
        lda     L994B,x
        sta     $DD00
        lsr     a
        lsr     a
        and     #$F7
        sta     $DD00
        lda     #$17
        nop
        nop
        sta     $DD00
        rts

L994B:  .byte   $07,$87,$27,$A7,$47,$C7,$67,$E7
        .byte   $17,$97,$37,$B7,$57,$D7,$77,$F7
L995B:  lda     $0330
        cmp     #$20
        beq     L998B
L9962:  bit     $DD00
        bvs     L9962
        ldy     #$03
        nop
        ldx     $01
L996C:  lda     $DD00
        lsr     a
        lsr     a
        nop
        nop
        ora     $DD00
        lsr     a
        lsr     a
        nop
        nop
        ora     $DD00
        lsr     a
        lsr     a
        nop
        nop
        ora     $DD00
        sta     $C1,y
        dey
        bpl     L996C
        rts

L998B:  bit     $DD00
        bvs     L998B
        ldy     #$03
        nop
        ldx     $01
L9995:  lda     $DD00
        lsr     a
        lsr     a
        nop
        nop
        nop
        ora     $DD00
        lsr     a
        lsr     a
        nop
        nop
        ora     $DD00
        lsr     a
        lsr     a
        nop
        nop
        ora     $DD00
        sta     $C1,y
        dey
        bpl     L9995
        rts

L99B5:  tax
        beq     L99C3
        ldx     #$16
L99BA:  lda     L9A50,x
        sta     L0110,x
        dex
        bpl     L99BA
L99C3:  jmp     LA851

L99C6:  jmp     LF530

L99C9:  pla
        pla
        pla
        tay
        lda     #$F4
        pha
        lda     #$A6
        pha
        jmp     _disable_rom_set_01

L99D6:  pla
        pla
        pla
        tay
        lda     #$F4
        pha
        lda     #$F2
        pha
        jmp     _disable_rom_set_01

new_load2:
        sty     $93
        tya
        ldy     $BA
        cpy     #$07
        beq     L99B5
        cpy     #$08
        bcc     L99C9
        cpy     #$0A
        bcs     L99C9
        tay
        lda     $B7
        beq     L99C9
        jsr     _load_bb_indy
        cmp     #$24
        beq     L99C9
        ldx     $B9
        cpx     #$02
        beq     L99C9
        jsr     LA784
        lda     #$60
        sta     $B9
        jsr     LA71B
        lda     $BA
        jsr     LED09
        lda     $B9
        jsr     LEDC7
        jsr     LEE13
        sta     $AE
        lda     $90
        lsr     a
        lsr     a
        bcs     L99C6
        jsr     LEE13
        sta     $AF
        txa
        bne     L9A35
        lda     $C3
        sta     $AE
        lda     $C4
        sta     $AF
L9A35:  jsr     LA7A8
        lda     $AF
        cmp     #$04
        bcc     L99D6
        jmp     L9AF0

        lda     #$0C
        sta     $01
        lda     ($AC),y
        ldy     #$0F
        sty     $01
        ldy     #$00
        jmp     LA9BB

L9A50:  lda     #$0C
        sta     $01
        lda     ($C3),y
        cmp     $BD
        beq     L9A5C
        stx     $90
L9A5C:  eor     $D7
        sta     $D7
        lda     #$0F
        sta     $01
        jmp     LA8FF

L9A67:  jmp     LF636

L9A6A:  jmp     LF5ED

L9A6D:  jmp     LA7C6

new_save2:
        lda     $BA
        cmp     #$07
        beq     L9A6D
        cmp     #$08
        bcc     L9A6A
        cmp     #$0A
        bcs     L9A6A
        ldy     $B7
        beq     L9A6A
        lda     #$61
        sta     $B9
        jsr     LA71B
        jsr     LA77E
        jsr     LA648
        bne     L9A67
        stx     $90
        stx     $A4
        jsr     LFB8E
        sec
        lda     $AC
        sbc     #$02
        sta     $AC
        bcs     L9AA3
        dec     $AD
L9AA3:  jsr     L9AD0
        lda     $C1
        jsr     L9AC7
        lda     $C2
        jsr     L9AC7
L9AB0:  lda     #$35
        jsr     _load_ac_indy
        jsr     L9AC7
        bne     L9AB0
        lda     $A4
        bmi     L9AC4
        jsr     L9AD0
        jmp     L9AB0

L9AC4:  cli
        clc
        rts

L9AC7:  jsr     L9906
        jsr     LFCDB
        dec     $93
        rts

L9AD0:  sec
        lda     $AE
        sbc     $AC
        tax
        sta     $93
        lda     $AF
        sbc     $AD
        bne     L9AE8
        cpx     #$FF
        beq     L9AE8
        inx
        txa
        dec     $A4
        bne     L9AED
L9AE8:  lda     #$FE
        sta     $93
        tya
L9AED:  jmp     L9906

L9AF0:  jsr     UNTALK
        jsr     LA691
        lda     #$06
        sta     $93
        lda     #$FA
        ldy     #$9B
        ldx     #$04
        jsr     LA6D5
        lda     #$9A
        jsr     IECOUT
        lda     #$05
        jsr     IECOUT
        jsr     UNLSTN
        sei
        lda     $D011
        tax
        and     #$10
        sta     $95
        txa
        and     #$EF
        sta     $D011
        lda     $DD00
        and     #$07
        ora     $95
        sta     $95
        lda     $C1
        sta     $A4
        lda     $C2
        sta     $B9
        sec
        lda     $AE
        sbc     #$02
        sta     $90
        lda     $AF
        sbc     #$00
        sta     $A3
L9B3D:  bit     $DD00
        bmi     L9B82
        cli
        php
        lda     $95
        and     #$07
        sta     $DD00
        lda     $95
        and     #$10
        ora     $D011
        sta     $D011
        lda     $A4
        sta     $C1
        lda     $B9
        sta     $C2
        lda     #$00
        sta     $A3
        sta     $94
        sta     $90
        lda     #$60
        sta     $B9
        lda     #$E0
        jsr     LA612
        jsr     UNLSTN
        plp
        bcs     L9B78
        lda     #$1D
        sec
        rts

L9B78:  lda     #$40
        sta     $90
        jsr     LA694
        jmp     LF5A9

L9B82:  bvs     L9B3D
        lda     #$20
        sta     $DD00
L9B89:  bit     $DD00
        bvc     L9B89
        lda     #$00
        sta     $DD00
        jsr     L995B
        lda     #$FE
        sta     $A5
        lda     $C3
        clc
        adc     $A3
        tax
        asl     $C3
        php
        sec
        lda     $90
        sbc     $C3
        sta     $93
        bcs     L9BAD
        dex
L9BAD:  plp
        bcc     L9BB1
        dex
L9BB1:  stx     $94
        ror     $C3
        ldx     $C2
        beq     L9BC8
        dex
        stx     $A5
        txa
        clc
        adc     $93
        sta     $AE
        lda     $94
        adc     #$00
        sta     $AF
L9BC8:  ldy     #$00
        lda     $C3
        bne     L9BD7
        jsr     L995B
        ldy     #$02
        ldx     #$02
        bne     L9BE5
L9BD7:  lda     $C1
        sta     ($93),y
        iny
L9BDC:  tya
        pha
        jsr     L995B
        pla
        tay
        ldx     #$03
L9BE5:  cpy     $A5
        bcs     L9BED
        lda     $C1,x
        sta     ($93),y
L9BED:  iny
        cpy     #$FE
        bcs     L9BF7
        dex
        bpl     L9BE5
        bmi     L9BDC
L9BF7:  jmp     L9B3D

        lda     $43
        sta     $C1
L9BFE:  jsr     L0582
L9C01:  bvc     L9C01
        clv
        lda     $1C01
        sta     $25,y
        iny
        cpy     #$07
        bne     L9C01
        jsr     LF556
L9C12:  bvc     L9C12
        clv
        lda     $1C01
        sta     ($30),y
        iny
        cpy     #$05
        bne     L9C12
        jsr     LF497
        ldx     #$05
        lda     #$00
L9C26:  eor     $15,x
        dex
        bne     L9C26
        tay
        beq     L9C31
L9C2E:  jmp     LF40B

L9C31:  inx
L9C32:  lda     $12,x
        cmp     $16,x
        bne     L9C2E
        dex
        bpl     L9C32
        jsr     LF7E8
        ldx     $19
        cpx     $43
        bcs     L9C2E
        lda     $53
        sta     $060F,x
        lda     $54
        sta     $05FA,x
        lda     #$FF
        sta     $0624,x
        dec     $C1
        bne     L9BFE
        lda     #$01
        sta     $C3
        ldx     $09
L9C5D:  lda     $C2
        sta     $0624,x
        inc     $C2
        lda     $060F,x
        cmp     $08
        bne     L9C75
        lda     $05FA,x
        tax
        inc     $C3
        bne     L9C5D
        beq     L9C2E
L9C75:  cmp     #$24
        bcs     L9C2E
        sta     $08
        lda     $05FA,x
        sta     $09
L9C80:  jsr     L0582
        iny
L9C84:  bvc     L9C84
        clv
        lda     $1C01
        sta     ($30),y
        iny
        cpy     #$04
        bne     L9C84
        ldy     #$00
        jsr     LF7E8
        ldx     $54
        cpx     $43
        bcs     L9C2E
        lda     $0624,x
        cmp     #$FF
        beq     L9C80
        stx     $C0
        jsr     LF556
L9CA8:  bvc     L9CA8
        clv
        lda     $1C01
        sta     ($30),y
        iny
        bne     L9CA8
        ldy     #$BA
L9CB5:  bvc     L9CB5
        clv
        lda     $1C01
        sta     L0100,y
        iny
        bne     L9CB5
        jsr     LF7E8
        lda     $53
        beq     L9CCC
        lda     #$00
        sta     $54
L9CCC:  sta     $34
        sta     $C1
        ldx     $C0
        lda     $0624,x
        sta     $53
        lda     #$FF
        sta     $0624,x
        jsr     LF6D0
        lda     #$42
        sta     $36
        ldy     #$08
        sty     $1800
L9CE8:  lda     $1800
        lsr     a
        bcc     L9CE8
        ldy     #$00
        dec     $36
        sty     $1800
        bne     L9CFE
        dec     $C3
        bne     L9C80
        jmp     LF418

L9CFE:  ldy     $C1
        lda     ($30),y
        lsr     a
        lsr     a
        lsr     a
        sta     $5C
        lda     ($30),y
        and     #$07
        sta     $5D
        iny
        bne     L9D15
        iny
        sty     $31
        ldy     #$BA
L9D15:  lda     ($30),y
        asl     a
        rol     $5D
        asl     a
        rol     $5D
        lsr     a
        lsr     a
        lsr     a
        sta     $5A
        lda     ($30),y
        lsr     a
        iny
        lda     ($30),y
        rol     a
        rol     a
        rol     a
        rol     a
        rol     a
        and     #$1F
        sta     $5B
        lda     ($30),y
        and     #$0F
        sta     $58
        iny
        lda     ($30),y
        asl     a
        rol     $58
        lsr     a
        lsr     a
        lsr     a
        sta     $59
        lda     ($30),y
        asl     a
        asl     a
        asl     a
        and     #$18
        sta     $56
        iny
        lda     ($30),y
        rol     a
        rol     a
        rol     a
        rol     a
        and     #$07
        ora     $56
        sta     $56
        lda     ($30),y
        and     #$1F
        sta     $57
        iny
        sty     $C1
        ldy     #$08
        sty     $1800
        ldx     $55,y
L9D68:  lda     $05C2,x
        sta     $1800
        lda     $05DA,x
        ldx     $54,y
        sta     $1800
        dey
        bne     L9D68
        jmp     L04F6

        ldx     #$03
        stx     $31
L9D80:  inx
        bne     L9D86
        jmp     LF40B

L9D86:  jsr     LF556
L9D89:  bvc     L9D89
        clv
        lda     $1C01
        cmp     $24
        bne     L9D80
        rts

        ldx     #$00
        stx     $1800
        stx     $C2
        lda     $19
        sta     $09
        lda     $18
        sta     $08
L9DA3:  lda     #$E0
        sta     $01
L9DA7:  lda     $01
        bmi     L9DA7
        cmp     #$02
        bcs     L9DBB
        lda     $08
        bne     L9DA3
        lda     #$02
        sta     $1800
        jmp     LC194

L9DBB:  inx
        ldy     #$0A
        sty     $1800
        jmp     LE60A

        .byte   $00,$0A,$0A,$02,$00,$0A,$0A,$02
        .byte   $00,$00,$08,$00,$00,$00,$08,$00
        .byte   $00,$02,$08,$00,$00,$02,$08,$00
        .byte   $00,$08,$0A,$0A,$00,$00,$02,$02
        .byte   $00,$00,$0A,$0A,$00,$00,$02,$02
        .byte   $00,$08,$08,$08,$00,$00,$00,$00
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF
