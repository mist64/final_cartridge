; da65 V2.14 - Git d112322
; Created:    2015-01-06 18:50:57
; Input file: fc3b.bin
; Page:       1


        .setcpu "6502"

L0110           := $0110
L0150           := $0150
L0220           := $0220
L0228           := $0228
L0234           := $0234
L0564           := $0564
L800F           := $800F
L80CE           := $80CE
LC1C8           := $C1C8
LD227           := $D227
LDBA5           := $DBA5
LDE0F           := $DE0F
LDE14           := $DE14
LDE6C           := $DE6C
LDF95           := $DF95
LDFE0           := $DFE0
LE4E0           := $E4E0
LE50C           := $E50C
LE60A           := $E60A
LE716           := $E716
LE96C           := $E96C
LEA31           := $EA31
LED0C           := $ED0C
LEDB9           := $EDB9
LEDDD           := $EDDD
LEDEF           := $EDEF
LEDFE           := $EDFE
LEEF4           := $EEF4
LF11E           := $F11E
LF1CA           := $F1CA
LF250           := $F250
LF279           := $F279
LF30F           := $F30F
LF31F           := $F31F
LF418           := $F418
LF646           := $F646
LF654           := $F654
LF707           := $F707
LF82E           := $F82E
LF969           := $F969
LFB8E           := $FB8E
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

        .addr   L80CE
        .addr   LDE14
LA004:  jmp     LA10F

LA007:  jmp     LA138

        jmp     LA183

LA00D:  pha
        lda     $DC0C
        cmp     #$FE
        beq     LA035
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
        bne     LA0E5
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

LA10F:  lda     #$C0
        ldy     #$DF
        sta     $0320
        sty     $0321
        lda     #$C9
        ldy     #$DF
        sta     $0326
        sty     $0327
        lda     #$D5
        ldy     #$DF
        sta     $0322
        sty     $0323
        lda     #$CF
        ldy     #$DF
        sta     $032C
        sty     $032D
        rts

LA138:  lda     #$61
        ldy     #$A1
        sta     $0320
        sty     $0321
        lda     #$A2
        ldy     #$A1
        sta     $0326
        sty     $0327
        lda     #$D5
        ldy     #$A1
        sta     $0322
        sty     $0323
        lda     #$D1
        ldy     #$A1
        sta     $032C
        sty     $032D
        rts

        txa
        pha
        jsr     LF30F
        beq     LA173
LA168:  pla
        tax
        jmp     LF250

LA16D:  pla
        lda     #$04
        jmp     LF279

LA173:  jsr     LF31F
        lda     $BA
        cmp     #$04
        bne     LA168
        jsr     LA183
        bcs     LA16D
        pla
        rts

LA183:  jsr     LA09F
        lda     $DC0C
        cmp     #$FF
        beq     LA19B
        sei
        jsr     LA0C7
        bcs     LA19B
        lda     #$04
        sta     $9A
        jsr     LA1FC
        clc
LA19B:  rts

        jsr     LA1A2
        jmp     LDE0F

LA1A2:  pha
        lda     $9A
        cmp     #$04
        beq     LA1AD
LA1A9:  pla
        jmp     LF1CA

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

        jsr     LA1D1
        jmp     LDE0F

        jsr     LA1D5
        jmp     LDE0F

LA1D1:  lda     #$00
        sta     $98
LA1D5:  lda     #$04
        ldx     #$03
        cmp     $9A
        bne     LA1E7
        bit     $DD0C
        bpl     LA1E7
        jsr     LA09F
        beq     LA1EE
LA1E7:  cpx     $9A
        bcs     LA1EE
        jsr     LEDFE
LA1EE:  cpx     $99
        bcs     LA1F5
        jsr     LEDEF
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
        beq     LA317
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
        bne     LA41D
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
        bne     LA471
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

LA47B:  .byte   $80,$40,$20,$10,$08,$04,$02,$01
LA483:  lda     #$33
        sta     $01
LA487:  lda     ($FB),y
        and     $A4
        beq     LA494
        lda     $A5
        ora     LA47B,y
        sta     $A5
LA494:  dey
        bpl     LA487
        lda     #$37
        sta     $01
        rts

LA49C:  jsr     LA4CC
        lda     $DC0C
        cmp     #$FE
        beq     LA4D4
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
        lda     $0612
        tax
        lsr     a
        adc     #$03
        sta     $95
        sta     $31
        txa
        adc     #$06
        sta     $32
LA510:  jsr     L0564
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
        jmp     LF969

LA531:  jsr     LF11E
LA534:  ldy     #$00
        sty     $94
        lda     $80
        sta     ($94),y
        iny
        lda     $81
        sta     ($94),y
        iny
LA542:  jsr     L0564
        sta     ($30),y
        iny
        cpy     $0611
        bne     LA542
        jsr     L0150
        inc     $B6
        ldx     $0612
        lda     $81
        sta     $07,x
        lda     $80
        cmp     $06,x
        beq     LA510
        sta     $06,x
        jmp     LF418

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
        jsr     LDF95
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
        jmp     LC1C8

LA5F4:  ldx     $0613
        jmp     LE60A

LA5FA:  ldx     #$09
LA5FC:  lda     $0607,x
        sta     $014F,x
        dex
        bne     LA5FC
        jmp     L0150

        jsr     LDBA5
        jsr     LEEF4
        jmp     LD227

        brk
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
        jsr     LE716
        tya
        jmp     LE716

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

        jsr     LA6C1
        bne     LA647
        lda     #$07
        sta     $93
        lda     #$00
        ldy     #$A5
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

LA6A8:  lda     LA6B3,y
        beq     LA6A7
        jsr     LE716
        iny
        bne     LA6A8
LA6B3:  .byte   " FROM $"
        .byte   $00
        .byte   " TO $"
        .byte   $00
LA6C1:  jsr     LA61C
        jsr     IECIN
        tay
