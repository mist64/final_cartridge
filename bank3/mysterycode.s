;****************************
;  This code is not fully understood yet
;  
;  Its purpose seems to be reading and writing the directory.
;****************************

      .setcpu "6502x"

.include "../core/kernal.i"
.include "../core/fc3ioreg.i"
.include "persistent.i"

.import load_ae_rom_hidden
.import __diredit_cmds_LOAD__,__diredit_cmds_RUN__,__diredit_cmds_SIZE__

.segment "mysterycode"

      .byte $b0,$90,$da
W915D:
      jsr  W930C+1                      ; ??????!!
      lda  #$80
      sta  $90                         ; Statusbyte ST of I/O KERNAL
      rts

      lda  #$B0
      sta  $C2
      lda  $0200
      sta  $C3
      lda  $0201
      sta  $C4
W9173:
      lda  #>$A000
      sta  $AF
      ldy  #<$A000
      sty  $AE
      lda  ($C3),y
      tax
      bne  :+
      jmp  fill_loop
:     jsr  store_a_ff_to_ae
      txa
      bpl  :+
      jmp  W9200
W918C:
:     ldy  #$02
      jsr  load_ae_rom_hidden
      bpl  @2
      lda  #$05
      ora  $AE
      sta  $AE
      ldy  #$00
:     lda  ($C3),y
      beq  :+
      jsr  load_ae_rom_hidden
      cmp  ($C3),y
      bne  @2
      iny
      cpy  #$11
      bne  :-
      beq  @1
:     cpy  #$10
      beq  :+
      jsr  load_ae_rom_hidden
      cmp  #$A0
      bne  @2
:     iny
      tya
      jsr  W936D
      ldy  #$00
      lda  $AE
      and  #$F0
      sta  $AE
      lda  #$00
      sta  ($C1),y
      iny
      sta  ($C1),y
      iny
:     jsr  load_ae_rom_hidden
      sta  ($C1),y
      iny
      cpy  #$20
      bne  :-
      tya
      clc
      adc  $C1
      sta  $C1
      bcc  W9173
      inc  $C2
      lda  $C2
      cmp  #$C0
      bcc  W9173
@1:
      jmp  W915D

@2:
      lda  $AE
      and  #$F0
      clc
      adc  #$20
      sta  $AE
      bcc  :+
      inc  $AF
:     lda  $AF
      cmp  $AD
      bcs  @1
      jmp  W918C

W9200:
      jsr  clear_a000_bfff
      lda  #fcio_nmi_line | fcio_bank_0
      jmp  _jmp_bank

clear_a000_bfff:
      ; Fill $A000..$BFFF with #$00
      lda  #>$A000
      sta  $AD
      ldx  #$20
      lda  #$00
      tay
      sta  $AC
fill_loop:
:     sta  ($AC),y
      iny
      bne  :-
      inc  $AD
      dex
      bne  :-

      ; Copy directory editing commands to low RAM
      ldx  #<(__diredit_cmds_SIZE__-1)
:     lda  __diredit_cmds_LOAD__,x
      sta  $0202,x
      dex
      bpl  :-

      jsr  write_hash_to_chan_2
      lda  #$00
      sta  $AC
      sta  $AE
      sta  $C1
      lda  #>$A000
      sta  $AD
:     jsr  send_read_block
      jsr  W9452
      jsr  read_254byte_from_chan_2
      inc  $AD
      cpx  #$00
      beq  W9265
      cpx  #$12
      bne  close
      cmp  #$13
      bcs  close
      jsr  nibble2ascii
      ; Store sector number
      stx  read_block+10
      sta  read_block+11
      lda  $AD
      cmp  #$B0
      bcc  :-
close:
      jsr  close_chn2
      lda  #$80
      sta  $90                          ; Statusbyte ST of I/O KERNAL
      rts

W9265:
      lda  #$B0
      sta  $C2
      lda  $0200
      sta  $C3
      lda  $0201
      sta  $C4
      ldy  #<$A000
      sty  $AE
      sty  $0200
      lda  #>$A000
      sta  $AF
      ldy  #$02
