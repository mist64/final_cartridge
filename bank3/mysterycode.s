;****************************
;  This code is not fully understood yet
;  
;  Its purpose seems to be reading and writing the directory.
;****************************

      .setcpu "6502x"

.include "../core/kernal.i"
.include "../core/fc3ioreg.i"
.include "persistent.i"

.import store_a_ff_to_ae,fill_loop
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
      jsr  _load_ae_rom_hidden
      bpl  @2
      lda  #$05
      ora  $AE
      sta  $AE
      ldy  #$00
:     lda  ($C3),y
      beq  :+
      jsr  _load_ae_rom_hidden
      cmp  ($C3),y
      bne  @2
      iny
      cpy  #$11
      bne  :-
      beq  @1
:     cpy  #$10
      beq  :+
      jsr  _load_ae_rom_hidden
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
:     jsr  _load_ae_rom_hidden
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

.segment "junk0"



      .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
      .byte $FF, $FF, $FF, $FF, $FF, $FF, $1C 

.segment "ramcode"

      ; Installed to zeropage at $0060

WA421:
      jmp  $1D48

      jmp  $1D58

      jsr  $154D
      jmp  $B603

      lda  #$0D
      jsr  $1599
      jsr  $1CDA
      jsr  $1D58
      jsr  $137A
      jsr  $1CAD
      jmp  $B603

      jsr  $18DA
      jsr  $1EB1
      bcs  @1
      ldx  #$6E
      ldy  #$11
      lda  #$49
      jsr  _enable_fcbank0
      txa
      beq  :+
      jmp  $18D4
:     jsr  $12BF
@1:   ldx  #$FB ; init stack?
      txs
      lda  #$58
      jsr  _enable_fcbank0
      nop
      nop
      nop
      jmp  $8003 ; warmstart ??

.segment "mysterybytes2"
      .byte $cd
      .byte $19,$a1,$19,$ef,$19,$47,$1a,$66
      .byte $1a,$52,$1a,$5a,$1a,$73,$1a,$5d
      .byte $1a,$96,$1a,$88,$1a,$71,$10,$21
      .byte $14,$27,$1a,$d0,$1f,$dd,$1f

.segment "ramcode2"

;WA489
      jsr  $148D
      sec
      lda  $0DC1
      sbc  $9F
      sta  $0DC1
      bcs  :+
      dec  $0DC2
:     rts

      jsr  $148D
      clc
      lda  $0DC1
      adc  $9F
WE4A4:
      sta  $0DC1
      bcc  :+
      inc  $0DC2
:     rts

      lda  $0E04
      bpl  :+
      clc
      adc  #$01
:     and  #$0F
      sec
      adc  $5700,x
      sta  $9F
      rts

      lda  $0DC1
      cmp  #$2A
      bcc  :+
      lda  $0DC2
      cmp  #$01
:     rts

      sei
:     lda  $D012
      cmp  #$FB
      bcc  :-
      cli
      rts

      ldy  #$01
      clc
      lda  #$2A
      adc  $0DBE
      tax
      bcc  :+
      iny
:     sty  $FA
      ldy  $0DBF
      lda  #$03
      jsr  _enable_fcbank0
      ldx  $FE
      ldy  $FF
      stx  $0DC7
      sty  $0DC8
      rts

WE4F6:
      ldy  #$00
      lda  ($8B),y
      sta  ($35),y
      tax
      tya
      iny
      sta  ($35),y
      inc  $8B
      bne  :+
      inc  $8C
:     inc  $35
      bne  :+
      inc  $36
:     rts

      rts

      ldy  #$00
      lda  ($8B),y
      cmp  #$0D
      beq  WE4F6
      rts

WE518:
      lda  $8B
      bne  :+
      dec  $8C
:     dec  $8B
      lda  $35
      bne  :+
      dec  $36
:     dec  $35
      ldy  #$00
      lda  ($35),y
      sta  ($8B),y
      tax
      tya
      sta  ($35),y
      rts

      dec  $36
      ldy  #$FF
      lda  ($35),y
      inc  $36
      cmp  #$0D
      beq  WE518
      rts

      lda  $A3
      bpl  :+
      clc
      adc  #$01
:     and  #$0F
      sta  $96
      ldy  #$00
      sty  $0DC1
      sty  $0DC2
@1:   lda  ($C3),y
      beq  @x
      tax
      sec
      lda  $5700,x
      adc  $96
      adc  $0DC1
      sta  $0DC1
      bcc  :+
      inc  $0DC2
:     iny
      bne  @1
