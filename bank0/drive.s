; ----------------------------------------------------------------
; Common drive code
; ----------------------------------------------------------------
; The BASIC extension and fast format call into this.

.include "../core/kernal.i"

; from wrapper
.import disable_rom_jmp_error

; from basic
.import set_drive

.global print_line_from_drive
.global check_iec_error
.global cmd_channel_listen
.global listen_second
.global command_channel_talk
.global talk_second
.global m_w_and_m_e
.global listen_6F_or_error
.global listen_or_error
.global device_not_present

.segment "drive"

print_line_from_drive:
        jsr     IECIN
        jsr     $E716 ; output character to the screen
        cmp     #CR
        bne     print_line_from_drive
        jmp     UNTALK

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

cmd_channel_listen:
        lda     #$6F
listen_second:
        pha
        jsr     set_drive
        jsr     LISTEN
        pla
        jsr     SECOND
        lda     ST
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
        ldy     #0
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

listen_6F_or_error:
        lda     #$6F
listen_or_error:
        jsr     listen_second
        bmi     device_not_present
        rts

device_not_present:
        ldx     #5 ; "DEVICE NOT PRESENT"
        jmp     disable_rom_jmp_error