LA6C8:  jsr     IECIN
        cmp     #$0D
        bne     LA6C8
        jsr     UNTALK
        cpy     #$30
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

        ldy     #$00
        sty     $90
        lda     $BA
        jsr     LED0C
        lda     $B9
        ora     #$F0
        jsr     LEDB9
        lda     $90
        bpl     LA734
        pla
        pla
        jmp     LF707

LA734:  jsr     LDE6C
        jsr     LEDDD
        iny
        cpy     $B7
        bne     LA734
        jmp     LF654

LA742:  jsr     LF82E
        beq     LA764
        ldy     #$1B
LA749:  jsr     LA7B3
LA74C:  bit     $DC01
        bpl     LA766
        jsr     LF82E
        bne     LA74C
        ldy     #$6A
        jmp     LA7B3

LA75B:  jsr     LF82E
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
        jsr     LE716
        iny
        cpy     #$15
        bne     LA773
        rts

LA77E:  jsr     LA7B1
        bmi     LA796
        rts

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
LA79C:  jsr     LDE6C
        jsr     LE716
        iny
        cpy     $B7
        bne     LA79C
LA7A7:  rts

LA7A8:  ldy     #$49
        lda     $93
        beq     LA7B3
        ldy     #$59
        .byte   $2C
LA7B1:  ldy     #$51
LA7B3:  bit     $9D
        bpl     LA7C4
LA7B7:  lda     $F0BD,y
        php
        and     #$7F
        jsr     LE716
        iny
        plp
        bpl     LA7B7
LA7C4:  clc
        rts

        ldx     #$0E
LA7C8:  lda     $9A41,x
        sta     L0110,x
        dex
        bpl     LA7C8
        ldx     #$05
        stx     $AB
        jsr     LFB8E
        jsr     LA75B
        bcc     LA7E2
        lda     #$00
        jmp     LDE0F

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
LA808:  jsr     LDE6C
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
        ldx     #$03
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
        jmp     LDE0F

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
        jsr     LE4E0
        sei
        lda     $01
        and     #$1F
        sta     $01
        ldy     $B7
        beq     LA88C
LA880:  dey
        jsr     LDE6C
        cmp     $0341,y
        bne     LA851
        tya
        bne     LA880
LA88C:  sty     $90
        jsr     LA7A8
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
        jmp     LDE0F

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
        jmp     LDE0F

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

        sei
        rts

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
        lda     #$3D
        sta     $0316
        lda     #$02
        sta     $0317
        lda     #$43
        sta     $0251
        lda     #$37
        sta     $0253
        lda     #$70
        sta     $0257
        ldx     #$22
LAB1B:  lda     LAB25,x
        sta     L0220,x
        dex
        bpl     LAB1B
        brk
LAB25:  sta     $DFFF
        pla
        sta     $01
        lda     ($C1),y
        pha
        lda     #$37
        sta     $01
        lda     #$40
        sta     $DFFF
        pla
        rts

        jsr     LDE0F
        sta     $01
        lda     $024B
        rti

        jsr     L0228
        jmp     LAB48

LAB48:  cld
        pla
        sta     $024D
        pla
        sta     $024C
        pla
        sta     $024B
        pla
        sta     $024A
        pla
        sta     $0249
        pla
        sta     $0248
        tsx
        stx     $024E
        jsr     LB6B3
        jsr     LA007
        jsr     LB4B7
        lda     $0251
        cmp     #$43
        bne     LAB76
        .byte   $2C
LAB76:  lda     #$42
        ldx     #$2A
        jsr     LB4A1
        clc
        lda     $0249
        adc     #$FF
        sta     $0249
        lda     $0248
        adc     #$FF
        sta     $0248
        lda     $BA
        and     #$FB
        sta     $BA
        lda     #$42
        sta     $0251
        lda     #$80
        sta     $028A
        bne     LABA5
LABA0:  jsr     LB4D5
        bne     LAC06
LABA5:  ldx     #$00
LABA7:  lda     LBA15,x
        beq     LABB2
        jsr     BSOUT
        inx
        bne     LABA7
LABB2:  ldx     #$3B
        jsr     LB49F
        lda     $0248
        jsr     LB559
        lda     $0249
        jsr     LB559
        jsr     LB4B4
        lda     $0250
        jsr     LB559
        lda     $024F
        jsr     LB559
        jsr     LB4B4
        lda     $0253
        bpl     LABE6
        lda     #$44
        jsr     BSOUT
        lda     #$52
        jsr     BSOUT
        bne     LABEB
LABE6:  and     #$0F
        jsr     LB559
LABEB:  ldy     #$00
LABED:  jsr     LB4B4
        lda     $024B,y
        jsr     LB559
        iny
        cpy     #$04
        bne     LABED
        jsr     LB4B4
        lda     $024A
        jsr     LB563
        beq     LAC0E
LAC06:  lda     #$3F
        .byte   $2C
LAC09:  lda     #$0D
        jsr     BSOUT
LAC0E:  ldx     $024E
        txs
        lda     #$00
        sta     $0254
        jsr     LB49A
LAC1A:  jsr     LB4C2
        cmp     #$2E
        beq     LAC1A
        cmp     #$20
        beq     LAC1A
        ldx     #$1A
LAC27:  cmp     LBA3B,x
        bne     LAC3B
        stx     $0252
        txa
        asl     a
        tax
        lda     LBA56+1,x
        pha
        lda     LBA56,x
        pha
        rts

LAC3B:  dex
        bpl     LAC27
        bmi     LAC06
LAC40:  jsr     BASIN
        cmp     #$43
        beq     LAC66
        cmp     #$53
        beq     LAC66
        jmp     LAC06

LAC4E:  lda     #$91
        ldx     #$0D
        jsr     LB4A1
        lda     #$1D
        ldx     #$00
LAC59:  sta     $0277,x
        inx
        cpx     #$07
        bne     LAC59
        stx     $C6
        jmp     LAC1A

