;*****************************************************************************
;  Final Cartridge III reconstructed source code
;
;  This file implements the functions of the game menu of the freezer
;*****************************************************************************

      .setcpu "6502x"

.include "../core/kernal.i"
.include "../core/fc3ioreg.i"
.include "persistent.i"

.import _jmp_bank,_enable_fcbank0,_disable_fc3rom_set_01
.import freezer_set_c64and_fc3_rts
.import freezer_ultimax_exec_menu
.import autofire_lda_dc01,autofire_ldx_dc01,autofire_ldy_dc01
.import autofire_lda_dc00,autofire_ldx_dc00,autofire_ldy_dc00
.import __romio2l_RUN__
.importzp __FREEZERZP_START__,__FREEZERZP_SIZE__
.import __tape_backup_loader_LOAD__,__tape_backup_loader_SIZE__
.import __disk_backup_loader_LOAD__,__disk_backup_loader_SIZE__
.importzp __zp_load_mem_1_RUN__,__zp_load_mem_2_RUN__
.import __freezer_restore_1_LOAD__,__freezer_restore_1_SIZE__
.import __freezer_restore_2_RUN__,__freezer_restore_2_SIZE__
.import __memswap_LOAD__
.importzp __memswap_RUN__,__memswap_SIZE__
.importzp tmpptr_a,tmpvar1

.segment "freezer_game_swap"

swap_8000_4000:
      ldy  #$80                         ; Swap from $8000
      .byte $2c                         ; bit $xxxx (3 byte nop)
swap_c000_4000:
      ldy #$c0
      ldx  #__memswap_SIZE__-1
:     lda  __memswap_LOAD__,x
      sta  __memswap_RUN__,x
      dex
      bpl  :-
      sty  <(swap_zpcode_ptr2+1)
      ldx  #$40                         ; Number of pages
      lda  #$34                         ; Hide ROM
      ldy  #$00
      sei
      jmp  swap_zpcode

.segment "memswap":zeropage
.proc swap_zpcode
      sta  $01
:     lda  (ptr1),y                     ; load a byte from $4000+
      pha                               ; and save to stack
      lda  (ptr2),y                     ; load a byte from $8000+ or $c000+
      sta  (ptr1),y                     ; store into $4000x
      pla                               ; restore saved byte
      sta  (ptr2),y                     ; save into $8000+ or $c000+
      iny                               ; inc low byte
      bne  :-
      inc  <(ptr1+1)                    ; inc high byte of $4000 pointer
      inc  <(ptr2+1)                    ; inc high byte of $8000/$c000 pointer
      dex                               ; dec page counter
      bne  :-                           ; loop until all pages have been swapped
      lda  #$37                         ; BASIC, KERNAL and IO visible
      sta  $01
      rts
ptr1: .word $4000
ptr2: .word $8000
.endproc

swap_zpcode_ptr2 = swap_zpcode::ptr2    ; Necessary because ca65 only knows scope after it has been defined.

.segment "freezer_game"

      ; These are the opcodes for
      ; lda absolute
      ; ldx absolute
      ; ldy absolute
      ; lda absolute,x
      ; lda absolute,y
load_abs_opcodes:      .byte $ad,$ae,$ac,$bd,$b9

      ; These are the opcodes for
      ; lda #imm
      ; ldx #imm
      ; ldy #imm
load_imm_opcodes:      .byte $a9,$a2,$a0
autofire_traps:
      .byte <autofire_lda_dc01,<autofire_ldx_dc01,<autofire_ldy_dc01
      .byte <autofire_lda_dc00,<autofire_ldx_dc00,<autofire_ldy_dc00
      .byte $2a,$24

.global freezer_joyswap
freezer_joyswap:
      jsr  joyswap_patch_code_0200
      jsr  swap_8000_4000
      jsr  joyswap_patch_code_4000
      jsr  swap_8000_4000
      jsr  swap_c000_4000
      jsr  joyswap_patch_code_4000
      jsr  swap_c000_4000
      ldy  #$35
      jmp  _disable_fc3rom_set_01

.global freezer_autofire
freezer_autofire:
      jsr  autofire_patch_code_0200
      jsr  swap_8000_4000
      jsr  autofire_patch_code_4000
      jsr  swap_8000_4000
      jsr  swap_c000_4000
      jsr  autofire_patch_code_4000
      jsr  swap_c000_4000
      lda  #$02
      sta  $0120
      sta  $0121
      lda  #fcio_c64_crtrom_off|fcio_nmi_line|fcio_bank_3
      ldy  #$35                         ; ROM hidden, I/O visible
      jmp  freezer_set_c64and_fc3_rts

.global freezer_sprite_I,freezer_sprite_II
freezer_sprite_I:
      lda  #$1E
      .byte $2c
freezer_sprite_II:
      lda #$1F
      sta  tmpvar1
      jsr  sprite_patch_code_0200
      jsr  swap_8000_4000
      jsr  sprite_patch_code_4000
      jsr  swap_8000_4000
      jsr  swap_c000_4000
      jsr  sprite_patch_code_4000
      jsr  swap_c000_4000
      ldy  #$35                         ; IO only
      jmp  _disable_fc3rom_set_01

autofire_patch_code_0200:
      lda  #$02                         ; High byte of start pointer
      .byte $2c                         ; bit $xxxx (3 byte nop)
autofire_patch_code_4000:
      lda  #$40                         ; High byte of start pointer
      sta  tmpptr_a+1
      ldy  #$00                         ; Low byte of start pointer
      sty  tmpptr_a
@1:   ldx  #.sizeof(load_abs_opcodes)
      ldy  #0
      lda  (tmpptr_a),y                 ; Load a byte from RAM
:     dex                               ; All opcodes checked?
      bmi  @4                           ; Then jump to prepare for next byte
      cmp  load_abs_opcodes,x           ; Compare with an opcode
      bne  :-                           ; Not equal, then next opcpde
      ; Byte matches a load opcode
      iny
      lda  (tmpptr_a),y                 ; Load next byte from RAM (should be low byte of absolute address)
      beq  @2                           ; 0? CIA port A is low byte $00.
      cpx  #$03                         ; Was it a load with index?
      bcs  @4                           ; If yes, it's not what we are looking for
      cmp  #$01                         ; 1? CIA port B is low byte $01
      bne  @4
@2:   sta  tmpvar1                      ; Store low byte
      iny
      lda  (tmpptr_a),y                 ; Load next byte from RAM (should be high byte of absolute address)
      cmp  #$DC                         ; $DCxx is CIA 1
      bne  @4
      ldy  #$00                         ; Point back to opcode
      lda  #$20                         ; Opcode of JSR absolute
      sta  (tmpptr_a),y                 ; Replace opcode with JSR (code will JSR into trap)
      iny
      lda  tmpvar1                      ; Restore low byte
      bne  @3                           ; If 1 then no need to add table index
      ; It was a load from CIA port A
      txa
      clc
      adc  #3                           ; Traps for port A start at 3 in table
      tax
@3:   lda  autofire_traps,x             ; Load low byte of pointer to trap
      sta  (tmpptr_a),y                 ; Patch into instruction
      iny
      lda  #>__romio2l_RUN__            ; $DFxx
      sta  (tmpptr_a),y                 ; Patch into instruction
@4:
      inc  tmpptr_a                     ; inc low byte of pointer
      bne  @1
      inc  tmpptr_a+1                   ; inc high byte of pointer
      lda  tmpptr_a+1
      cmp  #$80                         ; cartridge rom starts at $8000
      bcc  @1                           ; when we arrive here, stop scanning
      rts

joyswap_patch_code_0200:
      lda  #$02                         ; High byte of start pointer
      .byte $2c                         ; bit $xxxx (3 byte nop)
joyswap_patch_code_4000:
      lda  #$40                         ; High byte of start pointer
      sta  tmpptr_a+1
      lda  #$00                         ; Low byte of start pointer
      sta  tmpptr_a
@1:   ldx  #$03                         ; Check 3 opcodes
      ldy  #0
      lda  (tmpptr_a),y                 ; Load a byte from RAM
@2:   dex
      bmi  @3
      cmp  load_abs_opcodes,x
      bne  @2
      iny
      lda  (tmpptr_a),y                 ; Load next byte from RAM (should be low byte of absolute address)
      sta  tmpvar1                      ; Store low byte
      cmp  #$04
      bcs  @3
      iny
      lda  (tmpptr_a),y                 ; Load next byte from RAM (should be high byte of absolute address)
      cmp  #$DC                         ; $DCxx is CIA 1
      bne  @3
      dey
      lda  tmpvar1                      ; Restore low byte
      eor  #$01                         ; Swap $dc01 with $dc00 to swap joystick port
      sta  (tmpptr_a),y                 ; Patch into instruction
@3:   inc  tmpptr_a
      bne  @1
      inc  tmpptr_a+1
      lda  tmpptr_a+1
      cmp  #$80                         ; cartridge rom starts at $8000
      bcc  @1                           ; when we arrive here, stop scanning
      rts

sprite_patch_code_0200:
      lda  #$02                         ; High byte of start pointer
      .byte $2c                         ; bit $xxxx (3 byte nop)
sprite_patch_code_4000:
      lda #$40                          ; High byte of start pointer
      sta  tmpptr_a+1
      lda  #$00                         ; Low byte of start pointer
      sta  tmpptr_a
@1:   ldx  #$03                         ; Check 3 opcodes
      ldy  #0
      lda  (tmpptr_a),y                 ; Load a byte from RAM
@2:   dex
      bmi  @4
      cmp  load_abs_opcodes,x
      bne  @2
      iny
      lda  (tmpptr_a),y                 ; Load next byte from RAM (should be low byte of absolute address)
      cmp  tmpvar1                      ; Is low byte the relevant sprite collision register?
      bne  @4
@3:   iny
      lda  (tmpptr_a),y                 ; Load next byte from RAM (should be high byte of absolute address)
      cmp  #>$D000                      ; $D0xx is VIC-II
      bne  @4
      lda  load_imm_opcodes,x
      ldy  #0
      sta  (tmpptr_a),y                 ; Patch opcode into memory
      tya
      iny
      sta  (tmpptr_a),y                 ; Change into LDx #0
      lda  #$EA                         ; NOP
      iny
      sta  (tmpptr_a),y                 ; Place nop in memory
@4:   inc  tmpptr_a
      bne  @1
      inc  tmpptr_a+1
      lda  tmpptr_a+1
      cmp  #$80
      bcc  @1
      rts

