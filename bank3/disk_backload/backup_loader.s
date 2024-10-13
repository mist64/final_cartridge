.import __LOWCODE_LOAD__, __LOWCODE_RUN__
.import __DRIVECODE_LOAD__
.import __MAIN_LAST__

.include "../../core/kernal.i"

;
; This is the loader that loads and continues a Final Cartridge III disk
; backup. It is stored in the "FC" file along with the contents of memory
; til $0402. Most data is stored in a file "-FC" that stores the
; memory contents from $0403 to $fffd. This file is RLE compressed and
; needs decompression.
;.
; Zeropage, stack, $0200..0402 and colour RAM is included in the loader
; and starts right after code end.
;

.segment "BASIC_STUB"

.incbin "basic_stub.bin"

.segment "CODE"

stored_zeropage   = __MAIN_LAST__ + $0000
stored_stack      = __MAIN_LAST__ + $0100
stored_colram     = __MAIN_LAST__ + $0200
stored_vicregs    = __MAIN_LAST__ + $0400
stored_0400       = __MAIN_LAST__ + $042f

nr_vicregs        = $2f

start:
      sei
      ; Backup the file name of the loader
      ldy  #$00
:     lda  ($BB),y                      ; Pointer: current file name
      sta  filename_load+1,y
      iny
      cpy  #15
      beq  :+
      cpy  $B7                          ; Length of current file name
      bne  :-
:     lda  #$00                         ; Terminate with a zero
      sta  filename_load+1,y

      ; NTSC C64s have a higher clock speed, so an extra nop needs to be
      ; inserted in the receive code.
      lda  $02A6                        ; Indicator PAL/NTSC, 0=NTSC, 1=PAL
      bne  @pal
      ldx  #ntsc_move_len-1
:     lda  receive_4_bytes_load+ntsc_point_ofs,x
      sta  receive_4_bytes_load+ntsc_point_ofs+1,x
      dex
      bpl  :-

      dec  receive_4_bytes_load+ntsc_jump_ofs+2 ; Adjust branch to longer code length

@pal: lda  #$7F
      sta  $DC0D                        ; Interrupt control register CIA #1
      sta  $DD0D                        ; Interrupt control register CIA #2

      ; Initialize all SID voices
      ldx  #14                          ; Start with voice 3, iterate down
:     lda  #$80                         
      sta  $D402,x                      ; Pulse width low byte
      sta  $D403,x                      ; Pulse width high byte
      lda  #$21                         ; Sawtooth + voice on
      sta  $D404,x                      ; Voice control register
      lda  #$08                         
      sta  $D405,x                      ; Attack/Decay
      lda  #$80                         
      sta  $D406,x                      ; Sustain/Release
      txa
      sec
      sbc  #$07                         ; Subtract 7 for next voice                         
      tax
      bpl  :-

      lda  #$8F                         
      sta  $D418                        ; Select volume and filter mode
      ldx  #$00                         
      stx  $DC0E                        ; Control register A of CIA #1

      ;
      ; Note that the freezer, upon entry, searches for two memory areas:
      ; one contains a backup of $0070..$00d6, the other the "restore"
      ; routine.
      ;
      ; The loader restores the memory in this state, i.e. after loading
      ; memory, $0070..$00d6 still can be used by the loader, and the restore
      ; routine is loaded from backup as well. It can ultimately do an rts to
      ; activate the restore routine that restores both memory areas and
      ; returns control to the program.

 @1:  ; Restore the zero page
      lda  stored_zeropage,x
      sta  $00,x
      ; Restore the stack
      lda  stored_stack,x
      sta  $0100,x

      ; Restore the $0400..$0402
      cpx  #$03
      bcs  :+
      lda  stored_0400,x
      sta  $0400,x
:     inx
      bne  @1

      ldx  #nr_vicregs-1
:     lda  stored_vicregs,x
      sta  $D000,x
      dex
      bpl  :-

      lda  #$0B                         ; Disable screen
      sta  $D011                          ; $93 contains the backed up stack pointer
      ldx  $93
      txs

      ; Restore the colour ram
      ; Colour ram is stored in a compacted form, as it is only 4-bit, two colour
      ; RAM locations fit in a byte.
      ldx  #$00
