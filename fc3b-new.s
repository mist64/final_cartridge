; da65 V2.14 - Git d112322
; Created:    2014-12-28 14:46:58
; Input file: fc3b.bin
; Page:       1


        .setcpu "6502"

; ----------------------------------------------------------------
; RAM locations
; ----------------------------------------------------------------
L0110           := $0110
L0220           := $0220

; ----------------------------------------------------------------
; Bank 0 (LO) Symbols
; ----------------------------------------------------------------
fast_format     := $800F
go_basic        := $80CE
L9A41           := $9A41

; ----------------------------------------------------------------
; I/O Extension ROM Symbols
; ----------------------------------------------------------------
_disable_rom    := $DE0F
_basic_warm_start := $DE14
_load_bb_indy   := $DE6C
_new_ckout      := $DFC0
_new_bsout      := $DFC9
_new_clall      := $DFCF
_new_clrch      := $DFD5
LDFE0           := $DFE0

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

.segment        "fc3b": absolute

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

LA1C8: ; XXX unused?? should this be "new_clrch"?
        jsr     new_clrch2
new_clrch: ; $A1CB
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
LA500:
        lda     $0612
        tax
        lsr     a
        adc     #$03
        sta     $95
        sta     $31
        txa
        adc     #$06
        sta     $32
LA510:  jsr     $0564 ; XXX LA564
        beq     LA522
        sta     $81
        tax
        inx
        stx     $0611
        lda     #$00
        sta     $80
        beq     LA534
LA522:  lda     $02FC
        bne     LA531
        lda     $02FA
        bne     LA531
        lda     #$72
        jmp     $F969

LA531:  jsr     $F11E ; drive ROM
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
        cpy     $0611
        bne     LA542
        jsr     $0150
        inc     $B6
        ldx     $0612
        lda     $81
        sta     $07,x
        lda     $80
        cmp     $06,x
        beq     LA510
        sta     $06,x
        jmp     $F418 ; drive ROM

LA564:
        lda     #$00
        sta     $1800
        lda     #$04
LA56B:  bit     $1800
        bne     LA56B
        sta     $C0
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
        sta     a:$C0
        lda     $1800
        asl     a
        nop
        nop
        ora     $1800
        and     #$0F
        ora     $C0
        sta     $C0
        lda     #$02
        sta     $1800
        lda     $C0
        rts

        nop
        lda     #$EA
        sta     $0572
        sta     $0573
        ldx     #$11
LA5A6:  lda     $0589,x
        sta     $058A,x
        dex
        bpl     LA5A6
        ldx     #$64
LA5B1:  lda     $F574,x
        sta     $014F,x
        dex
        bne     LA5B1
        lda     #$60
        sta     $01B4
        inx
        stx     $82
        stx     $83
        jsr     $DF95 ; drive ROM
        inx
        stx     $1800
LA5CB:  inx
        bne     LA5CB
        sta     $0613
        asl     a
        sta     $0612
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
        jmp     $C1C8 ; drive ROM

LA5F4:  ldx     $0613
        jmp     $E60A

LA5FA:  ldx     #$09
LA5FC:  lda     $0607,x
        sta     $014F,x
        dex
        bne     LA5FC
        jmp     $0150

        jsr     $DBA5
        jsr     $EEF4
        jmp     $D227

        brk

; ----------------------------------------------------------------
; C64 IEC code
; ----------------------------------------------------------------
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

; ??? unreached?
        jsr     LA6C1
        bne     LA647
        lda     #$07
        sta     $93
        lda     #<LA500
        ldy     #>LA500
        ldx     #$05
        jsr     LA6D5
        lda     $0330
        cmp     #$20
        beq     LA66A
        lda     #$9C
        jsr     IECOUT
        lda     #$05
        bne     LA671
LA66A:  lda     #$AF
        jsr     IECOUT
        lda     #$05
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

        ldy     #$00
        bit     $08A0
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

LA6D5:  sta     $C3
        sty     $C4
        ldy     #$00
LA6DB:  lda     #$57
        jsr     LA707
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
        lda     #$45
LA707:  pha
        lda     #$6F
        jsr     LA612
        lda     #$4D
        jsr     IECOUT
        lda     #$2D
        jsr     IECOUT
        pla
        jmp     IECOUT

; ??? unreferenced?
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

; ??? unreferenced?
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
        ldx     #$02
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

