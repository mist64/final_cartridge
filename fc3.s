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
        .include "persistent.i"

.global new_bsout
.global new_ckout
.global new_clall
.global new_clrch
.global new_detokenize
.global new_execute
.global new_expression
.global new_load
.global new_mainloop
.global new_save
.global kbd_handler
.global load_and_run_program

CHRGET          := $0073
CHRGOT          := $0079

; ----------------------------------------------------------------
; RAM locations
; ----------------------------------------------------------------
L0100           := $0100
L0110           := $0110
L01B8           := $01B8
L0220           := $0220

; ----------------------------------------------------------------
; Bank 2 (Desktop, Freezer/Print) Symbols
; ----------------------------------------------------------------
L8000           := $8000
LBFFA           := $BFFA

; ----------------------------------------------------------------
; KERNAL Symbols
; ----------------------------------------------------------------
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

.segment "part1"

        .addr   entry ; FC3 entry
        .addr   $FE5E ; default cartridge soft reset entry point
        .byte   $C3,$C2,$CD,"80" ; 'cbm80'

entry:  jmp     entry2

        jmp     perform_desktop_disk_operation

fast_format: ; $A00F
        jmp     fast_format2

        jmp     init_read_disk_name

        jmp     init_write_bam

        jmp     init_vectors_jmp_bank_2

        jmp     go_basic

        jmp     print_screen

        jmp     init_load_and_basic_vectors

        jsr     set_io_vectors_with_hidden_rom
        lda     #$43 ; bank 2
        jmp     _jmp_bank

init_load_and_basic_vectors:
        jsr     init_load_save_vectors
init_basic_vectors:
        ldx     #$09
L8031:  lda     basic_vectors,x ; overwrite BASIC vectors
        sta     $0302,x
        dex
        bpl     L8031
        rts

init_vectors_jmp_bank_2:
        jsr     init_load_save_vectors
        jsr     init_basic_vectors
        lda     #>(LBFFA - 1)
        pha
        lda     #<(LBFFA - 1) ; ???
        pha
        lda     #$42 ; bank 2
        jmp     _jmp_bank

entry2: 
        ; short-circuit startup, skipping memory test
        jsr     $FDA3 ; init I/O
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
        jsr     $FE2D ; set memtop
        lda     #$08
        sta     $0282 ; start of BASIC $0800
        lda     #$04
        sta     $0288 ; start of screen RAM $0400
        lda     #<$033C
        sta     $B2
        lda     #>$033C
        sta     $B3 ; datasette buffer
        jsr     $FD15 ; init I/O (same as RESTOR)
        jsr     $FF5B ; video reset (same as CINT)
        jsr     $E453 ; assign $0300 BASIC vectors
        jsr     init_load_and_basic_vectors
        cli
        pla ; $ D
        tax
        pla
        cpx     #$7F ; $DC01 value
        beq     L80C4 ; 1988-13 changes this to "bne" to start into BASIC
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
L80AA:  jmp     ($A000)

mg87_signature:
        .byte   "MG87"

go_desktop:
        lda     #$80
        sta     $02A8 ; unused
        jsr     $E3BF ; init BASIC, print banner
        lda     #>(L8000 - 1)
        pha
        lda     #<(L8000 - 1)
        pha
        lda     #$42 ; bank 2
        jmp     _jmp_bank ; jump to desktop

L80C4:  ldx     #'M'
        cpx     $CFFC
        bne     go_basic
        dec     $CFFC ; destroy signature
go_basic:
        ldx     #<$A000
        ldy     #>$A000
        jsr     $FE2D ; set MEMTOP
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
        .addr   _new_tokenize   ; $0304 ICRNCH tokenization
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
        jsr     $E716 ; output character to the screen
        cmp     #$0D
        bne     L8110
        jmp     UNTALK

check_iec_error:
        jsr     command_channel_talk
        jsr     IECIN
        tay
L8124:  jsr     IECIN
        cmp     #$0D ; skip message
        bne     L8124
        jsr     UNTALK
        cpy     #'0'
        rts

cmd_channel_listen:
        lda     #$6F
listen_second:
        pha
        jsr     set_drive
        jsr     LISTEN
        pla
        jsr     SECOND
        lda     $90
        rts

command_channel_talk:
        lda     #$6F
talk_second:
        pha
        jsr     set_drive
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
L8194:  jsr     listen_second
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

; ----------------------------------------------------------------
; "AUTO" Command - automatically number a BASIC program
; ----------------------------------------------------------------
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
L824D:  nop
        nop
        nop ; used to be "jsr L8253" in 1988-05
        jmp     L9865

.global L8253
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
L8369:  jsr     $E566 ; cursor home
        jsr     L839D
        ldx     $B1
        jsr     $E88C ; set cursor row
        ldy     $B0
        sty     $D3
        lda     ($D1),y
        eor     #$80
        sta     ($D1),y
        pla
        sta     $D4
        pla
        tax
        jsr     $E88C ; set cursor row
        pla
        sta     $D5
        pla
        sta     $D3
L838C:  rts

; ----------------------------------------------------------------
; "HELP" Command - list BASIC line of last error
; ----------------------------------------------------------------
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
        jsr     talk_second
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
        jsr     talk_second
        jmp     UNLSTN

L84C8:  lda     $9A
        cmp     #$03
        beq     L84DB
        bit     $DD0C
        bmi     L84DB
        jsr     UNLSTN
        lda     #$60
        jsr     talk_second
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

save_chrget_ptr:
        lda     $7A
        sta     $5A
        lda     $7B
        sta     $5B
        rts

L85F1:  ldx     #L8606_end - L8606 - 1
L85F3:  lda     L8606,x
        sta     $0334,x
        dex
        bpl     L85F3
        rts

L85FD:
        .byte   $9B,$8A,$A7,$89,$8D,$CB
L85FD_end:

L8603:
        .byte   $AB,$A4,$2C
L8603_end:

L8606:
        .byte   $64,$00,$0A,$00
L8606_end:

; ??? unused?
        .byte   $FF

new_basic_keywords:
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

; ----------------------------------------------------------------
; "MREAD" Command - read 192 bytes from RAM into buffer
; ----------------------------------------------------------------
MREAD:  jsr     _get_int
        jsr     install_memcpy_code
        jmp     $0110

; ----------------------------------------------------------------
; "MWRITE" Command - write 192 bytes from buffer into RAM
; ----------------------------------------------------------------
MWRITE: jsr     _get_int
        jsr     install_memcpy_code
        lda     #$B2 ; switch source and dest
        sta     memcpy_selfmod1 - memcpy_code_at_0110 + 1 + $0110
        lda     #$14
        sta     memcpy_selfmod2 - memcpy_code_at_0110 + 1 + $0110
        sei
        jmp     $0110

install_memcpy_code:
        ldy     #memcpy_code_at_0110_end - memcpy_code_at_0110 - 1 + 6 ; XXX
L86EC:  lda     memcpy_code_at_0110,y
        sta     $0110,y
        dey
        bpl     L86EC
        ldy     #$C1
        sei
        rts

memcpy_code_at_0110:
        lda     #$34
        sta     $01
L86FD:  dey
memcpy_selfmod1:
        lda     ($14),y
memcpy_selfmod2:
        sta     ($B2),y
        cpy     #$00
        bne     L86FD
        lda     #$37
        sta     $01
        cli
        rts
memcpy_code_at_0110_end:

; ----------------------------------------------------------------
; "DEL" Command - delete BASIC lines
; ----------------------------------------------------------------
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

; ----------------------------------------------------------------
; "RENUM" Command - renumber BASIC lines
; ----------------------------------------------------------------
RENUM:  jsr     L85F1
        jsr     L8512
        beq     L8749
        cmp     #','
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
        cmp     #'"'
        beq     L87C8
        ldy     $C1
        bne     L87D1
        cmp     #$8F
        beq     L87CB
        ldx     #L85FD_end - L85FD - 1
L87E5:  cmp     L85FD,x
        beq     L87EF
        dex
        bpl     L87E5
        bmi     L87D1

L87EF:  jsr     save_chrget_ptr
        jsr     _CHRGET
L87F5:  ldx     #L8603_end - L8603 - 1
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
        jsr     $E3B3 ; clear carry if byte = "0"-"9" (CHRGET!)
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

; ----------------------------------------------------------------
; "FIND" Command - find a string in a BASIC program
; ----------------------------------------------------------------
FIND:   ldy     #$00
        sty     $C2
        eor     #$22
        bne     L88D4
        jsr     L85BF
        ldy     #$22
L88D4:  sty     $C1
        jsr     save_chrget_ptr
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

; ----------------------------------------------------------------
; "OLD" Command - recover a deleted program
; ----------------------------------------------------------------
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

; ----------------------------------------------------------------
; "OFF" Command - disable BASIC extensions
; ----------------------------------------------------------------
OFF:    bne     L89BC
        sei
        jsr     $FD15
        jsr     $E453 ; assign $0300 BASIC vectors
        jsr     cond_init_load_save_vectors
        cli
        jmp     L9881

; ----------------------------------------------------------------
; "KILL" Command - disable all cartridge functionality
; ----------------------------------------------------------------
KILL:   bne     L89BC
        sei
        jsr     $FD15
        jsr     $E453 ; assign $0300 BASIC vectors
        cli
        lda     #>$E385
        pha
        lda     #<$E385 ; BASIC warm start
        pha
        lda     #$F0 ; cartridge off
        jmp     _jmp_bank

L89BC:  rts

; ----------------------------------------------------------------
; "MON" Command - enter machine code monitor
; ----------------------------------------------------------------
MON:    bne     L89BC
        jmp     monitor

; ----------------------------------------------------------------
; "BAR" Command - enable/disable pull-down menu
; ----------------------------------------------------------------
BAR:    tax
        lda     #$00
        cpx     #$CC
        beq     L89CB
        lda     #$80
L89CB:  sta     $02A8
        jmp     L9888

; ----------------------------------------------------------------
; "DESKTOP" Command - start Desktop
; ----------------------------------------------------------------
DESKTOP:
        bne     L89BC
        ldx     #a_are_you_sure - messages
        jsr     print_msg
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

print_msg:
        lda     a_are_you_sure,x
        beq     L89FA
        jsr     $E716 ; output character to the screen
        inx
        bne     print_msg
L89FA:  rts

messages:
a_are_you_sure:
        .byte   "ARE YOU SURE (Y/N)?", $0D, 0
a_ready:
        .byte   $0D,"READY.",$0D,$00

; ----------------------------------------------------------------
; "DLOAD" Command - load a program from disk
; ----------------------------------------------------------------
DLOAD:  
        lda     #$00 ; load flag
        .byte   $2C
; ----------------------------------------------------------------
; "DVERIFY" Command - verify a program on disk
; ----------------------------------------------------------------
DVERIFY:
        lda     #$01 ; verify flag
        sta     $0A
        jsr     set_filename_or_colon_asterisk
        jmp     L989A

; ----------------------------------------------------------------
; "DSAVE" Command - save a program to disk
; ----------------------------------------------------------------
DSAVE:  jsr     set_filename_or_empty
        jmp     L98AF

; ----------------------------------------------------------------
; "DAPPEND" Command - append a program from disk to program in RAM
; ----------------------------------------------------------------
DAPPEND:
        jsr     set_filename_or_colon_asterisk
        jmp     L8A35

; ----------------------------------------------------------------
; "APPEND" Command - append a program to program in RAM
; ----------------------------------------------------------------
APPEND: jsr     L98A9
L8A35:  jsr     L8986
        lda     #$00
        sta     $B9
        ldx     $22
        ldy     $23
        jmp     L98C7

; ----------------------------------------------------------------
; "DOS" Command - send command to drive
; ----------------------------------------------------------------
DOS:    cmp     #'"'
        beq     L8A5D ; DOS with a command
L8A47:  jsr     L8192
        jsr     UNLSTN
        jsr     command_channel_talk
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
send_drive_command:
        ldy     #$00
        jsr     _lda_7a_indy
        cmp     #'D' ; drive command "D"
        beq     L8A87
        cmp     #'F' ; drive command "F"
        bne     L8A84
        jsr     fast_format2
L8A84:  jmp     L8BE3

; drive command "D"
L8A87:  iny
        lda     ($7A),y
        cmp     #$3A
        bne     L8A84
        jsr     UNLSTN
        jsr     init_read_disk_name
        beq     L8A97
        rts

L8A97:  lda     #$62
        jsr     listen_second
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
        jsr     init_write_bam
        jsr     cmd_channel_listen
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
        jsr     something_with_printer
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
        jsr     $EDBE ; set ATN
        bne     L8B31
L8B2E:  jsr     SECOND
L8B31:  lda     $90
        cmp     #$80
L8B35:  lda     #$04
        sta     $9A
        rts

L8B3A:  jmp     L9855

; ----------------------------------------------------------------
; "PLIST" Command - send BASIC listing to printer
; ----------------------------------------------------------------
PLIST:  jsr     L8AF0
        bcs     L8B6D
        lda     $2B
        ldx     $2C
        sta     $5F
        stx     $60
        lda     #<_new_warmstart
        ldx     #>_new_warmstart
        jsr     L8B66 ; set $0300 vector
        jmp     L987A

.global L8B54
L8B54:
        jsr     set_io_vectors
        lda     #$0D
        jsr     BSOUT
        jsr     CLRCH
        jsr     set_io_vectors_with_hidden_rom
        lda     #<$E38B
        ldx     #>$E38B ; default value
L8B66:  sta     $0300
        stx     $0301 ; $0300 IERROR basic warm start
        rts

L8B6D:  lda     #$03
        sta     $9A
        jmp     L819A

; ----------------------------------------------------------------
; "PDIR" Command - send disk directoy to printer
; ----------------------------------------------------------------
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

set_filename_or_colon_asterisk:
        lda     #<(a_colon_asterisk_end - a_colon_asterisk); ":*" (XXX "<" required to make ca65 happy)
        .byte   $2C
set_filename_or_empty:
        lda     #$00 ; empty filename
        jsr     set_filename
        rts ; XXX omit jsr and rts

set_filename:
        jsr     set_colon_asterisk
        tax
        ldy     #$01
        jsr     SETLFS
        jsr     $E206 ; RTS if end of line
        jsr     _get_filename
        rts ; XXX jsr/rts -> jmp

set_colon_asterisk:
        ldx     #<a_colon_asterisk
        ldy     #>a_colon_asterisk
        jsr     SETNAM
set_drive:
        lda     #$00
        sta     $90
        lda     #$08
        cmp     $BA
        bcc     L8BD1 ; device number 9 or above
L8BCE:  sta     $BA
L8BD0:  rts

L8BD1:  lda     #$09
        cmp     $BA
        bcs     L8BD0
        lda     #$08 ; set drive 8
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
L8BF0:  cmp     #'"'
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
        bcs     L8C5F ; token above
        cmp     #$80
        bcc     L8C59 ; below
        bit     $0F
        bmi     L8C55
        cmp     #$CC
        bcc     L8C2B ; standard C64 token
        sbc     #$4C
        ldx     #<new_basic_keywords
        stx     $22
        ldx     #>new_basic_keywords
        bne     L8C31
        
L8C2B:  ldx     #<basic_keywords
        stx     $22
        ldx     #>basic_keywords
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
        lda     #<_kbd_handler
        ldx     #>_kbd_handler
L8C78:  sei
        sta     $028F ; set keyboard decode pointer
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

; ----------------------------------------------------------------
; "DUMP" Command - show list of all BASIC variables
; ----------------------------------------------------------------
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

; ----------------------------------------------------------------
; "ARRAY" Command - show list of all BASIC arrays
; ----------------------------------------------------------------
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

; ----------------------------------------------------------------
; "MEM" Command - display memory usage
; ----------------------------------------------------------------
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

; ----------------------------------------------------------------
; "TRACE" Command - enable/disable printing each BASIC line executed
; ----------------------------------------------------------------
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

; ----------------------------------------------------------------
; "REPLACE" Command - replace a string in a BASIC program
; ----------------------------------------------------------------
REPLACE:
        ldy     #$00
        eor     #$22
        bne     L8EDC
        jsr     L85BF
        ldy     #$22
L8EDC:  sty     $C1
        jsr     save_chrget_ptr
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

; ----------------------------------------------------------------
; "ORDER" Command - reorder BASIC lines after APPEND
; ----------------------------------------------------------------
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

.import __pack_header_LOAD__
.import __pack_header_RUN__

UNPACK: bne     L900B
        ldx     #$11 ; arbitrary length
L9010:  lda     __pack_header_LOAD__,x
        cmp     __pack_header_RUN__,x
        bne     L900B ; do nothing if not packed
        dex
        bpl     L9010
        ldx     #alt_pack_run_end - alt_pack_run - 1