@x:   rts

      ldy  #0
      lda  #$FF
      sta  ($35),y
      tya
      iny
      sta  ($35),y
      inc  $35
      bne  :+
      inc  $36
:     rts

      lda  $35
      bne  :+
      dec  $36
:     dec  $35
      ldy  #$00
      lda  ($35),y
      tax
      tya
      sta  ($35),y
      rts

      inc  $8B
      bne  :+
      inc  $8C
:     clc
      rts

      dec  $36
      ldy  #$00
:     dey
      lda  ($35),y
      cmp  #$FF
      bne  :-
      tya
      eor  #$FF
      tax
      sta  $C3
      inc  $36
      ldy  $36
      sec
      lda  $35
      sbc  $C3
      sta  $C3
      bcs  :+
      dey
:     sty  $C4
      rts

      ldy  #0
      sta  ($35),y
      inc  $35
      bne  :+
      inc  $36
:     tya
      sta  ($35),y
      rts

      sec
      lda  #$2A
      sbc  $0DC1
      sta  $8D
      lda  #$01
      sbc  $0DC2
      sta  $8E
      jsr  $165E
      bcs  @2
      jsr  $1C5C
      lda  $8E
      rts
@2:   jsr  $1C74
      lda  $8E
      rts

WA5E7:
      jsr  $14F8
      jsr  $1469
      lda  #$01
      sta  $0DCA
      bne  @1
      jsr  $14F8
      jsr  $1469
      lda  #$00
      sta  $0DCA
      beq  :+
      lda  #$FF
      sta  $0DCA
:     jsr  $14F8
      jsr  $1469
      inc  $0DCA
      cpx  #$20
      bne  :-
      lda  $0DCA
      bne  :+
      inc  $0DCA
      bne  @1
:     jsr  $14D6
@1:   jsr  $154D
      jsr  $1323
      jsr  $1CDA
      lda  $0DC9
      cmp  $0DCB
      bne  :+
      jsr  $1DF5
      dec  $0DC9
      ldy  $0DC9
      lda  $0DE6,y
      sta  $0DBF
:     jsr  $1D58
      inc  $0DC9
      ldy  $0DC9
      lda  $0DE6,y
      sta  $0DBF
      lda  $8B
      sta  $0DCD,y
      lda  #$00
      sta  $0DC1
      sta  $0DC2
      lda  $0DCA
      sta  $8E
      beq  WE66D
:     jsr  $14D6
      jsr  $147B
      dec  $8E
      bne  :-
WE66D:
      jsr  $1CAD
      jmp  $14B5

      ldx  $0DCA
      beq  @xc
      dec  $36
      ldy  #$FE
      bne  :+
      ldx  $0DCA
      beq  @xc
      dec  $36
      ldy  #$FF
:     lda  ($35),y
      cmp  #$20
      beq  @xs
      dey
      dex
      bne  :-
      inc  $36
@xc:  clc
      rts

@xs:  inc  $36
      sec
      rts

      lda  $35
      cmp  #$01
      bne  @rts
      beq  :+
      lda  $35
      bne  @rts
:     lda  $36
      cmp  #$58
@rts: rts

WE6AA:
      jsr  $1681
      beq  WE6D4
      jsr  $14F8
      cpx  #$20
      bcc  WE6CB
      cpx  #$7E
      bcc  WE6AA
      txa
      eor  #$A0
      cmp  #$61
      bcc  WE6CB
      cmp  #$7E
      bcs  WE6CB
      ldy  #$00
      sta  ($8B),y
      beq  WE6AA
WE6CB:
      cpx  #$0D
      beq  WE6AA
      jsr  $156F
      bcc  WE6AA
WE6D4:
      jmp  $154D

      lda  #$00
      sta  $0DC9
      sta  $0DCA
      sta  $0DC1
      sta  $0DC2
      ldx  $0E01
      ldy  $0E02
      stx  $0DBE
      sty  $0DBF
      rts

WE6F2:
      jsr  $15A7
      beq  WE720
      jsr  $14D6
      txa
      beq  WE71D
      cpx  #$0D
      beq  WE71D
      inc  $0DCA
      jsr  $147B
      lda  $A6
      cmp  $0DC2
      bcc  WE717
      bne  WE6F2
      lda  $0DC1
      cmp  $A5
      bcc  WE6F2
WE717:
      jsr  $1469
      dec  $0DCA
WE71D:
      jsr  $14F8
WE720:
      rts

WE721:
      lda  $0DCA
      beq  @x
      jsr  $14F8
      txa
      dec  $0DCA
      jsr  $1469
      lda  $0DC2
      cmp  $A6
      bcc  @x
      bne  WE721
      lda  $A5
      cmp  $0DC1
      bcc  WE721