; ??? unreferenced?
        .byte   "EN"
        .byte   $C4
        .byte   "FO"
        .byte   $D2
        .byte   "NEX"
        .byte   $D4
        .byte   "DAT"
        .byte   $C1
        .byte   "INPUT"
        .byte   $A3
        .byte   "INPU"
        .byte   $D4
        .byte   "DI"
        .byte   $CD
        .byte   "REA"
        .byte   $C4
        .byte   "LE"
        .byte   $D4
        .byte   "GOT"
        .byte   $CF
        .byte   "RU"
        .byte   $CE
        .byte   "I"
        .byte   $C6
        .byte   "RESTOR"
        .byte   $C5
        .byte   "GOSU"
        .byte   $C2
        .byte   "RETUR"
        .byte   $CE
        .byte   "RE"
        .byte   $CD
        .byte   "STO"
        .byte   $D0
        .byte   "O"
        .byte   $CE
        .byte   "WAI"
        .byte   $D4
        .byte   "LOA"
        .byte   $C4
        .byte   "SAV"
        .byte   $C5
        .byte   "VERIF"
        .byte   $D9
        .byte   "DE"
        .byte   $C6
        .byte   "POK"
        .byte   $C5
        .byte   "PRINT"
        .byte   $A3
        .byte   "PRIN"
        .byte   $D4
        .byte   "CON"
        .byte   $D4
        .byte   "LIS"
        .byte   $D4
        .byte   "CL"
        .byte   $D2
        .byte   "CM"
        .byte   $C4
        .byte   "SY"
        .byte   $D3
        .byte   "OPE"
        .byte   $CE
        .byte   "CLOS"
        .byte   $C5
        .byte   "GE"
        .byte   $D4
        .byte   "NE"
        .byte   $D7
        .byte   "TAB"
        .byte   $A8
        .byte   "T"
        .byte   $CF
        .byte   "F"
        .byte   $CE
        .byte   "SPC"
        .byte   $A8
        .byte   "THE"
        .byte   $CE
        .byte   "NO"
        .byte   $D4
        .byte   "STE"
        .byte   $D0,$AB,$AD,$AA,$AF,$DE
        .byte   "AN"
        .byte   $C4
        .byte   "O"
        .byte   $D2,$BE,$BD,$BC
        .byte   "SG"
        .byte   $CE
        .byte   "IN"
        .byte   $D4
        .byte   "AB"
        .byte   $D3
        .byte   "US"
        .byte   $D2
        .byte   "FR"
        .byte   $C5
        .byte   "PO"
        .byte   $D3
        .byte   "SQ"
        .byte   $D2
        .byte   "RN"
        .byte   $C4
        .byte   "LO"
        .byte   $C7
        .byte   "EX"
        .byte   $D0
        .byte   "CO"
        .byte   $D3
        .byte   "SI"
        .byte   $CE
        .byte   "TA"
        .byte   $CE
        .byte   "AT"
        .byte   $CE
        .byte   "PEE"
        .byte   $CB
        .byte   "LE"
        .byte   $CE
        .byte   "STR"
        .byte   $A4
        .byte   "VA"
        .byte   $CC
        .byte   "AS"
        .byte   $C3
        .byte   "CHR"
        .byte   $A4
        .byte   "LEFT"
        .byte   $A4
        .byte   "RIGHT"
        .byte   $A4
        .byte   "MID"
        .byte   $A4
        .byte   "G"
        .byte   $CF,$00

; ----------------------------------------------------------------
; Monitor (~4750 bytes)
; ----------------------------------------------------------------
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

LB42D:  lda     #$DE
        pha
        lda     #$04
        pha
        lda     #$00
        jmp     LOAD

LB438:  lda     #$DE
        pha
        lda     #$04
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

; ??? unreferenced?
; $BFA0
        sei
        pha
        lda     $00
        pha
        lda     #$2F
        sta     $00
        lda     $01
        ora     #$20
        pha
        lda     #$37
        sta     $01
        lda     #$13
        sta     $DFFF
        lda     $DC0B
        lda     $DD0B
        txa
        pha
        tya
        pha
        lda     $02A1
        pha
        ldx     #$0A
LBFC7:  lda     $02,x
        pha
        dex
        bpl     LBFC7
        lda     $DD0E
        pha
        lda     $DD0F
        pha
        lda     #$00
        sta     $DD0E
        sta     $DD0F
        lda     #$7C
        sta     $DD0D
        ldx     #$03
        jmp     LDFE0

        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$A0,$FF,$A0,$FF,$A0
        .byte   $FF

; End of "fc3b" segment
.code