L901D:  lda     alt_pack_run,x
        sta     pack_run,x
        dex
        bpl     L901D
        lda     #>(pack_entry - 1)
        pha
        lda     #<(pack_entry - 1)
        pha
        jmp     _disable_rom

alt_pack_run:
        jsr     $A663 ; CLR
        jmp     $E386 ; BASIC warm start
alt_pack_run_end:

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
L9050:  sta     $FE00,y
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
L907A:  lda     __pack_header_LOAD__,y
        sta     __pack_header_RUN__,y
        iny
        cpy     #pack_header_end - pack_header
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
        inc     $FE00,x
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
        lda     $FE00,x
        cmp     $FE00,y
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

; ??? unused?
        ldx     #$00
        lda     ($AC,x)
        inc     $AC
        bne     L9188
        inc     $AD
L9188:  ldx     $AD
        rts

.segment "pack_header"

pack_header: ; $918B
        .word   pack_link ; BASIC link pointer
        .word   1987 ; line number
        .byte   $9E, "2061", 0
pack_link:
        .word 0
; decompression
pack_entry:
        sei
        lda     #$34
        sta     $01
        lda     #$00
        sta     $AE
        lda     #$00
        sta     $AF
L91A4:  dec     $2E
        dec     pack_selfmod + 2
        ldy     #$00
L91AB:  lda     ($2D),y
pack_selfmod:
        sta     $0000,y
        dey
        bne     L91AB
        lda     $2E
        cmp     #$07
        bne     L91A4
        ldx     #stack_code_end - stack_code - 1
        txs
L91BC:  lda     stack_code,x; copy to $0100
        pha
        dex
        bpl     L91BC
        txs
        jmp     L0100

stack_code: ; lives at $0100
        ldx     #$00
L91C9:  lda     ($AE),y
L91CB:  inc     $AE
        bne     L91D1
        inc     $AF
L91D1:  cmp     #$00
        beq     L91FB
stack_selfmod1:
        sta     $1000,x
        inx
        bne     L91DE
        inc     stack_selfmod1 - stack_code + 2 + $0100
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
pack_run:
        jsr     $A659 ; CLR
        jmp     $A7AE ; next statement

L91FB:  lda     ($AE),y
        inc     $AE
        bne     L9203
        inc     $AF
L9203:  cmp     #$00
        bne     L920B
        lda     #$00
        bne     stack_selfmod1
L920B:  sta     $FF
        lda     ($AE),y
        ldy     stack_selfmod1 - stack_code + 2 + $0100
        sty     stack_selfmod2 - stack_code + 2 + $0100
        ldy     $FF
        iny
L9218:  dey
        beq     L91CB
stack_selfmod2:
        sta     $1000,x
        inx
        bne     L9218
        inc     L0110
        inc     $0156
        bne     L9218
stack_code_end:
pack_header_end:

; ----------------------------------------------------------------

.segment "part1b"

kbd_handler:
        lda     $CC
        bne     L927C ; do not flash cursor
        ldy     $CB
        lda     ($F5),y
        cmp     #$03
        bne     L923A
        jsr     L9460
        beq     L927C
L923A:  ldx     $028D
        cpx     #$04 ; CTRL key down
        beq     L9247
        cpx     #$02 ; CBM key down?
        bcc     L9282 ; SHIFT or nothing
        bcs     L927C ; CBM

L9247:  cmp     #$13 ; CTRL + HOME: put cursor at bottom left
        bne     L925D
        jsr     L93B4
        ldy     #$00
        sty     $D3
        ldy     #$18 ; 25
        jsr     $E56A ; set cursor line
        jsr     L9460
        jmp     L92C5

L925D:  cmp     #$14 ; CTRL + DEL: delete to end of line
        bne     L926A
        jsr     L93B4
        jsr     L9469
        jmp     L92C5

L926A:  cmp     #$0D ; CTRL + CR: print screen
        bne     L927C
        jsr     L93B4
        inc     $02A7
        inc     $CC
        jsr     print_screen
        jmp     L92CC

L927C:  jmp     _evaluate_modifier

L927F:  jmp     _disable_rom

L9282:  cmp     #$11 ; DOWN
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
        sta     $0277,y ; kbd buffer
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
        jsr     $E716 ; output character to the screen
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
        jsr     $E566 ; cursor home
        jsr     L9448
        jsr     $E566 ; cursor home
        lda     #$40
        sta     $02AB
        jmp     L92CC

L93B4:  lsr     $CF
        bcc     L93C0
        ldy     $CE
        ldx     $0287
        jsr     $EA18 ; put a character in the screen
L93C0:  rts

L93C1:  ldy     $ECF0,x ; low bytes of screen line addresses
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
        jsr     $E9F0 ; fetch a screen address
        lda     $ECEF,x
        sta     $AC
        lda     $D8,x
        jsr     $E9C8 ; shift screen line
        bmi     L941B
L942D:  jsr     $E9FF ; clear screen line X
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

print_screen:
        lda     #$07
        jsr     L8B06
        bcs     L946E
        jsr     set_io_vectors
        ldy     #$00
        sty     $AC
        lda     $0288 ; video RAM address hi
        sta     $AD
        ldx     #$19 ; 25 iterations for 25 lines
L9488:  lda     #$0D ; CR
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
        cpy     #$28 ; 40 columns
        bne     L948F
        tya
        clc
        adc     $AC
        sta     $AC
        bcc     L94B3
        inc     $AD
L94B3:  dex
        bne     L9488
        lda     #$0D ; CR
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

; ----------------------------------------------------------------
; Helper code called from Desktop
; ----------------------------------------------------------------

; file name at $0200
load_and_run_program:
        ldx     #a_ready - messages
        jsr     print_msg ; print "READY."
        ldx     #$FB
        txs
        lda     #$80
        sta     $9D ; direct mode
        ldy     #$FF
        sty     $3A ; direct mode
        iny
        sty     $0A
        sty     $BB ; file name pointer low
        sty     $02A8
        lda     #$01
        sta     $B9
        lda     #$02 
        sta     $BC ; read filename from $0200
        sta     $7B
L9533:  lda     ($BB),y
        sta     $C000,y
        beq     L953D
        iny
        bne     L9533
L953D:  sty     $B7
        lda     #$C0
        sta     $BC ; file name pointer high (fn at $C000)
        lda     #'R'
        sta     $0277
        lda     #'U'
        sta     $0278
        lda     #'N'
        sta     $0279
        lda     #$0D ; CR
        sta     $027A
        lda     #$04 ; number of characters in kbd buffer
        sta     $C6
        jmp     $E16F ; LOAD

; performs a (fast) disk operation for Desktop
perform_desktop_disk_operation:
        tya
        pha ; bank to return to
        cpx     #$01
        beq     read_directory
        cpx     #$02
        beq     send_drive_command_at_0200
        cpx     #$03
        beq     read_cmd_channel
        cpx     #$04
        beq     read_disk_name
        cpx     #$05
        beq     reset_load_and_run
        jmp     L969A ; second half of operations (XXX why?)

; reads zero terminated disk name to $0200
read_disk_name:
        jsr     cmd_channel_listen
        bmi     zero_terminate ; XXX X is undefined here
        jsr     UNLSTN
        ldx     #$00
        jsr     init_read_disk_name
        bne     zero_terminate
        lda     #$62
        jsr     talk_second
        ldx     #$00
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
        lda     $90
        bmi     jmp_bank_from_stack
        ldx     #$00
L95B6:  jsr     IECIN
        cmp     #$0D ; CR
        beq     L95C3
        sta     $0200,x ; read command channel
        inx
        bne     L95B6
L95C3:  jsr     UNTALK
zero_terminate:
        lda     #$00
        sta     $0200,x ; zero terminate
jmp_bank_from_stack:
        pla
        jmp     _jmp_bank

send_drive_command_at_0200:
        jsr     cmd_channel_listen
        bmi     jmp_bank_from_stack
        lda     #<$0200
        sta     $7A
        lda     #>$0200
        sta     $7B
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
        sta     $B9
        jsr     talk_second
        ldx     #$06
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
        cmp     #$00
        bne     L9629
        beq     L9602 ; always; loop

iecin_or_ret:
        jsr     IECIN
        ldy     $90
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
        jsr     store_directory_byte
        dec     $C3
L9676:  dex
        beq     L964F
        bpl     L9651
        jmp     terminate_directory_name ; XXX redundant

terminate_directory_name:
        lda     #$00
store_directory_byte:
        sty     $AE
        ldy     #$00
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

L969A:  cpx     #$0B
        beq     set_printer_output
        cpx     #$0C
        beq     print_character
        cpx     #$0D
        beq     reset_printer_output
        jsr     disk_operation_fallback
        jmp     jmp_bank_from_stack

reset_printer_output:
        lda     #$0D ; CR
        jsr     BSOUT
        jsr     CLALL
        lda     #$01
        jsr     CLOSE
        jsr     set_io_vectors_with_hidden_rom
        jmp     jmp_bank_from_stack

set_printer_output:
        jsr     set_io_vectors
        lda     #$01 ; LFN
        ldy     #$07 ; secondary address
        ldx     #$04 ; printer
        jsr     SETLFS
        lda     #$00
        jsr     SETNAM
        jsr     OPEN
        ldx     #$01
        jsr     CKOUT
        jmp     jmp_bank_from_stack

print_character:
        lda     $0200
        jsr     BSOUT
        jmp     jmp_bank_from_stack

; ----------------------------------------------------------------

.import __fast_format_drive_LOAD__
.import __fast_format_drive_RUN__

fast_format2:
        lda     #$05
        sta     $93 ; times $20 bytes
        lda     #<__fast_format_drive_LOAD__
        ldy     #>__fast_format_drive_LOAD__
        ldx     #>__fast_format_drive_RUN__
        jsr     m_w_and_m_e
        lda     #<fast_format_drive_code_entry
        jsr     IECOUT
        lda     #>fast_format_drive_code_entry
        jmp     IECOUT

init_read_disk_name:
        lda     #$F2
        jsr     listen_second
        lda     #'#'
        jsr     IECOUT
        jsr     UNLSTN
        ldy     #drive_cmd_u1 - drive_cmds
        jsr     send_drive_cmd ; send "U1:2 0 18 0", block read of BAM
        jsr     check_iec_error
        bne     unlisten_e2 ; error
        ldy     #drive_cmd_bp - drive_cmds
        jsr     send_drive_cmd ; send "B-P 2 144", read name
        lda     #$00
        rts

init_write_bam:
        ldy     #drive_cmd_u2 - drive_cmds
        jsr     send_drive_cmd ; send "U2:2 0 18 0", block write of BAM
unlisten_e2:
        lda     #$E2
        jsr     listen_second
        jsr     UNLSTN
        lda     #$01
        rts

send_drive_cmd:
        jsr     cmd_channel_listen
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

; ----------------------------------------------------------------

.segment "fast_format_drive"

; XXX
L045C           := $045C
L0463           := $0463
L04F6           := $04F6
L0582           := $0582
L0630           := $0630

fast_format_drive_code:
        jmp     L0463

fast_format_drive_code_entry:
        jsr     $C1E5 ; drive ROM
        bne     L9768
        jmp     $C1F3 ; drive ROM

L9768:  sty     $027A
        lda     #$A0
        jsr     $C268 ; drive ROM
        jsr     $C100 ; drive ROM
        ldy     $027B
        cpy     $0274
        bne     L977E
        jmp     $EE46 ; drive ROM

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
        jsr     $D6D3 ; drive ROM
        lda     $22
        bne     L97AA
        lda     #$C0
        jsr     L045C
L97AA:  lda     #$E0
        jsr     L045C
        cmp     #$02
        bcc     L97B6
        jmp     $C8E8 ; drive ROM

L97B6:  jmp     $EE40 ; drive ROM

        sta     $01
L97BB:  lda     $01
        bmi     L97BB
        rts

        lda     $51
        cmp     ($32),y
        beq     L97CB
        sta     ($32),y
        jmp     $F99C ; drive ROM

L97CB:  ldx     #$04
L97CD:  cmp     $FED7,x
        beq     L97D7
        dex
        bcs     L97CD
        bcc     L9838
L97D7:  jsr     $FE0E ; drive ROM
        lda     #$FF
        sta     $1C01
L97DF:  bvc     L97DF
        clv
        inx
        cpx     #$05
        bcc     L97DF
        jsr     $FE00 ; drive ROM
L97EA:  lda     $1C00
        bpl     L97FD
        bvc     L97EA
        clv
        inx
        bne     L97EA
        iny
        bpl     L97EA
L97F8:  lda     #$03
        jmp     $FDD3 ; drive ROM

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
        jmp     $FCB1 ; drive ROM

; ----------------------------------------------------------------

.segment "part2"

; wrappers for BASIC/KERNAL calls with cartridge ROM disabled

L9855:  lda     #>($AF08 - 1)
        pha
        lda     #<($AF08 - 1) ; SYNTAX ERROR
disable_rom_jmp:
        pha
        jmp     _disable_rom

L985E:  lda     #>($B97E - 1) ; OVERFLOW ERROR
        pha
        lda     #<($B97E - 1)
        bne     disable_rom_jmp ; always

L9865:  lda     #>($A49F - 1) ; used to be $A4A2 in 1988-05
        pha
        lda     #<($A49F - 1) ; input line
        bne     disable_rom_jmp ; always

        lda     #>($A7AE - 1)
        pha
        lda     #<($A7AE - 1) ; interpreter loop
        bne     disable_rom_jmp ; always

L9873:  lda     #>($A437 - 1)
        pha
        lda     #<($A437 - 1) ; ERROR
        bne     disable_rom_jmp

L987A:  lda     #>($A6C3 - 1)
        pha
        lda     #<($A6C3 - 1) ; LIST worker code
        bne     disable_rom_jmp

.global L9881
L9881:  lda     #>($E386 - 1) ; BASIC warm start
        pha
        lda     #<($E386 - 1)
        bne     disable_rom_jmp

L9888:  lda     #>($A8F8 - 1)
        pha
        lda     #<($A8F8 - 1) ; DATA
        bne     disable_rom_jmp

L988F:  ldx     #>($A663 - 1)
        ldy     #<($A663 - 1) ; CLR
        lda     #>($E386 - 1)
        pha
        lda     #<($E386 - 1) ; BASIC warm start
        bne     L98A3

L989A:  ldx     #>($E16F - 1)
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

L98A9:  ldx     #>($E1D4 - 1)
        ldy     #<($E1D4 - 1) ; get args for LOAD/SAVE
        bne     jsr_with_rom_disabled

L98AF:  ldx     #>($E159 - 1)
        ldy     #<($E159 - 1) ; SAVE
L98B3:  bne     jsr_with_rom_disabled

        ldx     #>($A579 - 1)
        ldy     #<($A579 - 1) ; tokenize
L98B9:  bne     jsr_with_rom_disabled

L98BB:  ldx     #>($A560 - 1)
        ldy     #<($A560 - 1) ; line input
        bne     jsr_with_rom_disabled

L98C1:  ldx     #>($A3BF - 1)
        ldy     #<($A3BF - 1) ; BASIC memory management
        bne     jsr_with_rom_disabled

L98C7:  lda     #>($E175 - 1)
        pha
        lda     #<($E175 - 1) ; LOAD worker
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
        jsr     LA762 ; ???
        lda     #$60
        sta     $B9
        .byte $20

; ----------------------------------------------------------------

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
        cmp     #<_new_load
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

L99C6:  jmp     $F530 ; IEC LOAD - used in the error case

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
        jsr     $ED09 ; TALK
        lda     $B9
        jsr     $EDC7 ; SECTLK
        jsr     $EE13 ; IECIN
        sta     $AE
        lda     $90
        lsr     a
        lsr     a
        bcs     L99C6
        jsr     $EE13 ; IECIN
        sta     $AF
        txa
        bne     L9A35
        lda     $C3
        sta     $AE
        lda     $C4
        sta     $AF
L9A35:  jsr     print_loading
        lda     $AF
        cmp     #$04
        bcc     L99D6
        jmp     L9AF0

; ----------------------------------------------------------------

.segment "code_at_0100"

; will be placed at $0100
L9A41:
        lda     #$0C
        sta     $01
        lda     ($AC),y
        ldy     #$0F
        sty     $01
        ldy     #$00
        jmp     LA9BB

.segment "code_at_0110"

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

; ----------------------------------------------------------------

.segment "part3"

L9A67:  jmp     $F636 ; LDA #0 : SEC : RTS

L9A6A:  jmp     $F5ED ; default SAVE vector

L9A6D:  jmp     $A7C6 ; interpreter loop