LAC66:  sta     $0252
LAC69:  jsr     LB4F1
        jsr     LB4D5
        bne     LAC80
        jsr     LB644
        jmp     LAC86

LAC77:  jmp     LAEAC

LAC7A:  jsr     LB4F1
        jsr     LB4C2
LAC80:  jsr     LB625
        jsr     LB4FD
LAC86:  lda     $0252
        beq     LACAE
        cmp     #$17
        beq     LACAE
        cmp     #$01
        beq     LACDB
        cmp     #$06
        beq     LACE4
        cmp     #$07
        beq     LAC77
        cmp     #$43
        beq     LACAE
        cmp     #$53
        beq     LACAE
        jmp     LAE88

LACA6:  jsr     LB64D
        bcs     LACAE
LACAB:  jmp     LAC4E

LACAE:  jsr     LB4B7
        lda     $0252
        beq     LACC4
        cmp     #$53
        beq     LACD0
        cmp     #$43
        beq     LACCA
        jsr     LAD39
        jmp     LACA6

LACC4:  jsr     LAD28
        jmp     LACA6

LACCA:  jsr     LAD0F
        jmp     LACA6

LACD0:  jsr     LACF0
        jmp     LACA6

LACD6:  jsr     LB64D
        bcc     LACAB
LACDB:  jsr     LB4B7
        jsr     LAD49
        jmp     LACD6

LACE4:  jsr     LB4C2
        jsr     LB508
        jsr     LB22E
        jmp     LAC09

LACF0:  ldx     #$5D
        jsr     LB49F
        jsr     LB552
        jsr     LB4B4
        ldy     #$00
LACFD:  jsr     LB2E9
        jsr     LB563
        iny
        cpy     #$03
        bne     LACFD
        jsr     LB6A8
        tya
        jmp     LB8CA

LAD0F:  ldx     #$5B
        jsr     LB49F
        jsr     LB552
        jsr     LB4B4
        ldy     #$00
        jsr     LB2E9
        jsr     LB563
        jsr     LB6A8
        jmp     LB575

LAD28:  ldx     #$3A
        jsr     LB49F
        jsr     LB552
        jsr     LB57E
        jsr     LB4B4
        jmp     LB590

LAD39:  ldx     #$27
        jsr     LB49F
        jsr     LB552
        jsr     LB4B4
        ldx     #$20
        jmp     LB592

LAD49:  ldx     #$2C
LAD4B:  jsr     LB49F
        jsr     LAD5A
        jsr     LB6A8
        lda     $0205
        jmp     LB028

LAD5A:  jsr     LB552
        jsr     LB4B4
        jsr     LAF62
        jsr     LAF40
        jsr     LAFAF
        jmp     LAFD7

LAD6C:  jsr     LB4F1
        jsr     LB644
        jsr     LB4BC
        jsr     LB4DB
        ldy     #$00
        jsr     LB2F7
        jsr     LB497
        jsr     LAD0F
        jsr     LB49A
        jsr     LB677
        jmp     LAC1A

LAD8C:  jsr     LB4F1
        jsr     LB644
        jsr     LB4BC
        jsr     LB4DB
        ldy     #$00
        beq     LAD9F
LAD9C:  jsr     LB4E0
LAD9F:  jsr     LB2F7
        iny
        cpy     #$03
        bne     LAD9C
        jsr     LB497
        jsr     LACF0
        jsr     LB49A
        jsr     LB67A
        jmp     LAC1A

LADB6:  jsr     LB4F1
        jsr     LB5BE
        jsr     LB497
        jsr     LAD39
        jsr     LB49A
        jsr     LB67D
        jmp     LAC1A

LADCB:  jsr     LB4F1
        jsr     LB5E5
        jsr     LB497
        jsr     LAD28
        jsr     LB49A
        jsr     LB671
        jmp     LAC1A

LADE0:  jsr     LB4F1
        lda     $C4
        sta     $0248
        lda     $C3
        sta     $0249
        jsr     LB4C2
        jsr     LB4FD
        lda     $C3
        sta     $024F
        lda     $C4
        sta     $0250
        jsr     LB4C2
        jsr     LB4C2
        cmp     #$44
        bne     LAE12
        jsr     LB4C2
        cmp     #$52
        bne     LAE3D
        ora     #$80
        bmi     LAE1B
LAE12:  jsr     LB510
        cmp     #$08
        bcs     LAE3D
        ora     #$30
LAE1B:  sta     $0253
        ldx     #$00
LAE20:  jsr     LB4C2
        jsr     LB508
        sta     $024B,x
        inx
        cpx     #$04
        bne     LAE20
        jsr     LB4C2
        jsr     LB4E0
        sta     $024A
        jsr     LB497
        jmp     LABB2

LAE3D:  jmp     LAC06

LAE40:  jsr     LB4FD
        ldx     #$03
        jsr     LB5E7
        lda     #$2C
        jsr     LAE7C
        jsr     LB66E
        jmp     LAC1A

LAE53:  jsr     LB4F1
        jsr     LB030
        jsr     LB05C
        ldx     #$00
        stx     $0206
LAE61:  ldx     $024E
        txs
        jsr     LB08D
        jsr     LB0AB
        jsr     LB625
        jsr     LB0EF
        lda     #$41
        jsr     LAE7C
        jsr     LB674
        jmp     LAC1A

LAE7C:  pha
        jsr     LB497
        pla
        tax
        jsr     LAD4B
        jmp     LB49A

LAE88:  jsr     LB655
        bcs     LAE90
        jmp     LAC06

LAE90:  sty     $020A
        jsr     LB4C2
        jsr     LB4FD
        lda     $0252
        cmp     #$08
        beq     LAEA6
        jsr     LB1CB
        jmp     LAC09

LAEA6:  jsr     LB245
        jmp     LAC0E

LAEAC:  jsr     LB4C2
        ldx     #$00
        stx     $020B
        jsr     LB4C2
        cmp     #$22
        bne     LAECF
