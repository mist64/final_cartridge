;****************************
;
; This code has to do with creating screenshots. It is copied to $5000
; when a screenshot is printed.
;
;****************************

      .setcpu "6502x"

.include "../core/kernal.i"
.include "../core/fc3ioreg.i"
.include "persistent.i"


.segment "screenshotcode"
      sei
      lda  #<$EA31
      sta  $0314                        ; Vector: Hardware Interrupt (IRQ)
      lda  #>$EA31
      sta  $0315                        ; Vector: Hardware Interrupt (IRQ)
      ldx  #$00
      stx  $D01A                        ; IRQ mask register

      ;
      ; Backup zero page to $7000
      ;
      ldx  #$02
:     lda  $00,x
      sta  $7000,x
      inx
      bne  :-
      ; Hide the FC3
      lda  #fcio_nmi_line | fcio_c64_crtrom_off | fcio_bank_0
      sta  fcio_reg

      lda  $0B21
      and  #$0F
      sta  $0B21
      lda  $0B16
      and  #$10
      asl
      asl
      asl
      sta  $50
      lda  $0B11
      and  #$20
      asl
      asl
      sta  $26
      ;
      ; Swap memory from $0C00..$1BFF with $C000..$CFFF
      ;
      ldy  #$00
      sty  $AC
      sty  $AE
      lda  #$0C
      sta  $AD
      lda  #$C0
      sta  $AF
      ldx  #$10
:     lda  ($AC),y
      pha
      lda  ($AE),y
      sta  ($AC),y
      pla
      sta  ($AE),y
      iny
      bne  :-
      inc  $AD
      inc  $AF
      dex
      bne  :-

      ldx  $0201
      beq  @1
      dex
      beq  @2
      lda  #$40
      .byte $2c                         ; BIT $xxxx, skip next instruction
@1:
      lda #$80
      .byte $2c                         ; BIT $xxxx, skip next instruction
@2:
      lda #$00
      sta  $3C
      lda  #$00
      ldx  $0202
      bne  :+
      lda  #$80
:     sta  $36
      lda  #$00
      ldx  $0203
      beq  :+
      lda  #$80
:     sta  $35
      ldx  $0204
      inx
      stx  $31
      ldx  $0205
      inx
      stx  $32
      lda  #$00
      ldx  $0206
      cpx  #$06
      bcc  :+
      lda  #$80
:     sta  $37
      lda  tabel1,x
      sta  $30
      lda  $0207
      beq  :+
      lda  #$FF
:     sta  $25
      ldx  #$08
      bit  $3C
      bpl  @4
      dex
      lda  #$E0
      ldy  #$01
      bit  $36
      bpl  :+
      lda  #$80
      ldy  #$02
:     sta  $40
      sty  $41
      lda  #$FF
      sta  $46
@4:   stx  $3D
      lda  $31
      bit  $35
      bpl  :+
      lda  $32
:     sta  $29
      bit  $36
      bmi  :+
      jsr  routine1
:     bit  $35
      bmi  @3
      jsr  routine2
      jsr  routine3
      jsr  routine4
      jsr  routine5

@map_in_bank_2:
      ; Map in FC3 bank 2
      lda  #fcio_nmi_line | fcio_bank_2
      sei
      sta  fcio_reg
      lda  #<$DE21
      sta  $0314
      lda  #>$DE21
      sta  $0315


      ;
      ; Swap memory from $0C00..$1BFF with $C000..$CFFF
      ;
      ldy  #$00
      sty  $AC
      sty  $AE
      lda  #$0C
      sta  $AD
      lda  #$C0
      sta  $AF
      ldx  #$10
:     lda  ($AC),y
      pha
      lda  ($AE),y
      sta  ($AC),y
      pla
      sta  ($AE),y
      iny
      bne  :-
      inc  $AD
      inc  $AF
      dex
      bne  :-

      ;
      ; Copy to $7000 back to zero page
      ;
      ldx  #$02
