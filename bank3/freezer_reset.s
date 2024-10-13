;*****************************************************************************
;  Final Cartridge III reconstructed source code
;
;  This file implements the functions of the reset menu of the freezer
;*****************************************************************************

      .setcpu "6502x"

.include "../core/kernal.i"
.include "../core/fc3ioreg.i"
.include "persistent.i"

.import _jmp_bank,_enable_fcbank0,_disable_fc3rom_set_01
.importzp __FREEZERZP_START__,__FREEZERZP_SIZE__
.import __freezer_restore_1_LOAD__,__freezer_restore_1_SIZE__
.import __freezer_restore_2_RUN__,__freezer_restore_2_SIZE__
.importzp freezer_mem_a,freezer_mem_a_val,freezer_mem_b,freezer_mem_b_val
.import monitor

.segment "freezer_monitor"

init_load_and_basic_vectors = $8021

.global freezer_goto_monitor
freezer_goto_monitor:
      ldx  #$FF
      txs
      jsr  IOINIT_direct
      jsr  RESTOR_direct
      lda  #$00
      tay
:     sta  $0002,y                      ; Clear zeropage
      sta  $0200,y                      ; Clear $02xx
      iny
      bne  :-
      ldx  #<$A000
      ldy  #>$A000
      jsr  $FD8D                        ; Set top, bottom of memory and screen base
      jsr  CINT_direct
      jsr  $E453                        ; Routine: Set BASIC vectors (case 0x300..case 0x309)
      jsr  $E3BF                        ; Routine: Set USR instruction and memory for BASIC
      lda  #>(monitor-1)
      pha
      lda  #<(monitor-1)
      pha
      lda  #>(init_load_and_basic_vectors-1)
      pha
      lda  #<(init_load_and_basic_vectors-1)
      pha
      jmp  _enable_fcbank0


.segment "freezer_reset"

.global freezer_zero_fill
freezer_zero_fill:
      ldy  #$00
      sty  $AC
      lda  #$08
      sta  $AD
      lda  #$33
      sei
      sta  $01
      tya
:     sta  ($AC),y
      iny
      bne  :-
      inc  $AD
      bne  :-
c64_reset:
      lda  #>(START-1)
      pha
      lda  #<(START-1)
      pha
      lda  #$37
      sta  $01
      jmp  _enable_fcbank0

.global write_mg87_and_reset
write_mg87_and_reset:
      ldx  #sizeof_MG87 - 1
:     lda  MG87,x
      sta  $CFFC,x
      dex
      bpl  :-
      bmi  c64_reset ; always

MG87: .byte "MG87"
sizeof_MG87 = .sizeof(MG87)

      ;
      ; Got to the printer settings menu
      ;
.global freezer_goto_settings
freezer_goto_settings:
      ldy  #__FREEZERZP_SIZE__ - 1
      lda  freezer_mem_a_val
:     sta  (freezer_mem_a),y
      dey
      bpl :-
      ldy  #<__freezer_restore_1_SIZE__ - 1
      lda  freezer_mem_b_val
:     sta  (freezer_mem_b),y
      dey
      bpl  :-
      jmp  $A000