LAEBB:  jsr     LB4D5
        beq     LAEE7
        cmp     #$22
        beq     LAEE7
        sta     $0200,x
        inx
        cpx     #$20
        bne     LAEBB
        jmp     LAC06

LAECF:  jsr     LB510
        bcs     LAEDC
LAED4:  jsr     LB4D5
        beq     LAEE7
        jsr     LB508
LAEDC:  sta     $0200,x
        inx
        cpx     #$20
        bne     LAED4
LAEE4:  jmp     LAC06

LAEE7:  stx     $0252
        txa
        beq     LAEE4
        jsr     LB293
        jmp     LAC0E

LAEF3:  jsr     LB4D5
        beq     LAF03
        jsr     LB4F4
        jsr     LB4D5
        beq     LAF06
        jmp     LAC06

LAF03:  jsr     LB63A
LAF06:  lda     $0253
        bmi     LAF2B
        jsr     LB6B3
        jsr     LA004
        ldx     $024E
        txs
        lda     $C4
        pha
        lda     $C3
        pha
        lda     $024A
        pha
        ldx     $024C
        ldy     $024D
        lda     $0253
        jmp     L0234

LAF2B:  lda     #$45
        jsr     LBBD0
        lda     $C3
        jsr     IECOUT
        lda     $C4
        jsr     IECOUT
        jsr     UNLSTN
        jmp     LAC09

LAF40:  pha
        ldy     #$00
LAF43:  cpy     $0205
        beq     LAF52
        bcc     LAF52
        jsr     LB4B4
        jsr     LB4B4
        bcc     LAF58
LAF52:  jsr     LB2E9
        jsr     LB559
LAF58:  jsr     LB4B4
        iny
        cpy     #$03
        bne     LAF43
        pla
        rts

LAF62:  ldy     #$00
        jsr     LB2E9
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
        lda     LB937,x
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
        lda     LB97B,x
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
        lda     LB995,y
        sta     $020A
        lda     LB9D5,y
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
        jmp     LB4B4

LAFD7:  ldx     #$06
LAFD9:  cpx     #$03
        bne     LAFF4
        ldy     $0205
        beq     LAFF4
LAFE2:  lda     $0207
        cmp     #$E8
        php
        jsr     LB2E9
        plp
        bcs     LB00B
        jsr     LB559
        dey
        bne     LAFE2
LAFF4:  asl     $0207
        bcc     LB007
        lda     LB988,x
        jsr     BSOUT
        lda     LB98E,x
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
        jsr     LB559
        txa
        jmp     LB559

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
LB035:  jsr     LB4C2
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
        jsr     LB513
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
        lda     LB9D5,x
        jsr     LB130
        lda     LB995,x
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
        lda     LB988,x
        jsr     LB130
        lda     LB98E,x
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
LB11D:  jsr     LB2F7
        dey
        bne     LB11A
LB123:  lda     $0206
        jsr     LB2F7
        rts

LB12A:  jmp     LAC0E

LB12D:  jsr     LB130
LB130:  stx     $0203
        ldx     $0204
        cmp     $0210,x
        beq     LB146
LB13B:  inc     $0206
        beq     LB143
        jmp     LAE61

LB143:  jmp     LAC0E

LB146:  inx
        stx     $0204
        ldx     $0203
        rts

LB14E:  jsr     LB4F1
        jsr     LB4A8
        jsr     LB644
        jsr     LB54A
        jsr     LB48E
        jsr     LB4B1
        jsr     LBC50
        jmp     LAC0E

LB166:  ldy     #$00
        sty     $C1
        sty     $C2
        jsr     LB4BC
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
LB19B:  jsr     LB4A8
        jsr     LB4B1
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
        jsr     LB54A
        jmp     LAC0E

LB1B9:  jsr     LB6B3
        jsr     LA004
        lda     #$00
        sta     $028A
        ldx     $024E
        txs
        jmp     LDE14

LB1CB:  lda     $C3
        cmp     $C1
        lda     $C4
        sbc     $C2
        bcs     LB1FC
        ldy     #$00
        ldx     #$00
LB1D9:  jsr     LB2E9
        pha
        jsr     LB625
        pla
        jsr     LB2F7
        jsr     LB625
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
LB20E:  jsr     LB2E9
        pha
        jsr     LB625
        pla
        jsr     LB2F7
        jsr     LB625
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
LB230:  jsr     LB2F7
        ldx     $C1
        cpx     $C3
        bne     LB23F
        ldx     $C2
        cpx     $C4
        beq     LB244
LB23F:  jsr     LB575
        bne     LB230
LB244:  rts

LB245:  jsr     LB4B7
        clc
        lda     $C1
        adc     $0209
        sta     $0209
        lda     $C2
        adc     $020A
        sta     $020A
        ldy     #$00
LB25B:  jsr     LB2E9
        sta     $0252
        jsr     LB625
        jsr     LB2E9
        pha
        jsr     LB625
        pla
        cmp     $0252
        beq     LB274
        jsr     LB54D
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
LB28D:  jsr     LB575
        bne     LB25B
LB292:  rts

LB293:  jsr     LB4B7
LB296:  jsr     LB655
        bcc     LB2B3
        ldy     #$00
LB29D:  jsr     LB2E9
        cmp     $0200,y
        bne     LB2AE
        iny
        cpy     $0252
        bne     LB29D
        jsr     LB54D
LB2AE:  jsr     LB575
        bne     LB296
LB2B3:  rts

LB2B4:  lda     #$52
        jsr     LBBD0
        jsr     LBBE4
        jsr     UNLSTN
        jsr     LBC98
        jsr     IECIN
        pha
        jsr     UNTALK
        pla
        rts

LB2CB:  lda     #$57
        jsr     LBBD0
        jsr     LBBE4
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

LB2E9:  sei
        lda     $0253
        bmi     LB2B4
        clc
        pha
        lda     $0257
        jmp     L0220