new_save2:
        lda     $BA
        cmp     #$07
        beq     L9A6D ; tape turbo
        cmp     #$08
        bcc     L9A6A ; not a drive
        cmp     #$0A
        bcs     L9A6A ; not a drive (XXX why only support drives 8 and 9?)
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
        jsr     $FB8E ; copy I/O start address to buffer address
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
        jsr     $FCDB ; inc $AC/$AD
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
.import __drive_code_LOAD__
.import __drive_code_RUN__
        lda     #<__drive_code_LOAD__
        ldy     #>__drive_code_LOAD__
        ldx     #$04 ; $0400
        jsr     transfer_code_to_drive
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
        bvs     L9B78 ; used to be "bcs" in 1988-05
        lda     #$1D
        sec
        rts

L9B78:  lda     #$40
        sta     $90
        jsr     LA694
        jmp     $F5A9 ; LOAD done

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

; ----------------------------------------------------------------

.segment "drive_code"
; drive code
drive_code:
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
        jsr     $F556 ; drive ROM
L9C12:  bvc     L9C12
        clv
        lda     $1C01
        sta     ($30),y
        iny
        cpy     #$05
        bne     L9C12
        jsr     $F497 ; drive ROM
        ldx     #$05
        lda     #$00
L9C26:  eor     $15,x
        dex
        bne     L9C26
        tay
        beq     L9C31
L9C2E:  jmp     $F40B ; drive ROM

L9C31:  inx
L9C32:  lda     $12,x
        cmp     $16,x
        bne     L9C2E
        dex
        bpl     L9C32
        jsr     $F7E8 ; drive ROM
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
        jsr     $F7E8 ; drive ROM
        ldx     $54
        cpx     $43
        bcs     L9C2E
        lda     $0624,x
        cmp     #$FF
        beq     L9C80
        stx     $C0
        jsr     $F556 ; drive ROM
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
        jsr     $F7E8 ; drive ROM
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
        jsr     $F6D0 ; drive ROM
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
        jmp     $F418 ; drive ROM

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
        jmp     $F40B ; drive ROM

L9D86:  jsr     $F556 ; drive ROM
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
        jmp     $C194 ; drive ROM

L9DBB:  inx
        ldy     #$0A
        sty     $1800
        jmp     $E60A ; drive ROM

; ??? unreferenced?
        .byte   0, 10, 10, 2
        .byte   0, 10, 10, 2
        .byte   0, 0, 8, 0
        .byte   0, 0, 8, 0
        .byte   0, 2, 8, 0
        .byte   0, 2, 8, 0
        .byte   0, 8, 10, 10, 0, 0, 2, 2
        .byte   0, 0, 10, 10, 0, 0, 2, 2
        .byte   0, 8, 8, 8
        .byte   0, 0, 0, 0

; ----------------------------------------------------------------

; This is at $A000

.segment "part4"

; ??? unused?
        .addr   go_basic
        .addr   _basic_warm_start

set_io_vectors_with_hidden_rom:
        jmp     set_io_vectors_with_hidden_rom2

set_io_vectors:  
        jmp     set_io_vectors2

something_with_printer:
        jmp     LA183

; ----------------------------------------------------------------
; Centronics and RS-232 printer drivers
; ----------------------------------------------------------------
LA00D:  pha
        lda     $DC0C
        cmp     #$FE
        beq     LA035 ; RS-232
        pla
        jsr     LA021
        lda     #$10
LA01B:  bit     $DD0D
        beq     LA01B
        rts

LA021:  sta     $DD01
        lda     $DD0D
        lda     $DD00
        and     #$FB
        sta     $DD00
        ora     #$04
        sta     $DD00
        rts

; IEC transfer, send
LA035:  pla
        sta     $A5
        txa
        pha
LA03A:  lda     $DD01
        asl     a
        asl     a
        bcc     LA03A
        lda     #$10
        sta     $DD0E
        lda     #$64
        sta     $DD04
        lda     #$00
        sta     $DD05
        lda     $DD0D
        bit     $D011
        bmi     LA065
LA058:  lda     $D012
        and     #$0F
        cmp     #$02
        beq     LA065
        cmp     #$0A
        bne     LA058
LA065:  lda     #$11
        sta     $DD0E
        ldx     #$0A
        clc
        bcc     LA077
LA06F:  lda     $DD0D
        lsr     a
        bcc     LA06F
        lsr     $A5
LA077:  lda     $DD00
        and     #$FB
        bcc     LA080
        ora     #$04
LA080:  sta     $DD00
        dex
        bne     LA06F
LA086:  lda     $DD0D
        lsr     a
        bcc     LA086
        lda     $DD00
        and     #$FB
        ora     #$04
        sta     $DD00
LA096:  lda     $DD0D
        lsr     a
        bcc     LA096
        pla
        tax
        rts

LA09F:  lda     $DD0C
        and     #$7F
        sta     $DD0C
        lda     #$3F
        sta     $DD02
        lda     $DD00
        ora     #$04
        sta     $DD00
        lda     #$10
        sta     $DD0E
        lda     #$FF
        sta     $DD04
        sta     $DD05
        lda     #$00
        sta     $DD03
        rts

LA0C7:  lda     $DC0C
        cmp     #$FE
        bne     LA0E5 ; not RS-232
        lda     #$7F
        sta     $DD03
        sta     $DD0D
        lda     #$3F
        sta     $DD02
        lda     #$04
        ora     $DD00
        sta     $DD00
LA0E3:  clc
        rts

LA0E5:  dec     $DD03
        bit     $DD0C
        bvs     LA0E3
        lda     #$11
        jsr     LA021
        lda     #$FF
        sta     $DC07
        lda     #$19
        sta     $DC0F
        lda     $DC0D
LA0FF:  lda     $DD0D
        and     #$10
        bne     LA0E3
        lda     $DC0D
        and     #$02
        beq     LA0FF
        sec
        rts
; ----------------------------------------------------------------

; these routines turn the cartridge ROM on before,
; and turn it back off afterwards
set_io_vectors_with_hidden_rom2:
        lda     #<_new_ckout
        ldy     #>_new_ckout
        sta     $0320 ; CKOUT
        sty     $0321
        lda     #<_new_bsout
        ldy     #>_new_bsout
        sta     $0326 ; BSOUT
        sty     $0327
        lda     #<_new_clrch
        ldy     #>_new_clrch
        sta     $0322 ; CLRCH
        sty     $0323
        lda     #<_new_clall
        ldy     #>_new_clall
        sta     $032C ; CLALL
        sty     $032D
        rts

; these routines assume the cartridge ROM is mapped
set_io_vectors2:
        lda     #<new_ckout
        ldy     #>new_ckout
        sta     $0320 ; CKOUT
        sty     $0321
        lda     #<new_bsout2
        ldy     #>new_bsout2
        sta     $0326 ; BSOUT
        sty     $0327
        lda     #<new_clrch2
        ldy     #>new_clrch2
        sta     $0322 ; CLRCH
        sty     $0323
        lda     #<new_clall2
        ldy     #>new_clall2
        sta     $032C ; CLALL
        sty     $032D
        rts

; ----------------------------------------------------------------
new_ckout: ; $A161
        txa
        pha
        jsr     $F30F ; find LFN
        beq     LA173
LA168:  pla
        tax
        jmp     $F250 ; KERNAL CKOUT

LA16D:  pla
        lda     #$04
        jmp     $F279 ; set output to IEC bus

LA173:  jsr     $F31F ; set file par from table
        lda     $BA
        cmp     #$04 ; printer
        bne     LA168
        jsr     LA183
        bcs     LA16D
        pla
        rts

LA183:  jsr     LA09F
        lda     $DC0C
        cmp     #$FF
        beq     LA19B ; "no centronics check"
        sei
        jsr     LA0C7
        bcs     LA19B
        lda     #$04
        sta     $9A
        jsr     LA1FC
        clc
LA19B:  rts

new_bsout: ; $A19C
        jsr     new_bsout2
        jmp     _disable_rom

new_bsout2:
        pha
        lda     $9A
        cmp     #$04
        beq     LA1AD
LA1A9:  pla
        jmp     $F1CA ; KERNAL BSOUT

LA1AD:  bit     $DD0C
        bpl     LA1A9
        pla
        sta     $95
        sei
        jsr     LA4E6
        bcs     LA1C0
        lda     $95
        jsr     LA00D
LA1C0:  lda     $95
        cli
        clc
        rts

new_clall: ; $A1C5
        jsr     new_clall2
        jmp     _disable_rom

new_clrch: ; $A1CB
        jsr     new_clrch2
        jmp     _disable_rom

new_clall2:
        lda     #$00
        sta     $98
new_clrch2:
        lda     #$04
        ldx     #$03
        cmp     $9A
        bne     LA1E7
        bit     $DD0C
        bpl     LA1E7
        jsr     LA09F
        beq     LA1EE
LA1E7:  cpx     $9A
        bcs     LA1EE
        jsr     $EDFE ; UNLISTEN
LA1EE:  cpx     $99
        bcs     LA1F5
        jsr     $EDEF ; UNTALK
LA1F5:  stx     $9A
        lda     #$00
        sta     $99
        rts

LA1FC:  lda     $B9
        cmp     #$FF
        beq     LA219
        and     #$0F
        beq     LA219
        cmp     #$07
        beq     LA21C
        cmp     #$09
        beq     LA21F
        cmp     #$0A
        beq     LA222
        cmp     #$08
        beq     LA225
        lda     #$C0
        .byte   $2C
LA219:  lda     #$C1
        .byte   $2C
LA21C:  lda     #$C2
        .byte   $2C
LA21F:  lda     #$C4
        .byte   $2C
LA222:  lda     #$C8
        .byte   $2C
LA225:  lda     #$D0
        sta     $DD0C
        rts

LA22B:  lda     $95
        cmp     #$C0
        bcc     LA245
        cmp     #$E0
        bcc     LA23D
        cmp     #$FF
        bne     LA241
        lda     #$7E
        bne     LA245
LA23D:  and     #$7F
        bcc     LA25B
LA241:  and     #$BF
        bcc     LA255
LA245:  cmp     #$40
        bcc     LA263
        cmp     #$60
        bcc     LA25F
        cmp     #$80
        bcc     LA25B
        cmp     #$A0
        bcc     LA257
LA255:  and     #$7F
LA257:  ora     #$40
        bne     LA269
LA25B:  and     #$DF
        bcc     LA269
LA25F:  and     #$BF
        bcc     LA269
LA263:  cmp     #$20
        bcs     LA269
        ora     #$80
LA269:  sta     $95
        rts

LA26C:  lda     $DD0C
        lsr     a
        bcs     LA2D1
        lsr     a
        bcs     LA2D2
        lsr     a
        bcc     LA27B
LA278:  jmp     LA39A

LA27B:  lsr     a
        bcs     LA278
        lsr     a
        bcs     LA282
        rts

LA282:  lda     $95
        cmp     #$0A
        beq     LA29A
        cmp     #$0D
        beq     LA29A
        cmp     #$20
        bcc     LA298
        cmp     #$80
        bcc     LA29A
        cmp     #$A0
        bcs     LA29A
LA298:  sec
        rts

LA29A:  lda     $D018
        and     #$02
        beq     LA2A4
        jsr     LA34F
LA2A4:  clc
        rts

LA2A6:  cmp     #$80
        bcc     LA2B0
        cmp     #$A0
        bcs     LA2B0
        sec
        rts

LA2B0:  lda     $DD0C
        lsr     a
        and     #$18
        bne     LA2BC
        bcc     LA2C0
        clc
        rts

LA2BC:  and     #$10
        beq     LA2C3
LA2C0:  jsr     LA34F
LA2C3:  clc
        rts

LA2C5:  pha
        lda     $DD0C
        and     #$CF
        sta     $DD0C
        pla
        clc
        rts

LA2D1:  lsr     a
LA2D2:  lsr     a
        bcc     LA2E0
        lsr     a
        lda     $95
        and     #$0F
        sta     $95
        bcc     LA319
        bcs     LA327
LA2E0:  lda     $95
        cmp     #$91
        beq     LA309
        cmp     #$20
        bcs     LA2A6
        cmp     #$0A
        beq     LA2C5
        cmp     #$0C
        beq     LA2C5
        cmp     #$0D
        beq     LA2C5
        cmp     #$11
        beq     LA30C
        cmp     #$10
        bne     LA317
        lda     $DC0C
        cmp     #$FE
        beq     LA317 ; RS-232
        lda     #$04
        bne     LA311
LA309:  lda     #$10
        .byte   $2C
LA30C:  lda     #$30
        jsr     LA2C5
LA311:  ora     $DD0C
        sta     $DD0C
LA317:  sec
        rts

LA319:  asl     a
        asl     a
        adc     $95
        asl     a
        sta     $A4
        lda     #$08
        ora     $DD0C
        bne     LA34A
LA327:  clc
        adc     $A4
        sta     $95
        lda     #$1B
        jsr     LA00D
        lda     #$44
        jsr     LA00D
        lda     $95
        jsr     LA00D
        lda     #$00
        jsr     LA00D
        lda     #$09
        jsr     LA00D
        lda     $DD0C
        and     #$F3
LA34A:  sta     $DD0C
        sec
        rts

LA34F:  lda     $95
        cmp     #$41
        bcc     LA373
        cmp     #$5B
        bcs     LA35D
        ora     #$20
        bne     LA373
LA35D:  cmp     #$61
        bcc     LA373
        cmp     #$7B
        bcs     LA369
        and     #$DF
        bcc     LA373
LA369:  cmp     #$C1
        bcc     LA373
        cmp     #$DB
        bcs     LA373
        and     #$7F
LA373:  sta     $95
        rts

LA376:  ldy     #$03
LA378:  asl     a
        rol     $FC
        dey
        bne     LA378
        rts

LA37F:  sta     $A4
        tya
        pha
        lda     $D018
        lsr     a
        and     #$01
        ora     #$1A
        sta     $FC
        lda     $A4
        jsr     LA376
        sta     $FB
        jsr     LA441
        pla
        tay
        rts

LA39A:  lda     $95
        cmp     #$0A
        beq     LA3BF
        cmp     #$0D
        beq     LA3BF
        jsr     LA22B
        tya
        pha
        ldy     $033C
        lda     $95
        sta     $033D,y
        inc     $033C
        cpy     #$1D
        bne     LA3BB
        jsr     LA3BF
LA3BB:  pla
        tay
        sec
        rts

LA3BF:  pha
        lda     $033C
        beq     LA43C
        jsr     LA49C
        tya
        pha
        lda     #$00
        sta     $FC
        lda     $033C
        jsr     LA376
        sta     $FB
        lda     $DC0C
        cmp     #$FE
        bne     LA41D ; not RS-232
        txa
        pha
        ldx     #$30
LA3E1:  lda     $FB
        sec
        sbc     #$64
        tay
        lda     $FC
        sbc     #$00
        bcc     LA3F4
        sta     $FC
        sty     $FB
        inx
        bne     LA3E1
LA3F4:  txa
        jsr     LA00D
        ldx     #$30
LA3FA:  lda     $FB
        sec
        sbc     #$0A
        tay
        lda     $FC
        sbc     #$00
        bcc     LA40D
        sta     $FC
        sty     $FB
        inx
        bne     LA3FA
LA40D:  txa
        jsr     LA00D
        lda     $FB
        ora     #$30
        jsr     LA00D
        pla
        tax
        jmp     LA427

LA41D:  lda     $FB
        jsr     LA00D
        lda     $FC
        jsr     LA00D
LA427:  ldy     #$00
LA429:  lda     $033D,y
        jsr     LA37F
        iny
        cpy     $033C
        bne     LA429
        lda     #$00
        sta     $033C
        pla
        tay
LA43C:  pla
        sta     $95
        clc
        rts

LA441:  lda     #$80
        sta     $A4
LA445:  lda     #$00
        sta     $A5
        ldy     #$07
        jsr     LA483
        lda     $DD0C
        lsr     a
        lsr     a
        lsr     a
        lda     $A5
        bcs     LA45A
        eor     #$FF
LA45A:  sta     $A5
        lda     $DC0C
        cmp     #$FE
        bne     LA471 ; not RS-232
        txa
        pha
        ldx     #$08
        lda     $A5
LA469:  asl     a
        ror     $A5
        dex
        bne     LA469
        pla
        tax
LA471:  lda     $A5
        jsr     LA00D
        lsr     $A4
        bcc     LA445
        rts

pow2:  .byte   $80,$40,$20,$10,$08,$04,$02,$01

LA483:  lda     #$33
        sta     $01
LA487:  lda     ($FB),y
        and     $A4
        beq     LA494
        lda     $A5
        ora     pow2,y
        sta     $A5
LA494:  dey
        bpl     LA487
        lda     #$37
        sta     $01
        rts

LA49C:  jsr     LA4CC
        lda     $DC0C
        cmp     #$FE
        beq     LA4D4 ; RS-232
        lda     $DC0C
        bne     LA4B0
LA4AB:  lda     #$4B
LA4AD:  jmp     LA00D

