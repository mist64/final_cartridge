; ----------------------------------------------------------------
; Some common drive code
; ----------------------------------------------------------------

.include "kernal.i"

CR              := $0D

; from fc3
.import disable_rom_jmp_error
.import set_drive

.segment "drive"

.global print_line_from_drive
print_line_from_drive:
        jsr     IECIN
        jsr     $E716 ; output character to the screen
        cmp     #CR
        bne     print_line_from_drive
        jmp     UNTALK

.global check_iec_error
check_iec_error:
        jsr     command_channel_talk
        jsr     IECIN
        tay
L8124:  jsr     IECIN
        cmp     #CR ; skip message
        bne     L8124
        jsr     UNTALK
        cpy     #'0'
        rts

.global cmd_channel_listen
cmd_channel_listen:
        lda     #$6F
.global listen_second
listen_second:
        pha
        jsr     set_drive
        jsr     LISTEN
        pla
        jsr     SECOND
        lda     $90
        rts

.global command_channel_talk
command_channel_talk:
        lda     #$6F
.global talk_second
talk_second:
        pha
        jsr     set_drive
        jsr     TALK
        pla
        jmp     TKSA

.global m_w_and_m_e
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
        jsr     listen_6F_or_error
        lda     #'M'
        jsr     IECOUT
        lda     #'-'
        jsr     IECOUT
        pla
        jmp     IECOUT

.global listen_6F_or_error
listen_6F_or_error:
        lda     #$6F
.global listen_or_error
listen_or_error:
        jsr     listen_second
        bmi     device_not_present
        rts

.global device_not_present
device_not_present:
        ldx     #$05 ; "DEVICE NOT PRESENT"
        jmp     disable_rom_jmp_error

