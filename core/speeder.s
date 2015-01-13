; ----------------------------------------------------------------
; Disk and Tape Speeder
; ----------------------------------------------------------------
; This speeds up LOAD and SAVE on both disk and tape

.include "kernal.i"
.include "persistent.i"

.global new_load
.global new_save

L0110           := $0110

.segment "speeder_a"

new_load:
	jmp new_load2
new_save:
	jmp new_save2

send_byte:
        pha
 :      bit     $DD00
        bpl     :-
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        tax
:       lda     $D012
        cmp     #$31
        bcc     :+
        and     #$06
        cmp     #$02
        beq     :-
:       lda     #$07
        sta     $DD00
        lda     iec_tab,x
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
        lda     iec_tab,x
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
.assert >* = >send_byte, error, "Page boundary!"

iec_tab:
        .byte   $07,$87,$27,$A7,$47,$C7,$67,$E7
        .byte   $17,$97,$37,$B7,$57,$D7,$77,$F7
.assert >* = >iec_tab, error, "Page boundary!"

receive_4_bytes:
       lda     $0330
        cmp     #<_new_load
        beq     L998B
:       bit     $DD00
        bvs     :-
        ldy     #3
        nop
        ldx     $01
:       lda     $DD00
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
        bpl     :-
.assert >* = >:-, error, "Page boundary!"
        rts

L998B:  bit     $DD00
        bvs     L998B
        ldy     #3
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
.assert >* = >L998B, error, "Page boundary!"

; *** tape
L99B5:  tax
        beq     L99C3
        ldx     #$16
:       lda     L9A50,x
        sta     L0110,x
        dex
        bpl     :-
L99C3:  jmp     LA851
; *** tape

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
        ldy     DEV
        cpy     #7
        beq     L99B5 ; tape turbo
        cpy     #8
        bcc     L99C9
        cpy     #10
        bcs     L99C9
        tay
        lda     $B7
        beq     L99C9
        jsr     _load_FILENAME_indy
        cmp     #$24
        beq     L99C9
        ldx     SECADDR
        cpx     #2
        beq     L99C9
        jsr     print_searching
        lda     #$60
        sta     SECADDR
        jsr     LA71B
        lda     DEV
        jsr     $ED09 ; TALK
        lda     SECADDR
        jsr     $EDC7 ; SECTLK
        jsr     $EE13 ; IECIN
        sta     $AE
        lda     ST
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
        cmp     #4
        bcc     L99D6
        jmp     L9AF0

; ----------------------------------------------------------------

.segment "tape_stack_code"

; will be placed at $0100
load_ac_indy:
        lda     #$0C
        sta     $01
        lda     ($AC),y
        ldy     #$0F
        sty     $01
        ldy     #0
        jmp     LA9BB
load_ac_indy_end:

L9A50:  lda     #$0C
        sta     $01
        lda     ($C3),y
        cmp     $BD
        beq     :+
        stx     ST
:       eor     $D7
        sta     $D7
        lda     #$0F
        sta     $01
        jmp     LA8FF

.segment "speeder_b"

L9A67:  jmp     $F636 ; LDA #0 : SEC : RTS

L9A6A:  jmp     $F5ED ; default SAVE vector

L9A6D:  jmp     $A7C6 ; interpreter loop

new_save2:
        lda     DEV
        cmp     #7
        beq     L9A6D ; tape turbo
        cmp     #8
        bcc     L9A6A ; not a drive
        cmp     #10
        bcs     L9A6A ; not a drive (XXX why only support drives 8 and 9?)
        ldy     $B7
        beq     L9A6A
        lda     #$61
        sta     SECADDR
        jsr     LA71B
        jsr     LA77E
        jsr     LA648
        bne     L9A67
        stx     ST
        stx     $A4
        jsr     $FB8E ; copy I/O start address to buffer address
        sec
        lda     $AC
        sbc     #2
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

L9AC7:  jsr     send_byte
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
L9AED:  jmp     send_byte

