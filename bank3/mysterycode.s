;****************************
;  This code is not fully understood yet
;  
;  Its purpose seems to be reading and writing the directory.
;****************************

      .setcpu "6502x"

.include "../core/kernal.i"
.include "../core/fc3ioreg.i"
.include "persistent.i"

.import load_ae_rom_hidden,store_a_ff_to_ae,fill_loop
.import __diredit_cmds_LOAD__,__diredit_cmds_RUN__,__diredit_cmds_SIZE__
.import W9200
.import not_last_sector
.import next_dir_entry

.segment "mysterycode"

      .byte $b0,$90,$da
W915D:
      jsr  next_dir_entry+1            ; ??????!!
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
      jsr  not_last_sector
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


.segment "mysterybytes"

; These bytes might just be some random padding, because the screenshot code starts at exactly $9500.
; This might also be code, but it doesn't look like it would be actually executable code.

      .byte $15, $03, $a0, $00, $84, $ac, $84, $ae
      .byte $a9, $0c, $85, $ad, $a9, $c0, $85