:     lda  stored_colram,x
      jsr  nibble2ay
      sta  $D800,x                      ; Color RAM
      tya
      sta  $DA00,x                      ; Color RAM
      lda  stored_colram + $0100,x
      jsr  nibble2ay
      sta  $D900,x                      ; Color RAM
      tya
      sta  $DB00,x                      ; Color RAM

      ; Install lowcode in page $0300
      lda  __LOWCODE_LOAD__ + $0100,x
      sta  $0300,x
      inx
      bne  :-

	  ; Open the second (main) file of the backup
      jsr  open_second_file

      jsr  UNTALK
      
      ; Upload the drive code and execute it
      jsr  upload_drivecode
      lda  #<drivecode_entry
      jsr  IECOUT
      lda  #>drivecode_entry
      jsr  IECOUT
      jsr  UNLSTN

      ; Install lowcode in page $0200
      sei
:     lda  __LOWCODE_LOAD__,y
      sta  $0200,y                      ; INPUT buffer of BASIC
      iny
      bne  :-

      ; Y=0
      sty  $96

      ; Now pages $0200 and $0300 are coming. Skip for now.
:     jsr  receive_byte
      jsr  receive_byte
      iny
      bne  :-

:     jsr  receive_byte
      sta  vectors_tmp,y
      iny
      cpy  #$03
      bne  :-

      jsr  receive_byte
      sta  $91
      sta  cdsl+1                       ; Self-modify code
      jsr  receive_byte
      sta  $92
      sta  cdsh+1                       ; Self modify code
      lda  #$35
      sta  $01                          ; 6510 I/O register
      ldy  #0
      jmp  receive_main_memory

.proc nibble2ay
      pha
      lsr
      lsr
      lsr
      lsr
      tay
      pla
      and  #$0F
      rts
.endproc

.proc upload_drivecode
      ldx  #4
      lda  #<__DRIVECODE_LOAD__
      sta  $C3                          ; Transient tape load
      lda  #>__DRIVECODE_LOAD__
      sta  $C4                          ; Transient tape load
      ; Send M-W
@bl:  lda  #'w'
      jsr  send_Mx
      tya
      jsr  IECOUT
      txa
      jsr  IECOUT
      lda  #' '
      jsr  IECOUT
:     lda  ($C3),y
      jsr  IECOUT
      iny
      tya
      and  #$1F
      bne  :-
      jsr  UNLSTN
      tya
      bne  @bl
      inc  $C4                          ; Transient tape load
      inx
      cpx  #$06
      bcc  @bl
      ; Send M-E
      lda  #'e'
send_Mx:
      pha
      lda  #$08
      jsr  LISTEN
      lda  #$6F                         ; Command channel 15
      jsr  SECOND
      lda  #'m'
      jsr  IECOUT
      lda  #'-'
      jsr  IECOUT
      pla
      jmp  IECOUT
.endproc

.segment "DRIVECODE"
jobqueue_entry:
      jmp  read_track                   ; This is executed by means of the $e0 command of the 1541
                                        ; job queue.

drivecode_entry:
      ldx  #$00
      stx  $1800
      lda  $19                          ; Transient strings stack
      sta  $09                          ; Screen column after last TAB
      lda  $18                          ; Last transient strings address
      sta  $08                          ; Flag: search the quotation marks at the end of one string
      ; This drive code is uploaded at $0400, buffer 1 in 1541 memory and also extends into buffer 2
      ; at $0500. $01 is the memory location of the 1541 job queue where to send commands for buffer
      ; 1. By writing the $e0 command into the job queue, the 1541 preares for reading a sector
      ; (moving the head etc.) and tnen executes the program in the buffer.
      ; Code will start executing at jobqueue_entry
      
@1:   lda  #$E0
      sta  $01
:     lda  $01
      bmi  :-                           ; Wait until the $e0 command finishes.
      cmp  #$02                         ; Error condition
      bcs  :+                           ; then jump
      lda  $08                          ; Last track??
      bne  @1                           ; No, then loop
:     lda  #$02
      sta  $1800
      jmp  $C194                        ; Prepare status message

