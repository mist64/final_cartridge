.import __LOWCODE_LOAD__
.import __MAIN_LAST__

;
; This is the loader that loads and continues a Final Cartridge III tape
; backup. After the loader, a file is stored on tape that stores the
; memory contents from $0403 to $fffd. This file is RLE compressed and
; needs decompression.
; 
; Zeropage, stack, $0200..0403 and colour RAM is included in the loader
; and starts right after code end.
;

.zeropage
zp_loaded_byte    := $90
zp_bit_counter    := $91
zp_load_0200_addr := $92
zp_decompress_dst := $91
zp_decompress_src := $96

.segment "BASIC_STUB"

.incbin "basic_stub.bin"

.segment "CODE"

stored_zeropage   = __MAIN_LAST__ + $0000
stored_stack      = __MAIN_LAST__ + $0100
stored_colram     = __MAIN_LAST__ + $0200
stored_vicregs    = __MAIN_LAST__ + $0600
stored_0400       = __MAIN_LAST__ + $062f

nr_vicregs        = $2f

start:
      sei
      lda  #$7F
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

@1:   ; Restore the zero page
      lda  stored_zeropage,x
      sta  $00,x
      ; Restore the stack
      lda  stored_stack,x
      sta  $0100,x
      ; Restore the colour ram
      lda  stored_colram+$0000,x
      sta  $D800,x
      lda  stored_colram+$0100,x
      sta  $D900,x
      lda  stored_colram+$0200,x
      sta  $DA00,x
      lda  stored_colram+$0300,x
      sta  $DB00,x
      ; Install the low code that will load the rest of the backup
      lda  __LOWCODE_LOAD__+$0000,x
      sta  $0200,x
      lda  __LOWCODE_LOAD__+$0100,x
      sta  $0300,x
      cpx  #$03
      bcs  :+
      lda  stored_0400,x
      sta  $0400,x
:     inx
      bne  @1
      ldx  #nr_vicregs-1
:     lda  stored_vicregs,x
      sta  $D000,x                      ; Position X sprite 0
      dex
      bpl  :-
      ldx  $93                          ; $93 contains the backed up stack pointer
      txs
      lda  #$35                         ; Only I/O
      sta  $01                          ; 6510 I/O register
      jmp  lowcode_entry

.segment "LOWCODE"

.proc tape_load_byte_fast
      lda  #8                           ; Load 8 bits
bc1:  sta  $A3                          ; Bit counter
n:    jsr  tape_load_bit_fast
      rol  z:zp_loaded_byte             ; Rol bit into z:zp_loaded_byte
bc2:  dec  $A3                          ; Decrease bit counter
      bne  n
      lda  z:zp_loaded_byte             ; Return loaded byte in A
      rts
.endproc

.proc tape_load_bit_fast
      lda  #$10                         ; Wait until flag bit
:     bit  $DC0D                        ; Interrupt control register CIA #1
      beq  :-
      lda  $DD0D                        ; Interrupt control register CIA #2
      stx  $DD07                        ; Timer B #2: HI Byte
      pha
      lda  #$19                         ; Start timer B
      sta  $DD0F                        ; Control register B of CIA #2
      pla
      lsr                               ; Bit 1 (timer B underflow) to C
      lsr
      rts
.endproc

lowcode_entry:
      jsr  tape_prepare
      jsr  tape_read_turbotape_header
      ; Load 4 bytes:
:     jsr  tape_load_byte_fast
      sta  $0397,y                      ; Tape I/O buffer
      iny
      cpy  #$03
      bne  :-

      ; Get the load address at $91/$92 and patch code below
      jsr  tape_load_byte_fast
      sta  zp_decompress_dst
      sta  @load_loadaddr_low+1
      jsr  tape_load_byte_fast
      sta  zp_decompress_dst+1
      sta  @load_loadaddr_high+1

      ; Load the backup in memory
      ldy  #0
:     jsr  tape_load_byte_fast
      dec  $01                          ; Hide I/O
      sta  (zp_decompress_dst),y
      inc  $01                          ; Enable I/O
      inc  z:zp_decompress_dst
      bne  :-
      inc  z:zp_decompress_dst+1        ; Constant (timeout) of time misure for tape
      bne  :-

      ; Decompress the backup
      lda  #$1B                         ; Enable the screen
      sta  $D011                        ; VIC control register
      lda  #$34                         ; Back to normal memory layout
      sta  $01                          ; 6510 I/O register
@load_loadaddr_low:
      lda  #$FF
      sta  $96
@load_loadaddr_high:
      lda  #$FF
      sta  $97
      ; Decompressed data written to addresses starting at $0403
      lda  #<$0403
      sta  zp_decompress_dst            ; Flag: key STOP/ key RVS
      lda  #>$0403
      sta  zp_decompress_dst+1          ; Constant (timeout) of time misure for tape
      ldy  #0
      ldx  #0
@8:   lda  ($96),y                      ; Number (EOT) of cassette sincronism
      bne  @1
      jsr  load_next_byte
      tax
@2:   jsr load_next_byte
      jsr store_next_byte
      dex
