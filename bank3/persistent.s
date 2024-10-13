; ----------------------------------------------------------------
; I/O Area ROM
; ----------------------------------------------------------------
; This is a max. 512 byte section that lives at $1E00-$1FFF of
; bank 0 of the ROM, and will also be mapped into the I/O extension
; area at $DE00-$DFFF, so it's always visible.

; It contains soms trampolines to be able to switch from/to Ultimax
; mode for the freezer and contains the autofire code for the joystick

      .setcpu "6502x"

.include "../core/fc3ioreg.i"
.include "../core/kernal.i"

.import freezer_init
.import freezer_exec_menu
;.import freezer_exec_bank

.segment "romio1l"
;
;
; ROMIO1 area ($DE00)
;
;

fc_bank_id:
      .byte fcio_bank_3|fcio_nmi_line

;
; Jump into a bank of the FC3 ROM
;
; Jumps to a routine in the FC3 ROM of which the address is on the stack
; and the bank number in A.
;

.global _jmp_bank
_jmp_bank:
        sta  fcio_reg
        rts

.global _enable_fcbank0
_enable_fcbank0: ; $DE05
        pha
        lda     #fcio_bank_0|fcio_c64_16kcrtmode|fcio_nmi_line
a_to_fcio_pla:
        sta     fcio_reg
        pla
        rts

; _disable_fc3rom:        Hides the FC3 ROMS from memory
; _disable_fc3rom_set_01: Stores Y into $01 and hides the FC3 ROMS from memory
;

.global _disable_fc3rom_set_01
_disable_fc3rom_set_01:; $DE0D
        sty     $01
.global _disable_fc3rom
_disable_fc3rom: ; $DE0F
        pha
        lda     #fcio_bank_0|fcio_c64_crtrom_off|fcio_nmi_line
        bne     a_to_fcio_pla			; always taken

        ; padding
        .byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte $FF,$FF,$FF,$FF

;
; Do an "lda($AE),y" with ROMs disabled and interrupts off
;

.global load_ae_rom_hidden
load_ae_rom_hidden: ; $de20
        sei
        lda  #$35
        sta  $01
        lda  ($AE),y
        pha
        lda  #$37
        sta  $01
        pla
        cli
        rts

.segment "romio1h"

freezer_upd_sprptr_16k:
      lda  #fcio_bank_3|fcio_c64_16kcrtmode
      sta  fcio_reg
      jsr  $BC40                        ; jump into bank 3
ultimax_bank3_rts:
      lda  #fcio_bank_3|fcio_c64_ultimaxmode
      sta  fcio_reg
      rts

;
; Go to ultimax mode, execute the freezer menu and return to 16K mode
;

.global freezer_ultimax_exec_menu
freezer_ultimax_exec_menu:
      jsr  ultimax_bank3_rts
      jsr  freezer_exec_menu
bank3_16kmode:
      ldx  #fcio_bank_3|fcio_c64_16kcrtmode
      stx  fcio_reg
      rts

;
; Go to 16k mode, execute $bc5b and return to ultimax mode
;

freezer_redirirq_menu:
      jsr  bank3_16kmode
      jsr  $BC5B
      jsr  ultimax_bank3_rts
      jmp  freezer_exec_menu

;
; Go to ultimax mode, execute $fbe4 and return to 16K mode
;

      jsr  ultimax_bank3_rts
      jsr  $FBE4
      jmp  bank3_16kmode

;
; Go to ultimax mode, execute $fb98 and return to 16K mode
;

      jsr  ultimax_bank3_rts
      jsr  $FB98
      jmp  bank3_16kmode


.segment "romio2l"

.global autofire_ldy_dc01
autofire_ldy_dc01:
      pha
      tya
      jsr  autofire_lda_dc01
autofire_ldy_exit:
      tay
      pla
      cpy  #0
      rts

.global autofire_ldx_dc01
autofire_ldx_dc01:
      pha
      txa
      jsr  autofire_lda_dc01
autofire_ldx_exit:
      tax
      pla
      cpx  #0
      rts

.global autofire_ldy_dc00
autofire_ldy_dc00:
      pha
      tya
      jsr  autofire_lda_dc00
      jmp  autofire_ldy_exit

.global autofire_ldx_dc00
autofire_ldx_dc00:
      pha
      txa
      jsr  autofire_lda_dc00
      jmp  autofire_ldx_exit

      cpy  #$01
      beq  autofire_lda_dc01
      bne  autofire_lda_dc00
      cpx  #$01
      beq  autofire_lda_dc01
.global autofire_lda_dc00
autofire_lda_dc00:
      lda  $DC00                        ; Data port A #1: keyboard, joystick, paddle, optical pencil
      jmp  autofire_chkbutton

.global autofire_lda_dc01
autofire_lda_dc01:
      lda  $DC02                        ; Data direction register port A #1
      pha
      lda  #$00
      sta  $DC02                        ; Data direction register port A #1
      lda  $DC01                        ; Data port B #1: keyboard, joystick, paddle
      sta  $0122                        ; Save to tmp location in stack memory
      pla
      sta  $DC02                        ; Data direction register port A #1
      lda  $0122                        ; Load from tmp location
      pha
      and  #$10                         ; Fire button pressed?
      beq autofire_button_pressed
      pla
      lda  $DC01                        ; Data port B #1: keyboard, joystick, paddle
      rts

      lda  $0122
autofire_chkbutton:
      pha
      and  #$10                         ; Fire button pressed?
      beq  autofire_button_pressed
pla_rts:
      pla
      rts

autofire_button_pressed:
      lda  $0120
      bne  autofire_signal
      dec  $0121
      bne  pla_rts
      lda  #$02 
      sta  $0120
      sta  $0121
      bne  pla_rts                      ; Always
autofire_signal:
      dec  $0121
      beq  autofire_signal_press
      pla
      ora  #$10                         ; Unpress the button
      rts

autofire_signal_press:
      lda  #$00
      sta  $0120
      lda  #$01
      sta  $0121
      pla
      rts

.global freezer_set_c64and_fc3_rts
freezer_set_c64and_fc3_rts:
      sta  fcio_reg
      sty  $01
      rts

      .segment "romio2h"

t_freezer_init:
      stx  fcio_reg
      sta  $DD0D                        ; Interrupt control register CIA #2
      jmp  freezer_init                 ; Continue freezer init in 16K crt mode

bank1_jump:
      lda  #fcio_bank_1 | fcio_c64_crtrom_off |fcio_nmi_line ; goto_desktop
      sta  fcio_reg                     ; Execution continues in bank 1
reset_c64:
      jmp  START                        ; Routine: Startup

