; ----------------------------------------------------------------
; Screen Editor Additions
; ----------------------------------------------------------------
; This adds the following features to the KERNAL screen editor:
; * CTRL + HOME: put cursor at bottom left
; * CTRL + DEL: delete to end of line
; * CTRL + CR: print screen
; * F-key shortcuts with SpeedDOS layout (LIST/RUN/DLOAD/DOS"$")
; * auto-scrolling of BASIC programs: when the screen scrolls
;   either direction, a new BASIC line is LISTed

.include "kernal.i"
.include "persistent.i"

.import list_line
.import store_d1_spaces
.import print_dec
.import send_printer_listen
.import set_io_vectors
.import set_io_vectors_with_hidden_rom

CR              := $0D

.segment "screen_editor"

.global kbd_handler
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

L926A:  cmp     #CR ; CTRL + CR: print screen
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
        sbc     #$85 ; KEY_F1
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
        bne     L927F ; always

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
        jsr     print_dec
        jsr     list_line
L9460:  lda     #$00
        sta     $D4
        sta     $D8
        sta     $C7
        rts

L9469:  jsr     store_d1_spaces
        bcs     L9460
L946E:  lda     #$03
        sta     $9A
        rts

.global print_screen
print_screen:
        lda     #7 ; secondary address
        jsr     send_printer_listen
        bcs     L946E
        jsr     set_io_vectors
        ldy     #$00
        sty     $AC
        lda     $0288 ; video RAM address hi
        sta     $AD
        ldx     #25 ; lines
L9488:  lda     #CR
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
        cpy     #40 ; columns
        bne     L948F
        tya
        clc
        adc     $AC
        sta     $AC
        bcc     L94B3
        inc     $AD
L94B3:  dex
        bne     L9488
        lda     #CR
        jsr     BSOUT
        jsr     CLRCH
        jmp     set_io_vectors_with_hidden_rom

fkey_strings:
        .byte   $8D, "LIST:", CR, 0
        .byte   $8D, "RUN:", CR, 0
        .byte   "DLOAD", CR, 0
        .byte   $8D, $93, "DOS",'"', "$",CR, 0
        .byte   $8D, "M", 'O' + $80, ":", CR, 0
        .byte   $8D, "OLD:", CR, 0
        .byte   "DSAVE", '"', 0
        .byte   "DOS", '"', 0