@1:   jsr  load_ae_rom_hidden
      bpl  :+
      inc  $0200
:     jsr  W930C
      bcc  @1
W928D:
      lda  #>$A000
      sta  $AF
      ldy  #<$A000
      sty  $AE
      lda  ($C3),y
      tax
      bne  :+
      jmp  W9331
:     jsr  inc_c3c4_beyond_z
      txa
      bmi  W931E
      dec  $0200
W92A6:
      ldy  #$02
      jsr  load_ae_rom_hidden
      bpl  W9304
      lda  #$05
      ora  $AE
      sta  $AE
      ldy  #$00
:     lda  ($C3),y
      beq  :+
      jsr  load_ae_rom_hidden
      cmp  ($C3),y
      bne  W9304
      iny
      cpy  #$11
      bne  :-
      beq  W9301
:     cpy  #$10
      beq  :+
      jsr  load_ae_rom_hidden
      cmp  #$A0
      bne  W9304
:     iny
      tya
      jsr  add_to_c3c4
      ldy  #$00
      lda  $AE
      and  #$F0
      sta  $AE
      lda  #$00
      sta  ($C1),y
      iny
      sta  ($C1),y
      iny
:     jsr  load_ae_rom_hidden
      sta  ($C1),y
      iny
      cpy  #$20
      bne  :-
W92F1:
      tya
      clc
      adc  $C1
      sta  $C1
      bcc  W928D
      inc  $C2
      lda  $C2
      cmp  #$C0
      bcc  W928D
W9301:
@c:   jmp  close

W9304:
      jsr  W930C
      bcs  W9301
      jmp  W92A6

W930C:
      lda  $AE
      and  #$F0
      clc
      adc  #$20
      sta  $AE
      bcc  :+
      inc  $AF
:     lda  $AF
      cmp  $AD
      rts

W931E:
      ldy  #$FF
      jsr  inc_c3c4_beyond_z
      ldy  #$00
:     lda  dirline,y
      sta  ($C1),y
      iny
      cpy  #$20
      bne  :-
      beq  W92F1
W9331:
      lda  $0200
      bne  W9301
      lda  #$30
      sta  read_block+23
      lda  #$31
      sta  read_block+24
      lda  $C1
      bne  W9346
      dec  $C2
W9346:
      lda  #$00
      sta  $AE
      lda  #$B0
      sta  $AF
      lda  #$02
      sta  $AC
W9352:
      ldy  #$00
      lda  $AF
      cmp  $C2
      bcs  :+
      lda  #$12
      sta  ($AE),y
      iny
      lda  $AC
      sta  ($AE),y
      bne  W936D
:     tya
store_a_ff_to_ae:
      sta  ($AE),y
      lda  #$FF
      iny
      sta  ($AE),y
W936D:
      lda  $AC
      sec
      sbc  #$01
      jsr  nibble2ascii
      ; Store sector number
      stx  read_block+23
      sta  read_block+24
      jsr  W9452
      jsr  send_256byte_to_channel_2
      jsr  send_write_block
      lda  $AF
      cmp  $C2
      bcs  :+
      inc  $AF
      inc  $AC
      jmp  W9352

:     lda  #$13
      sec
      sbc  $AC
      sta  $C1
      lda  #$FF
      sta  $C2
      sta  $C3
      sta  $C4
:     clc
      rol  $C2
      rol  $C3
      rol  $C4
      dec  $AC
      bne  :-
      lda  $C4
      and  #$07
      sta  $C4
      lda  #$30
      ; Store sector number
      sta  read_block+10
      sta  read_block+11
      sta  read_block+23
      sta  read_block+24
      jsr  send_read_block
      jsr  W9455
      lda  #$62
      jsr  listen_second
      ldx  #$00
:     lda  $C1,x
      jsr  IECOUT
      inx
      cpx  #4
      bne  :-
      jsr  UNLSTN
      jsr  send_write_block
      lda  #$6F
      jsr  listen_second
      lda  #'I'
      jsr  IECOUT
      jsr  UNLSTN
      jmp  close_chn2