LA4B0:  cmp     #$30
        bcc     LA4AB
        cmp     #$5B
        bcs     LA4AB
        cmp     #$37
        bcc     LA4C2
        cmp     #$4B
        bcc     LA4AB
        bcs     LA4AD
LA4C2:  pha
        lda     #$2A
        jsr     LA00D
        pla
        and     #$0F
        .byte   $2C
LA4CC:  lda     #$1B
        bit     $0DA9
        jmp     LA00D

LA4D4:  lda     #$4E
        jsr     LA00D
        jsr     LA4CC
        lda     #$47
        jsr     LA00D
        lda     #$30
        jmp     LA00D

LA4E6:  lda     $DD0C
        cmp     #$C1
        bcc     LA4F0
        jsr     LA26C
LA4F0:  rts
; ----------------------------------------------------------------

        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF
        .byte   $FF

; ----------------------------------------------------------------
; drive code $0500
; ----------------------------------------------------------------
.segment "drive_code2"

drive_code2:
        lda     L0612
        tax
        lsr     a
        adc     #$03
        sta     $95
        sta     $31
        txa
        adc     #$06
        sta     $32
LA510:  jsr     receive_byte
        beq     :+
        sta     $81
        tax
        inx
        stx     L0611
        lda     #$00
        sta     $80
        beq     LA534

:       lda     $02FC
        bne     :+
        lda     $02FA ; XXX ORing the values together is shorter
        bne     :+
        lda     #$72
        jmp     $F969 ; DISK FULL

:       jsr     $F11E ; find and allocate free block
LA534:  ldy     #$00
        sty     $94
        lda     $80
        sta     ($94),y
        iny
        lda     $81
        sta     ($94),y
        iny
LA542:  jsr     $0564
        sta     ($30),y
        iny
        cpy     L0611
        bne     LA542
        jsr     $0150
        inc     $B6
        ldx     L0612
        lda     $81
        sta     $07,x
        lda     $80
        cmp     $06,x
        beq     LA510
        sta     $06,x
        jmp     $F418 ; set OK code

receive_byte:
        lda     #$00
        sta     $1800
        lda     #$04
:       bit     $1800
        bne     :-
        sta     $C0
drive_code2_timing_selfmod1:
        sta     $C0
        lda     $1800
        asl     a
        nop
        nop
        ora     $1800
        asl     a
        asl     a
        asl     a
        asl     a
        sta     a:$C0 ; 16 bit address for timing!
        lda     $1800
        asl     a
        nop
L0589:
        nop
L058A:
        ora     $1800
        and     #$0F
        ora     $C0
        sta     $C0
        lda     #$02
        sta     $1800
        lda     $C0
        rts
L0589_end:
        nop ; filler, gets overwritten when L0589 gets copied down by 1 byte

L059C:
        lda     #$EA
        sta     drive_code2_timing_selfmod1
        sta     drive_code2_timing_selfmod1 + 1 ; insert 1 cycle into code
        ldx     #L0589_end - L0589 - 1
LA5A6:  lda     L0589,x
        sta     L058A,x ; insert 3 cycles into code
        dex
        bpl     LA5A6
L05AF:
        ldx     #$64
LA5B1:  lda     $F575 - 1,x; copy "write data block to disk" to RAM
        sta     $0150 - 1,x
        dex
        bne     LA5B1
        lda     #$60
        sta     $01B4 ; add RTS at the end, just after GCR decoding
        inx
        stx     $82
        stx     $83
        jsr     $DF95 ; drive ROM
        inx
        stx     $1800
LA5CB:  inx
        bne     LA5CB
        sta     L0612 + 1
        asl     a
        sta     L0612
        tax
        lda     #$40
        sta     $02F9
LA5DB:  lda     $06,x
        beq     LA5FA
        sta     $0A
        lda     #$E0
        sta     $02
LA5E5:  lda     $02
        bmi     LA5E5
        cmp     #$02
        bcc     LA5DB
        cmp     #$72
        bne     LA5F4
        jmp     $C1C8 ; set error message

LA5F4:  ldx     L0612 + 1
        jmp     $E60A

LA5FA:  ldx     #L0608_end - L0608
LA5FC:  lda     L0608 - 1,x
        sta     $0150 - 1,x
        dex
        bne     LA5FC
        jmp     $0150

L0608:
        jsr     $DBA5 ; write directory entry
        jsr     $EEF4 ; write BAM
        jmp     $D227 ; close channel
L0608_end:

L0611:
        brk
L0612:

; ----------------------------------------------------------------
; C64 IEC code
; ----------------------------------------------------------------
.segment "part5"

LA612:  pha
        lda     $BA
        jsr     LISTEN
        pla
        jmp     SECOND

LA61C:  lda     #$6F
        pha
        lda     $BA
        jsr     TALK
        pla
        jmp     TKSA

LA628:  jsr     LA632
        jsr     $E716 ; KERNAL: output character to screen
        tya
        jmp     $E716 ; KERNAL: output character to screen

LA632:  pha
        and     #$0F
        jsr     LA63E
        tay
        pla
        lsr     a
        lsr     a
        lsr     a
        lsr     a
LA63E:  clc
        adc     #$F6
        bcc     LA645
        adc     #$06
LA645:  adc     #$3A
LA647:  rts

LA648:
        jsr     LA6C1
        bne     LA647
        lda     #$07
        sta     $93
.import __drive_code2_LOAD__
.import __drive_code2_RUN__
        lda     #<__drive_code2_LOAD__
        ldy     #>__drive_code2_LOAD__
        ldx     #$05
        jsr     transfer_code_to_drive
        lda     $0330
        cmp     #<_new_load
        beq     LA66A ; speeder enabled
        lda     #<L059C
        jsr     IECOUT
        lda     #>L059C
        bne     LA671

LA66A:  lda     #<L05AF
        jsr     IECOUT
        lda     #>L05AF
LA671:  jsr     IECOUT
        jsr     UNLSTN
        sei
        lda     $D015
        sta     $93
        sty     $D015
        lda     $DD00
        and     #$07
        sta     $A4
        ora     #$10
        sta     $A5
        sta     $DD00
        jmp     LA9F6

LA691:
        ldy     #$00
        .byte   $2C
LA694:
        ldy     #$08
        bit     $9D
        bpl     LA6A7
        jsr     LA6A8
        lda     $AF
        jsr     LA628
        lda     $AE
        jmp     LA628

LA6A7:  rts

LA6A8:  lda     s_from,y
        beq     LA6A7
        jsr     $E716 ; KERNAL: output character to screen
        iny
        bne     LA6A8

s_from: .byte   " FROM $", 0
        .byte   " TO $", 0

LA6C1:  jsr     LA61C
        jsr     IECIN ; first character, ASCII error code
        tay
LA6C8:  jsr     IECIN
        cmp     #$0D
        bne     LA6C8 ; read until CR
        jsr     UNTALK
        cpy     #'0' ; = no error
        rts

transfer_code_to_drive:
        sta     $C3
        sty     $C4
        ldy     #$00
LA6DB:  lda     #'W'
        jsr     LA707 ; send "M-W"
        tya
        jsr     IECOUT
        txa
        jsr     IECOUT
        lda     #$20
        jsr     IECOUT
LA6ED:  lda     ($C3),y
        jsr     IECOUT
        iny
        tya
        and     #$1F
        bne     LA6ED
        jsr     UNLSTN
        tya
        bne     LA6DB
        inc     $C4
        inx
        cpx     $93
        bcc     LA6DB
        lda     #'E' ; send "M-E"
LA707:  pha
        lda     #$6F
        jsr     LA612
        lda     #'M'
        jsr     IECOUT
        lda     #'-'
        jsr     IECOUT
        pla
        jmp     IECOUT

LA71B:
        ldy     #$00
        sty     $90
        lda     $BA
        jsr     $ED0C ; LISTEN
        lda     $B9
        ora     #$F0
        jsr     $EDB9 ; SECLST
        lda     $90
        bpl     LA734
        pla
        pla
        jmp     $F707 ; DEVICE NOT PRESENT ERROR

LA734:  jsr     _load_bb_indy
        jsr     $EDDD ; KERNAL IECOUT
        iny
        cpy     $B7
        bne     LA734
        jmp     $F654 ; UNLISTEN

LA742:  jsr     $F82E ; cassette sense
        beq     LA764
        ldy     #$1B
LA749:  jsr     LA7B3
LA74C:  bit     $DC01
        bpl     LA766
        jsr     $F82E ; cassette sense
        bne     LA74C
        ldy     #$6A
        jmp     LA7B3

LA75B:  jsr     $F82E ; cassette sense
        beq     LA764
        ldy     #$2E
LA762: ; ???
        bne     LA749
LA764:  clc
        rts

LA766:  sec
        rts

LA768:  lda     $9D
        bpl     LA7A7
        ldy     #$63
        jsr     LA7B7
        ldy     #$05
LA773:  lda     ($B2),y
        jsr     $E716 ; KERNAL: output character to screen
        iny
        cpy     #$15
        bne     LA773
        rts

LA77E:  jsr     LA7B1
        bmi     LA796
        rts

LA784:
        lda     $9D
        bpl     LA7A7
        ldy     #$0C
        jsr     LA7B7
        lda     $B7
        beq     LA7A7
        ldy     #$17
        jsr     LA7B7
LA796:  ldy     $B7
        beq     LA7A7
        ldy     #$00
LA79C:  jsr     _load_bb_indy
        jsr     $E716 ; KERNAL: output character to screen
        iny
        cpy     $B7
        bne     LA79C
LA7A7:  rts

print_loading:
        ldy     #$49 ; "LOADING"
        lda     $93
        beq     LA7B3
        ldy     #$59 ; "VERIFYING"
        .byte   $2C
LA7B1:  ldy     #$51 ; "SAVING"
LA7B3:  bit     $9D
        bpl     LA7C4
LA7B7:  lda     $F0BD,y ; KERNAL strings
        php
        and     #$7F
        jsr     $E716 ; KERNAL: output character to screen
        iny
        plp
        bpl     LA7B7 ; until MSB set
LA7C4:  clc
        rts

        ldx     #$0E
LA7C8:  lda     L9A41,x
        sta     L0110,x
        dex
        bpl     LA7C8
        ldx     #$05
        stx     $AB
        jsr     $FB8E ; copy I/O start address to buffer address
        jsr     LA75B
        bcc     LA7E2
        lda     #$00
        jmp     _disable_rom

LA7E2:  jsr     LA77E
        jsr     LA9EA
        jsr     LA999
        lda     $B9
        clc
        adc     #$01
        dex
        jsr     LA9BB
        ldx     #$08
LA7F6:  lda     $AC,y
        jsr     LA9BB
        ldx     #$06
        iny
        cpy     #$05
        nop
        bne     LA7F6
        ldy     #$00
        ldx     #$02
LA808:  jsr     _load_bb_indy
        cpy     $B7
        bcc     LA812
        lda     #$20
        dex
LA812:  jsr     LA9BB
        ldx     #$03
        iny
        cpy     #$BB
        bne     LA808
        lda     #$02
        sta     $AB
        jsr     LA999
        tya
        jsr     LA9BB
        sty     $D7
        ldx     #$05
LA82B:  jsr     L0110
        ldx     #$03 ; used to be "#$02" in 1988-05
        inc     $AC
        bne     LA837
        inc     $AD
        dex
LA837:  lda     $AC
        cmp     $AE
        lda     $AD
        sbc     $AF
        bcc     LA82B
LA841:  lda     $D7
        jsr     LA9BB
        ldx     #$07
        dey
        bne     LA841
        jsr     LA912
        jmp     _disable_rom

LA851:  jsr     LA8C9
        lda     $AB
        cmp     #$02
        beq     LA862
        cmp     #$01
        bne     LA851
        lda     $B9
        beq     LA86C
LA862:  lda     $033C
        sta     $C3
        lda     $033D
        sta     $C4
LA86C:  jsr     LA768
        cli
        lda     $A1
        jsr     $E4E0 ; wait for CBM key
        sei
        lda     $01
        and     #$1F
        sta     $01
        ldy     $B7
        beq     LA88C
LA880:  dey
        jsr     _load_bb_indy
        cmp     $0341,y
        bne     LA851
        tya
        bne     LA880
LA88C:  sty     $90
        jsr     print_loading
        lda     $C3
        sta     $AC
        lda     $C4
        sta     $AD
        sec
        lda     $033E
        sbc     $033C
        php
        clc
        adc     $C3
        sta     $AE
        lda     $033F
        adc     $C4
        plp
        sbc     $033D
        sta     $AF
        jsr     LA8E5
        lda     $BD
        eor     $D7
        ora     $90
        clc
        beq     LA8C2
        sec
        lda     #$FF
        sta     $90
LA8C2:  ldx     $AE
        ldy     $AF
        jmp     _disable_rom

LA8C9:  jsr     LA92B
        lda     $BD
        cmp     #$00
        beq     LA8C9
        sta     $AB
LA8D4:  jsr     LA96E
        lda     $BD
        sta     ($B2),y
        iny
        cpy     #$C0
        bne     LA8D4
        beq     LA913
LA8E2:  jmp     L0110

LA8E5:  jsr     LA92B
LA8E8:  jsr     LA96E
        cpy     $93
        bne     LA8E2
        lda     #$0B
        sta     $01
        lda     $BD
        sta     ($C3),y
        eor     $D7
        sta     $D7
        lda     #$0F
        sta     $01
LA8FF:
        inc     $C3
        bne     LA905
        inc     $C4
LA905:  lda     $C3
        cmp     $AE
        lda     $C4
        sbc     $AF
        bcc     LA8E8
        jsr     LA96E
LA912:  iny
LA913:  sty     $C0
        lda     #$00
        sta     $02A0
        lda     $D011
        ora     #$10
        sta     $D011
        lda     $01
        ora     #$20
        sta     $01
        cli
        clc
        rts

LA92B:  jsr     LA742
        bcc     LA939
        pla
        pla
        pla
        pla
        lda     #$00
        jmp     _disable_rom

LA939:  jsr     LA9EA
        sty     $D7
        lda     #$07
        sta     $DD06
        ldx     #$01
LA945:  jsr     LA97E
        rol     $BD
        lda     $BD
        cmp     #$02
        beq     LA954
        cmp     #$F2
        bne     LA945
LA954:  ldy     #$09
LA956:  jsr     LA96E
        lda     $BD
        cmp     #$02
        beq     LA956
        cmp     #$F2
        beq     LA956
LA963:  cpy     $BD
        bne     LA945
        jsr     LA96E
        dey
        bne     LA963
        rts

LA96E:  lda     #$08
        sta     $A3
LA972:  jsr     LA97E
        rol     $BD
        nop
        nop
        dec     $A3
        bne     LA972
        rts

LA97E:  lda     #$10
LA980:  bit     $DC0D
        beq     LA980
        lda     $DD0D
        stx     $DD07
        pha
        lda     #$19
        sta     $DD0F
        pla
        lsr     a
        lsr     a
        rts

        lda     #$04
        sta     $AB
LA999:  ldy     #$00
LA99B:  lda     #$02
        jsr     LA9BB
        ldx     #$07
        dey
        cpy     #$09
        bne     LA99B
        ldx     #$05
        dec     $AB
        bne     LA99B
LA9AD:  tya
        jsr     LA9BB
        ldx     #$07
        dey
        bne     LA9AD
        dex
        dex
        sty     $D7
        rts

LA9BB:  sta     $BD
        eor     $D7
        sta     $D7
        lda     #$08
        sta     $A3
LA9C5:  asl     $BD
        lda     $01
        and     #$F7
        jsr     LA9DD
        ldx     #$11
        nop
        ora     #$08
        jsr     LA9DD
        ldx     #$0E
        dec     $A3
        bne     LA9C5
        rts

LA9DD:  dex
        bne     LA9DD
        bcc     LA9E7
        ldx     #$0B
LA9E4:  dex
        bne     LA9E4
LA9E7:  sta     $01
        rts

LA9EA:  ldy     #$00
        sty     $C0
        lda     $D011
        and     #$EF
        sta     $D011
LA9F6:  dex
        bne     LA9F6
        dey
        bne     LA9F6
        sei
        rts

; ??? unreferenced?
        sei
        rts