L9AF0:  jsr     UNTALK
        jsr     LA691
        lda     #6
        sta     $93
.import __drive_code_load_LOAD__
.import __drive_code_load_RUN__
        lda     #<__drive_code_load_LOAD__
        ldy     #>__drive_code_load_LOAD__
        ldx     #>__drive_code_load_RUN__ ; $0400
        jsr     transfer_code_to_drive
        lda     #<L059A
        jsr     IECOUT
        lda     #>L059A
        jsr     IECOUT
        jsr     UNLSTN
        sei
        lda     $D011
        tax
        and     #$10 ; save screen enable bit
        sta     $95
        txa
        and     #$EF
        sta     $D011
        lda     $DD00
        and     #$07
        ora     $95 ; save VIC bank (XXX #$03 would have been enough)
        sta     $95
        lda     $C1
        sta     $A4
        lda     $C2
        sta     SECADDR
        sec
        lda     $AE
        sbc     #2
        sta     ST
        lda     $AF
        sbc     #0
        sta     $A3
L9B3D:  bit     $DD00
        bmi     L9B82
        cli
        php
        lda     $95
        and     #$07
        sta     $DD00 ; restore VIC bank
        lda     $95
        and     #$10
        ora     $D011 ; restore screen enable bit
        sta     $D011
        lda     $A4
        sta     $C1
        lda     SECADDR
        sta     $C2
        lda     #0
        sta     $A3
        sta     $94
        sta     ST
        lda     #$60
        sta     SECADDR
        lda     #$E0
        jsr     LA612
        jsr     UNLSTN
        plp
        bvs     L9B78 ; used to be "bcs" in 1988-05
        lda     #$1D
        sec
        rts

L9B78:  lda     #$40
        sta     ST
        jsr     LA694
        jmp     $F5A9 ; LOAD done

L9B82:  bvs     L9B3D
        lda     #$20
        sta     $DD00
:       bit     $DD00
        bvc     :-
        lda     #0
        sta     $DD00
        jsr     receive_4_bytes
        lda     #$FE
        sta     $A5
        lda     $C3
        clc
        adc     $A3
        tax
        asl     $C3
        php
        sec
        lda     ST
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
        adc     #0
        sta     $AF
L9BC8:  ldy     #0
        lda     $C3
        bne     L9BD7
        jsr     receive_4_bytes
        ldy     #2
        ldx     #2
        bne     L9BE5
L9BD7:  lda     $C1
        sta     ($93),y
        iny
L9BDC:  tya
        pha
        jsr     receive_4_bytes
        pla
        tay
        ldx     #3
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

.segment "drive_code_load" ; $0400

drive_code_load:
        lda     $43
        sta     $C1
L9BFE:  jsr     L0582
L9C01:  bvc     L9C01
        clv
        lda     $1C01
        sta     $25,y
        iny
        cpy     #7
        bne     L9C01
        jsr     $F556
L9C12:  bvc     L9C12
        clv
        lda     $1C01
        sta     ($30),y
        iny
        cpy     #5
        bne     L9C12
        jsr     $F497
        ldx     #5
        lda     #0
L9C26:  eor     $15,x
        dex
        bne     L9C26
        tay
        beq     L9C31
L9C2E:  jmp     $F40B

L9C31:  inx
L9C32:  lda     $12,x
        cmp     $16,x
        bne     L9C2E
        dex
        bpl     L9C32
        jsr     $F7E8
        ldx     $19
        cpx     $43
        bcs     L9C2E
        lda     $53
        sta     L060F,x
        lda     $54
        sta     L05FA,x
        lda     #$FF
        sta     L0624,x
        dec     $C1
        bne     L9BFE
        lda     #1
        sta     $C3
        ldx     $09
L9C5D:  lda     $C2
        sta     L0624,x
        inc     $C2
        lda     L060F,x
        cmp     $08
        bne     L9C75
        lda     L05FA,x
        tax
        inc     $C3
        bne     L9C5D
        beq     L9C2E
L9C75:  cmp     #$24
        bcs     L9C2E
        sta     $08
        lda     L05FA,x
        sta     $09
L9C80:  jsr     L0582
        iny
L9C84:  bvc     L9C84
        clv
        lda     $1C01
        sta     ($30),y
        iny
        cpy     #4
        bne     L9C84
        ldy     #0
        jsr     $F7E8
        ldx     $54
        cpx     $43
        bcs     L9C2E
        lda     L0624,x
        cmp     #$FF
        beq     L9C80
        stx     $C0
        jsr     $F556
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
        sta     $0100,y
        iny
        bne     L9CB5
        jsr     $F7E8
        lda     $53
        beq     L9CCC
        lda     #0
        sta     $54
L9CCC:  sta     $34
        sta     $C1
        ldx     $C0
        lda     $0624,x
        sta     $53
        lda     #$FF
        sta     L0624,x
        jsr     $F6D0
        lda     #$42
        sta     $36
        ldy     #$08
        sty     $1800
L9CE8:  lda     $1800
        lsr     a
        bcc     L9CE8
        ldy     #0
L04F6:
        dec     $36
        sty     $1800
        bne     L9CFE
        dec     $C3
        bne     L9C80
        jmp     $F418

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
L0564:
        iny
        sty     $C1
        ldy     #$08
        sty     $1800
        ldx     $55,y
:       lda     L05CA - 8,x ; ???
        sta     $1800
        lda     L05DA,x
        ldx     $54,y
        sta     $1800
        dey
        bne     :-
        jmp     L04F6

L0582:
        ldx     #3
        stx     $31
L9D80:  inx
        bne     L9D86
        jmp     $F40B

L9D86:  jsr     $F556
L9D89:  bvc     L9D89
        clv
        lda     $1C01
        cmp     $24
        bne     L9D80
        rts

L059A:
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
        cmp     #2
        bcs     L9DBB
        lda     $08
        bne     L9DA3
        lda     #$02
        sta     $1800
        jmp     $C194

L9DBB:  inx
        ldy     #$0A
        sty     $1800
        jmp     $E60A

L05CA:
        .byte   0, 10, 10, 2
        .byte   0, 10, 10, 2
        .byte   0, 0, 8, 0
        .byte   0, 0, 8, 0
L05DA:
        .byte   0, 2, 8, 0
        .byte   0, 2, 8, 0
        .byte   0, 8, 10, 10, 0, 0, 2, 2
        .byte   0, 0, 10, 10, 0, 0, 2, 2
        .byte   0, 8, 8, 8
        .byte   0, 0, 0, 0
L05FA:
L060F := L05FA + 21
L0624 := L060F + 21

; ----------------------------------------------------------------
; drive code $0500
; ----------------------------------------------------------------
.segment "drive_code_save"

ram_code := $0150

drive_code_save:
        lda     L0612
        tax
        lsr     a
        adc     #3
        sta     $95
        sta     $31
        txa
        adc     #6
        sta     $32
LA510:  jsr     receive_byte
        beq     :+
        sta     $81
        tax
        inx
        stx     L0611
        lda     #0
        sta     $80
        beq     LA534

:       lda     $02FC
        bne     :+
        lda     $02FA ; XXX ORing the values together is shorter
        bne     :+
        lda     #$72
        jmp     $F969 ; DISK FULL

:       jsr     $F11E ; find and allocate free block
LA534:  ldy     #0
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
        cpy     L0611
        bne     LA542
        jsr     ram_code
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
drive_code_save_timing_selfmod1:
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
        sta     drive_code_save_timing_selfmod1
        sta     drive_code_save_timing_selfmod1 + 1 ; insert 1 cycle into code
        ldx     #L0589_end - L0589 - 1
LA5A6:  lda     L0589,x
        sta     L058A,x ; insert 3 cycles into code
        dex
        bpl     LA5A6
L05AF:
        ldx     #$64
LA5B1:  lda     $F575 - 1,x; copy "write data block to disk" to RAM
        sta     ram_code - 1,x
        dex
        bne     LA5B1
        lda     #$60
        sta     ram_code + $64 ; add RTS at the end, just after GCR decoding
        inx
        stx     $82
        stx     $83
        jsr     $DF95
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
        cmp     #2
        bcc     LA5DB
        cmp     #$72
        bne     LA5F4
        jmp     $C1C8 ; set error message

LA5F4:  ldx     L0612 + 1
        jmp     $E60A

LA5FA:  ldx     #L0608_end - L0608
LA5FC:  lda     L0608 - 1,x
        sta     ram_code - 1,x
        dex
        bne     LA5FC
        jmp     ram_code

L0608:
        jsr     $DBA5 ; write directory entry
        jsr     $EEF4 ; write BAM
        jmp     $D227 ; close channel
L0608_end:

L0611:
        .byte   0
L0612:


; ----------------------------------------------------------------
; C64 IEC code
; ----------------------------------------------------------------
.segment "speeder_c"

LA612:  pha
        lda     DEV
        jsr     LISTEN
        pla
        jmp     SECOND

LA61C:  lda     #$6F
        pha
        lda     DEV
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
        lda     #7
        sta     $93
.import __drive_code_save_LOAD__
.import __drive_code_save_RUN__
        lda     #<__drive_code_save_LOAD__
        ldy     #>__drive_code_save_LOAD__
        ldx     #>__drive_code_save_RUN__
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
        ldy     #0
        .byte   $2C
LA694:
        ldy     #8
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
        cmp     #CR
        bne     LA6C8 ; read until CR
        jsr     UNTALK
        cpy     #'0' ; = no error
        rts

transfer_code_to_drive:
        sta     $C3
        sty     $C4
        ldy     #0
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
        ldy     #0
        sty     ST
        lda     DEV
        jsr     $ED0C ; LISTEN
        lda     SECADDR
        ora     #$F0
        jsr     $EDB9 ; SECLST
        lda     ST
        bpl     LA734
        pla
        pla
        jmp     $F707 ; DEVICE NOT PRESENT ERROR

LA734:  jsr     _load_FILENAME_indy
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

print_found:
        lda     $9D
        bpl     LA7A7
        ldy     #$63 ; "FOUND"
        jsr     print_kernal_string
        ldy     #5
LA773:  lda     ($B2),y
        jsr     $E716 ; KERNAL: output character to screen
        iny
        cpy     #$15
        bne     LA773
        rts

LA77E:  jsr     LA7B1
        bmi     LA796
        rts

print_searching:
        lda     $9D
        bpl     LA7A7
        ldy     #$0C ; "SEARCHING"
        jsr     print_kernal_string
        lda     $B7
        beq     LA7A7
        ldy     #$17 ; "FOR"
        jsr     print_kernal_string
LA796:  ldy     $B7
        beq     LA7A7
        ldy     #0
LA79C:  jsr     _load_FILENAME_indy
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
print_kernal_string:
        lda     $F0BD,y ; KERNAL strings
        php
        and     #$7F
        jsr     $E716 ; KERNAL: output character to screen
        iny
        plp
        bpl     print_kernal_string ; until MSB set
LA7C4:  clc
        rts

; ----------------------------------------------------------------
; tape related

.segment "tape"

; ??? unused?
        ldx     #load_ac_indy_end - load_ac_indy - 1
:       lda     load_ac_indy,x
        sta     L0110,x
        dex
        bpl     :-
        ldx     #5
        stx     $AB
        jsr     $FB8E ; copy I/O start address to buffer address
        jsr     LA75B
        bcc     :+
        lda     #0
        jmp     _disable_rom
:       jsr     LA77E
        jsr     turn_screen_off
        jsr     LA999
        lda     SECADDR
        clc
        adc     #1
        dex
        jsr     LA9BB
        ldx     #8
:       lda     $AC,y
        jsr     LA9BB
        ldx     #6
        iny
        cpy     #5
        nop
        bne     :-
        ldy     #0
        ldx     #2
LA808:  jsr     _load_FILENAME_indy
        cpy     $B7
        bcc     :+
        lda     #$20
        dex
:       jsr     LA9BB
        ldx     #3
        iny
        cpy     #$BB
        bne     LA808
        lda     #2
        sta     $AB
        jsr     LA999
        tya
        jsr     LA9BB
        sty     $D7
        ldx     #5
LA82B:  jsr     L0110
        ldx     #3 ; used to be "#2" in 1988-05
        inc     $AC
        bne     :+
        inc     $AD
        dex
:       lda     $AC
        cmp     $AE
        lda     $AD
        sbc     $AF
        bcc     LA82B
LA841:  lda     $D7
        jsr     LA9BB
        ldx     #7
        dey
        bne     LA841
        jsr     LA912
        jmp     _disable_rom

LA851:  jsr     LA8C9
        lda     $AB
        cmp     #2
        beq     LA862
        cmp     #1
        bne     LA851
        lda     SECADDR
        beq     LA86C ; "LOAD"[...]",n,0" -> skip load address
LA862:  lda     $033C
        sta     $C3
        lda     $033D
        sta     $C4
LA86C:  jsr     print_found
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
        jsr     _load_FILENAME_indy
        cmp     $0341,y
        bne     LA851
        tya
        bne     LA880
LA88C:  sty     ST
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
        ora     ST
        clc
        beq     LA8C2
        sec
        lda     #$FF
        sta     ST
LA8C2:  ldx     $AE
        ldy     $AF
        jmp     _disable_rom

LA8C9:  jsr     LA92B
        lda     $BD
        cmp     #0 ; XXX not needed
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
        lda     #0
        sta     $02A0
        lda     $D011
        ora     #$10
        sta     $D011 ; turn screen on
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
        lda     #0
        jmp     _disable_rom

LA939:  jsr     turn_screen_off
        sty     $D7
        lda     #$07
        sta     $DD06
        ldx     #1
LA945:  jsr     LA97E
        rol     $BD
        lda     $BD
        cmp     #2
        beq     LA954
        cmp     #$F2
        bne     LA945
LA954:  ldy     #9
LA956:  jsr     LA96E
        lda     $BD
        cmp     #2
        beq     LA956
        cmp     #$F2
        beq     LA956
LA963:  cpy     $BD
        bne     LA945
        jsr     LA96E
        dey
        bne     LA963
        rts

LA96E:  lda     #8
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

        lda     #4
        sta     $AB
LA999:  ldy     #0
LA99B:  lda     #2
        jsr     LA9BB
        ldx     #7
        dey
        cpy     #9
        bne     LA99B
        ldx     #5
        dec     $AB
        bne     LA99B
LA9AD:  tya
        jsr     LA9BB
        ldx     #7
        dey
        bne     LA9AD
        dex
        dex
        sty     $D7
        rts

LA9BB:  sta     $BD
        eor     $D7
        sta     $D7
        lda     #8
        sta     $A3
LA9C5:  asl     $BD
        lda     $01
        and     #$F7
        jsr     LA9DD
        ldx     #$11
        nop
        ora     #8
        jsr     LA9DD
        ldx     #14
        dec     $A3
        bne     LA9C5
        rts

LA9DD:  dex
        bne     LA9DD
        bcc     LA9E7
        ldx     #11
LA9E4:  dex
        bne     LA9E4
LA9E7:  sta     $01
        rts

turn_screen_off:
        ldy     #0
        sty     $C0
        lda     $D011
        and     #$EF
        sta     $D011 ; turn screen off
LA9F6:  dex
        bne     LA9F6 ; delay (XXX waiting for $D012 == 0 would be cleaner)
        dey
        bne     LA9F6
        sei
        rts

; XXX junk
        sei
        rts