send_256byte_to_channel_2:
      lda  #$62
      jsr  listen_second
      ldy  #$00
:     jsr  load_ae_rom_hidden
      jsr  IECOUT
      iny
      bne  :-
      jmp  UNLSTN

read_254byte_from_chan_2:
      lda  #$62
      jsr  talk_second
      ldy  #$02
      jsr  IECIN
      tax
      jsr  IECIN
      pha
:     jsr  IECIN
      sta  ($AC),y
      iny
      bne  :-
      jsr  UNTALK
      pla
      rts

write_hash_to_chan_2:
      lda  #$00
      sta  $90
      lda  #$F2
      jsr  listen_second
      lda  $90
      bmi  W9484
      lda  #'#'
      jsr  IECOUT
      jmp  UNLSTN

close_chn2:
      lda  #$E2
      jsr  listen_second
      jmp  UNLSTN

listen_second:
      pha
      lda  $BA                          ; Current device number
      jsr  LISTEN
      pla
      jmp  SECOND

talk_second:
      pha
      lda  $BA                          ; Current device number
      jsr  TALK
      pla
      jmp  TKSA

send_read_block:
      ldx  #<(read_block - __diredit_cmds_RUN__)
      .byte $2c
send_write_block:
      ldx  #<(write_block - __diredit_cmds_RUN__)
      .byte $2c
W9452:
      ldx  #<(seek_0 - __diredit_cmds_RUN__)
      .byte $2c
W9455:
      ldx  #<(seek_72 - __diredit_cmds_RUN__)
      lda  #$6F
      jsr  listen_second
:     lda  $0202,x
      beq  :+
      jsr  IECOUT
      inx
      bne  :-
:     jsr  UNLSTN
      ; Check for error omn cmd channel 15
      lda  #$6F
      jsr  talk_second
      jsr  IECIN
      pha
:     cmp  #$0D
      beq  :+
      jsr  IECIN
      bne  :-
:     jsr  UNTALK
      pla
      cmp  #$30
      beq  _rts2
W9484:
      pla
      pla
      jmp  close

inc_c3c4_beyond_z:
:     iny
      lda  ($C3),y
      bne  :-
      iny
      tya
add_to_c3c4:
      clc
      adc  $C3
      sta  $C3
      bcc  _rts2
      inc  $C4
_rts2: rts

;
; Convert a nibble (actually a number 0..19) to ASCII with fixed with.
; 
; IN:   A  - Nibble
;
; OUT:  A - Least significant digit
;       X - Most sigificant digit
;
.proc nibble2ascii
      ldx  #'0'
      cmp  #$0A
      bcc  :+
      inx
      sbc  #$0A
:     ora  #'0'
      rts
.endproc

dirline:
      .byte $00, $00, $80, $12, $00, $2D, $2D, $2D 
      .byte $2D, $2D, $2D, $2D, $2D, $2D, $2D, $2D 
      .byte $2D, $2D, $2D, $2D, $2D, $00, $00, $00 
      .byte $00, $00, $00, $00, $00, $00, $00, $00 

.segment "diredit_cmds"

read_block:     .asciiz "U1:2 0 18 01"            ; Read block on channel 2 from drive 0, track 18 sector 1
write_block:    .asciiz "U2:2 0 18 01"            ; Write block on channel 2 to drive 0, track 18 sector 1
seek_0:         .asciiz "B-P 2 0"                 ; Seek channel 2 to position 0
seek_72:        .asciiz "B-P 2 72"                ; Seek channel 2 to position 72

.segment "mysterybytes"

; These bytes might just be some random padding, because the screenshot code starts at exactly $9500.
; This might also be code, but it doesn't look like it would be actually executable code.

      .byte $15, $03, $a0, $00, $84, $ac, $84, $ae
      .byte $a9, $0c, $85, $ad, $a9, $c0, $85