LB2F7:  sei
        pha
        lda     $0253
        bmi     LB2CB
        cmp     #$35
        bcs     LB306
        lda     #$33
        sta     $01
LB306:  pla
        sta     ($C1),y
        pha
        lda     #$37
        sta     $01
        pla
        rts

LB310:  jsr     LB4D5
        beq     LB326
        cmp     #$20
        beq     LB310
        cmp     #$30
        bcc     LB32E
        cmp     #$34
        bcs     LB32E
        and     #$03
        ora     #$40
        .byte   $2C
LB326:  lda     #$70
        sta     $0257
        jmp     LAC09

LB32E:  jmp     LAC06

LB331:  jsr     LB4D5
        beq     LB33F
        cmp     #$20
        beq     LB331
        cmp     #$44
        beq     LB34A
        .byte   $2C
LB33F:  lda     #$37
        cmp     #$38
        bcs     LB32E
        cmp     #$30
        bcc     LB32E
        .byte   $2C
LB34A:  lda     #$80
        sta     $0253
        jmp     LAC09

LB352:  lda     #$6F
        jsr     LBC8D
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

LB371:  ldy     #$02
        sty     $BC
        dey
        sty     $B9
        dey
        sty     $B7
        lda     #$08
        sta     $BA
        lda     #$10
        sta     $BB
        jsr     LB4CB
        bne     LB3B6
LB388:  lda     $0252
        cmp     #$0B
        bne     LB3CC
LB38F:  jsr     LB35C
        jsr     LB6B3
        ldx     $C1
        ldy     $C2
        jsr     LB42D
        php
        jsr     LA007
        jsr     LB6B3
        plp
LB3A4:  bcc     LB3B3
LB3A6:  ldx     #$00
LB3A8:  lda     $F0BD,x
        jsr     BSOUT
        inx
        cpx     #$0A
        bne     LB3A8
LB3B3:  jmp     LAC0E

LB3B6:  cmp     #$22
        bne     LB3CC
LB3BA:  jsr     LB4D5
        beq     LB388
        cmp     #$22
        beq     LB3CF
        sta     ($BB),y
        inc     $B7
        iny
        cpy     #$10
        bne     LB3BA
LB3CC:  jmp     LAC06

LB3CF:  jsr     LB4D5
        beq     LB388
        cmp     #$2C
LB3D6:  bne     LB3CC
        jsr     LB508
        and     #$0F
        beq     LB3CC
        cmp     #$01
        beq     LB3E7
        cmp     #$04
        bcc     LB3CC
LB3E7:  sta     $BA
        jsr     LB4D5
        beq     LB388
        cmp     #$2C
LB3F0:  bne     LB3D6
        jsr     LB4FD
        jsr     LB625
        jsr     LB4D5
        bne     LB408
        lda     $0252
        cmp     #$0B
        bne     LB3F0
        dec     $B9
        beq     LB38F
LB408:  cmp     #$2C
LB40A:  bne     LB3F0
        jsr     LB4FD
        jsr     LB4CB
        bne     LB40A
        ldx     $C3
        ldy     $C4
        lda     $0252
        cmp     #$0C
        bne     LB40A
        dec     $B9
        jsr     LB35C
        jsr     LB438
        jsr     LA007
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

LB443:  jsr     LB352
        jsr     LB4D5
        beq     LB466
        cmp     #$24
        beq     LB475
        cmp     #$46
        bne     LB458
        jsr     L800F
        lda     #$46
LB458:  jsr     IECOUT
        jsr     LB4D5
        bne     LB458
        jsr     UNLSTN
        jmp     LAC09

LB466:  jsr     LB4B7
        jsr     UNLSTN
        jsr     LBC98
        jsr     LBCA5
        jmp     LAC0E

LB475:  jsr     UNLSTN
        jsr     LB4B7
        lda     #$F0
        jsr     LBC8D
        lda     #$24
        jsr     IECOUT
        jsr     UNLSTN
        jsr     LBCD2
        jmp     LAC0E

LB48E:  jsr     LB4B4
        lda     #$3D
        ldx     #$20
        bne     LB4A1
LB497:  ldx     #$91
        .byte   $2C
LB49A:  ldx     #$2E
        lda     #$0D
        .byte   $2C
LB49F:  lda     #$2E
LB4A1:  jsr     BSOUT
        txa
        jmp     BSOUT

LB4A8:  jsr     LB497
        lda     #$2E
        bit     $1DA9
        .byte   $2C
LB4B1:  lda     #$23
        .byte   $2C
LB4B4:  lda     #$20
        .byte   $2C
LB4B7:  lda     #$0D
        jmp     BSOUT

LB4BC:  jsr     LB4CB
        jmp     LB4C5

LB4C2:  jsr     LB4D5
LB4C5:  bne     LB4CA
        jmp     LAC0E

LB4CA:  rts

LB4CB:  jsr     BASIN
        cmp     #$20
        beq     LB4CB
        cmp     #$0D
        rts

LB4D5:  jsr     BASIN
        cmp     #$0D
        rts

LB4DB:  pha
        ldx     #$08
        bne     LB4E6
LB4E0:  ldx     #$08
LB4E2:  pha
        jsr     LB4C2
LB4E6:  cmp     #$2A
        beq     LB4EB
        clc
LB4EB:  pla
        rol     a
        dex
        bne     LB4E2
        rts

LB4F1:  jsr     LB4C2
LB4F4:  cmp     #$20
        beq     LB4F1
        jsr     LB510
        bcs     LB500
LB4FD:  jsr     LB508
LB500:  sta     $C4
        jsr     LB508
        sta     $C3
        rts

LB508:  lda     #$00
        sta     $0256
        jsr     LB4C2
LB510:  jsr     LB536
LB513:  jsr     LB528
        asl     a
        asl     a
        asl     a
        asl     a
        sta     $0256
        jsr     LB533
        jsr     LB528
        ora     $0256
        sec
        rts