basic_keywords:
        .byte   "EN", 'D' + $80
        .byte   "FO", 'R' + $80
        .byte   "NEX", 'T' + $80
        .byte   "DAT", 'A' + $80
        .byte   "INPUT", '#' + $80
        .byte   "INPU", 'T' + $80
        .byte   "DI", 'M' + $80
        .byte   "REA", 'D' + $80
        .byte   "LE", 'T' + $80
        .byte   "GOT", 'O' + $80
        .byte   "RU", 'N' + $80
        .byte   "I", 'F' + $80
        .byte   "RESTOR", 'E' + $80
        .byte   "GOSU", 'B' + $80
        .byte   "RETUR", 'N' + $80
        .byte   "RE", 'M' + $80
        .byte   "STO", 'P' + $80
        .byte   "O", 'N' + $80
        .byte   "WAI", 'T' + $80
        .byte   "LOA", 'D' + $80
        .byte   "SAV", 'E' + $80
        .byte   "VERIF", 'Y' + $80
        .byte   "DE", 'F' + $80
        .byte   "POK", 'E' + $80
        .byte   "PRINT", '#' + $80
        .byte   "PRIN", 'T' + $80
        .byte   "CON", 'T' + $80
        .byte   "LIS", 'T' + $80
        .byte   "CL", 'R' + $80
        .byte   "CM", 'D' + $80
        .byte   "SY", 'S' + $80
        .byte   "OPE", 'N' + $80
        .byte   "CLOS", 'E' + $80
        .byte   "GE", 'T' + $80
        .byte   "NE", 'W' + $80
        .byte   "TAB", '(' + $80
        .byte   "T", 'O' + $80
        .byte   "F", 'N' + $80
        .byte   "SPC", '(' + $80
        .byte   "THE", 'N' + $80
        .byte   "NO", 'T' + $80
        .byte   "STE", 'P' + $80
        .byte   '+' + $80
        .byte   '-' + $80
        .byte   '*' + $80
        .byte   '/' + $80
        .byte   '^' + $80
        .byte   "AN", 'D' + $80
        .byte   "O", 'R' + $80
        .byte   '>' + $80
        .byte   '=' + $80
        .byte   '<' + $80
        .byte   "SG", 'N' + $80
        .byte   "IN", 'T' + $80
        .byte   "AB", 'S' + $80
        .byte   "US", 'R' + $80
        .byte   "FR", 'E' + $80
        .byte   "PO", 'S' + $80
        .byte   "SQ", 'R' + $80
        .byte   "RN", 'D' + $80
        .byte   "LO", 'G' + $80
        .byte   "EX", 'P' + $80
        .byte   "CO", 'S' + $80
        .byte   "SI", 'N' + $80
        .byte   "TA", 'N' + $80
        .byte   "AT", 'N' + $80
        .byte   "PEE", 'K' + $80
        .byte   "LE", 'N' + $80
        .byte   "STR", '$' + $80
        .byte   "VA", 'L' + $80
        .byte   "AS", 'C' + $80
        .byte   "CHR", '$' + $80
        .byte   "LEFT", '$' + $80
        .byte   "RIGHT", '$' + $80
        .byte   "MID", '$' + $80
        .byte   "G", 'O' + $80
        .byte   0

; ----------------------------------------------------------------
; Monitor (~4750 bytes)
; ----------------------------------------------------------------
.segment "monitor"

monitor: ; $AB00
        lda     #<(brk_entry - ram_code + L0220)
        sta     $0316
        lda     #>(brk_entry - ram_code + L0220)
        sta     $0317 ; BRK vector
        lda     #$43
        sta     $0251
        lda     #$37
        sta     $0253 ; bank 7
        lda     #$70
        sta     $0257 ; value of $DFFF, by default, hide cartridge
        ldx     #ram_code_end - ram_code - 1
LAB1B:  lda     ram_code,x
        sta     L0220,x
        dex
        bpl     LAB1B
        brk ; <- nice!

; code that will be copied to $0220
ram_code:
; $0220
; read from memory with a specific ROM and cartridge config
        sta     $DFFF ; set cartridge config
        pla
        sta     $01 ; set ROM config
        lda     ($C1),y ; read
; $0228
; enable all ROMs
        pha
        lda     #$37
        sta     $01 ; restore ROM config
        lda     #$40
        sta     $DFFF ; resture cartridge config
        pla
        rts
; $0234
; rti
        jsr     _disable_rom
        sta     $01
        lda     $024B ; A register
        rti

brk_entry:
        jsr     $0228; enable all ROMs
        jmp     LAB48
ram_code_end:

LAB48:  cld ; <- important :)
        pla
        sta     $024D ; Y
        pla
        sta     $024C ; X
        pla
        sta     $024B ; A
        pla
        sta     $024A ; P
        pla
        sta     $0249 ; PC lo
        pla
        sta     $0248 ; PC hi
        tsx
        stx     $024E
        jsr     set_irq_vector
        jsr     set_io_vectors
        jsr     print_cr
        lda     $0251
        cmp     #'C'
        bne     LAB76
        .byte   $2C ; XXX bne + skip = beq + 2
LAB76:  lda     #'B'
        ldx     #'*'
        jsr     print_a_x
        clc
        lda     $0249 ; PC lo
        adc     #$FF
        sta     $0249 ; PC lo
        lda     $0248
        adc     #$FF
        sta     $0248 ; decrement PC
        lda     $BA
        and     #$FB
        sta     $BA
        lda     #$42
        sta     $0251
        lda     #$80
        sta     $028A
        bne     LABA5 ; always

; ----------------------------------------------------------------
; "R" - dump registers
; ----------------------------------------------------------------
cmd_r:
        jsr     basin_cmp_cr
        bne     syntax_error
LABA5:  ldx     #$00
LABA7:  lda     s_regs,x
        beq     print_registers
        jsr     BSOUT
        inx
        bne     LABA7
print_registers:
        ldx     #';'
        jsr     print_dot_x
        lda     $0248 ; PC hi
        jsr     print_hex_byte2 ; address hi
        lda     $0249 ; PC lo
        jsr     print_hex_byte2 ; address lo
        jsr     print_space
        lda     $0250 ; $0315
        jsr     print_hex_byte2 ; IRQ hi
        lda     $024F ; $0314
        jsr     print_hex_byte2 ; IRQ lo
        jsr     print_space
        lda     $0253 ; bank
        bpl     LABE6
        lda     #'D'
        jsr     BSOUT
        lda     #'R'
        jsr     BSOUT
        bne     LABEB ; negative bank means drive ("DR")
LABE6:  and     #$0F
        jsr     print_hex_byte2 ; bank
LABEB:  ldy     #$00
LABED:  jsr     print_space
        lda     $024B,y
        jsr     print_hex_byte2 ; registers...
        iny
        cpy     #$04
        bne     LABED
        jsr     print_space
        lda     $024A ; processor status
        jsr     print_bin
        beq     input_loop ; always

syntax_error:
        lda     #'?'
        .byte   $2C
print_cr_then_input_loop:
        lda     #$0D ; CR
        jsr     BSOUT

input_loop:
        ldx     $024E
        txs
        lda     #$00
        sta     $0254
        jsr     print_cr_dot
input_loop2:
        jsr     basin_if_more
        cmp     #'.'
        beq     input_loop2 ; skip dots
        cmp     #' '
        beq     input_loop2 ; skip spaces
        ldx     #$1A
LAC27:  cmp     command_names,x
        bne     LAC3B
        stx     $0252 ; save command index
        txa
        asl     a
        tax
        lda     function_table+1,x
        pha
        lda     function_table,x
        pha
        rts
LAC3B:  dex
        bpl     LAC27
        bmi     syntax_error ; always

; ----------------------------------------------------------------
; "EC"/"ES"/"D" - dump character or sprite data
; ----------------------------------------------------------------
cmd_e:
        jsr     BASIN
        cmp     #'C'
        beq     cmd_mid2
        cmp     #'S'
        beq     cmd_mid2
        jmp     syntax_error

fill_kbd_buffer_with_csr_right:
        lda     #$91 ; UP
        ldx     #$0D ; CR
        jsr     print_a_x
        lda     #$1D ; CSR RIGHT
        ldx     #$00
LAC59:  sta     $0277,x ; fill kbd buffer with 7 CSR RIGHT characters
        inx
        cpx     #$07
        bne     LAC59
        stx     $C6 ; 7
        jmp     input_loop2

cmd_mid2:
        sta     $0252 ; write 'C' or 'S' into command index

; ----------------------------------------------------------------
; "M"/"I"/"D" - dump 8 hex byes, 32 ASCII bytes, or disassemble
;               ("EC" and "ES" also end up here)
; ----------------------------------------------------------------
cmd_mid:
        jsr     get_hex_word
        jsr     basin_cmp_cr
        bne     LAC80 ; second argument
        jsr     copy_c3_c4_to_c1_c2
        jmp     LAC86

is_h:   jmp     LAEAC

; ----------------------------------------------------------------
; "F"/"H"/"C"/"T" - find, hunt, compare, transfer
; ----------------------------------------------------------------
cmd_fhct:
        jsr     get_hex_word
        jsr     basin_if_more
LAC80:  jsr     swap_c1_c2_and_c3_c4
        jsr     get_hex_word3
LAC86:  lda     $0252 ; command index (or 'C'/'S')
        beq     is_mie ; 'M' (hex dump)
        cmp     #$17
        beq     is_mie ; 'I' (ASCII dump)
        cmp     #$01
        beq     is_d ; 'D' (disassemble)
        cmp     #$06
        beq     is_f ; 'F' (fill)
        cmp     #$07
        beq     is_h ; 'H' (hunt)
        cmp     #'C'
        beq     is_mie ; 'EC'
        cmp     #'S'
        beq     is_mie ; 'ES'
        jmp     LAE88

LACA6:  jsr     LB64D
        bcs     is_mie
LACAB:  jmp     fill_kbd_buffer_with_csr_right

is_mie:
        jsr     print_cr
        lda     $0252 ; command index (or 'C'/'S')
        beq     LACC4 ; 'M'
        cmp     #'S'
        beq     LACD0
        cmp     #'C'
        beq     LACCA
        jsr     dump_ascii_line
        jmp     LACA6

LACC4:  jsr     dump_hex_line
        jmp     LACA6

; EC
LACCA:  jsr     dump_char_line
        jmp     LACA6

; ES
LACD0:  jsr     dump_sprite_line
        jmp     LACA6

LACD6:  jsr     LB64D
        bcc     LACAB
is_d:   jsr     print_cr
        jsr     dump_assembly_line
        jmp     LACD6

is_f:   jsr     basin_if_more
        jsr     get_hex_byte
        jsr     LB22E
        jmp     print_cr_then_input_loop

dump_sprite_line:
        ldx     #']'
        jsr     print_dot_x
        jsr     print_hex_16
        jsr     print_space
        ldy     #$00
LACFD:  jsr     load_byte
        jsr     print_bin
        iny
        cpy     #$03
        bne     LACFD
        jsr     print_8_spaces
        tya ; 3
        jmp     add_a_to_c1_c2

dump_char_line:
        ldx     #'['
        jsr     print_dot_x
        jsr     print_hex_16
        jsr     print_space
        ldy     #$00
        jsr     load_byte
        jsr     print_bin
        jsr     print_8_spaces
        jmp     inc_c1_c2

dump_hex_line:
        ldx     #':'
        jsr     print_dot_x
        jsr     print_hex_16
        jsr     dump_8_hex_bytes
        jsr     print_space
        jmp     dump_8_ascii_characters

dump_ascii_line:
        ldx     #$27  ; "'"
        jsr     print_dot_x
        jsr     print_hex_16
        jsr     print_space
        ldx     #$20
        jmp     dump_ascii_characters

dump_assembly_line:
        ldx     #','
LAD4B:  jsr     print_dot_x
        jsr     disassemble_line; XXX why not inline?
        jsr     print_8_spaces
        lda     $0205
        jmp     LB028

disassemble_line:
        jsr     print_hex_16
        jsr     print_space
        jsr     LAF62
        jsr     LAF40
        jsr     LAFAF
        jmp     LAFD7

; ----------------------------------------------------------------
; "[" - input character data
; ----------------------------------------------------------------
cmd_leftbracket:
        jsr     get_hex_word
        jsr     copy_c3_c4_to_c1_c2
        jsr     basin_skip_spaces_if_more
        jsr     LB4DB
        ldy     #$00
        jsr     store_byte
        jsr     print_up
        jsr     dump_char_line
        jsr     print_cr_dot
        jsr     fill_kbd_buffer_leftbracket
        jmp     input_loop2

; ----------------------------------------------------------------
; "]" - input sprite data
; ----------------------------------------------------------------
cmd_rightbracket:
        jsr     get_hex_word
        jsr     copy_c3_c4_to_c1_c2
        jsr     basin_skip_spaces_if_more
        jsr     LB4DB
        ldy     #$00
        beq     LAD9F
LAD9C:  jsr     get_bin_byte
LAD9F:  jsr     store_byte
        iny
        cpy     #$03
        bne     LAD9C
        jsr     print_up
        jsr     dump_sprite_line
        jsr     print_cr_dot
        jsr     fill_kbd_buffer_rightbracket
        jmp     input_loop2

; ----------------------------------------------------------------
; "'" - input 32 ASCII characters
; ----------------------------------------------------------------
cmd_singlequote:
        jsr     get_hex_word
        jsr     read_ascii
        jsr     print_up
        jsr     dump_ascii_line
        jsr     print_cr_dot
        jsr     fill_kbd_buffer_singlequote
        jmp     input_loop2

; ----------------------------------------------------------------
; ":" - input 8 hex bytes
; ----------------------------------------------------------------
cmd_colon:
        jsr     get_hex_word
        jsr     read_8_bytes
        jsr     print_up
        jsr     dump_hex_line
        jsr     print_cr_dot
        jsr     fill_kbd_buffer_semicolon
        jmp     input_loop2

; ----------------------------------------------------------------
; ";" - set registers
; ----------------------------------------------------------------
cmd_semicolon:
        jsr     get_hex_word
        lda     $C4
        sta     $0248 ; PC hi
        lda     $C3
        sta     $0249 ; PC lo
        jsr     basin_if_more
        jsr     get_hex_word3
        lda     $C3
        sta     $024F ; $0314
        lda     $C4
        sta     $0250 ; $0315
        jsr     basin_if_more ; skip upper nybble of bank
        jsr     basin_if_more
        cmp     #'D' ; "drive"
        bne     LAE12
        jsr     basin_if_more
        cmp     #'R'
        bne     LAE3D
        ora     #$80 ; XXX why not lda #$80?
        bmi     LAE1B ; always
LAE12:  jsr     get_hex_byte2
        cmp     #$08
        bcs     LAE3D ; syntax error
        ora     #$30
LAE1B:  sta     $0253 ; bank
        ldx     #$00
LAE20:  jsr     basin_if_more
        jsr     get_hex_byte
        sta     $024B,x ; registers
        inx
        cpx     #$04
        bne     LAE20
        jsr     basin_if_more
        jsr     get_bin_byte
        sta     $024A ; processor status
        jsr     print_up
        jmp     print_registers

LAE3D:  jmp     syntax_error

; ----------------------------------------------------------------
; "," - input up to three hex values
; ----------------------------------------------------------------
cmd_comma:
        jsr     get_hex_word3
        ldx     #$03
        jsr     LB5E7
        lda     #$2C
        jsr     LAE7C
        jsr     fill_kbd_buffer_comma
        jmp     input_loop2

; ----------------------------------------------------------------
; "A" - assemble
; ----------------------------------------------------------------
cmd_a:
        jsr     get_hex_word
        jsr     LB030
        jsr     LB05C
        ldx     #$00
        stx     $0206
LAE61:  ldx     $024E
        txs
        jsr     LB08D
        jsr     LB0AB
        jsr     swap_c1_c2_and_c3_c4
        jsr     LB0EF
        lda     #'A'
        jsr     LAE7C
        jsr     fill_kbd_buffer_a
        jmp     input_loop2

LAE7C:  pha
        jsr     print_up
        pla
        tax
        jsr     LAD4B
        jmp     print_cr_dot

LAE88:  jsr     LB655
        bcs     LAE90
        jmp     syntax_error

LAE90:  sty     $020A
        jsr     basin_if_more
        jsr     get_hex_word3
        lda     $0252 ; command index (or 'C'/'S')
        cmp     #$08 ; 'C'
        beq     LAEA6
        jsr     LB1CB
        jmp     print_cr_then_input_loop

LAEA6:  jsr     LB245
        jmp     input_loop

LAEAC:  jsr     basin_if_more
        ldx     #$00
        stx     $020B
        jsr     basin_if_more
        cmp     #$22
        bne     LAECF
LAEBB:  jsr     basin_cmp_cr
        beq     LAEE7
        cmp     #$22
        beq     LAEE7
        sta     $0200,x
        inx
        cpx     #$20
        bne     LAEBB
        jmp     syntax_error

LAECF:  jsr     get_hex_byte2
        bcs     LAEDC
LAED4:  jsr     basin_cmp_cr
        beq     LAEE7
        jsr     get_hex_byte
LAEDC:  sta     $0200,x
        inx
        cpx     #$20
        bne     LAED4
LAEE4:  jmp     syntax_error

LAEE7:  stx     $0252 ; command index (or 'C'/'S')
        txa
        beq     LAEE4
        jsr     LB293
        jmp     input_loop