:     lda  $7000,x
      sta  $00,x
      inx
      bne  :-
      inx
      stx  $D01A                        ; IRQ mask register
      cli
      rts

@3:   jsr  routine4
      jsr  routine3
      jsr  routine2
      jsr  routine6
      jmp  @map_in_bank_2

routine2:
      ldx  $32
      lda  #$C8
      sta  $33
      lda  #$00
      sta  $34
@1:   dex
      beq  _rts
      lda  $33
      clc
      adc  #$C8
      sta  $33
      lda  $34
      adc  #$00
      sta  $34
      jmp  @1

routine4:
      ldx  $31
      lda  #$40
      sta  $33
      lda  #$01
      sta  $34
@1:   dex
      beq  _rts
      lda  $33
      clc
      adc  #$40
      sta  $33
      lda  $34
      adc  #$01
      sta  $34
      jmp  @1

_rts: rts

routine3:
      ldx  #$00
      stx  $43
      stx  $44
      ldx  $33
      ldy  $34
:     sec
      stx  $45
      txa
      sbc  #$07
      tax
      tya
      sbc  #$00
      tay
      bcc  :+
      inc  $43
      bne  :-
      inc  $44
      bne  :-
:     lda  #$00
      ldx  $45
      beq  @1
:     sec
      rol
      dex
      bne  :-
@1:   sta  $45
      rts


routine21:
      lda  $43
      bne  :+
      dec  $44
      bpl  :+
      rts
:     dec  $43
      lda  $43
      ora  $44
      bne  :+
      lda  $45
      sta  $46
:     lda  #$00
      rts

print_digit_at_17:
      ldy  #$11
      .byte $2c
print_digit_at_18:
      ldy #$12
      eor  #$30
      pha
      clc
      jsr  PLOT
      pla
      jmp  BSOUT

routine1:
      lda  #$00
      tay
      sta  $48
      ldx  #>$6000
      stx  $49
      ldx  #$0B
:     sta  ($48),y
      iny
      bne  :-
      inc  $49
      dex
      bne  :-

      ldx  $32
:     clc
      adc  $31
      dex
      bne  :-
      stx  $52
      ldx  #$04
      pha
:     asl
      rol  $52
      dex
      bne  :-
      sta  $51
      pla
      asl
      sta  $47
      ldx  #$00
      stx  $3B
      ldx  #$04
:     asl
      rol  $3B
      dex
      bne  :-
      clc
      adc  #$00
      sta  $3A
      lda  $3B
      adc  #$60
      sta  $3B
      ldx  #$0F
@2:   lda  tabel4,x
      tay
      beq  @3
      lda  #$00
      sta  $48
      sta  $49
@1:   clc
      adc  $47
      sta  $48
      bcc  :+
      inc  $49
:     dey
      bne  @1
      ldy  #$04
:     lsr  $49
      ror
      dey
      bne  :-
@3:   sta  end_of_text,x
      dex
      bpl  @2
      ldy  #$0F
@5:   lda  end_of_text,y
      beq  @4
      jsr  routine7
:     lda  #$01
      sta  ($48),y
      jsr  routine8
      dex
      beq  @4
      lda  #$01
      sta  ($53),y
      jsr  routine9
      dex
      bne  :-
@4:   dey
      bpl  @5
      lda  $31
      asl
      asl
      asl
      asl
      ldx  #$10
      bit  $35
      bpl  :+
      tax
      lda  #$10
:     sta  $27
      stx  $28
      rts

routine7:
      sta  $11
      lda  #$00
      sta  $48
      clc
      adc  $51
      sta  $53
      lda  #$60
      sta  $49
      adc  $52
      sta  $54
      sec
      lda  $3A
      sbc  $53
      sta  $53
      lda  $3B
      sbc  $54
      lsr
      sta  $54
      ror  $53
      lda  $53
      and  #$F0
      clc
      adc  #$00
      sta  $53
      lda  #$60
      adc  $54
      sta  $54
      clc
      lda  $53
      adc  $51
      sta  $53
      lda  $54
      adc  $52
      sta  $54
      ldx  #$00
      stx  $39
      lda  $47
      dex