LB528:  cmp     #$3A
        and     #$0F
        bcc     LB530
        adc     #$08
LB530:  rts

        clc
        rts

LB533:  jsr     LB4C2
LB536:  cmp     #$30
        bcc     LB547
        cmp     #$40
        bcc     LB546
        cmp     #$41
        bcc     LB547
        cmp     #$47
        bcs     LB547
LB546:  rts

LB547:  jmp     LAC06

LB54A:  lda     #$24
        .byte   $2C
LB54D:  lda     #$20
        jsr     BSOUT
LB552:  lda     $C2
        jsr     LB559
        lda     $C1
LB559:  sty     $0255
        jsr     LBCB2
        ldy     $0255
        rts

LB563:  ldx     #$08
LB565:  rol     a
        pha
        lda     #$2A
        bcs     LB56D
        lda     #$2E
LB56D:  jsr     BSOUT
        pla
        dex
        bne     LB565
        rts

LB575:  clc
        inc     $C1
        bne     LB57D
        inc     $C2
        sec
LB57D:  rts

LB57E:  ldx     #$08
        ldy     #$00
LB582:  jsr     LB4B4
        jsr     LB2E9
        jsr     LB559
        iny
        dex
        bne     LB582
        rts

LB590:  ldx     #$08
LB592:  ldy     #$00
LB594:  jsr     LB2E9
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
        tya
        jmp     LB8CA

LB5BE:  ldx     #$20
        ldy     #$00
        jsr     LB644
        jsr     LB4C2
LB5C8:  sty     $0209
        ldy     $D3
        lda     ($D1),y
        php
        jsr     LB4C2
        ldy     $0209
        plp
        bmi     LB5E0
        cmp     #$60
        bcs     LB5E0
        jsr     LB2F7
LB5E0:  iny
        dex
        bne     LB5C8
        rts

LB5E5:  ldx     #$08
LB5E7:  ldy     #$00
        jsr     LB644
        jsr     LB4BC
        jsr     LB510
        jmp     LB607

LB5F5:  jsr     LB60F
        jsr     LB60F
        bne     LB604
        jsr     LB60F
        bne     LB619
        beq     LB60A
LB604:  jsr     LB510
LB607:  jsr     LB2F7
LB60A:  iny
        dex
        bne     LB5F5
        rts

LB60F:  jsr     LB4D5
        bne     LB616
        pla
        pla
LB616:  cmp     #$20
        rts

LB619:  jmp     LAC06

LB61C:  cmp     #$30
        bcc     LB623
        cmp     #$47
        rts

LB623:  sec
        rts

LB625:  lda     $C4
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

LB63A:  lda     $0248
        sta     $C4
        lda     $0249
        sta     $C3
LB644:  lda     $C3
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
        sta     $0209
        tya
        sbc     $C2
        tay
        ora     $0209
        rts

LB66C:  clc
        rts

LB66E:  lda     #$2C
        .byte   $2C
LB671:  lda     #$3A
        .byte   $2C
LB674:  lda     #$41
        .byte   $2C
LB677:  lda     #$5B
        .byte   $2C
LB67A:  lda     #$5D
        .byte   $2C
LB67D:  lda     #$27
        sta     $0277
        lda     $C2
        jsr     LBCBC
        sta     $0278
        sty     $0279
        lda     $C1
        jsr     LBCBC
        sta     $027A
        sty     $027B
        lda     #$20
        sta     $027C
        lda     #$06
        sta     $C6
        rts

LB6A2:  lda     #$1D
        ldx     #$07
        bne     LB6AC
LB6A8:  lda     #$20
        ldx     #$08
LB6AC:  jsr     BSOUT
        dex
        bne     LB6AC
        rts

LB6B3:  lda     $0314
        cmp     #$E2
        bne     LB6C1
        lda     $0315
        cmp     #$B6
        beq     LB6D3
LB6C1:  lda     $0314
        ldx     $0315
        sta     $024F
        stx     $0250
        lda     #$E2
        ldx     #$B6
        bne     LB6D9
LB6D3:  lda     $024F
        ldx     $0250
LB6D9:  sei
        sta     $0314
        stx     $0315
        cli
        rts

        lda     #$B6
        pha
        lda     #$F1
        pha
        lda     #$00
        pha
        pha
        pha
        pha
        jmp     LEA31

        lda     $0254
        bne     LB6FA
        lda     $C6
        bne     LB700
LB6FA:  pla
        tay
        pla
        tax
        pla
        rti

LB700:  lda     $0277
        cmp     #$88
        bne     LB71C
        lda     #$40
        sta     $0277
        lda     #$24
        sta     $0278
        lda     #$0D
        sta     $0279
        lda     #$03
        sta     $C6
        bne     LB6FA
LB71C:  cmp     #$87
        bne     LB733
        ldx     #$18
        cpx     $D6
        beq     LB72E
        jsr     LB8D9
        ldy     $D3
        jsr     LE50C
LB72E:  lda     #$11
        sta     $0277
LB733:  cmp     #$86
        bne     LB74A
        ldx     #$00
        cpx     $D6
        beq     LB745
        jsr     LB8D9
        ldy     $D3
        jsr     LE50C
LB745:  lda     #$91
        sta     $0277
LB74A:  cmp     #$11
        beq     LB758
        cmp     #$91
        bne     LB6FA
        lda     $D6
        beq     LB75E
        bne     LB6FA
LB758:  lda     $D6
        cmp     #$18
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
        jsr     LB4B7
        jsr     LAD28
        jmp     LB7C7

LB790:  jsr     LAF62
        lda     $0205
        jsr     LB028
        jsr     LB4B7
        jsr     LAD49
        jmp     LB7C7

LB7A2:  jsr     LB575
        jsr     LB4B7
        jsr     LAD0F
        jmp     LB7C7

LB7AE:  lda     #$03
        jsr     LB8CA
        jsr     LB4B7
        jsr     LACF0
        jmp     LB7C7

