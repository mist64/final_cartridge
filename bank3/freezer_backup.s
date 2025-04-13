;*****************************************************************************
;  Final Cartridge III reconstructed source code
;
;  This file implements the backup functionality of the freezer
;*****************************************************************************

      .setcpu "6502x"

.include "../core/kernal.i"
.include "../core/fc3ioreg.i"
.include "persistent.i"

.import __tape_backup_loader_LOAD__,__tape_backup_loader_SIZE__
.import __disk_backup_loader_LOAD__,__disk_backup_loader_SIZE__
.import __zp_load_mem_1_LOAD__,__zp_load_mem_1_SIZE__
.import __zp_load_mem_2_LOAD__,__zp_load_mem_2_SIZE__
.importzp __zp_load_mem_1_RUN__,__zp_load_mem_2_RUN__
.importzp tmpvar1,tmpptr_a,spritexy_backup
.import write_mg87_and_reset

.segment "backup_disk"

.global freezer_backup_disk

freezer_backup_disk:
      lda  #$00
      sta  $D015                        ; Disable sprites
      sta  $D418                        ; Mute sound
      ldy  #$06
      jsr  set_1541_sector_interleave
      jsr  open_fc
      lda  #<__disk_backup_loader_LOAD__
      sta  tmpptr_a
      lda  #>__disk_backup_loader_LOAD__
      sta  tmpptr_a+1

      ldy  #0
@1:   lda  (tmpptr_a),y
      jsr  IECOUT
      inc  tmpptr_a
      bne  :+
      inc  tmpptr_a+1
:     lda  tmpptr_a
      cmp  #<(__disk_backup_loader_LOAD__ + __disk_backup_loader_SIZE__)
      lda  tmpptr_a+1
      sbc  #>(__disk_backup_loader_LOAD__ + __disk_backup_loader_SIZE__)
      bcc  @1

      ; Backup the zero page
      ldx  #$00
@2:   lda  $00,x
      cpx  #spritexy_backup             ; ???? No backup of sprite 2 x coord?
      bne  :+
      lda  #$00
:     jsr  IECOUT
      inx
      bne  @2

      ; Backup the stack
:     lda  $0100,x
      jsr  IECOUT
      inx
      bne  :-

      ; Backup the colour RAM
:     lda  $DA00,x                      ; Color RAM
      jsr  st_high_nibble
      lda  $D800,x                      ; Color RAM
      jsr  st_low_nibble
      inx
      bne  :-
:     lda  $DB00,x                      ; Color RAM
      jsr  st_high_nibble
      lda  $D900,x                      ; Color RAM
      jsr  st_low_nibble
      inx
      bne  :-

      ; Backup VIC-II registers
:     lda  $D000,x                      ; Position X sprite 0
      jsr  IECOUT
      inx
      cpx  #$2F
      bne  :-

      ; Backup $0400..$0402
      ldx  #$00
:     lda  $0400,x                      ; Video matrix (25*40)
      jsr  IECOUT
      inx
      cpx  #$03
      bne  :-

      jsr  file_close_ch1

      sei

      ; Install the zp_load_mem* routines into zeropage
      ldx  #<__zp_load_mem_1_SIZE__-1
:     lda  __zp_load_mem_1_LOAD__,x
      sta  __zp_load_mem_1_RUN__,x
      dex
      bpl :-

      ; Backup $FFFD..$FFFF
      lda  #<$FFFD
      sta  tmpptr_a
      lda  #>$FFFD
      sta  tmpptr_a+1
      ldy  #$02
      lda  #$33
      sta  $01
:     jsr  zp_load_tmpptr_a
      sta  $009B,y
      dey
      bpl  :-

      ; Compress the memory
      jsr  backup_compress_ram
      lda  $99
      sta  tmpptr_a
      lda  $9A
      sta  tmpptr_a+1

      ldx  #<__zp_load_mem_2_SIZE__-1
:     lda  __zp_load_mem_2_LOAD__,x
      sta  __zp_load_mem_2_RUN__,x
      dex
      bpl  :-

      lda  tmpptr_a
      sta  $96
      lda  tmpptr_a+1
      sta  $97
      sec
      lda  #$00
      sbc  tmpptr_a
      sta  $9E
      lda  #$00
      sbc  tmpptr_a+1
      clc
      adc  #$04
      sta  $9F
      ldx  #$37
      stx  $01


      jsr  open_minusfc
      ldx  #$00

      ; Backup page $0200
:     lda  $0200,x
      jsr  IECOUT
      inx
      bne  :-

      ; Backup page $0300
:     lda  $0300,x
      jsr  IECOUT
      inx
      bne  :-

      ; X=0
      ; Backup some variables
:     lda  $9B,x
      jsr  IECOUT
      inx
      cpx  #$05
      bne  :-

      ldy  #<$0400
      sty  tmpptr_a
      lda  #>$0400
      sta  tmpptr_a+1
@3:   jsr  $00A6
      jsr  IECOUT
      inc  tmpptr_a
      bne  :+
      inc  tmpptr_a+1
:     lda  tmpptr_a
      cmp  $96
      lda  tmpptr_a+1
      sbc  $97
      bcc  @3
      jsr  file_close_ch1
      ldy  #$0A
      jsr  set_1541_sector_interleave
      jmp  write_mg87_and_reset


.segment "backup_disk_2"

st_high_nibble:
      asl
      asl
      asl
      asl
      sta  $A5
      rts

st_low_nibble:
      and  #$0F
      ora  $A5
      jmp  IECOUT

open_fc:
      lda  #$F1 ; OPEN channel 1
      jsr  listen_second
      jmp  send_fc

open_minusfc:
      lda  #$F1
      jsr  listen_second
      lda  #$2D
      jsr  IECOUT
send_fc:
      lda  #'F'
      jsr  IECOUT
      lda  #'C'
      jsr  IECOUT
      jsr  UNLSTN
      lda  #$61   ; LISTEN channel 1
listen_second:
      pha
      lda  #$08
      jsr  LISTEN
      pla
      jmp  SECOND

;
; Set 1541 sector interleave to value in Y
;
.proc set_1541_sector_interleave
      lda  #$6F                        ; Talk to channel 15
      jsr  listen_second
      ldx  #sizeof_interleave_write - 1
:     lda  interleave_write,x
      jsr  IECOUT
      dex
      bpl  :-
      tya
      jsr  IECOUT
      jmp  UNLSTN
.endproc

interleave_write:   .byte $01,$00,$69,'W','-','M'
sizeof_interleave_write = .sizeof(interleave_write)

file_close_ch1:
      jsr  UNLSTN
      lda  #$e1
      jsr  listen_second                ; Close channel 1
      jmp  UNLSTN


      sei
      lda  #$33
      sta  $01
      ldy  #$00
      sty  $C3
      lda  #$01
      sta  $C4
      tya
:     sta  ($C3),y
      iny
      bne  :-
      inc  $C4
      bne  :-
      lda  #$37
      sta  $01
      jmp  START                        ; KERNAL RESET routine

.segment "backup_compress"

;
; Compress the C64's memory from $0403 to $FFFD using Run Length Encoding
;
;
; Compressed stream opcodes:
;
; $00 nn aa bb cc ...      Copy $nn bytes to output (<256 bytes)
; $01 nn oo aa bb cc ...   Copy $oonn bytes to output (>=256 bytes)
; $02 oo nn xx             Copy a run of $oonn bytes with value xx to output (<256 bytes)
;  nn xx  (nn>$02)         Copy a run of $nn bytes with value xx to output (>=256 byte)


backup_compress_ram:
      lda  #>$0403                      ; RAM compression starts at $0403
      sta  $97
      sta  tmpptr_a+1
      sta  $9A
      ldy  #$00
      sty  $99
      lda  #<$0403                      ; RAM compression starts at $0403
      sta  $96                          ; Source ptr1
      sta  tmpptr_a                     ; Source ptr2
      ldy  #$00
      ldx  #$00
      ; Find at least 4 equal bytes in sequence
@find_run_of_4:
      ldy  #$00
      jsr  zp_load_96                   ; Load a byte from RAM
      sta  $98                          ; Open files number/Index of files table
:     iny
      jsr  zp_load_96                   ; Load another byte from RAM
      cmp  $98                          ; Same as previous?
      bne  @1
      cpy  #4
      bne  :-
      beq  @found4
@1:   jsr  incptrchkend
      bcc  @find_run_of_4              ; Not end of memory? Then continue
@found4:
      ldy  #$00
      ldy  #$00
      ; Compute the different between $96/$97 and tmpptr_a and store in $98
      sec
      lda  $96
      sbc  tmpptr_a
      tax
      lda  $97
      sbc  tmpptr_a+1
      sta  $98
      bne  @st_big_unmodified
      txa
      beq  @count_run ; Jump if low bytes equal
      ; Store <256 bytes up until the run unmodified
      lda  #$00
      jsr  zp_store_a_99
      txa
      jsr  zp_store_a_99
@2:   jsr  zp_load_tmpptr_a_inc_ptr2
      jsr  zp_store_a_99
      dex
@6:   bne  @2
      jsr  chkend
      bcc  @count_run
      rts
      ; Store >=256 bytes up until the run unmodified
@st_big_unmodified:
      lda  #$01
      jsr  zp_store_a_99
      txa
      pha
      jsr  zp_store_a_99
      lda  $98
      jsr  zp_store_a_99
      ldx  #$00
:     jsr  zp_load_tmpptr_a_inc_ptr2
      jsr  zp_store_a_99
      inx
      bne  :-
      dec  $98
      bne  :-
      pla
      tax
      clc
      bcc  @6
@count_run:
      jsr  zp_load_96
      sta  $98
:     jsr  incptrchkend
      bcs  :+
      jsr  zp_load_96
      cmp  $98
      beq  :-
:     ; Compute the length of the run
      sec
      lda  $96
      sbc  tmpptr_a
      tax
      lda  $97
      sbc  tmpptr_a+1
      pha

      ; Copy $96/$97 into tmpptr_a
      lda  $96
      sta  tmpptr_a
      lda  $97
      sta  tmpptr_a+1

      pla
      bne  @stbigrun
      txa
@stsmallrun:
      jsr  zp_store_a_99
      lda  $98
      jsr  zp_store_a_99
      jsr  chkend
      bcs  _rts
      jmp  @find_run_of_4

@stbigrun:
      pha
      lda  #$02
      jsr  zp_store_a_99
      txa
      jsr  zp_store_a_99
      pla
      bne  @stsmallrun

incptrchkend:
      inc  $96
      bne  chkend
      inc  $97
chkend:
      lda  $96
      cmp  #<$FFFD
      lda  $97
      sbc  #>$FFFD
      ; This will underflow if $96/$97 < $FFFD, thus C=1 if at end of memory.
_rts:
      rts

.proc zp_store_a_99
      sta  ($99),y
      inc  $99
      bne  :+
      inc  $9A
:     rts
.endproc

.proc zp_load_tmpptr_a_inc_ptr2
      jsr  zp_load_tmpptr_a
      inc  tmpptr_a
      bne  :+
      inc  tmpptr_a+1
:     rts
.endproc

.segment "zp_load_mem_1"

.proc zp_load_96
      inc  $01
      lda  ($96),y
      dec  $01
      rts
.endproc

.proc zp_load_tmpptr_a
      inc  $01
      lda  (tmpptr_a),y
      dec  $01
      rts
.endproc


.segment "zp_load_mem_2"

.proc zp_load_tmpptr_b
      lda  #$0C
      sta  $01
      lda  (tmpptr_a),y
      pha
      lda  #$0F
      sta  $01
      pla
      rts
.endproc

.segment "disk_backup_loader"

.incbin "disk_backload/backup_loader.prg"


.segment "freezer_backup_tape"

turbotape_tape_program_header:
      .word $0801 ; Load address of program
      .word $105a ; End address of program
      .byte $00
      .byte "FC"

.global freezer_backup_tape

freezer_backup_tape:
      lda  #$00                         ; Disable all sprites
      sta  $D015
      lda  #<__tape_backup_loader_LOAD__
      sta  tmpptr_a
      lda  #>__tape_backup_loader_LOAD__
      sta  tmpptr_a+1
      jsr  tape_prepare

      jsr  tape_write_header_fast       ; Sets Y=0
      lda  #$01                         ; Indicates that we are writing a BASIC program to tape
      jsr  tape_write_byte_fast
      ldx  #$08
:     lda  turbotape_tape_program_header,y
      jsr  tape_write_byte_fast
      ldx  #$07                         ; Reload pulse length
      iny
      cpy  #$07                         ; 8 bits written?
      bne  :-                           ; No, then loop
      ldy  #$00
:     lda  #$20                         ; Write the value $20 $B8 times to fill the header
      jsr  tape_write_byte_fast
      ldx  #$07                         ; Reload pulse length
      iny
      cpy  #$B9                         ; $B8 times
      bne  :-

      ; Write the loader to tape
      jsr  tape_write_header_fast       ; Write another header ; sets Y=0
      tya
      jsr  tape_write_byte_fast         ; Write a 0 byte
      ldx  #$07                         ; Reload pulse length
@1:   lda  (tmpptr_a),y                      ; Get a byte from the loader
      jsr  tape_write_byte_fast
      ldx  #$03                         ; Reload pulse length (compensated for extra instructions)
      inc  tmpptr_a                     ; Increase low byte of pointer
      bne  :+                           ; Next byte
      inc  tmpptr_a+1                   ; Increase high byte of pointer
      dex                               ; Compensate for extra instructions
      dex
:     lda  tmpptr_a
      cmp  #<(__tape_backup_loader_LOAD__ + __tape_backup_loader_SIZE__)
      lda  $92
      sbc  #>(__tape_backup_loader_LOAD__ + __tape_backup_loader_SIZE__)
      bcc  @1

      ; Write the zeropage to tape
      ldx  #$02
:     lda  $0000,y
      jsr  tape_write_byte_fast
      ldx  #$07
      iny
      bne  :-

      ; Write the stack to tape
:     lda  $0100,y
      jsr  tape_write_byte_fast
      ldx  #$07
      iny
      bne  :-

      ; Write the colour RAM to tape
      sty  tmpptr_a                     ; Y already 0
      lda  #$D8                         ; $D800
      sta  tmpptr_a+1
      ldx  #$04
:     lda  (tmpptr_a),y                 ; Load a byte from colour RAM
      jsr  tape_write_byte_fast
      ldx  #$08
      iny
      bne  :-
      ldx  #$03
      inc  tmpptr_a+1
      lda  tmpptr_a+1
      cmp  #$DC                         ; End of colour RAM ?
      bne  :-

      ; Save the VIC-II registers to tape
:     lda  $D000,y
      jsr  tape_write_byte_fast
      ldx  #$07
      iny
      cpy  #$2F
      bne  :-

      ; Save $0400..$0402 to tape
      ldy  #$00
:     lda  $0400,y                      ; Video matrix (25*40)
      jsr  tape_write_byte_fast
      ldx  #$07
      iny
      cpy  #$03
      bne  :-

      ; Save checksum to tape
      lda  $A4
      inx
      jsr  tape_write_byte_fast
      jsr  tape_finnish

      ; Install the zp_load_mem* routines into zeropage
      ldx  #<__zp_load_mem_1_SIZE__-1
:     lda  __zp_load_mem_1_LOAD__,x
      sta  __zp_load_mem_1_RUN__,x
      dex
      bpl  :-

      ; Retrieve the vectors from $FFFD
      ldy  #$02
      lda  #<$FFFD
      sta  tmpptr_a
      lda  #>$FFFD
      sta  tmpptr_a+1
      lda  #$33
      sta  $01
:     jsr  zp_load_tmpptr_a
      sta  $009B,y
      dey
      bpl  :-

      jsr  backup_compress_ram
      lda  $99
      sta  tmpptr_a
      lda  $9A
      sta  tmpptr_a+1

      ldx  #<__zp_load_mem_2_SIZE__-1
:     lda  __zp_load_mem_2_LOAD__,x
      sta  __zp_load_mem_2_RUN__,x
      dex
      bpl  :-

      lda  tmpptr_a
      sta  $96
      lda  tmpptr_a+1
      sta  $97

      ; Negate tmpptr_a, add $0400 and store in $9e/$9f
      sec
      lda  #0
      sbc  tmpptr_a
      sta  $9E
      lda  #0
      sbc  tmpptr_a+1
      clc
      adc  #$04
      sta  $9F

      lda  #$37
      sta  $01
      jsr  tape_prepare
      sty  tmpptr_a
      lda  #$04
      sta  tmpptr_a+1

      ; Write a turbo tape header
      jsr  tape_write_header_fast
      tya
      jsr  tape_write_byte_fast
      ldx  #$08
:     lda  $009B,y
      jsr  tape_write_byte_fast
      ldx  #$06
      iny
      cpy  #$05
      bne  :-

      ; Backup the compressed memory
      ldy  #$00
      ldx  #$07
@2:   jsr  zp_load_tmpptr_b
      sta  tmpvar1
      lda  #$08
      sta  $A3
:     asl  tmpvar1
      lda  $01
      and  #$F7
      jsr  tape_half_pulse
      ldx  #$11
      ora  #$08
      jsr  tape_half_pulse
      ldx  #$0E
      dec  $A3
      bne  :-
      ldx  #$03
      inc  tmpptr_a
      bne  :+
      dex
      dex
      inc  tmpptr_a+1
:     lda  tmpptr_a
      cmp  $96
      lda  tmpptr_a+1
      sbc  $97
      bcc  @2

      jsr  tape_finnish

      lda  #$37
      sta  $01
      jsr  tape_prepare
      jsr  tape_write_header_fast
      tya
      jsr  tape_write_byte_fast
      ldx  #$08

      ; Write the $0200 page
:     lda  $0200,y
      jsr  tape_write_byte_fast
      ldx  #$07
      iny
      bne  :-

      ; Write the $0300 page
:     lda  $0300,y
      jsr  tape_write_byte_fast
      ldx  #$07
      iny
      bne  :-
      jsr  tape_finnish

      jmp  write_mg87_and_reset


;
; Wait for a button press on tape, disable the screen and start the tape motor
;
tape_prepare:
      lda  #$10                         ; Bit 4 is cassette sense
:     bit  $01
      bne  :-                           ; Not presset? Then loop
      lda  $01
      and  #$07                         ; Enable tape motor
      sta  $01
      lda  #$0B
      sta  $D011                        ; Disable screen (normal value of $d011 is $1b)
      ldy  #0                           ; Do a delay loop, because VIC-II only stops bad lines
:     inx                               ; at the next frame.
      bne  :-
      iny
      bne  :-
      rts

;
; Enable the screen, and stop the tape motor
;
tape_finnish:
      lda  #$1B                         ; Enable screen
      sta  $D011
      lda  $01
      ora  #$20                         ; Bit 5 is tape motor
      sta  $01
      rts

;
; Write the Turbotape header to tape. A Turbotape header consists of 256 times the value
; 2. This is the pilot tone that allows synchronization. However, the following routine
; writes 5 * 247 times a 2, so the header is longer than the original turbotape program.
; Then the bytes 9,8,7,6,5,4,3,2,1 are written. This allows the reader to differentiate
; between a valid header and not just some random sequence of twos.
;
; Y=0 on return, code depends on this.
;

tape_write_header_fast:
      lda  #$05                         ; 5 times 247
      sta  $A5
      ldy  #$00                         ; Start at 0 and count down
:     lda  #$02                         ; Write a 2 to tape
      jsr  tape_write_byte_fast
      ldx  #$07                         ; Lenth of the low pase
      dey
      cpy  #$09                         ; Did we write 247 bytes?
      bne  :-                           ; No, then loop
      ldx  #$05                         ; Length of the low phase (slightly lower because
                                        ; we did exec more instructions).
      dec  $A5
      bne  :-
:     tya
      jsr  tape_write_byte_fast
      ldx  #$07                         ; Length of the low phase
      dey
      bne  :-
      dex                               ; Length of low phase to to 5 to account for extra
                                        ; instructions
      dex
      sty  $A4                          ; Y=0
      rts



      ldx  #$08
;
; Write the byte in A to tape
;
tape_write_byte_fast:
      sta  tmpvar1                      ; Store the byte to write
      eor  $A4                          ; Update checksum
      sta  $A4
      lda  #8                           ; 8 Bits to write
      sta  $A3
:     asl  tmpvar1                      ; Shift a bit out
      lda  $01
      and  #$F7                         ; Write the low pulse phase
      jsr  tape_half_pulse
      ldx  #17                          ; Length of pulse
      ora  #$08                         ; Write the high pulse phase
      jsr  tape_half_pulse
      ldx  #14                          ; Length of pulse
      dec  $A3                          ; Count down number of bits
      bne  :-                           ; More bits to write? Then loop.
      rts

;
; Do either the high or low phase of the pulse.
; C contains the bit to write to tape
;   0 = 176 us pulse
;   1 = 256 us pulse
;
; A contains the value to write to $01, either bit 3 set or reset depending
; on wheter to write the high or low phase.
;
tape_half_pulse:
:     dex
      bne  :-
      bcc  @1
      ldx  #$0B
:     dex
      bne  :-
@1:   sta  $01
      rts

.segment "tape_backup_loader"

.incbin "tape_backload/backup_loader.prg",2