:     sec
      inx
      sta  $10
      sbc  $11
      bcs  :-
      lda  $10
      beq  :+
      inx
:     txa
      ldx  #4
:     asl
      rol  $39
      dex
      bne  :-
      sta  $38
      lda  $39
      ldx  $11
      rts

routine8:
      clc
      lda  $48
      adc  #$10
      sta  $48
      lda  $49
      adc  #$00
      sta  $49
      rts

routine9:
      clc
      lda  $53
      adc  #$10
      sta  $53
      lda  $54
      adc  #$00
      sta  $54
      lda  $53
      cmp  $3A
      lda  $54
      sbc  $3B
      bcc  :+
      lda  #$00
      clc
      adc  $51
      sta  $53
      lda  #$60
      adc  $52
      sta  $54
:     rts

routine11:
      ldy  #$00
      sty  $48
      sty  $49
      rts

routine38:
      inc  $48
      bne  :+
      inc  $49
:     lda  $48
      cmp  #$80
      lda  $49
      sbc  #$02
      rts

W981C:
      jsr  routine10
      jsr  routine11
LL3:  jsr  routine12
:     jsr  routine13
      jsr  routine14
      bcc  @1
      jsr  routine15
      jsr  routine17
      bne  :-
      jsr  routine38
      bcs  W534E
@1:   jsr  routine37
      bne  LL3
      jsr  routine23
      lda  $DC01                        ; Data port B #1: keyboard, joystick, paddle
      cmp  #$7F
      beq  W534E
      jsr  routine24
      bne  LL3
W534E:
      jsr  W9D4D
      lda  #$01
      ldy  #$0A
      jsr  routine22
      lda  #$0D
      jsr  BSOUT
      jmp  W9D4D

routine5:
      jsr  routine20
      jsr  routine39
      bit  $3C
      bpl  W986E
      bit  $36
      bmi  W981C
W986E:
      bit  $36
      bpl  :+
      lda  #$0A
      jsr  BSOUT
:     lda  $06
      sta  $07
      lda  #$00
      sta  $10
W987F:
      lda  #$00
      sta  $11
W9883:
      lda  $10
      jsr  routine32
      jsr  routine12
W988B:
      jsr  routine36
      lda  $07
      sta  $06
      jsr  routine10
@4:   jsr  routine13
      jsr  routine37
      bne  :+
      jsr  routine23
:     inx
      cpx  $3D
      bne  @4
      jsr  routine31
      beq  :+
      lda  $C2
      cmp  #$FD
      bcc  @4
:     jsr  routine14
      bcc  @1
      jsr  routine29
@1:   jsr  routine17
      bne  W988B
      bit  $36
      bpl  @2
      inc  $11
      lda  $11
      cmp  #$02
      bne  W9883
      inc  $10
      lda  $10
      cmp  #$07
      bne  W987F
@2:   jsr  routine35
      bit  $3C
      bpl  @3
      jsr  routine21
      bpl  W986E
      bmi  W98E5
@3:   lda  $C4
      cmp  #$FD
      bcc  W986E
W98E5:
      jsr  routine28
      bit  $36
      bpl  :+
      lda  #'r'
      jsr  routine27
      lda  #$00
      jsr  BSOUT
:     jmp  $5835

routine24:
      inc  $02
      lda  $02
      cmp  #$C8
      rts

W9900:
      sty  $09
      jsr  routine11
W9905:
      jsr  routine10
      jsr  routine12
      sty  $02
      ldy  $09
:     jsr  routine13
      jsr  routine14
      bcc  :+
      jsr  routine15
      jsr  routine16
      jsr  routine24
      bcc  :-
:     jsr  routine38
      bcs  :+
      lda  $DC01                        ; Data port B #1: keyboard, joystick, paddle
      cmp  #$7F
      beq  :+
      jsr  routine30
      bne  W9905
      jsr  routine17
      sty  $09
      bne  W9905
:     jmp  W534E