LB7BC:  lda     #$20
        jsr     LB8CA
        jsr     LB4B7
        jsr     LAD39
LB7C7:  lda     #$91
        ldx     #$0D
        bne     LB7D1
LB7CD:  lda     #$0D
        ldx     #$13
LB7D1:  ldy     #$00
        sty     $C6
        sty     $0254
        jsr     LB4A1
        jsr     LB6A2
        jmp     LB6FA

LB7E1:  jsr     LB8FE
        lda     $020C
        cmp     #$2C
        beq     LB800
        cmp     #$5B
        beq     LB817
        cmp     #$5D
        beq     LB822
        cmp     #$27
        beq     LB82D
        jsr     LB8EC
        jsr     LAD28
        jmp     LB7CD

LB800:  jsr     LB625
        jsr     LB90E
        inc     $0205
        lda     $0205
        eor     #$FF
        jsr     LB028
        jsr     LAD49
        clc
        bcc     LB7CD
LB817:  lda     #$01
        jsr     LB8EE
        jsr     LAD0F
        jmp     LB7CD

LB822:  lda     #$03
        jsr     LB8EE
        jsr     LACF0
        jmp     LB7CD

LB82D:  lda     #$20
        jsr     LB8EE
        jsr     LAD39
        jmp     LB7CD

LB838:  lda     $D1
        ldx     $D2
        sta     $C3
        stx     $C4
        lda     #$19
        sta     $020D
LB845:  ldy     #$01
        jsr     LB88B
        cmp     #$3A
        beq     LB884
        cmp     #$2C
        beq     LB884
        cmp     #$5B
        beq     LB884
        cmp     #$5D
        beq     LB884
        cmp     #$27
        beq     LB884
        dec     $020D
        beq     LB889
        lda     $0277
        cmp     #$11
        bne     LB877
        sec
        lda     $C3
        sbc     #$28
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
        jsr     LB528
        asl     a
        asl     a
        asl     a
        asl     a
        sta     $020B
        jsr     LB88B
        jsr     LB528
        ora     $020B
        rts

LB8C8:  lda     #$08
LB8CA:  clc
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
        beq     LB8EB
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
        jsr     LE96C
        lda     #$94
        sta     $D9
        sta     $DA
        lda     #$13
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

LB937:  .byte   $40,$02,$45,$03,$D0,$08,$40,$09
        .byte   $30,$22,$45,$33,$D0,$08,$40,$09
        .byte   $40,$02,$45,$33,$D0,$08,$40,$09
        .byte   $40,$02,$45,$B3,$D0,$08,$40,$09
        .byte   $00,$22,$44,$33,$D0,$8C,$44,$00
        .byte   $11,$22,$44,$33,$D0,$8C,$44,$9A
        .byte   $10,$22,$44,$33,$D0,$08,$40,$09
        .byte   $10,$22,$44,$33,$D0,$08,$40,$09
        .byte   $62,$13,$78,$A9
LB97B:  .byte   $00,$21,$81,$82,$00,$00,$59,$4D
        .byte   $91,$92,$86,$4A,$85
LB988:  .byte   $9D,$2C,$29,$2C,$23,$28
LB98E:  .byte   $24,$59,$00,$58,$24,$24,$00
LB995:  .byte   $1C,$8A,$1C,$23,$5D,$8B,$1B,$A1
        .byte   $9D,$8A,$1D,$23,$9D,$8B,$1D,$A1
        .byte   $00,$29,$19,$AE,$69,$A8,$19,$23
        .byte   $24,$53,$1B,$23,$24,$53,$19,$A1
        .byte   $00,$1A,$5B,$5B,$A5,$69,$24,$24
        .byte   $AE,$AE,$A8,$AD,$29,$00,$7C,$00
        .byte   $15,$9C,$6D,$9C,$A5,$69,$29,$53
        .byte   $84,$13,$34,$11,$A5,$69,$23,$A0
LB9D5:  .byte   $D8,$62,$5A,$48,$26,$62,$94,$88
        .byte   $54,$44,$C8,$54,$68,$44,$E8,$94
        .byte   $00,$B4,$08,$84,$74,$B4,$28,$6E
        .byte   $74,$F4,$CC,$4A,$72,$F2,$A4,$8A
        .byte   $00,$AA,$A2,$A2,$74,$74,$74,$72
        .byte   $44,$68,$B2,$32,$B2,$00,$22,$00
        .byte   $1A,$1A,$26,$26,$72,$72,$88,$C8
        .byte   $C4,$CA,$26,$48,$44,$44,$A2,$C8
LBA15:  .byte   $0D
        .byte   "   PC  IRQ  BK AC XR YR SP NV#B"



        .byte   "DIZC"
        .byte   $0D,$00
LBA3B:  .byte   "MD:AGXFHCTRLS,O@$#*PE[]I';B"



LBA56:  .word   LAC69-1
        .word   LAC69-1
        .word   LADCB-1
        .word   LAE53-1
        .word   LAEF3-1
        .word   LB1B9-1
        .word   LAC7A-1
        .word   LAC7A-1
        .word   LAC7A-1
        .word   LAC7A-1
        .word   LABA0-1
        .word   LB371-1
        .word   LB371-1
        .word   LAE40-1
        .word   LB331-1
        .word   LB443-1
        .word   LB14E-1
        .word   LB166-1
        .word   LBA8F-1
        .word   LBBF7-1
        .word   LAC40-1
        .word   LAD6C-1
        .word   LAD8C-1
        .word   LAC69-1
        .word   LADB6-1
        .word   LADE0-1
        .word   LB310-1
LBA8C:  jmp     LAC06

LBA8F:  jsr     LB352
        jsr     UNLSTN
        jsr     BASIN
        cmp     #$57
        beq     LBAA0
        cmp     #$52
        bne     LBA8C