@x:   rts

      lda  $0DC2
      cmp  $A6
      bcc  WE6F2
      bne  WE721
      lda  $A5
      cmp  $0DC1
      bcs  WE6F2
      bcc  WE721
      cpy  $0DC9
      bcs  WE7B8
      sty  $F7
      sec
      lda  $0DC9
      sbc  $F7
WE760:
      sta  $F7
      inc  $F7
      lda  #$00
      sta  $A5
@3:   jsr  $14F8
      cpx  #$FF
      bne  @3
      jsr  $156F
      jsr  $1681
      beq  @4
      ldy  $0DC9
      lda  $8B
      ldx  $A5
      bne  @1
      cmp  $0DCD,y
      beq  @2
      inc  $A5
@1:   lda  #$00
      sta  $0DCD,y
@2:   dec  $F7
      beq  @4
      dec  $0DC9
      ldy  $0DC9
      lda  $0DE6,y
      sta  $0DBF
      bne  @3
@4:   jsr  $154D
      dec  $0DC9
      jsr  $1D58
      inc  $0DC9
      lda  #$00
      sta  $0DCA
      sta  $0DC1
      sta  $0DC2
      jmp  $14B5

WE7B8:
      sec
      tya
      sbc  $0DC9
      sta  $F7
WE7BF:
      jsr  $15A7
      beq  @1
:     jsr  $14D6
      jsr  $147B
      dec  $8E
      bne  :-
@1:    ldy  #$00
      lda  ($8B),y
      beq  WE760
      jsr  $14EF
      jsr  $154D
      lda  #$00
      sta  $0DCA
WE7DF:
      sta  $0DC1
      sta  $0DC2
      inc  $0DC9
      ldy  $0DC9
      lda  $0DE6,y
      sta  $0DBF
      dec  $F7
      bne  WE7BF
      jmp  $14B5

      lda  $0DC0
      beq  WE80C
      asl
      tax
      lda  $1447,x
      sta  $A4
      lda  $1448,x
      sta  $A5
      jmp  ($00A4)

WE80C:
      jmp  $1CAD

      sta  $A3
      sta  $A6
      stx  $A4
      sty  $A5
WE817:
      ldy  #$06
      lda  ($A4),y
      cmp  #$23
      bne  :+
      iny
      lda  ($A4),y
      cmp  $A3
      bne  WE84C
      beq  WE82F
:     iny
      lda  ($A4),y
      cmp  $A3
      beq  WE840
WE82F:
      ldy  #$00
      lda  ($A4),y
      tax
      iny
      lda  ($A4),y
      stx  $A4
      sta  $A5
      bne  WE817
      ldy  $A6
      rts

WE840:
      ldy  #$06
      lda  ($A4),y
      ora  #$02
      sta  ($A4),y
      ldy  #$09
      bne  WE856
WE84C:
      ldy  #$06
      lda  ($A4),y
      and  #$FD
      sta  ($A4),y
      ldy  #$0A
WE856:
      lda  ($A4),y
      pha
      ldy  #$08
      lda  ($A4),y
      sta  $A3
      ldy  #$02
      lda  ($A4),y
      tax
      iny
      lda  ($A4),y
      stx  $A4
      sta  $A5
      ldy  $A3
      pla
      sta  ($A4),y
      ldy  $A6
      rts

      lda  $B6
      cmp  #$08 
      bcs  WE891
      lda  $B5
WE87B:
      bne  :+
      jsr  $18C3
      lda  #$00
      sta  $0DC0
      lda  #$3C
      jsr  _enable_fcbank0
      jsr  $18CC
      jsr  $17D8
:     rts

WE891:
      ldy  #$00
      lda  $B6
      ldx  $0DCB
      inx
:     cmp  $0DE6,y
      bcc  WE8A4
      iny
      dex
      bpl  :-
      ldy  #$00
WE8A4:
      tya
      beq  @1
      dey
      sec
      ldx  $B5
      lda  $B4
      sbc  $0E01
      bcs  :+
      dex
      bpl  :+
      lda  #$00
      tax
:     sta  $A5
      stx  $A6
      sta  $0DC3
      stx  $0DC4
      cpy  $0DC9
      beq  :+
      jsr  $1733
      lda  $0DC3
      ldx  $0DC4
      sta  $A5
      stx  $A6
:     jsr  $1721
      jsr  $1323
      jsr  $1CAD
@1:   lda  $03C8
      beq  @1
      rts

      lda  #$50
      jsr  _enable_fcbank0
      jsr  $18DA
      rts

      jsr  $18D4
      lda  #$57
      jmp  _enable_fcbank0

      lda  #$43
      sta  $D015                        ; Sprites Abilitator
      rts

      lda  #$03
      sta  $D015                        ; Sprites Abilitator
      rts

      ldy  #$FF
      lda  $0E02
:     iny
      sta  $0DE6,y
      clc
      adc  $0E03
      cmp  #$BC
      bcc  :-
      sty  $0DCB
      iny
      lda  #$C8
      sta  $0DE6,y
      rts

      sei
      ldx  #<$EA31
      ldy  #>$EA31
      stx  $0314                        ; Vector: Hardware Interrupt (IRQ)
      sty  $0315                        ; Vector: Hardware Interrupt (IRQ)
      lda  #$F0
      sta  $D01A                        ; IRQ mask register
      cli
      rts

      sei
      ldx  #<$DE21
      ldy  #>$DE21
      stx  $0314                        ; Vector: Hardware Interrupt (IRQ)
      sty  $0315                        ; Vector: Hardware Interrupt (IRQ)
      lda  #$F1
      sta  $D01A                        ; IRQ mask register
      cli
      rts

      ldx  #$FF
      lda  $1070
      ldy  $0DBD
      cpy  #$08
      bcc  WE94E
      tay
      beq  WE968
WE94E:
      ldx  #$5F
      ldy  #$10
      sta  $8D
      stx  $8E
      sty  $8F
      lda  $0DBD
      sta  $F7
      ldx  #$00
      ldy  #$58
      lda  #$53
      jsr  _enable_fcbank0
      ldx  $8F
WE968:
      stx  $0DFF
      ldx  $AE
      ldy  $AF
      stx  $0DC3
      sty  $0DC4
      rts

      ldx  #$FF
      lda  $1070
      ldy  $0DBD
      cpy  #$08
      bcc  WE985
      tay
      beq  WE9B4
WE985:
      ldx  #$5F
      ldy  #$10
      sta  $8D
      stx  $8E
      sty  $8F
      ldx  $8B
      ldy  $8C
      stx  $A8
      sty  $A9
      lda  #$A8
      sta  $F7
      ldx  #$FF
      ldy  #$7F
      lda  $0DBD
      sta  $AA
      lda  #$54
      jsr  _enable_fcbank0
      ldx  #$00
      lda  $0DBD
      cmp  #$08
      bcc  WE9B4
      ldx  $8F
WE9B4:
      stx  $0DFF
      rts

WE9B8:
      jsr  $14D6
      txa
      bne  WE9B8
      jmp  $14F8

      jsr  $1679
      beq  @x1
@l:   jsr  $18DA
      jsr  $16B7
      jsr  $14B5
      jsr  $1323
      jsr  $1CAD
      ldy  $0DCB
      lda  #$00
:     sta  $0DCD,y
      dey
      bpl  :-
      jsr  $168A
      jsr  $B609
      jsr  $1323
      jsr  $18D4
@x1:  rts

      jsr  $1EB1
      bcs  @5
      jsr  $1AFD
      txa
      beq  :+
      rts

:     jsr  $12BF
@5:   jsr  $1A03
      ldx  #$00
      stx  $C6
      ldy  #$58
      stx  $35
      sty  $36
      jsr  $154D
      jmp  $19F9

      ldx  $0DC3
      ldy  $0DC4
      stx  $35
      sty  $36
      ldx  #$FF
      ldy  #$7F
      stx  $8B
      sty  $8C
      bne  @l
      ldx  #$05
      ldy  #$10
      lda  #$02
      jsr  _enable_fcbank0
      ldx  #$9A
      ldy  #$B3
      lda  #$08
      jsr  _enable_fcbank0
      ldx  #$9F
      ldy  #$10
      lda  #$02
      jsr  _enable_fcbank0
      ldx  #$9A 
      ldy  #$B3
      lda  #$08
      jmp  _enable_fcbank0

      lda  $0E04
      eor  #$10
      sta  $0E04
      sta  $A3
      and  #$10
      beq  @4
      ldy  #$6E
:     lda  #$06
      sta  $5710,y
      dey
      bpl  :-
      bmi  @3
@4:   jsr  $1123
@3:   jmp  $19A6

      lda  $0E04
      eor  #$80
      sta  $0E04
      clc
      bcc  :+
      lda  $0E04
:     sta  $A3
      jmp  $19A6

      jsr  $18E0
      jsr  $18DA
      jsr  $1A03
      jmp  $19A6

      lda  $0E05
      eor  #$01
      sta  $0E05
      sta  $8F
      jmp  $19A6

      jsr  $168A
      jsr  $18C3
      jsr  $18FB
      jsr  $1B30
      jsr  $190D
      jsr  $18CC
      jmp  $19A6

      lda  $0DFF
      beq  :+
      jsr  $1AF4
      jmp  $19DC
:     jmp  $19EF

      jsr  $18C3
      jsr  $1EFB
      jsr  $18CC
      jsr  $1CAD
      lda  $0DC0
      cmp  #$02
      bne  @2
      rts

@2:   jsr  $168A
      lda  #$00
      sta  $0DFF
      jsr  $18C3
      jsr  $1956
      jsr  $18CC
      lda  $0DFF
      beq  :+
      jsr  $1AF4
:     jmp  $19A6

      lda  #$80
      pha
      lda  #$0B
      pha
      ldy  $DE00
      lda  #$40
      jmp  _jmp_bank

      ldx  #$03
      jsr  $1AC6
      lda  $90                          ; Statusbyte ST of I/O KERNAL
      bmi  :+
      ldx  #$00
      lda  $0200
      cmp  #$30
      bne  :+
      lda  $0201
      cmp  #$30
      beq  @1
:     dex
@1:   stx  $8F
      stx  $0DFF
      rts

      jsr  $18DA
WEB17:
      ldx  #$39
      ldy  #$11
      bne  WEB48
      jsr  $18DA
      ldx  #$92
      ldy  #$11
      bne  WEB48
      jsr  $18DA
      ldx  #$BA
      ldy  #$11
      bne  WEB48
      jsr  $18DA
      ldx  #$F7
      ldy  #$11
      bne  WEB48
      jsr  $18DA
      ldx  #$40
      ldy  #$12
      bne  WEB48
      jsr  $18DA
      ldx  #$67
      ldy  #$12
WEB48:
      lda  #$49
      jsr  _enable_fcbank0
      jmp  $18D4

      lda  #$00
      sta  $90                          ; Statusbyte ST of I/O KERNAL
      jsr  $FF90                        ; Routine: Control KERNAL messages
      ldx  #$0B
WEB59:
      jsr  $1AC6
      ldx  #$0B
      jsr  $1AC6
      lda  $90                          ; Statusbyte ST of I/O KERNAL
      bmi  WEB9B
      jsr  $1B85
      tya
      beq  WEB9B
      ldy  #$00
      sty  $A6                          ; Pointer: I/O Buffer of tape
@1:   lda  ($8B),y
      cmp  #$0D
      beq  WEB8B
      cmp  #$5F
      bne  :+
      lda  #$0C
:     sta  $0200
      ldx  #$0C
      jsr  $1AC6
      inc  $A6
      ldy  $A6
      dec  $A4
      bne  @1
WEB8B:
      lda  #$0D
      sta  $0200
      ldx  #$0C
      jsr  $1AC6
      jsr  $1BB4
      jmp  $1B45

WEB9B:
      ldx  #$0D
      jsr  $1AC6
      lda  #$C0
      jmp  $FF90                        ; Routine: Control KERNAL messages

      lda  $0E00
      sta  $A4
      ldy  #$00
      sty  $A8
@4:   lda  ($8B),y
      beq  @5
      iny
      cmp  #$0D
      beq  @5
      ldx  $0E05
      beq  :+
      cmp  #$20
      bne  @6
:     sty  $A8
@6:   dec  $A4
      bne  @4
      ldy  $A8
      bne  @5
      ldy  $0E00
      bne  @5
@5:   sty  $A4
      sty  $A8
      rts

      clc
      lda  $8B
      adc  $A8
      sta  $8B
      bcc  :+
      inc  $8C
:     rts

      ldx  #$00
      ldy  #$00
      lda  #$02
      jsr  _enable_fcbank0
      lda  #$C8
      sta  $F9
      lda  #$05
      jsr  _enable_fcbank0
      lda  #$01
      sta  $FA
      ldx  #$3F
      ldy  #$00
      lda  #$03
      jsr  _enable_fcbank0
      lda  #$05
      jsr  _enable_fcbank0
      ldx  #$00
      ldy  #$C7
      lda  #$02
      jsr  _enable_fcbank0
      ldx  #$9F
      stx  $F8
      lda  #$04
      jsr  _enable_fcbank0
      ldx  #$9F
      ldy  #$C7
      lda  #$02
      jsr  _enable_fcbank0
      lda  #$04
      jsr  _enable_fcbank0
      rts

      lda  $A3
      bpl  :+
      clc
      adc  #$01
:     and  #$0F
      sta  $96
      ldy  #$00
      sty  $9E
      sty  $9F
      sty  $C4
@l:   lda  ($8B),y
      tax
      beq  @1
      cmp  #$0D 
      beq  @1
      tax
      sec
      lda  $5700,x
      adc  $96
      adc  $9E
      sta  $9E
      bcc  :+
      inc  $9F
:     iny
@1:   lda  $8F
      beq  :+
      cpx  #$21
      bcs  @3
:     lda  $8E
      cmp  $9F
      bcc  @x
      bne  @2
      lda  $9E
      cmp  $8D
      beq  @2
      bcs  @x
@2:   sty  $C4
@3:   txa 
      beq  @y
      cpx  #$0D
      beq  @y
      bne  @l ; always
@x:   ldy  $C4
      ldx  #$01
      rts
@y:   ldx  #$00
      rts

      jsr  $1C05
      tya
      bne  :+
      txa
      beq  :+
      lda  #$00
      sta  $8F
      jsr  $1C05
      lda  $0E05
      sta  $8F
:     sty  $8E
      rts

      jsr  $1C05
      sty  $8E
      rts

kungfu:
      ldy  #$00
      sty  $8D
      lda  $8E
      beq  @rts
:     lda  ($8B),y
      tax
      cmp  #$0D
      beq  @rts
      lda  #$19
      jsr  _enable_fcbank0
      inc  $8D
      ldy  $8D
      cpy  $8E
      bcc  :-
@rts: rts

shogun:
      ldy  $8E
      lda  ($8B),y
      cmp  #$0D
      bne  :+
      inc  $8E
:     clc
      lda  $8B
      adc  $8E
      sta  $8B
      bcc  :+
      inc  $8C
:     rts

      clc
      lda  #$31
      adc  $0DBF
      sta  $D00D                        ; Position Y sprite 6
      clc
      lda  #$17
      adc  $0DBE
      adc  $0DC1
      tay
      bcs  WECE7
      lda  $0DC2
      beq  WECEE
WECE7:
      lda  $D010                        ; Position X MSB sprites 0..7
      ora  #$40
      bne  WECF3
WECEE:
      lda  $D010                        ; Position X MSB sprites 0..7
      and  #$BF
WECF3:
      sta  $D010                        ; Position X MSB sprites 0..7
      sty  $D00C                        ; Position X sprite 6
      rts

      ldx  #$7B
      lda  #$19
      jsr  _enable_fcbank0
      sec
      lda  $0DC7
      sbc  $FE
      sta  $A4
      lda  $0DC8
      sbc  $FF
      bmi  @rts
      beq  :+
      lda  #$20
:     lsr  $A4
      lsr  $A4
      lsr  $A4
      ora  $A4
      sta  $A4
      lda  $FE
      and  #$07
      sta  $A7
      eor  #$07
      sta  $A5
      lda  $FF
      sta  $A8
      ldy  #$00
      jsr  $1D28
      ldx  $A8
      inx
      stx  $FF
      lda  $FE
      tax
      and  #$F8
      sta  $FE
      txa
      and  #$07
      sta  $A5
      eor  #$07
      sta  $A7
      ldy  #$40
      lda  $A4
      sta  $A6
@2:   lda  #$00
      ldx  $A5
@1:   sta  ($FE),y
      iny
      bne  :+
      inc  $FF
:     dex
      bpl  @1
      tya
      clc
      adc  $A7
      bcc  :+
      inc  $FF
:     tay
      dec  $A6
      bpl  @2
@rts: rts

      ldx  $8B
      ldy  $8C
      stx  $0DC5
      sty  $0DC6
      jsr  $1C97
      jmp  $1D62

      ldx  $8B
      ldy  $8C
      stx  $0DC5
      sty  $0DC6
      lda  $0DBF
      ldx  $0DC7
      ldy  $0DC8
      sta  $0DB8
      stx  $0DB9
      sty  $0DBA
      lda  $0DC9
      sta  $0DCC
      ldy  $0DCC
      cpy  $0DCB
      beq  WEDE3
      iny
      inc  $0DCC
      lda  $8B
      beq  :+
      cmp  $0DCD,y
      beq  WEDE3
:     sta  $0DCD,y
      lda  $0DE6,y
      sta  $0DBF
      jsr  $14B5
      ldx  $0DBE
      ldy  $0DBF
      lda  #$02
      jsr  _enable_fcbank0
      ldx  #$2A
      ldy  #$01
      stx  $8D
      sty  $8E
      jsr  $1C5C
      jsr  $1C7A
      jsr  $1CDA
      ldy  #$00
      lda  ($8B),y
      beq  :+
      jsr  $1C97
:     jmp  $1D7A

WEDE3:
      lda  $0DB8
      ldx  $0DB9
      ldy  $0DBA
      sta  $0DBF
      stx  $0DC7
      sty  $0DC8
      ldx  $0DC5
      ldy  $0DC6
      stx  $8B
      sty  $8C
      rts

samurai:
      lda  $0DCB
      sta  $A4
      lda  #$2A
      lsr
      lsr
      lsr
      ldx  #$01
      beq  :+
      ora  #$20
:     sta  $F7
      inc  $F7
      rts

ninja:
      lda  $0E02
      sta  $C3
      jsr  $1DE0
@3:   lda  $0E03
      sta  $A9
@2:   ldx  $0E01
      ldy  $C3
      lda  #$02
      jsr  _enable_fcbank0
      ldx  $FE
      ldy  $FF
      stx  $A7
      sty  $A8
      ldx  #$00
      ldy  $0E03
      lda  #$0C
      jsr  _enable_fcbank0
      ldx  $FE
      ldy  $FF
      stx  $A5
      sty  $A6
      inc  $C3
      ldy  #$00
      ldx  $F7
@1:   lda  ($A5),y
      sta  ($A7),y
      tya
      clc
      adc  #$08
      tay
      bne  :+
      inc  $A6
      inc  $A8
:     dex
      bne  @1
      dec  $A9
      bne  @2
      dec  $A4
      bne  @3
      ldy  $0DCB
      lda  #$00
      sta  $0DCD,y
      rts

      ldy  $0DCB
      lda  $0DE6,y
      sta  $C3
      jsr  $1DE0
@5:   lda  $0E03
      sta  $A9
@6:   dec  $C3
      ldx  $0E01
      ldy  $C3
      lda  #$02
      jsr  _enable_fcbank0
      ldx  $FE
      ldy  $FF
      stx  $A7
      sty  $A8
      ldx  #$00
      ldy  $0E03
      lda  #$0C
      jsr  _enable_fcbank0
      ldx  $FE
      ldy  $FF
      stx  $A5
      sty  $A6
      ldy  #$00
      ldx  $F7
@4:   lda  ($A7),y
      sta  ($A5),y
      tya
      clc
      adc  #$08
      tay
      bne  :+
      inc  $A6
      inc  $A8
:     dex
      bne  @4
      dec  $A9
      bne  @6
      dec  $A4
      bne  @5
      ldx  $0DCB
      dex
:     lda  $0DCD,x
      sta  $0DCE,x
      dex
      bpl  :-
      rts

      lda  $35
      cmp  #$01
      bne  :+
      lda  $36
      cmp  #$58
      bne  :+
      lda  $8B
      cmp  #$FF
      bne  :+
      lda  $8C
      cmp  #$7F
      bne  :+
      sec
      rts
:     clc
      rts

WEEED:
      ldx  #$A0
      ldy  #$46
      sty  $A3
      stx  $A4
      ldx  #$50
      ldy  #$3C
      jmp  _enable_fcbank0

WEEFC:
      ldx  #$50
      ldy  #$3C
      lda  #$02
      jsr  _enable_fcbank0
      ldx  #$A0
      ldy  #$46
      rts

      sec
      lda  $B4
      sbc  $C000
      sta  $9F
      sec
      lda  $B6
      sbc  $C001
      sta  $96
      rts

      lda  #$4B
      jsr  $1ECD
      jsr  $1EDC
      lda  #$08
      jsr  _enable_fcbank0
      ; ????
      ldx  #$51
      ldy  #$3D
      lda  #$02
      jsr  _enable_fcbank0
      ldx  #$9E
      ldy  #$44
      lda  #$06
      jsr  _enable_fcbank0
      ldx  #$50
      ldy  #$3C
      stx  $C000
      sty  $C001
      ldx  #$EE
      ldy  #$0F
WEF48:
      lda  #$23
      jsr  _enable_fcbank0
      ldx  $C014
      ldy  $C015
      bne  WEF48
      ; ?????
      ldx  #$5F
      ldy  #$53
      lda  #$02
      jsr  _enable_fcbank0
      ldx  #$82
      ldy  #$0A
      lda  #$09
      jsr  _enable_fcbank0
      jsr  $1EDC
      lda  #$09
      jsr  _enable_fcbank0
      jsr  $1F5C
      lda  #$4C
      jsr  $1ECD
      lda  #$00
      sta  $C6
      rts

WEF7C:
      ldx  #$50
      ldy  #$3C
      stx  $C000
      sty  $C001
@1:   lda  $03C8
      bne  @1
      jsr  $1EEA
      ldx  #$EE
      ldy  #$0F
:     lda  #$22
      jsr  _enable_fcbank0
      lda  #$35
      jsr  _enable_fcbank0
      bcs  :+
      ldx  $C014
      ldy  $C015
      bne  :-
      beq  @1
:     ldy  #$1E
:     lda  $0100,y
      sta  $5790,y
      dey
      bpl  :-
      lda  #$37
      jsr  _enable_fcbank0
      ldy  #$1E
:     lda  $5790,y
      sta  $0100,y
      dey
      bpl  :-
      ldy  #$0F
      lda  ($9B),y
      cmp  #$03
      bne  :+
      lda  $03C8
      sta  $D00D                        ; Position Y sprite 6
      beq  WEF7C
:     sta  $0DC0
      ldy  #$FF
WEFD8:
      iny
      lda  $104E,y
      cmp  #$61
      bcc  :+
      cmp  #$7B
      bcs  :+
      eor  #$20
:     sta  $105F,y
      tax
      bne  WEFD8
      sty  $1070
      rts

      jsr  $1B18
      txa
      bne  :+
      jsr  $10F0
      jsr  $19EF
:     rts

      jmp  $1B21

.segment "mysterybytes3"

      .byte $00, $00, $00, $00, $00 
      .byte $00, $00, $00, $00, $00, $00, $00, $00 
      .byte $00, $00, $00, $00, $00, $00, $00, $00 
      .byte $00, $00, $00, $00, $00, $00, $00, $00 
      .byte $00, $00, $00, $00, $00, $00, $00, $00 
      .byte $00, $00, $00, $00, $00, $00, $00, $00 
      .byte $00, $00, $00, $00, $00, $00, $00, $00 
      .byte $00, $00, $00, $00, $00, $00, $00, $00 
      .byte $00, $00, $00, $00, $00, $00, $00, $00 
      .byte $00, $00, $00, $00, $00, $00, $00, $00 
      .byte $00, $00, $00, $00, $00, $00, $00, $00 
      .byte $00, $00, $00, $00, $00, $00, $00, $00 
      .byte $00, $00, $00, $00, $00, $00, $00, $00 
      .byte $00, $00, $00, $00, $00, $00, $00, $00 
      .byte $00, $00, $00, $00, $00, $00, $00, $00 
      .byte $00, $00, $00, $00, $00, $00, $00, $00 
      .byte $00, $00, $00, $00, $00, $00, $00, $00 
      .byte $00, $00, $00, $00, $00, $00, $00, $00 
      .byte $00, $00, $00, $00, $00, $00, $00, $00 
      .byte $00, $00, $00, $00, $00, $00, $00, $00 
      .byte $00, $00, $00, $00, $00, $00, $00, $00 
      .byte $33, $33, $33, $33, $33, $33, $33, $33 
      .byte $33, $33, $33, $33, $33, $33, $33, $33 
      .byte $00

.segment "mysterybytes4"
      .byte $00, $00, $00, $00, $FF, $FF, $FF, $FF 
      .byte $00, $00, $00, $00, $FF, $FF, $FF, $FF 
      .byte $00, $00, $00, $00, $FF, $FF, $FF, $FF 
      .byte $00, $00, $00, $00, $FF, $FF, $FF, $FF 
      .byte $00, $00, $00, $00, $FF, $FF, $FF, $FF 
      .byte $00, $00, $00, $00, $FF, $FF, $FF, $FF 
      .byte $00, $00, $00, $00, $FF, $FF, $FF, $FF 
      .byte $00, $00

.segment "mysterybytes5"
      .byte $FF, $FF, $FF, $00, $00, $00, $00, $FF 
      .byte $F7, $FF, $FF, $00, $00, $00, $00, $FF 
      .byte $FF, $FF, $FF, $00, $00, $00, $00, $FF 
      .byte $FF, $FF, $FF, $00, $00, $00, $00, $FF 
      .byte $FF, $FF, $FF, $00, $00, $00, $00, $FF 
      .byte $FF, $FF, $FF, $00, $00, $00, $00, $FF 
      .byte $FF, $FF, $FF, $00, $00, $00, $00, $FF 
      .byte $FF, $FF, $FF, $00, $00, $00, $00, $FF 
      .byte $FF, $FF, $FF, $00, $00, $00, $00, $FF 
      .byte $FF, $FF, $FF, $00, $00
      