read_track:
      ; The fastloader won't just read a sector, it will read all sectors
      ; in the current track that belong to the file and transmit them
      ; to the C64

@2:   ldx  #>$0300                      ; Buffer 0 at $0300 the buffer we will read into
      stx  $31
@1:   inx
      bne  :+
      jmp  $F40B                        ; Read error

      ; Read a sector header
:     jsr  $F556                        ; Wait for SYNC on disk (sets Y=0)
:     bvc  :-                           ; Wait for a byte ready
      clv
      lda  $1C01
      cmp  $24                          ; Header block ID as expected?
      bne  @1                           ; No, then loop to get next header
      iny
:     bvc  :-                           ; Wait for a byte ready
      ; Now read 4 bytes
      clv
      lda  $1C01
      sta  ($30),y                      ; Store into buffer
      iny
      cpy  #$04
      bne  :-

      ldy  #$00
      jsr  $F7E8                        ; GCR decode first 5 bytes of sector data and write to $52..$55
      ldx  $54
      cpx  $09                          ; Does the header sector number match the one we want to read?
      bne  @2                           ; No then retry

      ;
      ; After the header comes the sector itself
      jsr  $F556                        ; Wait for SYNC on disk (sets Y=0)
      ; Now read 256 bytes
:     bvc  :-
      clv
      lda  $1C01
      sta  ($30),y
      iny
      bne  :-

      ldy  #$BA                         ; Read another 70 bytes
:     bvc  :-
      clv
      lda  $1C01
      sta  $0100,y                      ; Use end of the stack as temporary storage area
      iny
      bne  :-

      lda  #$42                         ; 66 GCR tuples to decode

      sta  $36                          ; GCR byte counter
      ldy  #0
      sty  $C1                          ; Offset in buffer
@3:   dec  $36                          ; Pointer: strings for auxiliari programs
      sty  $1800                        ; DATA OUT low, CLOCK OUT low
      bne  :+                           ; More tuples to decode?

      lda  $08                          ; Flag: search the quotation marks at the end of one string
      cmp  $22                          ; Utility programs pointers area
      beq  @2
      jmp  $F418                        ; buffer status at $0001 to 01 (succesfull completion)

      ; A GCR tuple consists of 8 groups of 5 bits to be decoded to 8 * 4 bit.
      ; The following extracts all 8 groups and transmits them. The GCR decode happens during
      ; transmission by table lookup.
:     ldy  $C1
      lda  ($30),y                      ; First 5 bits
      lsr
      lsr
      lsr
      sta  $5C

      lda  ($30),y                      ; Second 5 bits spread over byte 0 and 1
      and  #$07
      sta  $5D                          ; Scratch for numeric operation
      iny
      bne  :+
      iny
      sty  $31                          ; Set $31 to 1
      ldy  #$BA                         ; 70 bytes left to decode
:     lda  ($30),y                      ; Remaining bits in byte 1
      asl
      rol  $5D                          ; Shift into $5D
      asl
      rol  $5D                          ; Shift into $5D

      lsr                               ; Third 5 bits in byte 1
      lsr
      lsr
      sta  $5A

      lda  ($30),y                      ; Fourth 5 bits spead over byte 1 and 2
      lsr
      iny
      lda  ($30),y                      ; Byte 2
      rol
      rol
      rol
      rol
      rol
      and  #$1F
      sta  $5B

      lda  ($30),y                      ; Fifth 5 bits spread over byte 2 and 3
      and  #$0F
      sta  $58
      iny
      lda  ($30),y                      ; Byte 3
      asl
      rol  $58                          ; Shift into $58
      lsr
      lsr
      lsr
      sta  $59

      lda  ($30),y                      ; Sixth 5 bits in byte 3 and 4
      asl
      asl
      asl
      and  #$18
      sta  $56
      iny                               ; Byte 4
      lda  ($30),y                      ; Pointer: BASIC starting arrays
      rol
      rol
      rol
      rol
      and  #$07
      ora  $56
      sta  $56

      ; Indicate readyness for transmission and wait for C64 to ack
      lda  #$08
      sta  $1800
