;*****************************************************************************
;  Final Cartridge III reconstructed source code
;
;  The NMI interruprs handler that is executed in Ultimax mode, switches
;  back to 16K mode and then calls freezer_init in this file. Here the actual
;  freezing is done, then the routine to display the menu is called. The
;  menu code is not inside this file.
;
;  After the user has made a selction from the file menu, control is returned
;  to this file and a jump is made to the routine that executes the command.
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
.import __zp_load_mem_1_LOAD__,__zp_load_mem_1_SIZE__
.import __zp_load_mem_2_LOAD__,__zp_load_mem_2_SIZE__
.importzp __zp_load_mem_1_RUN__,__zp_load_mem_2_RUN__
.import __freezer_restore_1_LOAD__,__freezer_restore_1_SIZE__
.import __freezer_restore_2_RUN__,__freezer_restore_2_SIZE__
.import __memswap_LOAD__
.importzp __memswap_RUN__,__memswap_SIZE__
.import pset
.import freezer_goto_settings,freezer_zero_fill,write_mg87_and_reset
.import freezer_sprite_I,freezer_sprite_II,freezer_autofire,freezer_joyswap
.import freezer_backup_disk,freezer_backup_tape
.import freezer_goto_monitor

.segment "freezer_zeropage":zeropage

.global tmpptr_a,tmpvar1,spritexy_backup
.global freezer_mem_a,freezer_mem_a_val,freezer_mem_b,freezer_mem_b_val

ciareg_backup:      .res 32
tmpvar1:            .res 1
tmpptr_a:           .res 2
tmpvar2:            .res 1
spritexy_backup:    .res 8 ; Backup sprite 2..5 x/y coord ($D004..$D00B)
viciireg_backup:    .res 25
spritecol_backup:   .res 4
spriteptr_backup:   .res 4
colram_backup:      .res 16 ; Back for last 16 bytes of 1st line of colour RAM
zp2345_backup:      .res 4
freezer_mem_a:      .res 2
freezer_mem_a_val:  .res 1
freezer_mem_b:      .res 2
freezer_mem_b_val:  .res 1

.segment "freezer_entry_1"

.global freezer_init
freezer_init:
      ; Install loadram, routine at $0005
      ldx  #$06
:     lda  loadram,x
      sta  $05,x
      dex
      bpl  :-
      ldx  $02A0
      inx
      cpx  $02A2
      bne  :+
      inx
:     stx  $02A1
      ldx  #<$E000
      lda  #>$E000
      ldy  #__FREEZERZP_SIZE__          ; Find some memory for zero page backup
      jsr  freezer_find_memory
      lda  $02
      clc
      adc  #__FREEZERZP_SIZE__
      tax
      lda  $03
      adc  #$00
      ldy  #<__freezer_restore_1_SIZE__
      jsr  freezer_find_memory
      ;
      ; THis is a bit of a weird method... location of first memory region
      ; was not save, so the same block of memory again.
      ;
      ldx  #<$E000
      lda  #>$E000
      ldy  #__FREEZERZP_SIZE__
      jsr  freezer_find_memory
      ldy  #$00
      ; Backup the zeropage area that the freezer will use into the found memory
:     lda  __FREEZERZP_START__,y                      ; Lo Byte #1 (rounding)
      sta  ($02),y
      iny
      cpy  #<__FREEZERZP_SIZE__
      bne  :-

      lda  $02                          ; Low byte of found memory
      sta  freezer_mem_a                ; keep it for later
      lda  $03                          ; High byte of found memory
      sta  freezer_mem_a+1              ; keep it for later
      lda  $04                          ; value of the found memory
      sta  freezer_mem_a_val            ; keep it for later

      ; Save the NMI vector on the stack
      lda  $0318                        ; Vector: Not maskerable Interrupt (NMI)
      pha
      lda  $0319                        ; Vector: Not maskerable Interrupt (NMI)
      pha
      lda  #<temp_nmi_handler
      sta  $0318                        ; Vector: Not maskerable Interrupt (NMI)
      lda  #>temp_nmi_handler
      sta  $0319                        ; Vector: Not maskerable Interrupt (NMI)

      ; Backup the contents of the CIA registers and initalize them with correct
      ; values for the freezer.
      ldx  #$1F
@nextreg:
      lda  $DCF0,x                      ; Backup the cia registers
      sta  ciareg_backup,x
      txa
      and  #$0F
      cmp  #$02                         ; Is it a port DATA register?
      bcc  @dec_loop                    ; Yes, then no backup
      cmp  #$04                         ; Not port data nor ddr register?
      bcs  @1                           ; Then jump to further register tests
      lda  #$FF                         ; Initialize DDRs with $ff
      sta  $DCF0,x
      bne  @dec_loop
@1:
      cmp  #$0E                         ; Is it a timer control register?
      bcc  @2                           ; Then jump to further register tests
      lda  #$10                         ; Initialize control register with $10
      sta  $DCF0,x
@2:
      cmp  #$08                         ; Is it a timer value ?
      bcs  @dec_loop                    ; No, then go on
      cmp  #$04                         ; Is it a timer value ?
      bcc  @dec_loop                    ; No, then go on
      and  #$01                         ; Init both timers with $0001
      eor  #$01
      sta  $DCF0,x
@dec_loop:
      dex
      bpl  @nextreg

      ; Clear interrupt flags of both CIAs by reading from their ICR
      ldx  #$00
      lda  $DCFD,x
      ldx  #$10
      lda  $DCFD,x

      ; The interrupt mask inside the ICR of the CIA cannot be read, because reading the
      ; register has a different meaning. Both CIA's won't be restored on return, but cleared
      lda  #0
      sta  ciareg_backup + $0d
      sta  ciareg_backup + $1d

      ; Handle CIA timers...
      ldx  #$01                         ; Start with timer B
@nexttimer:
      ; Start the timer in one shot mode on both CIAs
      lda  #$19
      sta  $DC0E,x                      ; Control register A of CIA #1
      sta  $DD0E,x                      ; Control register A of CIA #2

      txa
      pha                               ; Push timer number
      asl                               ; Timer number *2
      bne  @3                           ; Jump if timer A
      lda  #$01
@3:
      sta  tmpvar2                      ; 1 for timer A, 2 for timer B
      ldx  #0
      .byte $2c                         ; bit $xxxx, skip next instruction
@nextcia_1:
      ldx #$10
@4:   lda  $DCFD,x                      ; load ICR
      tay
      and  tmpvar2                      ; Wait for timer underflow
      beq  @4
      tya
      bpl  @5                           ; Interrupt occured? No, then @5
      ora  $7D,x                        ; OR ISR into $7D/8D
      sta  $7D,x
@5:   dex
      bmi  @nextcia_1
      pla                               ; Restore cia number
      tax
      dex
      bpl  @nexttimer

      ; Delay loop
      ldy  #0
@6:   inx
      bne  @6
      iny
      bne  @6

      ; X=0
      .byte $2c                         ; bit $xxxx, skip next instruction
@nextcia_2:
      ldx  #$10
      lda  #$7F                         ; Disable all interrupt sources
      sta  $DCFD,x
      ldy  ciareg_backup + $D,x         ; Did an interrupt occur
      bmi  @7                           ; Then skip
      lda  #$7F
      sta  ciareg_backup + $D,x
@7:   dex
      bmi  @nextcia_2

      ; Restore the NMI vector
      pla
      sta  $0319
      pla
      sta  $0318                        ; Vector: Not maskerable Interrupt (NMI)

      ; Value of $dd0e/$dd0f was pushed on stack by NMI handler and set to 0
      ; before the CIA registers could be backed up, so correct this:
      pla
      sta  ciareg_backup + $1f
      pla
      sta  ciareg_backup + $1e

      lda  $04                          ; Value in found memory area
      pha                               ; Save for later
      lda  $02                          ; Lo byte of found memory area
      pha                               ; Save for later
      clc
      adc  #$67
      tax
      lda  $03                          ; Lo byte of found memory area
      pha                               ; Save for later
      adc  #$00
      ; A/X now points to end of found memory area
      ldy  #<__freezer_restore_1_SIZE__
      jsr  freezer_find_memory          ; Find another memory area of $5c bytes
      lda  $02
      sta  freezer_mem_b                ; Store high byte of area
      lda  $03                          ;
      sta  freezer_mem_b+1              ; Store low byte of area
      lda  $04                          ; Value found in memory area
      sta  freezer_mem_b_val            ; Save for later

      ; Install the freezer restore routine in the second memory area found and
      ; do live patching.
      ldy  #<__freezer_restore_1_SIZE__ - 1
:     lda  freezer_restore_mem_cia_vic,y
      sta  ($02),y
      dey
      bpl  :-

      ; Do some live patching of the freezer restore routine
      pla
      ldy  #<(r1 + 2 -__freezer_restore_1_LOAD__)
      sta  ($02),y
      ldy  #<(r2 + 2 -__freezer_restore_1_LOAD__)
      sta  ($02),y
      pla
      dey
      sta  ($02),y
      ldy  #<(r1 + 1 -__freezer_restore_1_LOAD__)
      sta  ($02),y
      pla
      ldy  #<(r3 + 1 -__freezer_restore_1_LOAD__)
      sta  ($02),y
      pla
      sta  tmpptr_a
      pla
      sta  tmpptr_a+1

      lda  $04
      tay
      ldx  #$FF
:     inx
      pla
      sta  $04,x
      cpx  #8
      bne  :-
      ; C=1 because X=8

      tya
      tax
      pla
      ldy  #<(r4 + 1 -__freezer_restore_1_LOAD__)
      sta  ($02),y
      pla
      ldy  #<(r5 + 1 -__freezer_restore_1_LOAD__)
      sta  ($02),y
      txa
      ldy  #<(r6 + 1 -__freezer_restore_1_LOAD__)
      sta  ($02),y

      ; The freezer restore routine will RTS to the
      ; current stack pointer - #$12
      ; C is still 1
      tsx
      lda  #$01
      pha
      txa
      sbc  #$12
      pha

      ; Patch loading the original value of the stack pointer
      tsx
      txa
      ldy  #<(r7 + 1 -__freezer_restore_1_LOAD__)
      sta  ($02),y

      ; Push a small routine on the stack that will overwrite
      ; the restore routine with the original value.
      ldx  #<sizeof_freezer_restore_fill_area - 1
:     lda  freezer_restore_fill_area,x
      pha
      dex
      bpl  :-

      ; push the location of the restore routine
      lda  $03
      pha
      lda  $02
      pha
      lda  #$9D                         ; Opcode for sta absolute,x
      pha

      lda  $D01A                        ; IRQ mask register
      ldy  #<(r8 + 1 -__freezer_restore_1_LOAD__)
      sta  ($02),y
      lda  $D015                        ; Sprites Abilitator
      ldy  #<(r9 + 1 -__freezer_restore_1_LOAD__)
      sta  ($02),y

      ; Disable VIC-II interrupts and ack pending ones
      ldx  #$00
      stx  $D01A                        ; IRQ mask register
      dex
      ldy  #$FF
      sty  $D019                        ; Interrupt indicator register

      ; The line where to generate a raster interrupt cannot be read because
      ; $D012/$D011 return the current raster line. Therefore we wait until a
      ; raster interrupt *condition* occurs to obtain the this value.
@8:   lda  $D011                        ; VIC control register
      bpl  @10
      inx
      cpx  #$04
      beq  @12
@9:   lda  $D019                        ; Interrupt indicator register
      and  #$01
      bne  @11
      bit  $D011                        ; VIC control register
      bmi  @9
@10:  lda  $D019                        ; Interrupt indicator register
      and  #$01
      beq  @8
@11:  lda  $D011                        ; VIC control register
      ldy  $D012
@12:  pha
      tya
      pha
      ldy  #<(r11 + 1 -__freezer_restore_1_LOAD__)
      pla
      sta  ($02),y
      ldy  #<(r10 + 1 -__freezer_restore_1_LOAD__)
      pla
      sta  ($02),y
      ldy  #<(r12 + 1 -__freezer_restore_1_LOAD__)
      lda  ciareg_backup + $0e
      ora  #$10
      sta  ($02),y
      ldy  #<(r13 + 1 -__freezer_restore_1_LOAD__)
      lda  ciareg_backup + $0f
      ora  #$10
      sta  ($02),y
      ldy  #<(r14 + 1 -__freezer_restore_1_LOAD__)
      lda  ciareg_backup + $1e
      ora  #$10
      sta  ($02),y
      ldy  #<(r15 + 1 -__freezer_restore_1_LOAD__)
      lda  ciareg_backup + $1f
      ora  #$10
      sta  ($02),y

      ; No idea... restore code has been patched with the backed up values
      ; ciareg_backup + $0e/$0f/$1e/$1f can in principle be reused for other
      ; purposes, but I cannot find any code that does this, so why clear
      ; them then?
      ldx  #$01
      lda  #$00
:     sta  ciareg_backup + $0e,x
      sta  ciareg_backup + $1e,x
      dex
      bpl  :-

      sec
      lda  $02
      sbc  #$01
      tay
      lda  $03
      sbc  #$00
      pha
      tya
      pha
      tsx
      stx  tmpvar2
      lda  tmpptr_a
      sta  $02
      lda  tmpptr_a+1
      sta  $03
      ldx  #.sizeof(spritexy_backup) - 1
:     lda  $D004,x                      ; Position X sprite 2
      sta  spritexy_backup,x
      dex 
      bpl  :-
      ldx  #.sizeof(viciireg_backup) - 1
:     lda  $D010,x
      sta  viciireg_backup,x
      dex
      bpl  :-
      ldx  #.sizeof(spritecol_backup) - 1
:     lda  $D029,x                      ; Color sprite 2
      sta  spritecol_backup,x
      dex
      bpl  :-
      ldx  #.sizeof(spriteptr_backup) - 1
:     lda  $C7FA,x
      sta  spriteptr_backup,x           ; Current secondary address
      dex
      bpl  :-
      ldx  #$17
      ; Backup the first 24 bytes of colour RAM to unused colour RAM
:     lda  $D800,x                      ; Color RAM
      sta  $DBE8,x                      ; Color RAM
      dex
      bpl  :-
      ; Backup the last 16 bytes of colour RAM to zeropage RAM
      ldx  #.sizeof(colram_backup) - 1
:     lda  $D818,x                      ; Color RAM
      sta  colram_backup,x
      dex
      bpl  :-
      ldx  #.sizeof(zp2345_backup) - 1
:     lda  $02,x
      sta  zp2345_backup,x
      dex
      bpl  :-

      ;
      ; Show the Freezer menu and let the user make a selection
      ;
      jsr  freezer_ultimax_exec_menu

      tay
      sei
      lda  #$0F
      sta  $D418                        ; Select volume and filter mode
      ldx  #.sizeof(zp2345_backup) - 1
:     lda  zp2345_backup,x
      sta  $02,x
      dex
      bpl  :-
      ldx  #.sizeof(spritexy_backup) - 1
:     lda  spritexy_backup,x
      sta  $D004,x                      ; Position X sprite 2
      dex
      bpl  :-
      ldx  #.sizeof(viciireg_backup) - 1
:     lda  viciireg_backup,x
      sta  $D010,x
      dex
      bpl  :-
      ldx  #.sizeof(spritecol_backup) - 1
:     lda  spritecol_backup,x
      sta  $D029,x                      ; Color sprite 2
      dex
      bpl  :-
      ldx  #.sizeof(spriteptr_backup) - 1
:     lda  spriteptr_backup,x
      sta  $C7FA,x
      dex
      bpl  :-
      ldx  #$17
:     lda  $DBE8,x                      ; Color RAM
      sta  $D800,x                      ; Color RAM
      dex
      bpl  :-

      ldx  #.sizeof(colram_backup) - 1
:     lda  colram_backup,x
      sta  $D818,x
      dex
      bpl  :-
      tsx
      stx  tmpvar2
      tya
      tax

      ; This is a routine that is executed after a backed has been loaded and this routine
      ; will finalize the loading. Since temp variables at $A6 are no longer needed, this
      ; routine can now be installed.
      ldy  #freezer_restore_0300_size-1
:     lda  freezer_restore_0300,y
      sta  $00A6,y
      dey
      bpl  :-

      ldy  #$00
      sty  $02A1
      sty  $D01A                        ; IRQ mask register
      sty  spritexy_backup              ; ???
      sty  $A3
      sty  $DD03                        ; Data direction register port A #2
      lda  #$7F
      sta  $D019                        ; Interrupt indicator register
      lda  #$3F
      sta  $DD02                        ; Data direction register port A #2
      lda  $80                          ; CHRGET (Introduce a char) subroutine
      and  #$07
      ora  #$10
      sta  $DD00                        ; Data port A #2: serial bus, RS-232, VIC memory
      dex
      beq  freezer_backup_disk_near
      dex
      beq  freezer_jmp_backup_tape
      dex
      beq  freezer_backup_disk_near
      dex
      beq  freezer_jmp_backup_tape
      dex
      beq  freezer_jmp_sprite_I
      dex
      beq  freezer_jmp_sprite_II
      dex
      beq  freezer_jmp_joyswap
      dex
      beq  freezer_jmp_autofire
      dex
      dex
      dex
      dex
      beq  freezer_settings
      dex
      dex
      beq  freezer_pset
      dex
      beq  freezer_final_kill
      dex
      beq  freezer_jmp_zero_fill
      dex
      beq  freezer_cbm64
      dex
      beq  freezer_run
      dex
      beq  freezer_monitor
      dex
      beq  freezer_goto_desktop
      bne  freezer_run
freezer_monitor:
      jmp  freezer_goto_monitor

freezer_goto_desktop:
      jmp  write_mg87_and_reset

freezer_jmp_zero_fill:
      jmp  freezer_zero_fill

freezer_cbm64:
      lda  #>(START-1)
      pha
      lda  #<(START-1)
      pha
      jmp  _enable_fcbank0

freezer_final_kill:
      ; Jump to RESET vector in KERNAL
      lda  #>(START-1)
      pha
      lda  #<(START-1)
      pha
      ; ROM bank 0, C64 in normal mode, NMI line released and disable FC3 hardware:
      lda  #fcio_bank_0|fcio_c64_crtrom_off|fcio_nmi_line|fcio_kill
      jmp  _jmp_bank

freezer_pset:
      jsr  call_pset_in_bank0
      jmp  freezer_run

call_pset_in_bank0:
      lda  #>pset
      pha
      lda  #<pset
      pha
      jmp  _enable_fcbank0

freezer_jmp_joyswap:
      jmp  freezer_joyswap

freezer_settings:
      jmp  freezer_goto_settings

freezer_jmp_backup_tape:
      jmp  freezer_backup_tape

freezer_jmp_autofire:
      jmp  freezer_autofire

freezer_jmp_sprite_I:
      jmp freezer_sprite_I

freezer_run:
      ldy  #$35
      jmp  $DE0D

freezer_jmp_sprite_II:
      jmp  freezer_sprite_II

freezer_backup_disk_near:

.segment "freezer_restore_0"
;
; This routine is stored into the zero page at $00a6
; If a backup is loaded, the loader jumps to this routine in the (restored) zero page
;
.proc freezer_restore_0300
:     jsr  IECIN
      sta  $0300,y
      iny
      bne  :-
      lda  #$08
      jsr  LISTEN
      lda  #$E0
      jsr  SECOND
      jsr  UNLSTN
      dec  $01
      rts
.endproc
freezer_restore_0300_size = .sizeof(freezer_restore_0300)

.assert freezer_backup_disk = freezer_backup_disk_near, error, "backup_disk must follow freezer_entry_1"

.segment "freezer_restore_1"
      ;
      ; This routine is copied to ram at second memory area found by freezer
      ; It is live patched.
      ;
freezer_restore_mem_cia_vic:
r4:   lda  #$FF
      sta  $02A1
      sei
      ; Restore the CIA registers
      ldx  #$20
:     lda  ciareg_backup-1,x
      sta  $DCEF,x
      dex
      bne  :-
r1:   lda  $0100,x                      ; live patched by freezer entry code
      sta  $70,x                        ; Lo Byte #1 (rounding)
r3:   lda  #$04
r2:   sta  $0100,x                      ; live patched by freezer entry code
      inx
      cpx  #__FREEZERZP_SIZE__
      bne  r1
r9:   lda  #$FF
      sta  $D015                        ; Sprites Abilitator
r10:  lda  #$FF
      sta  $D011                        ; Screen control register
r11:  lda  #$FF
      sta  $D012                        ; Raster interrupt line
r8:   lda  #$FF
      sta  $D01A                        ; IRQ mask register
r12:  lda  #$FF
      sta  $DC0E                        ; Control register A of CIA #1
r13:  lda  #$FF
      sta  $DC0F                        ; Control register B of CIA #1
r14:  lda  #$FF
      sta  $DD0E                        ; Control register A of CIA #2
r15:  lda  #$FF
      sta  $DD0F                        ; Control register B of CIA #2
      ldx  #$8F
      lda  $DC0D                        ; Interrupt control register CIA #1
      lda  $DD0D                        ; Interrupt control register CIA #2
      stx  $D019                        ; Interrupt indicator register
r5:   ldy  #$FF
r7:   ldx  #$FF
      txs
      ldx  #<__freezer_restore_1_SIZE__ - 1
r6:   lda  #$FF                         ; Value to overwrite restore routine with
      rts                               ; Jump to restore routine phase 2 (located on stack)

.segment "freezer_restore_2"

      ;
      ; This routine is copied to the stack by freezer
      ; It is live patched.
      ;
freezer_restore_l1:
      sta  $0100,x                       ; Live patched by address of memory area
freezer_restore_fill_area:
      dex
      bpl  freezer_restore_l1
      pla
      tax
      pla
      sta  $01
      pla
      sta  $00
      pla
      rti

sizeof_freezer_restore_fill_area = __freezer_restore_2_SIZE__ - (freezer_restore_fill_area - __freezer_restore_2_RUN__)


      .segment "freezer_entry_2"

;
; freezer_find_memory -- Find y consecutive bytes in memory with the same value
;
; This routine is used to find memory that the freezer can use. It searches ram
; for y consecutive bytes with the same value, so these bytes can be easily
; run-length encoded.
;
; In:
;  - A - High byte of start address
;  - X - Low byte of start address
;  - Y - Number of bytes to find
;
; Out:
;  - $02/$03 - Pointer to memory area



restart_at_0201:
      lda  #$02
      ldx  #$01
      .byte $2c ; 3 byte nop
freezer_find_memory:
      sty  $0c                          ; store number of bytes
      stx  $02                          ; store lo byte of addr
      sta  $03                          ; store hi byte of addr
      lda  #$33                         ; BASIC CHARROM KERNAL
      sta  $01
      jsr  $0005                        ; load a byte from RAM at ($02),y
      sta  $04                          ; save the byte
      ldy  #$00                         ; begin at the start of tye pointer
@nextbyte:
      iny
      cpy  $0C                          ; end reached?
      beq  @exit                        ; yes
      jsr  $0005                        ; load a byte from RAM at ($02),y
      cmp  $04                          ; same as last byte?
      beq  @nextbyte                    ; yes, tnen loop
      sta  $04                          ; it's not equal, save the byte
      tya
      clc
      adc  $02                          ; Add index where unequal to the pointer
      sta  $02
      bcc  @no_overflow
      inc  $03                          ; carry to high byte
      lda  $03                          ; end of memory reached?
      beq  restart_at_0201              ; then restart at $0201
      cmp  #$D0                         ; I/O area reached?
      beq  @io_area_reached
@no_overflow:
      ldy  #$00
      beq  @nextbyte
@io_area_reached:
      ; This code is mysterious, because by storing $33 into $01, the code above
      ; made I/O invisible and thus reading $d018 makes no sense. It looks like 
      ; the code checks wether screen ram is <$d000 or >=$e000. If yes, the screen
      ; ram is used as freezer memory. If no, the stack is used as a last resort.
      ;
      ; The first $C3 bytes of the screen buffer or stack is cleared, which is
      ; mysterious as well, since if consecutive bytes are found, nothing is
      ; cleared
      ;
      lda  $D018                        ; VIC memory control register
      and  #$F0
      lsr
      lsr
      sta  $03                          ; Jump Vector: real-integer conversion
      lda  $DD00                        ; Data port A #2: serial bus, RS-232, VIC memory
      and  #$03
      eor  #$03
      lsr
      ror
      ror
      ora  $03                          ; Jump Vector: real-integer conversion
      cmp  #$D0
      bcc  @screen_ok
      cmp  #$E0
      bcs  @screen_ok
      lda  #$01                         ; Use stack as last resort
@screen_ok:
      sta  $03                          ; Jump Vector: real-integer conversion
      ldy  #0
      sty  $02                          ; Low byte to zero
      tya
:     sta  ($02),y                      ; Clear the byte
      iny
      cpy  #$C3                         ; End reached?
      bne :-
@exit:
      lda  #$37                         ; Normal memory config
      sta  $01
      rts

.segment "freezer_entry_3"

loadram:
      ; $01 contains $33 i.e. BASIC CHARROM KERNAL visble
      inc  $01                          ; $01 contains $34, 100% RAM
      lda  ($02),y
      dec  $01                          ; re-enable ROM
      rts
temp_nmi_handler:
      rti
