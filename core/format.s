; ----------------------------------------------------------------
; Fast Format
; ----------------------------------------------------------------

.include "kernal.i"

; from drive
.import check_iec_error
.import cmd_channel_listen
.import listen_second
.import m_w_and_m_e

.global fast_format
.global init_read_disk_name
.global init_write_bam
.global unlisten_e2

.segment "fast_format"

.import __fast_format_drive_LOAD__
.import __fast_format_drive_RUN__

fast_format:
        lda     #5
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
        lda     #0
        rts

init_write_bam:
        ldy     #drive_cmd_u2 - drive_cmds
        jsr     send_drive_cmd ; send "U2:2 0 18 0", block write of BAM
unlisten_e2:
        lda     #$E2
        jsr     listen_second
        jsr     UNLSTN
        lda     #1
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

ram_code := $0630

; this lives at $0400
fast_format_drive_code:
        jmp     L0463

fast_format_drive_code_entry:
        jsr     $C1E5
        bne     L9768
        jmp     $C1F3

L9768:  sty     $027A
        lda     #$A0
        jsr     $C268
        jsr     $C100
        ldy     $027B
        cpy     $0274
        bne     L977E
        jmp     $EE46

L977E:  lda     $0200,y
        sta     $12
        lda     $0201,y
        sta     $13
        ldx     #$78
L978A:  lda     $FC36 - 1,x
        sta     ram_code - 1,x ; copy drive kernal code to RAM
        dex
        bne     L978A
        lda     #$60 ; add RTS at the end
        sta     ram_code + $78
        lda     #1
        sta     $80
        sta     $51
        jsr     $D6D3
        lda     $22
        bne     L97AA
        lda     #$C0
        jsr     L045C
L97AA:  lda     #$E0
        jsr     L045C
        cmp     #2
        bcc     L97B6
        jmp     $C8E8

L97B6:  jmp     $EE40

L045C:
        sta     $01
L97BB:  lda     $01
        bmi     L97BB
        rts

L0463:
        lda     $51
        cmp     ($32),y
        beq     L97CB
        sta     ($32),y
        jmp     $F99C

L97CB:  ldx     #4
L97CD:  cmp     $FED7,x
        beq     L97D7
        dex
        bcs     L97CD
        bcc     L9838
L97D7:  jsr     $FE0E
        lda     #$FF
        sta     $1C01
L97DF:  bvc     L97DF
        clv
        inx
        cpx     #5
        bcc     L97DF
        jsr     $FE00
L97EA:  lda     $1C00
        bpl     L97FD
        bvc     L97EA
        clv
        inx
        bne     L97EA
        iny
        bpl     L97EA
L97F8:  lda     #3
        jmp     $FDD3

L97FD:  sty     $C0
        stx     $C1
        ldx     $43
        ldy     #0
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
        ldx     #0
L9826:  sec
        sbc     $43
        bcs     L982E
        dey
        bmi     L9831
L982E:  inx
        bne     L9826
L9831:  stx     $0626 ; ??? never read
        cpx     #4
        bcc     L97F8
L9838:  jsr     ram_code
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
        jmp     $FCB1