LBAA0:  sta     $C3
        jsr     LB4BC
        jsr     LB510
        bcc     LBA8C
        sta     $C1
        jsr     LB4C2
        jsr     LB508
        bcc     LBA8C
        sta     $C2
        jsr     LB4D5
        bne     LBAC1
        lda     #$CF
        sta     $C4
        bne     LBACD
LBAC1:  jsr     LB508
        bcc     LBA8C
        sta     $C4
        jsr     LB4D5
        bne     LBA8C
LBACD:  jsr     LBB48
        jsr     LB625
        lda     $C1
        cmp     #$57
        beq     LBB25
        lda     #$31
        jsr     LBB6E
        jsr     LBC98
        jsr     IECIN
        cmp     #$30
        beq     LBB00
        pha
        jsr     LB4B7
        pla
LBAED:  jsr     LE716
        jsr     IECIN
        cmp     #$0D
        bne     LBAED
        jsr     UNTALK
        jsr     LBB5C
        jmp     LAC0E

LBB00:  jsr     IECIN
        cmp     #$0D
        bne     LBB00
        jsr     UNTALK
        jsr     LBBAE
        ldx     #$02
        jsr     CHKIN
        ldy     #$00
        sty     $C1
LBB16:  jsr     IECIN
        jsr     LB2F7
        iny
        bne     LBB16
        jsr     CLRCH
        jmp     LBB42

LBB25:  jsr     LBBAE
        ldx     #$02
        jsr     CKOUT
        ldy     #$00
        sty     $C1
LBB31:  jsr     LB2E9
        jsr     IECOUT
        iny
        bne     LBB31
        jsr     CLRCH
        lda     #$32
        jsr     LBB6E
LBB42:  jsr     LBB5C
        jmp     LB466

LBB48:  lda     #$02
        tay
        ldx     $BA
        jsr     SETLFS
        lda     #$01
        ldx     #$CF
        ldy     #$BB
        jsr     SETNAM
        jmp     OPEN

LBB5C:  lda     #$02
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
LBB71:  lda     LBBC1,x
        sta     $0200,x
        inx
        cpx     #$07
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
        jsr     LB352
        ldx     #$00
LBBA0:  lda     $0200,x
        jsr     IECOUT
        inx
        cpx     #$0C
        bne     LBBA0
        jmp     UNLSTN

LBBAE:  jsr     LB352
        ldx     #$00
LBBB3:  lda     LBBC8,x
        jsr     IECOUT
        inx
        cpx     #$07
        bne     LBBB3
        jmp     UNLSTN

LBBC1:  .byte   "U1:2 0 "
LBBC8:  .byte   "B-P 2 0#"
LBBD0:  pha
        lda     #$6F
        jsr     LBC8D
        lda     #$4D
        jsr     IECOUT
        lda     #$2D
        jsr     IECOUT
        pla
        jmp     IECOUT

LBBE4:  tya
        clc
        adc     $C1
        php
        jsr     IECOUT
        plp
        lda     $C2
        adc     #$00
        jmp     IECOUT

LBBF4:  jmp     LAC06

LBBF7:  lda     $0253
        bmi     LBBF4
        ldx     #$FF
        lda     $BA
        cmp     #$04
        beq     LBC11
        jsr     LB4D5
        beq     LBC16
        cmp     #$2C
        bne     LBBF4
        jsr     LB508
        tax
LBC11:  jsr     LB4D5
        bne     LBBF4
LBC16:  sta     $0277
        inc     $C6
        lda     #$04
        cmp     $BA
        beq     LBC39
        stx     $B9
        sta     $BA
        sta     $B8
        ldx     #$00
        stx     $B7
        jsr     CLOSE
        jsr     OPEN
        ldx     $B8
        jsr     CKOUT
        jmp     LAC1A

LBC39:  lda     $B8
        jsr     CLOSE
        jsr     CLRCH
        lda     #$08
        sta     $BA
        lda     #$00
        sta     $C6
        jmp     LAC0E

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
        jsr     LE716
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
LBC8D:  pha
        jsr     LBD32
        jsr     LISTEN
        pla
        jmp     SECOND

LBC98:  lda     #$6F
LBC9A:  pha
        jsr     LBD32
        jsr     TALK
        pla
        jmp     TKSA

LBCA5:  jsr     IECIN
        jsr     LE716
        cmp     #$0D
        bne     LBCA5
        jmp     UNTALK

LBCB2:  jsr     LBCBC
        jsr     BSOUT
        tya
        jmp     BSOUT

LBCBC:  pha
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

LBCD2:  lda     #$60
        sta     $B9
        jsr     LBC9A
        jsr     IECIN
        jsr     IECIN
LBCDF:  jsr     IECIN
        jsr     IECIN
        jsr     IECIN
        tax
        jsr     IECIN
        ldy     $90
        bne     LBD2F
        jsr     LBC4C
        lda     #$20
        jsr     LE716
        ldx     #$18
LBCFA:  jsr     IECIN
LBCFD:  ldy     $90
        bne     LBD2F
        cmp     #$0D
        beq     LBD09
        cmp     #$8D
        bne     LBD0B
LBD09:  lda     #$1F
LBD0B:  jsr     LE716
        inc     $D8
        jsr     GETIN
        cmp     #$03
        beq     LBD2F
        cmp     #$20
        bne     LBD20
LBD1B:  jsr     GETIN
        beq     LBD1B
LBD20:  dex
        bpl     LBCFA
        jsr     IECIN
        bne     LBCFD
        lda     #$0D
        jsr     LE716
LBD2D:  bne     LBCDF
LBD2F:  jmp     LF646

LBD32:  lda     #$00
        sta     $90
        lda     #$08
        cmp     $BA
        bcc     LBD3F
LBD3C:  sta     $BA
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
LBD59:  jsr     LE716
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
        lda     #$0D
        jsr     LE716
        bne     LBD2D
LBD7D:  jmp     LF646

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
        bne     LBD8A
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