routine6:
      jsr  routine20
      jsr  routine40
      ldy  #$00
      bit  $3C
      bpl  :+
      bit  $36
      bmi  W9900
W994D:
:     sty  $09
      lda  $03
      sta  $05
      lda  $06
      sta  $07
      bit  $36
      bpl  @4
      lda  #$0A
      jsr  BSOUT
      lda  #$00
      sta  $10
@3:
      lda  #$00
      sta  $11
@4:
      lda  $10
      jsr  routine32
      jsr  routine10
      jsr  routine12
      sty  $02
@2:   ldy  $09
      lda  $05
      sta  $03
      lda  $07
      sta  $06
      jsr  $54D4
@1:   jsr  routine13
      jsr  routine30
      bne  :+
      jsr  routine17
:     inx
      cpx  $3D
      bne  @1
      jsr  routine31
      beq  :+
      cpy  #$A0
      bcc  @1
:     jsr  routine14
      bcc  :+
      jsr  routine29
:     jsr  routine16
      jsr  routine24
      bne  @2
      bit  $36
      bpl  :+
      inc  $11
      lda  $11
      cmp  #$02
      bne  @4
      inc  $10
      lda  $10
      cmp  #$07
      bne  @3
:     bit  $3C
      bpl  :+
      jsr  routine21
      bpl  W994D
      bmi  W99D1
:     cpy  #$A0
      bcs  W99D1
      jmp  W994D

W99D1:
      jmp  W98E5

routine36:
      lda  #$00
      ldx  #$1A
:     sta  $0B30,x
      dex
      bpl  :-
      ldx  #$03
:     sta  $38,x
      dex
      bne  :-
      stx  $38
      rts

routine31:
      bit  $36
      bmi  W9A11
      bit  $50
      bpl  W9A0C
      tya
      pha
      ldy  #$00
      ldx  $38
:     lda  $0053,y
      eor  $25
      jsr  routine18
      sta  $0B30,x
      inx
      iny
      cpy  $29
      bne  :-
      pla
      tay
      jmp  W9A1F

W9A0C:
      lda  $9E
      eor  $25
W9A10:
      .byte $2c
W9A11:
      lda  $9E
      jsr  routine18
      pha
      lda  $38
      and  #$03
      tax
      pla
      sta  $39,x
W9A1F:
      lda  $37
      beq  @x
      ldx  #$00
      lda  $38
      clc
      adc  #$09
      sta  $38
      cmp  #$1B
@x:   rts

routine18:
      bit  $3C
      bpl  @x
      stx  $24
      ldx  #7
      sta  $9E
:     lsr  $9E
      rol
      dex
      bne  :-
      and  $46
      ora  #$80
      ldx  $24
@x:   rts

routine29:
      bit  $36
      bmi  routine15
      bit  $50
      bpl  routine15
@1:   lda  $0B2F,x
      jsr  BSOUT
      bit  $37
      bpl  :+
      lda  $0B38,x
      jsr  BSOUT
      lda  $0B41,x
      jsr  BSOUT
:     dex
      bne  @1
      rts

routine15:
      lda  $39
      jsr  BSOUT
      bit  $37
      bpl  :+
      lda  $3A
      jsr  BSOUT
      lda  $3B
      jsr  BSOUT
:     dex
      bne  routine15
      rts

routine12:
      ldy  #$00
      sty  $3E
      sty  $3F
      rts

routine14:
      lda  $29
      sta  $42
      bit  $3C
      bpl  @1
      lda  $40
      sec
      sbc  $3E
      tax
      lda  $41
      sbc  $3F
      bcc  @rts
      pha
      lda  $3E
      clc
      adc  $42
      sta  $3E
      bcc  :+
      inc  $3F
:     pla
      bne  @1
      clc
      txa
      beq  @rts
      cpx  $42
      bcc  @2
@1:   ldx  $42
@2:   sec
@rts: rts

routine40:
      ldy  #$60
      lda  #$7C
      ora  #$80
      bne  :+
routine39:
      ldy  #$00
      lda  #$80