; ----------------------------------------------------------------
; "G" - run code
; ----------------------------------------------------------------
cmd_g:
        jsr     basin_cmp_cr
        beq     LAF03
        jsr     get_hex_word2
        jsr     basin_cmp_cr
        beq     LAF06
        jmp     syntax_error

LAF03:  jsr     copy_pc_to_c3_c4_and_c1_c2
LAF06:  lda     $0253 ; bank
        bmi     LAF2B ; drive
        jsr     set_irq_vector
        jsr     set_io_vectors_with_hidden_rom
        ldx     $024E
        txs
        lda     $C4
        pha
        lda     $C3
        pha
        lda     $024A; processor status
        pha
        ldx     $024C
        ldy     $024D
        lda     $0253 ; bank
        jmp     $0234 ; rti
LAF2B:  lda     #'E' ; send M-E to drive
        jsr     send_m_dash2
        lda     $C3
        jsr     IECOUT
        lda     $C4
        jsr     IECOUT
        jsr     UNLSTN
        jmp     print_cr_then_input_loop

; ----------------------------------------------------------------
; assembler/disassembler
; ----------------------------------------------------------------
LAF40:  pha
        ldy     #$00
LAF43:  cpy     $0205
        beq     LAF52
        bcc     LAF52
        jsr     print_space
        jsr     print_space
        bcc     LAF58
LAF52:  jsr     load_byte
        jsr     print_hex_byte2
LAF58:  jsr     print_space
        iny
        cpy     #$03
        bne     LAF43
        pla
        rts

LAF62:  ldy     #$00
        jsr     load_byte
LAF67:  tay
        lsr     a
        bcc     LAF76
        lsr     a
        bcs     LAF85
        cmp     #$22
        beq     LAF85
        and     #$07
        ora     #$80
LAF76:  lsr     a
        tax
        lda     asmtab1,x
        bcs     LAF81
        lsr     a
        lsr     a
        lsr     a
        lsr     a
LAF81:  and     #$0F
        bne     LAF89
LAF85:  ldy     #$80
        lda     #$00
LAF89:  tax
        lda     asmtab2,x
        sta     $0207
        and     #$03
        sta     $0205
        tya
        and     #$8F
        tax
        tya
        ldy     #$03
        cpx     #$8A
        beq     LAFAB
LAFA0:  lsr     a
        bcc     LAFAB
        lsr     a
LAFA4:  lsr     a
        ora     #$20
        dey
        bne     LAFA4
        iny
LAFAB:  dey
        bne     LAFA0
        rts

LAFAF:  tay
        lda     nmemos1,y
        sta     $020A
        lda     nmemos2,y
        sta     $0208
        ldx     #$03
LAFBE:  lda     #$00
        ldy     #$05
LAFC2:  asl     $0208
        rol     $020A
        rol     a
        dey
        bne     LAFC2
        adc     #$3F
        jsr     BSOUT
        dex
        bne     LAFBE
        jmp     print_space

LAFD7:  ldx     #$06
LAFD9:  cpx     #$03
        bne     LAFF4
        ldy     $0205
        beq     LAFF4
LAFE2:  lda     $0207
        cmp     #$E8
        php
        jsr     load_byte
        plp
        bcs     LB00B
        jsr     print_hex_byte2
        dey
        bne     LAFE2
LAFF4:  asl     $0207
        bcc     LB007
        lda     asmtab3,x
        jsr     BSOUT
        lda     asmtab4,x
        beq     LB007
        jsr     BSOUT
LB007:  dex
        bne     LAFD9
        rts

LB00B:  jsr     LB01C
        tax
        inx
        bne     LB013
        iny
LB013:  tya
        jsr     print_hex_byte2
        txa
        jmp     print_hex_byte2

LB01B:  sec
LB01C:  ldy     $C2
        tax
        bpl     LB022
        dey
LB022:  adc     $C1
        bcc     LB027
        iny
LB027:  rts

LB028:  jsr     LB01B
        sta     $C1
        sty     $C2
        rts

LB030:  ldx     #$00
        stx     $0211
LB035:  jsr     basin_if_more
        cmp     #$20
        beq     LB030
        sta     $0200,x
        inx
        cpx     #$03
        bne     LB035
LB044:  dex
        bmi     LB05B
        lda     $0200,x
        sec
        sbc     #$3F
        ldy     #$05
LB04F:  lsr     a
        ror     $0211
        ror     $0210
        dey
        bne     LB04F
        beq     LB044
LB05B:  rts

LB05C:  ldx     #$02
LB05E:  jsr     BASIN
        cmp     #$0D
        beq     LB089
        cmp     #$3A
        beq     LB089
        cmp     #$20
        beq     LB05E
        jsr     LB61C
        bcs     LB081
        jsr     get_hex_byte3
        ldy     $C1
        sty     $C2
        sta     $C1
        lda     #$30
        sta     $0210,x
        inx
LB081:  sta     $0210,x
        inx
        cpx     #$17
        bcc     LB05E
LB089:  stx     $020A
        rts

LB08D:  ldx     #$00
        stx     $0204
        lda     $0206
        jsr     LAF67
        ldx     $0207
        stx     $0208
        tax
        lda     nmemos2,x
        jsr     LB130
        lda     nmemos1,x
        jmp     LB130

LB0AB:  ldx     #$06
LB0AD:  cpx     #$03
        bne     LB0C5
        ldy     $0205
        beq     LB0C5
LB0B6:  lda     $0207
        cmp     #$E8
        lda     #$30
        bcs     LB0DD
        jsr     LB12D
        dey
        bne     LB0B6
LB0C5:  asl     $0207
        bcc     LB0D8
        lda     asmtab3,x
        jsr     LB130
        lda     asmtab4,x
        beq     LB0D8
        jsr     LB130
LB0D8:  dex
        bne     LB0AD
        beq     LB0E3
LB0DD:  jsr     LB12D
        jsr     LB12D
LB0E3:  lda     $020A
        cmp     $0204
        beq     LB0EE
        jmp     LB13B

LB0EE:  rts

LB0EF:  ldy     $0205
        beq     LB123
        lda     $0208
        cmp     #$9D
        bne     LB11A
        jsr     LB655
        bcc     LB10A
        tya
        bne     LB12A
        ldx     $0209
        bmi     LB12A
        bpl     LB112
LB10A:  iny
        bne     LB12A
        ldx     $0209
        bpl     LB12A
LB112:  dex
        dex
        txa
        ldy     $0205
        bne     LB11D
LB11A:  lda     $C2,y
LB11D:  jsr     store_byte
        dey
        bne     LB11A
LB123:  lda     $0206
        jsr     store_byte
        rts

LB12A:  jmp     input_loop

LB12D:  jsr     LB130
LB130:  stx     $0203
        ldx     $0204
        cmp     $0210,x
        beq     LB146
LB13B:  inc     $0206
        beq     LB143
        jmp     LAE61

LB143:  jmp     input_loop

LB146:  inx
        stx     $0204
        ldx     $0203
        rts

; ----------------------------------------------------------------
; "$" - convert hex to decimal
; ----------------------------------------------------------------
cmd_dollar:
        jsr     get_hex_word
        jsr     print_up_dot
        jsr     copy_c3_c4_to_c1_c2
        jsr     print_dollar_hex_16
        jsr     LB48E
        jsr     print_hash
        jsr     LBC50
        jmp     input_loop

; ----------------------------------------------------------------
; "#" - convert decimal to hex
; ----------------------------------------------------------------
cmd_hash:
        ldy     #$00
        sty     $C1
        sty     $C2
        jsr     basin_skip_spaces_if_more
LB16F:  and     #$0F
        clc
        adc     $C1
        sta     $C1
        bcc     LB17A
        inc     $C2
LB17A:  jsr     BASIN
        cmp     #$30
        bcc     LB19B
        pha
        lda     $C1
        ldy     $C2
        asl     a
        rol     $C2
        asl     a
        rol     $C2
        adc     $C1
        sta     $C1
        tya
        adc     $C2
        asl     $C1
        rol     a
        sta     $C2
        pla
        bcc     LB16F
LB19B:  jsr     print_up_dot
        jsr     print_hash
        lda     $C1
        pha
        lda     $C2
        pha
        jsr     LBC50
        pla
        sta     $C2
        pla
        sta     $C1
        jsr     LB48E
        jsr     print_dollar_hex_16
        jmp     input_loop

; ----------------------------------------------------------------
; "X" - exit monitor
; ----------------------------------------------------------------
cmd_x:
        jsr     set_irq_vector
        jsr     set_io_vectors_with_hidden_rom
        lda     #$00
        sta     $028A
        ldx     $024E
        txs
        jmp     _basic_warm_start

LB1CB:  lda     $C3
        cmp     $C1
        lda     $C4
        sbc     $C2
        bcs     LB1FC
        ldy     #$00
        ldx     #$00
LB1D9:  jsr     load_byte
        pha
        jsr     swap_c1_c2_and_c3_c4
        pla
        jsr     store_byte
        jsr     swap_c1_c2_and_c3_c4
        cpx     $020A
        bne     LB1F1
        cpy     $0209
        beq     LB1FB
LB1F1:  iny
        bne     LB1D9
        inc     $C2
        inc     $C4
        inx
        bne     LB1D9
LB1FB:  rts

LB1FC:  clc
        ldx     $020A
        txa
        adc     $C2
        sta     $C2
        clc
        txa
        adc     $C4
        sta     $C4
        ldy     $0209
LB20E:  jsr     load_byte
        pha
        jsr     swap_c1_c2_and_c3_c4
        pla
        jsr     store_byte
        jsr     swap_c1_c2_and_c3_c4
        cpy     #$00
        bne     LB229
        cpx     #$00
        beq     LB22D
        dec     $C2
        dec     $C4
        dex
LB229:  dey
        jmp     LB20E

LB22D:  rts

LB22E:  ldy     #$00
LB230:  jsr     store_byte
        ldx     $C1
        cpx     $C3
        bne     LB23F
        ldx     $C2
        cpx     $C4
        beq     LB244
LB23F:  jsr     inc_c1_c2
        bne     LB230
LB244:  rts

LB245:  jsr     print_cr
        clc
        lda     $C1
        adc     $0209
        sta     $0209
        lda     $C2
        adc     $020A
        sta     $020A
        ldy     #$00
LB25B:  jsr     load_byte
        sta     $0252 ; command index (or 'C'/'S')
        jsr     swap_c1_c2_and_c3_c4
        jsr     load_byte
        pha
        jsr     swap_c1_c2_and_c3_c4
        pla
        cmp     $0252 ; command index (or 'C'/'S')
        beq     LB274
        jsr     print_space_hex_16
LB274:  jsr     STOP
        beq     LB292
        lda     $C2
        cmp     $020A
        bne     LB287
        lda     $C1
        cmp     $0209
        beq     LB292
LB287:  inc     $C3
        bne     LB28D
        inc     $C4
LB28D:  jsr     inc_c1_c2
        bne     LB25B
LB292:  rts

LB293:  jsr     print_cr
LB296:  jsr     LB655
        bcc     LB2B3
        ldy     #$00
LB29D:  jsr     load_byte
        cmp     $0200,y
        bne     LB2AE
        iny
        cpy     $0252 ; command index (or 'C'/'S')
        bne     LB29D
        jsr     print_space_hex_16
LB2AE:  jsr     inc_c1_c2
        bne     LB296
LB2B3:  rts

; ----------------------------------------------------------------
; memory load/store
; ----------------------------------------------------------------

; loads a byte at ($C1),y from drive RAM
LB2B4:  lda     #'R' ; send M-R to drive
        jsr     send_m_dash2
        jsr     iec_send_c1_c2_plus_y
        jsr     UNLSTN
        jsr     talk_cmd_channel
        jsr     IECIN ; read byte
        pha
        jsr     UNTALK
        pla
        rts

; stores a byte at ($C1),y in drive RAM
LB2CB:  lda     #'W' ; send M-W to drive
        jsr     send_m_dash2
        jsr     iec_send_c1_c2_plus_y
        lda     #$01
        jsr     IECOUT
        pla
        pha
        jsr     IECOUT
        jsr     UNLSTN
        pla
        rts

        lda     ($C1),y
        rts

        pla
        sta     ($C1),y
        rts

; loads a byte at ($C1),y from RAM with the correct ROM config
load_byte:
        sei
        lda     $0253 ; bank
        bmi     LB2B4 ; drive
        clc
        pha
        lda     $0257 ; value for $DFFF
        jmp     L0220 ; "lda ($C1),y" with ROM and cartridge config

; stores a byte at ($C1),y in RAM with the correct ROM config
store_byte:
        sei
        pha
        lda     $0253 ; bank
        bmi     LB2CB ; drive
        cmp     #$35
        bcs     LB306 ; I/O on
        lda     #$33 ; ROM at $A000, $D000 and $E000
        sta     $01 ; ??? why?
LB306:  pla
        sta     ($C1),y ; store
        pha
        lda     #$37
        sta     $01 ; restore ROM config
        pla
        rts

; ----------------------------------------------------------------
; "B" - set cartridge bank (0-3) to be visible at $8000-$BFFF
;       without arguments, this turns off cartridge visibility
; ----------------------------------------------------------------
cmd_b:  jsr     basin_cmp_cr
        beq     LB326 ; without arguments, set $70
        cmp     #' '
        beq     cmd_b ; skip spaces
        cmp     #'0'
        bcc     LB32E ; syntax error
        cmp     #'4'
        bcs     LB32E ; syntax error
        and     #$03 ; XXX no effect
        ora     #$40 ; make $40 - $43
        .byte   $2C
LB326:  lda     #$70 ; by default, hide cartridge
        sta     $0257
        jmp     print_cr_then_input_loop

LB32E:  jmp     syntax_error

; ----------------------------------------------------------------
; "O" - set bank
;       0 to 7 map to a $01 value of $30-$37, "D" switches to drive
;       memory
; ----------------------------------------------------------------
cmd_o:
        jsr     basin_cmp_cr
        beq     LB33F ; without arguments: bank 7
        cmp     #' '
        beq     cmd_o
        cmp     #'D'
        beq     LB34A ; disk
        .byte   $2C
LB33F:  lda     #$37 ; bank 7
        cmp     #$38
        bcs     LB32E ; syntax error
        cmp     #$30
        bcc     LB32E ; syntax error
        .byte   $2C
LB34A:  lda     #$80 ; drive
        sta     $0253 ; bank
        jmp     print_cr_then_input_loop

listen_command_channel:
        lda     #$6F
        jsr     init_and_listen
        lda     $90
        bmi     LB3A6
        rts

LB35C:  lda     #$16
        sta     $0326
        lda     #$E7
        sta     $0327
        lda     #$33
        sta     $0322
        lda     #$F3
        sta     $0323
        rts

; ----------------------------------------------------------------
; "L"/"S" - load/save file
; ----------------------------------------------------------------
cmd_ls:
        ldy     #$02
        sty     $BC
        dey
        sty     $B9
        dey
        sty     $B7
        lda     #$08
        sta     $BA
        lda     #$10
        sta     $BB
        jsr     basin_skip_spaces_cmp_cr
        bne     LB3B6
LB388:  lda     $0252 ; command index (or 'C'/'S')
        cmp     #$0B ; 'L'
        bne     LB3CC
LB38F:  jsr     LB35C
        jsr     set_irq_vector
        ldx     $C1
        ldy     $C2
        jsr     LB42D
        php
        jsr     set_io_vectors
        jsr     set_irq_vector
        plp
LB3A4:  bcc     LB3B3
LB3A6:  ldx     #$00
LB3A8:  lda     $F0BD,x ; "I/O ERROR"
        jsr     BSOUT
        inx
        cpx     #$0A
        bne     LB3A8
LB3B3:  jmp     input_loop

LB3B6:  cmp     #$22
        bne     LB3CC
LB3BA:  jsr     basin_cmp_cr
        beq     LB388
        cmp     #$22
        beq     LB3CF
        sta     ($BB),y
        inc     $B7
        iny
        cpy     #$10
        bne     LB3BA
LB3CC:  jmp     syntax_error

LB3CF:  jsr     basin_cmp_cr
        beq     LB388
        cmp     #$2C
LB3D6:  bne     LB3CC
        jsr     get_hex_byte
        and     #$0F
        beq     LB3CC
        cmp     #$01
        beq     LB3E7
        cmp     #$04
        bcc     LB3CC
LB3E7:  sta     $BA
        jsr     basin_cmp_cr
        beq     LB388
        cmp     #$2C
LB3F0:  bne     LB3D6
        jsr     get_hex_word3
        jsr     swap_c1_c2_and_c3_c4
        jsr     basin_cmp_cr
        bne     LB408
        lda     $0252 ; command index (or 'C'/'S')
        cmp     #$0B ; 'L'
        bne     LB3F0
        dec     $B9
        beq     LB38F
LB408:  cmp     #$2C
LB40A:  bne     LB3F0
        jsr     get_hex_word3
        jsr     basin_skip_spaces_cmp_cr
        bne     LB40A
        ldx     $C3
        ldy     $C4
        lda     $0252 ; command index (or 'C'/'S')
        cmp     #$0C ; 'S'
        bne     LB40A
        dec     $B9
        jsr     LB35C
        jsr     LB438
        jsr     set_io_vectors
        jmp     LB3A4

LB42D:  lda     #>(_enable_rom - 1)
        pha
        lda     #<(_enable_rom - 1)
        pha
        lda     #$00
        jmp     LOAD

LB438:  lda     #>(_enable_rom - 1)
        pha
        lda     #<(_enable_rom - 1)
        pha
        lda     #$C1
        jmp     SAVE

; ----------------------------------------------------------------
; "@" - send drive command
;       without arguments, this reads the drive status
;       $ shows the directory
;       F does a fast format
; ----------------------------------------------------------------
cmd_at: 
        jsr     listen_command_channel
        jsr     basin_cmp_cr
        beq     print_drive_status
        cmp     #'$'
        beq     LB475
        cmp     #'F'
        bne     LB458
        jsr     fast_format
        lda     #'F'
LB458:  jsr     IECOUT
        jsr     basin_cmp_cr
        bne     LB458
        jsr     UNLSTN
        jmp     print_cr_then_input_loop

; just print drive status
print_drive_status:
        jsr     print_cr
        jsr     UNLSTN
        jsr     talk_cmd_channel
        jsr     cat_line_iec
        jmp     input_loop

; show directory
LB475:  jsr     UNLSTN
        jsr     print_cr
        lda     #$F0 ; sec address
        jsr     init_and_listen
        lda     #'$'
        jsr     IECOUT
        jsr     UNLSTN
        jsr     directory
        jmp     input_loop

LB48E:  jsr     print_space
        lda     #'='
        ldx     #' '
        bne     print_a_x

print_up:
        ldx     #$91 ; UP
        .byte   $2C
print_cr_dot:
        ldx     #'.'
        lda     #$0D ; CR
        .byte   $2C
print_dot_x:
        lda     #'.'
print_a_x:
        jsr     BSOUT
        txa
        jmp     BSOUT

print_up_dot:
        jsr     print_up
        lda     #'.'
        .byte   $2C
; XXX unused?
        lda     #$1D ; CSR RIGHT
        .byte   $2C
print_hash:
        lda     #'#'
        .byte   $2C
print_space:
        lda     #' '
        .byte   $2C
print_cr:
        lda     #$0D ; CR
        jmp     BSOUT

basin_skip_spaces_if_more:
        jsr     basin_skip_spaces_cmp_cr
        jmp     LB4C5

; get a character; if it's CR, return to main input loop
basin_if_more:
        jsr     basin_cmp_cr
LB4C5:  bne     LB4CA ; rts
        jmp     input_loop

LB4CA:  rts

basin_skip_spaces_cmp_cr:
        jsr     BASIN
        cmp     #' '
        beq     basin_skip_spaces_cmp_cr ; skip spaces
        cmp     #$0D
        rts

basin_cmp_cr:
        jsr     BASIN
        cmp     #$0D
        rts

LB4DB:  pha
        ldx     #$08
        bne     LB4E6
get_bin_byte:
        ldx     #$08
LB4E2:  pha
        jsr     basin_if_more
LB4E6:  cmp     #'*'
        beq     LB4EB
        clc
LB4EB:  pla
        rol     a
        dex
        bne     LB4E2
        rts

; get a 16 bit ASCII hex number from the user, return it in $C3/$C4
get_hex_word:
        jsr     basin_if_more
get_hex_word2:
        cmp     #' ' ; skip spaces
        beq     get_hex_word
        jsr     get_hex_byte2
        bcs     LB500 ; ??? always
get_hex_word3:
        jsr     get_hex_byte
LB500:  sta     $C4
        jsr     get_hex_byte
        sta     $C3
        rts

; get a 8 bit ASCII hex number from the user, return it in A
get_hex_byte:
        lda     #$00
        sta     $0256 ; XXX not necessary?
        jsr     basin_if_more
get_hex_byte2:
        jsr     validate_hex_digit
get_hex_byte3:
        jsr     hex_digit_to_nybble
        asl     a
        asl     a
        asl     a
        asl     a
        sta     $0256 ; low nybble
        jsr     get_hex_digit
        jsr     hex_digit_to_nybble
        ora     $0256
        sec
        rts

hex_digit_to_nybble:
        cmp     #'9' + 1
        and     #$0F
        bcc     LB530
        adc     #'A' - '9'
LB530:  rts

        clc
        rts

; get character and check for legal ASCII hex digit
; XXX this also allows ":;<=>?" (0x39-0x3F)!!!
get_hex_digit:
        jsr     basin_if_more
validate_hex_digit:
        cmp     #'0'
        bcc     LB547 ; error
        cmp     #'@' ; XXX should be: '9' + 1
        bcc     LB546 ; ok
        cmp     #'A'
        bcc     LB547 ; error
        cmp     #'F' + 1
        bcs     LB547 ; error
LB546:  rts
LB547:  jmp     syntax_error

print_dollar_hex_16:
        lda     #'$'
        .byte   $2C
print_space_hex_16:
        lda     #' '
        jsr     BSOUT
print_hex_16:
        lda     $C2
        jsr     print_hex_byte2
        lda     $C1

print_hex_byte2:
        sty     $0255
        jsr     print_hex_byte
        ldy     $0255
        rts

print_bin:
        ldx     #$08
LB565:  rol     a
        pha
        lda     #'*'
        bcs     LB56D
        lda     #'.'
LB56D:  jsr     BSOUT
        pla
        dex
        bne     LB565
        rts

inc_c1_c2:
        clc
        inc     $C1
        bne     LB57D
        inc     $C2
        sec
LB57D:  rts

dump_8_hex_bytes:
        ldx     #$08
        ldy     #$00
LB582:  jsr     print_space
        jsr     load_byte
        jsr     print_hex_byte2
        iny
        dex
        bne     LB582
        rts

dump_8_ascii_characters:
       ldx     #$08
dump_ascii_characters:
        ldy     #$00
LB594:  jsr     load_byte
        cmp     #$20
        bcs     LB59F
        inc     $C7
        ora     #$40
LB59F:  cmp     #$80
        bcc     LB5AD
        cmp     #$A0
        bcs     LB5AD
        and     #$7F
        ora     #$60
        inc     $C7
LB5AD:  jsr     BSOUT
        lda     #$00
        sta     $C7
        sta     $D4
        iny
        dex
        bne     LB594
        tya ; number of bytes consumed
        jmp     add_a_to_c1_c2

read_ascii:
        ldx     #$20
        ldy     #$00
        jsr     copy_c3_c4_to_c1_c2
        jsr     basin_if_more
LB5C8:  sty     $0209
        ldy     $D3
        lda     ($D1),y
        php
        jsr     basin_if_more
        ldy     $0209
        plp
        bmi     LB5E0
        cmp     #$60
        bcs     LB5E0
        jsr     store_byte
LB5E0:  iny
        dex
        bne     LB5C8
        rts

read_8_bytes:
        ldx     #$08
LB5E7:  ldy     #$00
        jsr     copy_c3_c4_to_c1_c2
        jsr     basin_skip_spaces_if_more
        jsr     get_hex_byte2
        jmp     LB607

LB5F5:  jsr     basin_if_more_cmp_space ; ignore character where space should be
        jsr     basin_if_more_cmp_space
        bne     LB604 ; not space
        jsr     basin_if_more_cmp_space
        bne     LB619 ; not space, error
        beq     LB60A ; always

LB604:  jsr     get_hex_byte2
LB607:  jsr     store_byte
LB60A:  iny
        dex
        bne     LB5F5
        rts

basin_if_more_cmp_space:
        jsr     basin_cmp_cr
        bne     LB616
        pla
        pla
LB616:  cmp     #' '
        rts

LB619:  jmp     syntax_error

LB61C:  cmp     #$30
        bcc     LB623
        cmp     #$47
        rts

LB623:  sec
        rts

swap_c1_c2_and_c3_c4:
        lda     $C4
        pha
        lda     $C2
        sta     $C4
        pla
        sta     $C2
        lda     $C3
        pha
        lda     $C1
        sta     $C3
        pla
        sta     $C1
        rts

copy_pc_to_c3_c4_and_c1_c2:
        lda     $0248 ; PC hi
        sta     $C4
        lda     $0249 ; PC lo
        sta     $C3

copy_c3_c4_to_c1_c2:
        lda     $C3
        sta     $C1
        lda     $C4
        sta     $C2
        rts

LB64D:  lda     $C2
        bne     LB655
        bcc     LB655
        clc
        rts

LB655:  jsr     STOP
        beq     LB66C
        lda     $C3
        ldy     $C4
        sec
        sbc     $C1
        sta     $0209 ; $C3 - $C1
        tya
        sbc     $C2 
        tay ; $C4 - $C2
        ora     $0209
        rts

LB66C:  clc
        rts

fill_kbd_buffer_comma:
        lda     #','
        .byte   $2C
fill_kbd_buffer_semicolon:
        lda     #':'
        .byte   $2C
fill_kbd_buffer_a:
        lda     #'A'
        .byte   $2C
fill_kbd_buffer_leftbracket:
        lda     #'['
        .byte   $2C
fill_kbd_buffer_rightbracket:
        lda     #']'
        .byte   $2C
fill_kbd_buffer_singlequote:
        lda     #$27 ; "'"
        sta     $0277 ; keyboard buffer
        lda     $C2
        jsr     byte_to_hex_ascii
        sta     $0278
        sty     $0279
        lda     $C1
        jsr     byte_to_hex_ascii
        sta     $027A
        sty     $027B
        lda     #' '
        sta     $027C
        lda     #$06 ; number of characters
        sta     $C6
        rts

LB6A2:  lda     #$1D
        ldx     #$07
        bne     LB6AC ; always

; print 8 spaces - this is used to clear some leftover characters
; on the screen when re-dumping a line with proper spacing after the
; user may have entered it with condensed spacing
print_8_spaces:
        lda     #' '
        ldx     #$08
LB6AC:  jsr     BSOUT
        dex
        bne     LB6AC
        rts

; ----------------------------------------------------------------
; IRQ logic to handle F keys and scrolling
; ----------------------------------------------------------------
set_irq_vector:
        lda     $0314
        cmp     #<irq_handler
        bne     LB6C1
        lda     $0315
        cmp     #>irq_handler
        beq     LB6D3
LB6C1:  lda     $0314
        ldx     $0315
        sta     $024F ; $0314
        stx     $0250 ; $0315
        lda     #<irq_handler
        ldx     #>irq_handler
        bne     LB6D9 ; always
LB6D3:  lda     $024F ; $0314
        ldx     $0250 ; $0315
LB6D9:  sei
        sta     $0314
        stx     $0315
        cli
        rts

irq_handler:
        lda     #>after_irq ; XXX shouldn't this be "-1"?
        pha
        lda     #<after_irq
        pha
        lda     #$00 ; fill A/X/Y/P
        pha
        pha
        pha
        pha
        jmp     $EA31 ; run normal IRQ handler, then return to this code

after_irq:
        lda     $0254
        bne     LB6FA
        lda     $C6 ; number of characters in keyboard buffer
        bne     LB700
LB6FA:  pla ; XXX JMP $EA81
        tay
        pla
        tax
        pla
        rti

LB700:  lda     $0277 ; keyboard buffer
        cmp     #$88 ; F7 key
        bne     LB71C
        lda     #'@'
        sta     $0277
        lda     #'$'
        sta     $0278
        lda     #$0D
        sta     $0279 ; store "@$' + CR into keyboard buffer
        lda     #$03 ; 3 characters
        sta     $C6
        bne     LB6FA ; always

LB71C:  cmp     #$87 ; F5 key
        bne     LB733
        ldx     #24
        cpx     $D6 ; cursor line
        beq     LB72E ; already on last line
        jsr     LB8D9
        ldy     $D3
        jsr     $E50C ; KERNAL set cursor position
LB72E:  lda     #$11 ; DOWN
        sta     $0277 ; kbd buffer
LB733:  cmp     #$86
        bne     LB74A
        ldx     #$00
        cpx     $D6
        beq     LB745
        jsr     LB8D9
        ldy     $D3
        jsr     $E50C ; KERNAL set cursor position
LB745:  lda     #$91; UP
        sta     $0277 ; kbd buffer
LB74A:  cmp     #$11 ; DOWN
        beq     LB758
        cmp     #$91 ; UP
        bne     LB6FA
        lda     $D6 ; cursor line
        beq     LB75E ; top of screen
        bne     LB6FA
LB758:  lda     $D6 ; cursor line
        cmp     #24
        bne     LB6FA
LB75E:  jsr     LB838
        bcc     LB6FA
        jsr     LB897
        php
        jsr     LB8D4
        plp
        bcs     LB6FA
        lda     $D6
        beq     LB7E1
        lda     $020C
        cmp     #$2C
        beq     LB790
        cmp     #$5B
        beq     LB7A2
        cmp     #$5D
        beq     LB7AE
        cmp     #$27
        beq     LB7BC
        jsr     LB8C8
        jsr     print_cr
        jsr     dump_hex_line
        jmp     LB7C7

LB790:  jsr     LAF62
        lda     $0205
        jsr     LB028
        jsr     print_cr
        jsr     dump_assembly_line
        jmp     LB7C7

LB7A2:  jsr     inc_c1_c2
        jsr     print_cr
        jsr     dump_char_line
        jmp     LB7C7

LB7AE:  lda     #$03
        jsr     add_a_to_c1_c2
        jsr     print_cr
        jsr     dump_sprite_line
        jmp     LB7C7

LB7BC:  lda     #$20
        jsr     add_a_to_c1_c2
        jsr     print_cr
        jsr     dump_ascii_line
LB7C7:  lda     #$91 ; UP
        ldx     #$0D ; CR
        bne     LB7D1
LB7CD:  lda     #$0D ; CR
        ldx     #$13 ; HOME
LB7D1:  ldy     #$00
        sty     $C6
        sty     $0254
        jsr     print_a_x
        jsr     LB6A2
        jmp     LB6FA

LB7E1:  jsr     LB8FE
        lda     $020C
        cmp     #','
        beq     LB800
        cmp     #'['
        beq     LB817
        cmp     #']'
        beq     LB822
        cmp     #$27 ; "'"
        beq     LB82D
        jsr     LB8EC
        jsr     dump_hex_line
        jmp     LB7CD

LB800:  jsr     swap_c1_c2_and_c3_c4
        jsr     LB90E
        inc     $0205
        lda     $0205
        eor     #$FF
        jsr     LB028
        jsr     dump_assembly_line
        clc
        bcc     LB7CD
LB817:  lda     #$01
        jsr     LB8EE
        jsr     dump_char_line
        jmp     LB7CD

LB822:  lda     #$03
        jsr     LB8EE
        jsr     dump_sprite_line
        jmp     LB7CD

LB82D:  lda     #$20
        jsr     LB8EE
        jsr     dump_ascii_line
        jmp     LB7CD

LB838:  lda     $D1
        ldx     $D2
        sta     $C3
        stx     $C4
        lda     #$19
        sta     $020D
LB845:  ldy     #$01
        jsr     LB88B
        cmp     #':'
        beq     LB884
        cmp     #','
        beq     LB884
        cmp     #'['
        beq     LB884
        cmp     #']'
        beq     LB884
        cmp     #$27 ; "'"
        beq     LB884
        dec     $020D
        beq     LB889
        lda     $0277 ; kbd buffer
        cmp     #$11 ; DOWN
        bne     LB877
        sec
        lda     $C3
        sbc     #40
        sta     $C3
        bcs     LB845
        dec     $C4
        bne     LB845
LB877:  clc
        lda     $C3
        adc     #$28
        sta     $C3
        bcc     LB845
        inc     $C4
        bne     LB845
LB884:  sec
        sta     $020C
        rts

LB889:  clc
        rts

LB88B:  lda     ($C3),y
        iny
        and     #$7F
        cmp     #$20
        bcs     LB896
        ora     #$40
LB896:  rts

LB897:  cpy     #$16
        bne     LB89D
        sec
        rts

LB89D:  jsr     LB88B
        cmp     #$20
        beq     LB897
        dey
        jsr     LB8B1
        sta     $C2
        jsr     LB8B1
        sta     $C1
        clc
        rts

LB8B1:  jsr     LB88B
        jsr     hex_digit_to_nybble
        asl     a
        asl     a
        asl     a
        asl     a
        sta     $020B
        jsr     LB88B
        jsr     hex_digit_to_nybble
        ora     $020B
        rts

LB8C8:  lda     #$08
add_a_to_c1_c2:
        clc
        adc     $C1
        sta     $C1
        bcc     LB8D3
        inc     $C2