@3:   bne  @2
@6:   jsr  load_next_byte
      lda  $91
      cmp  #<$FFFD
      lda  $92
      sbc  #>$FFFD
      bcc  @8
      bcs  done_decompress
@1:   tax
      dex
      bne  @4
      jsr  load_next_byte
      pha
      jsr  load_next_byte
      sta  z:zp_loaded_byte             ; Store number of bytes into z:zp_loaded_byte
:     jsr  load_next_byte
      jsr  store_next_byte
      inx
      bne  :-
      dec  z:zp_loaded_byte             ; Decrease counter
      bne  :-
      pla
      tax
      sec
      bcs @3
@4:   dex
      beq  @7
      inx
      inx
      jsr  load_next_byte
:     jsr  store_next_byte
      dex
@5:   bne  :-
      beq  @6                           ; Always

@7:   jsr  load_next_byte
      pha
      jsr  load_next_byte
      sta  z:zp_loaded_byte
      jsr  load_next_byte
:     jsr  store_next_byte
      inx
      bne  :-
      dec  z:zp_loaded_byte
      bne  :-
      sta  z:zp_loaded_byte
      pla
      tax
      lda  z:zp_loaded_byte
      cpx  #0
      sec
      bcs  @5                           ; Always

.proc load_next_byte
      inc  z:zp_decompress_src
      bne  :+
      inc  z:zp_decompress_src+1
:     lda  (zp_decompress_src),y
      rts
.endproc

.proc store_next_byte
      sta  (zp_decompress_dst),y
      inc  z:zp_decompress_dst
      bne  :+
      inc  z:zp_decompress_dst+1
:     rts
.endproc

done_decompress:
      ; Restore vectors
:     lda  $0397,y                      ; Tape I/O buffer
      sta  $FFFD,y
      iny
      cpy  #$03
      bne  :-
      lda  #$35
      sta  $01
      ; Store the load_0200 code in the zero page
      ldx  #load_0200_size - 1
:     lda  load_0200,x
      sta  z:zp_load_0200_addr,x
      dex
      bpl  :-
      jsr  tape_prepare
      ; We will jump to load_0200 (in zeropage) via rts, so push adress
      lda  #$00
      pha
      lda  #zp_load_0200_addr -1
      pha
      lda  #$91
      sta  tape_load_byte_fast::bc1+1
      sta  tape_load_byte_fast::bc2+1
      jsr  tape_read_turbotape_header
      jsr  zp_load_0200_addr            ; Load data in $0200
      inc  z:patch_0200_0300_loc
      rts                               ; Load data in $0300
      ; When load_0200 returns, this will continue the backed up program

.proc tape_read_turbotape_header
      ;
      ; A turbotape header starts with a pilot tone of a large amount of $02 bytes
      ; in order to allow synchronization, then $09,$08,$07,$06,$05,$04,$03,$02,$01
      ; to allow a check wether it is a valid header.
      ;
      lda  #$07
      sta  $DD06                        ; Timer B #2: Lo Byte
      ldx  #$01
@1:   jsr  tape_load_bit_fast
      rol  z:zp_loaded_byte             ; Shift into z:zp_loaded_byte
      lda  z:zp_loaded_byte
      cmp  #$02                         ; If we have $02 it might be a pilot tone.
      bne  @1
      ldy  #$09                         ; Count down from 9
:     jsr  tape_load_byte_fast
      cmp  #$02                         ; Skip any remaining bytes of the pilot tone
      beq  :-
:     cpy  z:zp_loaded_byte             ; Equal to counter
      bne  @1                           ; No? Then it wasn't a header
      jsr  tape_load_byte_fast          ; Load next byte
      dey
      bne  :-
      rts
.endproc

.proc tape_prepare
      ; Wait for play on tape
      lda  #$10                         ; Cassette sense bit
:     bit  $01                          ; Cassette sense?
      bne  :-                           ; No, then loop
      lda  $01                          ; 6510 I/O register
      and  #$07                         ; Switch on tape motor
      sta  $01                          ; 6510 I/O register
      ldy  #$00
      lda  #$0B                         ; Disable screen
      sta  $D011                        ; VIC control register
:     dex                               ; Delay loop to wait until bad lines gone
      bne  :-
      dey
      bne  :-
      sei
      rts
.endproc

.proc load_0200
s:    lda  #$08
      sta  z:zp_bit_counter
n:    lda  #$10
:     bit  $DC0D                        ; Interrupt control register CIA #1
      beq  :-
      lda  $DD0D                        ; Interrupt control register CIA #2
      stx  $DD07                        ; Timer B #2: HI Byte
      pha
      lda  #$19                         ; Start timer B
      sta  $DD0F                        ; Control register B of CIA #2
      pla
      lsr                               ; Bit 1 (timer B underflow) to C
      lsr
      rol  z:zp_loaded_byte
      dec  z:zp_bit_counter
      bne  n
      lda  z:zp_loaded_byte
wrt:  sta  $0200,y
      iny
      bne  s
      rts
.endproc

load_0200_size = .sizeof(load_0200)
patch_0200_0300_loc := zp_load_0200_addr + (load_0200::wrt + 2 - load_0200)