:     lda  $1800
      lsr
      bcc  :-

      lda  #$00
      sta  $1800

      lda  ($30),y                      ; Seventh 5 bits
      and  #$1F
      sta  $57                          ; Scratch for numeric operation
      iny
      sty  $C1                          ; I/O starting address
      lda  $36                          ; Pointer: strings for auxiliari programs
      cmp  #$41                         ; Last tuple?
      bne  :+                           ; No then skip

      ; GCR decode track/sector no. for next sector of file
      ldx  $5A
      lda  $F8A0,x                      ; ROM GCR table for high nibbles
      ldx  $5B
      ora  $F8C0,x                      ; ROM GCR table for low nibbles
      sta  $08
      ldx  $58
      lda  $F8A0,x                      ; ROM GCR table for high nibbles
      ldx  $59
      ora  $F8C0,x                      ; ROM GCR table for low nibbles
      sta  $09

:     ldy  #$08                         ; Start transmission
      sty  $1800
      ldx  $55,y
:     lda  regvalue_lookup_01-8,x                      ; GCR table first two bits
      sta  $1800
      lda  regvalue_lookup_23-8,x                      ; GCR table second two byts
      ldx  $54,y
      sta  $1800
      dey
      bne  :-
      jmp  @3

regvalue_lookup_01:
        .byte   0, 10, 10, 2
        .byte   0, 10, 10, 2
        .byte   0, 0, 8, 0
        .byte   0, 0, 8, 0
        .byte   0, 2, 8, 0
        .byte   0, 2, 8, 0
.assert >* = >(regvalue_lookup_01-8), error, "Page boundary!"

regvalue_lookup_23:
        .byte   0, 8, 10, 10
        .byte   0, 0, 2, 2
        .byte   0, 0, 10, 10
        .byte   0, 0, 2, 2
        .byte   0, 8, 8, 8
        .byte   0, 0, 0, 0
.assert >* = >(regvalue_lookup_23-8), error, "Page boundary!"


.SEGMENT "LOWCODE"


.proc receive_byte
      lda  $96
      bne  :+
      jsr  receive_4_bytes
      ldx  #0
      lda  #$FE
      sta  $96
:     txa
      bpl  :+
      jsr  receive_4_bytes
      ldx  #3
:     lda  $C1,x                        ; I/O starting address
      dec  $96
      dex
      rts
.endproc

.proc receive_4_bytes
      ; X,Y preserved

      tya
      pha
:     bit  $DD00                        ; Wait clock
      bvs  :-
      lda  #$20
      sta  $DD00                        ; Data port A #2: serial bus, RS-232, VIC memory
:     bit  $DD00                        ; Data port A #2: serial bus, RS-232, VIC memory
      bvc  :-
      lda  #$00
      sta  $DD00                        ; Data port A #2: serial bus, RS-232, VIC memory
:     bit  $DD00                        ; Data port A #2: serial bus, RS-232, VIC memory
      bvs  :-
      ldy  #$03
      nop
      lda  $01                          ; 6510 I/O register
ll:   lda  $DD00                        ; Data port A #2: serial bus, RS-232, VIC memory
      lsr
      lsr
      nop
ntsc_point:
      nop
      ora  $DD00                        ; Data port A #2: serial bus, RS-232, VIC memory
      lsr
      lsr
      nop
      nop
      ora  $DD00                        ; Data port A #2: serial bus, RS-232, VIC memory
      lsr
      lsr
      nop
      nop
      ora  $DD00                        ; Data port A #2: serial bus, RS-232, VIC memory
      sta  $00C1,y                      ; I/O starting address
      dey
ntsc_jump:
      bpl  ll
      pla
      tay
      rts
ntsc_end:
      nop
.endproc

receive_4_bytes_load = receive_4_bytes - __LOWCODE_RUN__ + __LOWCODE_LOAD__
ntsc_point_ofs = receive_4_bytes::ntsc_point - receive_4_bytes
ntsc_jump_ofs = receive_4_bytes::ntsc_jump - receive_4_bytes
ntsc_move_len = receive_4_bytes::ntsc_end - receive_4_bytes::ntsc_point

receive_main_memory:
      ; Retrieve compressed memory via the fastloader