LB8D3:  rts

LB8D4:  lda     #$FF
        sta     $0254
LB8D9:  lda     #$FF
        sta     $CC
        lda     $CF
        beq     LB8EB ; rts
        lda     $CE
        ldy     $D3
        sta     ($D1),y
        lda     #$00
        sta     $CF
LB8EB:  rts

LB8EC:  lda     #$08
LB8EE:  sta     $020E
        sec
        lda     $C1
        sbc     $020E
        sta     $C1
        bcs     LB8FD
        dec     $C2
LB8FD:  rts

LB8FE:  ldx     #$00
        jsr     $E96C ; insert line at top of screen
        lda     #$94
        sta     $D9
        sta     $DA
        lda     #$13 ; HOME
        jmp     BSOUT

LB90E:  lda     #$10
        sta     $020D
LB913:  sec
        lda     $C3
        sbc     $020D
        sta     $C1
        lda     $C4
        sbc     #$00
        sta     $C2
LB921:  jsr     LAF62
        lda     $0205
        jsr     LB028
        jsr     LB655
        beq     LB936
        bcs     LB921
        dec     $020D
        bne     LB913
LB936:  rts

; ----------------------------------------------------------------
; assembler tables
; ----------------------------------------------------------------
asmtab1:
        .byte   $40,$02,$45,$03,$D0,$08,$40,$09
        .byte   $30,$22,$45,$33,$D0,$08,$40,$09
        .byte   $40,$02,$45,$33,$D0,$08,$40,$09
        .byte   $40,$02,$45,$B3,$D0,$08,$40,$09
        .byte   $00,$22,$44,$33,$D0,$8C,$44,$00
        .byte   $11,$22,$44,$33,$D0,$8C,$44,$9A
        .byte   $10,$22,$44,$33,$D0,$08,$40,$09
        .byte   $10,$22,$44,$33,$D0,$08,$40,$09
        .byte   $62,$13,$78,$A9
asmtab2:
        .byte   $00,$21,$81,$82,$00,$00,$59,$4D
        .byte   $91,$92,$86,$4A,$85

asmtab3:
        .byte   $9D ; CSR LEFT
        .byte   ',', ')', ',', '#', '('

asmtab4:
        .byte   '$', 'Y', 0, 'X', '$', '$', 0

; encoded mnemos:
; every combination of a byte of nmemos1 and nmemos2
; encodes 3 ascii characters
nmemos1:
        .byte   $1C,$8A,$1C,$23,$5D,$8B,$1B,$A1
        .byte   $9D,$8A,$1D,$23,$9D,$8B,$1D,$A1
        .byte   $00,$29,$19,$AE,$69,$A8,$19,$23
        .byte   $24,$53,$1B,$23,$24,$53,$19,$A1
        .byte   $00,$1A,$5B,$5B,$A5,$69,$24,$24
        .byte   $AE,$AE,$A8,$AD,$29,$00,$7C,$00
        .byte   $15,$9C,$6D,$9C,$A5,$69,$29,$53
        .byte   $84,$13,$34,$11,$A5,$69,$23,$A0
nmemos2:
        .byte   $D8,$62,$5A,$48,$26,$62,$94,$88
        .byte   $54,$44,$C8,$54,$68,$44,$E8,$94
        .byte   $00,$B4,$08,$84,$74,$B4,$28,$6E
        .byte   $74,$F4,$CC,$4A,$72,$F2,$A4,$8A
        .byte   $00,$AA,$A2,$A2,$74,$74,$74,$72
        .byte   $44,$68,$B2,$32,$B2,$00,$22,$00
        .byte   $1A,$1A,$26,$26,$72,$72,$88,$C8
        .byte   $C4,$CA,$26,$48,$44,$44,$A2,$C8

; ----------------------------------------------------------------

s_regs: .byte   $0D, "   PC  IRQ  BK AC XR YR SP NV#BDIZC", $0D, 0

; ----------------------------------------------------------------

command_names:
        .byte   "MD:AGXFHCTRLS,O@$#*PE[]I';B"

function_table:
        .word   cmd_mid-1
        .word   cmd_mid-1
        .word   cmd_colon-1
        .word   cmd_a-1
        .word   cmd_g-1
        .word   cmd_x-1
        .word   cmd_fhct-1
        .word   cmd_fhct-1
        .word   cmd_fhct-1
        .word   cmd_fhct-1
        .word   cmd_r-1
        .word   cmd_ls-1
        .word   cmd_ls-1
        .word   cmd_comma-1
        .word   cmd_o-1
        .word   cmd_at-1
        .word   cmd_dollar-1
        .word   cmd_hash-1
        .word   cmd_asterisk-1
        .word   cmd_p-1
        .word   cmd_e-1
        .word   cmd_leftbracket-1
        .word   cmd_rightbracket-1
        .word   cmd_mid-1
        .word   cmd_singlequote-1
        .word   cmd_semicolon-1
        .word   cmd_b-1

; ----------------------------------------------------------------

LBA8C:  jmp     syntax_error

; ----------------------------------------------------------------
; "*R"/"*W" - read/write sector
; ----------------------------------------------------------------
cmd_asterisk:
        jsr     listen_command_channel
        jsr     UNLSTN
        jsr     BASIN
        cmp     #'W'
        beq     LBAA0
        cmp     #'R'
        bne     LBA8C ; syntax error
LBAA0:  sta     $C3 ; save 'R'/'W' mode
        jsr     basin_skip_spaces_if_more
        jsr     get_hex_byte2
        bcc     LBA8C
        sta     $C1
        jsr     basin_if_more
        jsr     get_hex_byte
        bcc     LBA8C
        sta     $C2
        jsr     basin_cmp_cr
        bne     LBAC1
        lda     #$CF
        sta     $C4
        bne     LBACD
LBAC1:  jsr     get_hex_byte
        bcc     LBA8C
        sta     $C4
        jsr     basin_cmp_cr
        bne     LBA8C
LBACD:  jsr     LBB48
        jsr     swap_c1_c2_and_c3_c4
        lda     $C1
        cmp     #'W'
        beq     LBB25
        lda     #'1'
        jsr     LBB6E
        jsr     talk_cmd_channel
        jsr     IECIN
        cmp     #'0'
        beq     LBB00 ; no error
        pha
        jsr     print_cr
        pla
LBAED:  jsr     $E716 ; KERNAL: output character to screen
        jsr     IECIN
        cmp     #$0D ; print drive status until CR (XXX redundant?)
        bne     LBAED
        jsr     UNTALK
        jsr     close_2
        jmp     input_loop

LBB00:  jsr     IECIN
        cmp     #$0D ; receive all bytes (XXX not necessary?)
        bne     LBB00
        jsr     UNTALK
        jsr     LBBAE
        ldx     #$02
        jsr     CHKIN
        ldy     #$00
        sty     $C1
LBB16:  jsr     IECIN
        jsr     store_byte ; receive block
        iny
        bne     LBB16
        jsr     CLRCH
        jmp     LBB42 ; close 2 and print drive status

LBB25:  jsr     LBBAE
        ldx     #$02
        jsr     CKOUT
        ldy     #$00
        sty     $C1
LBB31:  jsr     load_byte
        jsr     IECOUT ; send block
        iny
        bne     LBB31
        jsr     CLRCH
        lda     #'2'
        jsr     LBB6E
LBB42:  jsr     close_2
        jmp     print_drive_status

LBB48:  lda     #$02
        tay
        ldx     $BA
        jsr     SETLFS
        lda     #$01
        ldx     #$CF
        ldy     #$BB
        jsr     SETNAM
        jmp     OPEN

close_2:
        lda     #$02
        jmp     CLOSE

LBB61:  ldx     #$30
        sec
LBB64:  sbc     #$0A
        bcc     LBB6B
        inx
        bcs     LBB64
LBB6B:  adc     #$3A
        rts

LBB6E:  pha
        ldx     #$00
LBB71:  lda     s_u1,x
        sta     $0200,x
        inx
        cpx     #s_u1_end - s_u1
        bne     LBB71
        pla
        sta     $0201
        lda     $C3
        jsr     LBB61
        stx     $0207
        sta     $0208
        lda     #$20
        sta     $0209
        lda     $C4
        jsr     LBB61
        stx     $020A
        sta     $020B
        jsr     listen_command_channel
        ldx     #$00
LBBA0:  lda     $0200,x
        jsr     IECOUT
        inx
        cpx     #$0C
        bne     LBBA0
        jmp     UNLSTN

LBBAE:  jsr     listen_command_channel
        ldx     #$00
LBBB3:  lda     s_bp,x
        jsr     IECOUT
        inx
        cpx     #s_bp_end - s_bp
        bne     LBBB3
        jmp     UNLSTN

s_u1:
        .byte   "U1:2 0 "
s_u1_end:
s_bp:
        .byte   "B-P 2 0"
s_bp_end:
        .byte   "#" ; ???

send_m_dash2:
        pha
        lda     #$6F
        jsr     init_and_listen
        lda     #'M'
        jsr     IECOUT
        lda     #'-'
        jsr     IECOUT
        pla
        jmp     IECOUT

iec_send_c1_c2_plus_y:
        tya
        clc
        adc     $C1
        php
        jsr     IECOUT
        plp
        lda     $C2
        adc     #$00
        jmp     IECOUT

LBBF4:  jmp     syntax_error

; ----------------------------------------------------------------
; "P" - set output to printer
; ----------------------------------------------------------------
cmd_p:
        lda     $0253 ; bank
        bmi     LBBF4 ; drive? syntax error
        ldx     #$FF
        lda     $BA ; device number
        cmp     #$04
        beq     LBC11 ; printer
        jsr     basin_cmp_cr
        beq     LBC16 ; no argument
        cmp     #','
        bne     LBBF4 ; syntax error
        jsr     get_hex_byte
        tax
LBC11:  jsr     basin_cmp_cr
        bne     LBBF4
LBC16:  sta     $0277; kbd buffer
        inc     $C6
        lda     #$04
        cmp     $BA
        beq     LBC39 ; printer
        stx     $B9
        sta     $BA ; set device 4
        sta     $B8
        ldx     #$00
        stx     $B7
        jsr     CLOSE
        jsr     OPEN
        ldx     $B8
        jsr     CKOUT
        jmp     input_loop2

LBC39:  lda     $B8
        jsr     CLOSE
        jsr     CLRCH
        lda     #$08
        sta     $BA
        lda     #$00
        sta     $C6
        jmp     input_loop

LBC4C:  stx     $C1
        sta     $C2
LBC50:  lda     #$31
        sta     $C3
        ldx     #$04
LBC56:  dec     $C3
LBC58:  lda     #$2F
        sta     $C4
        sec
        ldy     $C1
        .byte   $2C
LBC60:  sta     $C2
        sty     $C1
        inc     $C4
        tya
        sbc     LBC83,x
        tay
        lda     $C2
        sbc     LBC88,x
        bcs     LBC60
        lda     $C4
        cmp     $C3
        beq     LBC7D
        jsr     $E716 ; KERNAL: output character to screen
        dec     $C3
LBC7D:  dex
        beq     LBC56
        bpl     LBC58
        rts

LBC83:  ora     ($0A,x)
        .byte   $64
        inx
        .byte   $10
LBC88:  brk
        brk
        brk
        .byte   $03
        .byte   $27

init_and_listen:
        pha
        jsr     init_drive
        jsr     LISTEN
        pla
        jmp     SECOND

talk_cmd_channel:
        lda     #$6F
init_and_talk:
        pha
        jsr     init_drive
        jsr     TALK
        pla
        jmp     TKSA

cat_line_iec:
        jsr     IECIN
        jsr     $E716 ; KERNAL: output character to screen
        cmp     #$0D
        bne     cat_line_iec
        jmp     UNTALK

print_hex_byte:
        jsr     byte_to_hex_ascii
        jsr     BSOUT
        tya
        jmp     BSOUT

; convert byte into hex ASCII in A/Y
byte_to_hex_ascii:
        pha
        and     #$0F
        jsr     LBCC8
        tay
        pla
        lsr     a
        lsr     a
        lsr     a
        lsr     a
LBCC8:  clc
        adc     #$F6
        bcc     LBCCF
        adc     #$06
LBCCF:  adc     #$3A
        rts

directory:
        lda     #$60
        sta     $B9
        jsr     init_and_talk
        jsr     IECIN
        jsr     IECIN ; skip load address
LBCDF:  jsr     IECIN
        jsr     IECIN ; skip link word
        jsr     IECIN
        tax
        jsr     IECIN ; line number (=blocks)
        ldy     $90
        bne     LBD2F ; error
        jsr     LBC4C ; print A/X decimal
        lda     #' '
        jsr     $E716 ; KERNAL: output character to screen
        ldx     #$18
LBCFA:  jsr     IECIN
LBCFD:  ldy     $90
        bne     LBD2F ; error
        cmp     #$0D
        beq     LBD09 ; convert $0D to $1F
        cmp     #$8D
        bne     LBD0B ; also convert $8D to $1F
LBD09:  lda     #$1F ; ???BLUE
LBD0B:  jsr     $E716 ; KERNAL: output character to screen
        inc     $D8
        jsr     GETIN
        cmp     #$03
        beq     LBD2F ; STOP
        cmp     #' '
        bne     LBD20
LBD1B:  jsr     GETIN
        beq     LBD1B ; space pauses until the next key press
LBD20:  dex
        bpl     LBCFA
        jsr     IECIN
        bne     LBCFD
        lda     #$0D ; CR
        jsr     $E716 ; KERNAL: output character to screen
LBD2D:  bne     LBCDF ; next line
LBD2F:  jmp     $F646 ; CLOSE

init_drive:
        lda     #$00
        sta     $90 ; clear status
        lda     #$08
        cmp     $BA ; drive 8 and above ok
        bcc     LBD3F
LBD3C:  sta     $BA ; otherwise set drive 8
LBD3E:  rts

LBD3F:  lda     #$09
        cmp     $BA
        bcs     LBD3E
        lda     #$08
        .byte   $D0
LBD48:  .byte   $F3
        lda     $FF
LBD4B:  ldy     $90
        bne     LBD7D
        cmp     #$0D
        beq     LBD57
        cmp     #$8D
        bne     LBD59
LBD57:  lda     #$1F
LBD59:  jsr     $E716 ; KERNAL: output character to screen
        inc     $D8
        jsr     GETIN
        cmp     #$03
        beq     LBD7D
        cmp     #$20
        bne     LBD6E
LBD69:  jsr     GETIN
        beq     LBD69
LBD6E:  dex
        bpl     LBD48
        jsr     IECIN
        bne     LBD4B
        lda     #$0D ; CR
        jsr     $E716 ; KERNAL: output character to screen
        bne     LBD2D
LBD7D:  jmp     $F646 ; CLOSE

        lda     #$00
        sta     $90
        lda     #$08
        cmp     $BA
        bcc     LBD8D
LBD8A:  sta     $BA
LBD8C:  rts

LBD8D:  lda     #$09
        cmp     $BA
        bcs     LBD8C
        lda     #$08
        bne     LBD8A ; always

; ----------------------------------------------------------------
; end monitor
; ----------------------------------------------------------------

        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF

; ----------------------------------------------------------------
.segment "freezer"

; ----------------------------------------------------------------
; Freezer Entry
; ----------------------------------------------------------------
; In Ultimax mode, we have the following memory layout:
; $8000-$9FFF: bank 0 lo
; $E000-$FFFF: bank 0 hi

freezer: ; $FFA0
        sei
        pha
        lda     $00
        pha
        lda     #$2F
        sta     $00 ; default value of processor port DDR
        lda     $01
        ora     #$20 ; cassette motor off - but don't store
        pha
        lda     #$37
        sta     $01 ; processor port defaut value
        lda     #$13
        sta     $DFFF ; NMI = 1, GAME = 1, EXROM = 0
        lda     $DC0B ; CIA 1 TOD hours
        lda     $DD0B ; CIA 2 TOD hours (???)
        txa
        pha ; save X
        tya
        pha ; save Y
        lda     $02A1 ; RS-232 interrupt enabled
        pha
        ldx     #$0A
LBFC7:  lda     $02,x ; copy $02 - $0C onto stack
        pha
        dex
        bpl     LBFC7
        lda     $DD0E ; CIA 2 Timer A Control
        pha
        lda     $DD0F ; CIA 2 Timer B Control
        pha
        lda     #$00
        sta     $DD0E ; disable CIA 2 Timer A
        sta     $DD0F ; disable CIA 2 Timer B
        lda     #$7C
        sta     $DD0D ; disable some NMIs? (???)
        ldx     #$03
        jmp     LDFE0 ; ???

.segment "freezer_vectors"

; catch IRQ, NMI, RESET
        .word freezer ; NMI
        .word freezer ; RESET
        .word freezer ; IRQ