:     sty  $C3
      sta  $C4
      ldx  #$00
      stx  $02
      stx  $03
      stx  $05
      stx  $06
      dex
      stx  $04
      rts

      lda  $AF
      jsr  W9AE3
      sta  $AF
      lda  $AE
      jsr  W9AE3
      sta  $AE
      lda  $9E
W9AE3:
      bit  $3C
      bpl  reverse_bits_A
      lsr
      and  $04
      ora  #$80
      rts

reverse_bits_A:
      pla
      sta  $FD
      ldx  #8
:     lsr  $FD
      rol
      dex
      bne  :-
      rts

routine37:
      inc  $06
      lda  $06
      cmp  $32
      bcc  :+
      lda  #$00
      sta  $06
:     rts

routine30:
      inc  $06
      lda  $06
      cmp  $31
      bcc  :+
      lda  #$00
      sta  $06
:     rts

      bit  $50
      bmi  W9B1F

routine17:
      lda  $03
      eor  #$10
      sta  $03
      bne  W9B20
W9B1F:
      iny
W9B20:
      cpy  #$A0
      rts

W9B23:
      tax
      lda  tabel2,x
      sta  $39
      rts

tabel2:
      .byte $00,$01,$04,$03,$04,$05,$06,$07
      .byte $02,$02,$02,$00,$01,$05,$03,$01

W9B3A:
      bit  $3C
      bmi  W9B23
      ldx  $11
      beq  @1
      tax
      lda  tabel3,x
      cmp  $10
      sec
      bcs  @2
@1:   tax
      lda  tabel3+$10,x
      cmp  $10
      sec
@2:   beq  :+
      clc
:     rol  $9E
      rts

tabel3:
      .byte $00, $10, $01, $02, $01, $06, $02, $04
      .byte $05, $01, $01, $10, $10, $06, $02, $10
      .byte $10, $10, $01, $10, $02, $06, $02, $10
      .byte $10, $00, $10, $10, $10, $10, $10, $10


routine13:
      sei
      lda  #$34                         ; Disable ROM
      sta  $01
      tya
      pha
      txa
      pha
      lda  $03
      cmp  #$10
      lda  ($C1),y
      bcc  :+
      lsr
      lsr
      lsr
      lsr
:     and  #$0F
      jsr  routine25
      lda  #$37                         ; Enable ROM
      sta  $01
      pla
      tax
      pla
      tay
      cli
      rts

routine25:
      bit  $36
      bmi  W9B3A
      bit  $50
      bpl  W9BEB
      pha
      lda  #$00
      sta  $48
      lda  #$60
      sta  $49
      lda  $03
      beq  :+
      lda  $48
      clc
      adc  $51
      sta  $48
      lda  $49
      adc  $52
      sta  $49
:     ldx  $06
      beq  @3
@1:   lda  $48
      clc
      adc  $27
      sta  $48
      bcc  :+
      inc  $49
:     dex
      bne  @1
@3:   pla
      tay
      ldx  $29
@2:   lda  ($48),y
      clc
      beq  :+
      sec
:     rol  $52,x
      lda  $48
      clc
      adc  $28
      sta  $48
      bcc  :+
      inc  $49
:     dex
      bne  @2
      rts

W9BEB:
      bit  $26
      bpl  @3
      sta  $51
      lda  #$00
      sta  $48
      lda  #$40
      sta  $49
@1:   sec
      sbc  #$05
      bcc  @2
      pha
      clc
      lda  $48
      adc  #$28
      sta  $48
      bcc  :+
      inc  $49
:     pla
      jmp  @1
@2:   tya
      lsr
      lsr
      tay
      lda  ($48),y
      and  #$0F
      cmp  $51
      clc
      bcc  @4
@3:   cmp  $0B21
      clc
@4:   beq  :+
      sec
:     rol  $9E
      rts


routine35:
      lda  $C1
      sta  $C3
      lda  $C2
      sta  $C4
      rts