:     jsr  receive_byte
      dec  $01                          ; I/O invisible
      sta  ($91),y
      inc  $01                          ; I/O visible
      inc  $91                          ; Increase pointer low byte
      bne  :-
      inc  $92                          ; Increase pointer high byte
      bne  :-

:     lda  $96                          ; Receive but ignore sector slack
      beq  :+
      jsr  receive_byte
      jmp  :-

      ; Compressed memory has been retrieved, now start decompression
:     lda  #$34
      sta  $01                          ; 6510 I/O register
cdsl:
      lda  #<$FFFF                      ; Self modified with start of compressed data (L)
      sta  $96
cdsh:
      lda  #>$FFFF                      ; Self modified with start of compressed data (H)
      sta  $97
      lda  #<$0403                      ; Decompress from $0403 onwards
      sta  $91
      lda  #>$0403                      ; Decompress from $0403 onwards
      sta  $92
      ldx  #0
@5:
      lda  ($96),y
      bne  @7
      jsr  load_next_byte
      tax
@9:
      jsr  load_next_byte
      jsr  store_next_byte
      dex
@6:
      bne  @9
@2:
      jsr  load_next_byte
      lda  $91
      cmp  #<$FFFD
      lda  $92
      sbc  #>$FFFD                      ; Are we ready with decompression??
      bcc  @5                           ; No then loop.
      bcs  farcode                      ; Always

@7:   tax
      dex
      bne  @8
      jsr  load_next_byte
      pha
      jsr  load_next_byte
      sta  $90
:     jsr  load_next_byte
      jsr  store_next_byte
      inx
      bne  :-
      dec  $90
      bne  :-
      pla
      tax
      sec
      bcs  @6                           ; Always
@8:   dex
      beq  @4
      inx
      inx
      jsr  load_next_byte
@3:   jsr  store_next_byte
      dex
@1:   bne  @3
      beq  @2                           ; Always
@4:   jsr  load_next_byte
      pha
      jsr  load_next_byte
      sta  $90
      jsr  load_next_byte
:     jsr  store_next_byte
      inx
      bne  :-
      dec  $90
      bne  :-
      sta  $90
      pla
      tax
      lda  $90
      cpx  #$00
      sec
      bcs  @1                           ; Always

.proc load_next_byte
      inc  $96
      bne  :+
      inc  $97
:     lda  ($96),y
      rts
.endproc

.proc store_next_byte
      sta  ($91),y
      inc  $91
      bne  :+
      inc  $92
:     rts
.endproc


farcode:
      lda  #$36
      sta  $01                          ; 6510 I/O register

      ; Weird... this is the RS232 interrupt enable byte. No idea what is being done here:
      ldy  #$00
      sty  $02A1

      ; Put the vectors at the right place
      ldx  #$02
:     lda  vectors_tmp,x
      sta  $FFFD,x
      dex
      bpl  :-

      ; Close the second file
      lda  #$08
      jsr  LISTEN
      lda  #$E0
      jsr  SECOND
      jsr  UNLSTN

      ; Reopen the second file
      jsr  open_second_file

      ; Now retrieve page $0200 without fastloader
:     jsr  IECIN
      sta  $0200,y
      iny
      bne  :-

      ; The freezer has written the freeze_restore_0300 routine into the zero page at $00a6
      ; before writing memory to disk. This routine loads the $0300 page from disk and
      ; returns control to the program.
      ;
      ; we jump to there with rts
      lda  #$00
      pha
      lda  #$A5
      pha
      rts

.proc open_second_file
      lda  #$08
      jsr  LISTEN
      lda  #$F0                         ; $F0 = OPEN channel 0
      jsr  SECOND

      ; send the file name
      ldy  #0
:     lda  filename,y                   ; Tape I/O buffer
      beq  :+
      jsr  IECOUT
      iny
      bne  :-
:     jsr  UNLSTN

      ; Talk the file
      lda  #$08
      jsr  TALK
      ldy  #$00
      lda  #$60
      jmp  TKSA
.endproc

filename:
      .byte "-1234567890123456"

filename_load = filename - __LOWCODE_RUN__ + __LOWCODE_LOAD__

vectors_tmp = *