routine10:
      lda  $C3
      sta  $C1
      lda  $C4
      sta  $C2
      rts

routine23:
      lda  $C1
      clc
      adc  #$A0
      sta  $C1
      bcc  :+
      inc  $C2
:     rts

routine16:
      lda  $C1
      sec
      sbc  #$A0
      sta  $C1
      bcs  :+
      dec  $C2
:     rts

routine20:
      jsr  routine34
      bcs  W9C8A
      bit  $3C
      bmi  W9C7D
      bvc  W9C69
      lda  #$1C
      jsr  BSOUT
      lda  #'3'
      jsr  BSOUT
      lda  #'/'
      jmp  BSOUT

W9C69:
      lda  #'3'
      jsr  routine27
      lda  #$17
      jsr  BSOUT
      lda  #'A'
      jsr  routine27
      lda  #$08
      jmp  BSOUT

W9C7D:
      bit  $36
      bmi  W9C8F
      lda  #$08
W9C83:
      jmp  BSOUT

routine28:
      lda  #$0D
      bne  W9C83
W9C8A:
      pla 
      pla
      jmp  W9D4D

W9C8F:
      lda  #'C'
      jsr  routine27
      bit  $35
      bpl  :+
      jsr  routine26
      jmp  routine19
:     jsr  routine19

routine26:
      lda  $32
      ldx  #'2'
      ldy  #'0'
      cmp  #$01
      beq  out_2c0
      ldx  #'4'
      cmp  #$02
      beq  out_2c0
      ldx  #'6'
      cmp  #$03
      beq  out_2c0
      ldy  #'4'
      bne  out_2c0

routine19:
      lda  $31
      ldx  #'3'
      ldy  #'2'
      cmp  #$01
      beq  out_2c0
      ldx  #'6'
      ldy  #'4'
out_2c0:
      txa
      jsr  BSOUT
      tya
      jsr  BSOUT
      lda  #'0'
      jmp  BSOUT

routine27:
      pha
      lda  #$1B
      jsr  BSOUT
      pla
      bne  W9C83
routine32:
      bit  $36
      bpl  :+
      pha
      lda  #'r'
      jsr  routine27
      pla
      jsr  BSOUT
:     lda  $DC01
      cmp  #$7F
      beq  W9D33
      jsr  routine28
      bit  $3C
      bmi  W9D55
      lda  $30
      cmp  #$04
      bcs  W9D1F
      lda  $DC0C
      beq  :+
      cmp  #$37
      bcs  :+
      cmp  #$30
      bcs  W9D1F
:     lda  $30
      cmp  #$02
      bcs  W9D17
      adc  #$4B
      .byte $2C                         ; Skip next instruction
W9D17:
      adc  #$56
      jsr  routine27
      jmp  W5829

W9D1F:
      lda  #'*'
      jsr  routine27
      lda  $30
      jsr  BSOUT
W5829:
      lda  $33
      jsr  BSOUT
      lda  $34
      jmp  BSOUT

W9D33:
      pla
      pla
      jsr  routine28
      bit  $3C
      bmi  W9D48
      bit  $36 
      bpl  W9D4D
      lda  #'r'
      jsr  routine27
      lda  #$00
      .byte $2C                         ; Skip next instruction
W9D48:
      lda  #$0F
      jsr  BSOUT
W9D4D:
      jsr  CLALL
      lda  #$01
      jsr  CLOSE
W9D55:
      rts

routine34:
      lda  #$01
      ldy  #$01
      bit  $3C
      bpl  :+
      dey
routine22:
:     ldx  #4                           ; Device 4 = printer
      jsr  SETLFS

      lda  #0
      jsr  SETNAM
      jsr  OPEN
      ldx  #1
      jmp  CKOUT

tabel1:
      .byte $00, $01, $02, $03, $04, $06, $20, $21 
      .byte $26, $27

tabel4:
      .byte $10, $00, $0B, $03, $09, $05 
      .byte $0D, $01, $0A, $0E, $06, $0C, $07, $02 
      .byte $08, $04

end_of_text:
