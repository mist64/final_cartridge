; ----------------------------------------------------------------
; Disk and Tape Speeder
; ----------------------------------------------------------------
; This speeds up LOAD and SAVE on both disk and tape

.include "kernal.i"
.include "persistent.i"

.global new_load
.global new_save

L0110           := $0110

.segment "speeder_a"

new_load:
	jmp new_load2
new_save:
	jmp new_save2

send_byte:
        pha
@1:     bit     $DD00  ; Wait until DATA IN high
        bpl     @1
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        tax
@2:     lda     $D012
        cmp     #$31
        bcc     @3
        and     #$06
        cmp     #$02
        beq     @2
@3:     lda     #$07
        sta     $DD00
        lda     iec_tab,x
        nop
        nop
        sta     $DD00
        lsr     a
        lsr     a
        and     #$F7
        sta     $DD00
        pla
        and     #$0F
        tax
        lda     iec_tab,x
        sta     $DD00
        lsr     a
        lsr     a
        and     #$F7
        sta     $DD00
        lda     #$17
        nop
        nop
        sta     $DD00
        rts
.assert >* = >send_byte, error, "Page boundary!"

iec_tab:
        .byte   $07,$87,$27,$A7,$47,$C7,$67,$E7
        .byte   $17,$97,$37,$B7,$57,$D7,$77,$F7
.assert >* = >iec_tab, error, "Page boundary!"

receive_4_bytes:
        ; Note $DD00 is set to 0 before this routine is called
        ; PAL/NTSC check. Vector points to _new_load for NTSC, _new_load+1 for PAL
        lda     $0330
        cmp     #<_new_load
        beq     @ntsc
        ; PAL
@pal:   bit     $DD00  ; Wait until clock in low
        bvs     @pal
        ldy     #3
        nop
        ldx     $01
@1:     lda     $DD00
        lsr     a
        lsr     a
        nop
        nop
        ora     $DD00
        lsr     a
        lsr     a
        nop
        nop
        ora     $DD00
        lsr     a
        lsr     a
        nop
        nop
        ora     $DD00
        sta     $C1,y
        dey
        bpl     @1
.assert >* = >@pal, error, "Page boundary!"
        rts

@ntsc:  ; NTSC
        bit     $DD00
        bvs     @ntsc
        ldy     #3
        nop
        ldx     $01
@2:     lda     $DD00
        lsr     a
        lsr     a
        nop
        nop
        nop
        ora     $DD00
        lsr     a
        lsr     a
        nop
        nop
        ora     $DD00
        lsr     a
        lsr     a
        nop
        nop
        ora     $DD00
        sta     $C1,y
        dey
        bpl     @2
.assert >* = >@ntsc, error, "Page boundary!"
        rts

; *** tape
L99B5:  tax
        beq     L99C3
        ldx     #$16
:       lda     L9A50,x
        sta     L0110,x
        dex
        bpl     :-
L99C3:  jmp     LA851
; *** tape

L99C6:  jmp     $F530 ; IEC LOAD - used in the error case

L99C9:  pla
        pla
        pla
        tay
        lda     #$F4
        pha
        lda     #$A6
        pha
        jmp     _disable_fc3rom_set_01

L99D6:  pla
        pla
        pla
        tay
        lda     #$F4
        pha
        lda     #$F2
        pha
        jmp     _disable_fc3rom_set_01

new_load2:
        sty     $93
        tya
        ldy     FA
        cpy     #7
        beq     L99B5 ; tape turbo
        cpy     #8
        bcc     L99C9
        cpy     #10
        bcs     L99C9
        tay
        lda     $B7
        beq     L99C9
        jsr     _load_FNADR_indy
        cmp     #$24
        beq     L99C9
        ldx     SA
        cpx     #2
        beq     L99C9
        jsr     print_searching
        lda     #$60
        sta     SA
        jsr     LA71B
        lda     FA
        jsr     $ED09 ; TALK
        lda     SA
        jsr     $EDC7 ; SECTLK
        jsr     $EE13 ; IECIN
        sta     $AE
        lda     ST
        lsr     a
        lsr     a
        bcs     L99C6
        jsr     $EE13 ; IECIN
        sta     $AF
        txa
        bne     L9A35
        lda     $C3
        sta     $AE
        lda     $C4
        sta     $AF
L9A35:  jsr     print_loading
        lda     $AF
        cmp     #4
        bcc     L99D6
        jmp     L9AF0

; ----------------------------------------------------------------

.segment "tape_stack_code"

; will be placed at $0100
load_ac_indy:
        lda     #$0C
        sta     $01
        lda     ($AC),y
        ldy     #$0F
        sty     $01
        ldy     #0
        jmp     LA9BB
load_ac_indy_end:

L9A50:  lda     #$0C
        sta     $01
        lda     ($C3),y
        cmp     $BD
        beq     :+
        stx     ST
:       eor     $D7
        sta     $D7
        lda     #$0F
        sta     $01
        jmp     LA8FF

.segment "speeder_b"

L9A67:  jmp     $F636 ; LDA #0 : SEC : RTS

L9A6A:  jmp     $F5ED ; default SAVE vector

L9A6D:  jmp     $A7C6 ; interpreter loop

new_save2:
        lda     FA
        cmp     #7
        beq     L9A6D ; tape turbo
        cmp     #8
        bcc     L9A6A ; not a drive
        cmp     #10
        bcs     L9A6A ; not a drive (XXX why only support drives 8 and 9?)
        ldy     $B7
        beq     L9A6A
        lda     #$61
        sta     SA
        jsr     LA71B
        jsr     LA77E
        jsr     LA648
        bne     L9A67
        stx     ST
        stx     $A4
        jsr     $FB8E ; copy I/O start address to buffer address
        sec
        lda     $AC
        sbc     #2
        sta     $AC
        bcs     L9AA3
        dec     $AD
L9AA3:  jsr     L9AD0
        lda     $C1
        jsr     L9AC7
        lda     $C2
        jsr     L9AC7
L9AB0:  lda     #$35
        jsr     _load_ac_indy
        jsr     L9AC7
        bne     L9AB0
        lda     $A4
        bmi     L9AC4
        jsr     L9AD0
        jmp     L9AB0

L9AC4:  cli
        clc
        rts

L9AC7:  jsr     send_byte
        jsr     $FCDB ; inc $AC/$AD
        dec     $93
        rts

L9AD0:  sec
        lda     $AE
        sbc     $AC
        tax
        sta     $93
        lda     $AF
        sbc     $AD
        bne     L9AE8
        cpx     #$FF
        beq     L9AE8
        inx
        txa
        dec     $A4
        bne     L9AED
L9AE8:  lda     #$FE
        sta     $93
        tya
L9AED:  jmp     send_byte

L9AF0:  jsr     UNTALK
        jsr     LA691
        lda     #6
        sta     $93
.import __drive_code_load_LOAD__
.import __drive_code_load_RUN__
        lda     #<__drive_code_load_LOAD__
        ldy     #>__drive_code_load_LOAD__
        ldx     #>__drive_code_load_RUN__ ; $0400
        jsr     transfer_code_to_drive
        lda     #<drivecode_load_initialize
        jsr     IECOUT
        lda     #>drivecode_load_initialize
        jsr     IECOUT
        jsr     UNLSTN
        sei
        lda     $D011
        tax
        and     #$10 ; save screen enable bit
        sta     $95
        txa
        and     #$EF
        sta     $D011
        lda     $DD00
        and     #$07
        ora     $95 ; save VIC bank (XXX #$03 would have been enough)
        sta     $95
        lda     $C1
        sta     $A4
        lda     $C2
        sta     SA
        sec
        lda     $AE
        sbc     #2
        sta     ST
        lda     $AF
        sbc     #0
        sta     $A3
@back:  bit     $DD00 ; DATA IN high?
        bmi     @recv ; Then receive data
        cli
        php
        lda     $95
        and     #$07
        sta     $DD00 ; restore VIC bank
        lda     $95
        and     #$10
        ora     $D011 ; restore screen enable bit
        sta     $D011
        lda     $A4
        sta     $C1
        lda     SA
        sta     $C2
        lda     #0
        sta     $A3
        sta     $94
        sta     ST
        lda     #$60
        sta     SA
        lda     #$E0
        jsr     LA612
        jsr     UNLSTN
        plp
        bvs     @done ; used to be "bcs" in 1988-05
        lda     #$1D
        sec
        rts

@done:  lda     #$40
        sta     ST
        jsr     LA694
        jmp     $F5A9 ; LOAD done

@recv:  bvs     @back ; CLOCK IN high? Then back
        lda     #$20  ; DATA OUT high, CLOCK OUT 0
        sta     $DD00
@1:     bit     $DD00 ; Wait until CLOCK IN is high
        bvc     @1
        lda     #0    ; Clear $DD00 to simply receive algorithm
        sta     $DD00
        jsr     receive_4_bytes
        lda     #$FE
        sta     $A5
        lda     $C3
        clc
        adc     $A3
        tax
        asl     $C3
        php
        sec
        lda     ST
        sbc     $C3
        sta     $93
        bcs     @2
        dex
@2:     plp
        bcc     @3
        dex
@3:     stx     $94
        ror     $C3
        ldx     $C2
        beq     @4
        dex
        stx     $A5
        txa
        clc
        adc     $93
        sta     $AE
        lda     $94
        adc     #0
        sta     $AF
@4:     ldy     #0
        lda     $C3
        bne     @8
        jsr     receive_4_bytes ; in $C1..$C4
        ldy     #2
        ldx     #2
        bne     @5
@8:     lda     $C1
        sta     ($93),y
        iny
@9:     tya
        pha
        jsr     receive_4_bytes ; in $C1..C4
        pla
        tay
        ldx     #3
@5:     cpy     $A5
        bcs     @6
        lda     $C1,x           ; copy bytes ...
        sta     ($93),y         ; ...to target memory
@6:     iny
        cpy     #$FE
        bcs     @7
        dex
        bpl     @5
        bmi     @9
@7:     jmp     @back

; ----------------------------------------------------------------

.segment "drive_code_load" ; $0400

sector_not_needed = $FF

drive_code_load:
        lda     $43        ; Number of sectors on current track
        sta     $C1
L9BFE:
        ;
        ; Here we wait for a sector header and read it
        ;
        jsr     wait_for_header ; (sets Y=0)
        ; 7 more bytes to read
@1:     bvc     @1         ; Loop until byte ready
        clv
        lda     $1C01      ; Read next byte of header
        sta     $25,y      ; Store
        iny
        cpy     #7         ; Did we read 7 bytes?
        bne     @1         ; No? Read next byte
        ; Sector header has been read

        ; 
        ; Now we read 5 bytes of the sector data
        ;
        jsr     $F556      ; Wait for SYNC (sets Y=0)
@2:     bvc     @2         ; Loop until byte ready
        clv
        lda     $1C01
        sta     ($30),y
        iny
        cpy     #5         ; Did we read 5 bytes?
        bne     @2         ; No? Read next byte
        jsr     $F497      ; GCR decode header (not sector data) and write to $16..$1A

        ; Check checksum $1A = $16 xor $17 xor $18 xor $19
        ; Therefore xorring $16..$1A should result in 0
        ldx     #5
        lda     #0
@3:     eor     $15,x
        dex
        bne     @3
        tay
        beq     @4
@error: jmp     $F40B     ; Read error

                          ; X=0
@4:     inx               ; X=1
@6:     lda     $12,x     ; Compare expected header ID
        cmp     $16,x     ; ..  with read header ID
        bne     @error
        dex
        bpl     @6

        jsr     $F7E8     ; GCR decode first 5 bytes of sector data and write to $52..$55
        ldx     $19       ; Is the sector number that we read smaller
        cpx     $43       ; than the number of sectors on this track?
        bcs     @error
        lda     $53       ; Store next track
        sta     track_links,x
        lda     $54       ; Store next sector
        sta     sector_links,x
        lda     #sector_not_needed
        sta     sector_order,x ; initialize array
        dec     $C1
        bne     L9BFE
        
        ;
        ; Now build the sector_order array
        ;
        lda     #1
        sta     $C3
        ldx     $09       ; Sector last read
@7:     lda     $C2       ; Counter, initalized to 0 by drivecode_load_initialize
        sta     sector_order,x
        inc     $C2
        lda     track_links,x
        cmp     $08       ; Next sector on the same track as last?
        bne     @8        ; Then sector_order array is finished
        lda     sector_links,x ; Chain to
        tax                    ; next sector of file
        inc     $C3
        bne     @7
        beq     @error         ; If $C3 hits 0 (255 iterations), then there must be a cycle in the sector chain
        
        ;
        ; When we arrive here we either need to continue on a different track, or
        ; we hit the final sector of the file (A=0). Either way the sector_order array
        ; is complete.
        ;
@8:     cmp     #$24           ; Track >=36 ?
        bcs     @error         ; Then a problem. NOTE: This is incompatible with dual sided disks on 1571.
        sta     $08
        lda     sector_links,x
        sta     $09

        ;
        ; Wait for a sector header and read it
        ;
@9:     jsr     wait_for_header ; (sets Y=0)
        iny
        ; 3 more bytes to read
@10:    bvc     @10       ; Loop until byte ready
        clv
        lda     $1C01
        sta     ($30),y
        iny
        cpy     #4
        bne     @10
        ldy     #0
        jsr     $F7E8     ; GCR decode the bytes
        ldx     $54       ; If sector number
        cpx     $43       ; >= number of sectors on track
        bcs     @error    ; then there is a problem
        lda     sector_order,x
        cmp     #sector_not_needed   ; If we don't need to read this sector,
        beq     @9                   ; Wait for the next one
        stx     $C0

        ;
        ; This is a sector we need. so read its contents
        ;
        jsr     $F556     ; Wait for SYNC (sets Y=0)
        ; Read 256 bytes in the buffer
@11:    bvc     @11       ; Loop until byte ready
        clv
        lda     $1C01
        sta     ($30),y
        iny
        bne     @11
        ; Read another 70 bytes in the auxiliary buffer at end of the stack
        ldy     #$BA
@12:    bvc     @12      ; Loop until byte ready
        clv
        lda     $1C01
        sta     $0100,y
        iny
        bne     @12
        ; GCR decode bytes
        jsr     $F7E8
        lda     $53      ; Get link to next track ???
        beq     @13      ; 0? Then skip
        lda     #0       ; Clear link to next sector ???
        sta     $54
@13:    sta     $34
        sta     $C1
        ldx     $C0
        lda     sector_order,x
        sta     $53
        lda     #sector_not_needed   ; We won't need this sector anymore
        sta     sector_order,x
        jsr     $F6D0
        lda     #$42
        sta     $36

        ; Signal C64 that we want to transmit
        ldy     #$08     ; Clock out high, data out low
        sty     $1800
        ; C64 will set DATA IN high if it is ready to receive
@14:    lda     $1800
        lsr     a
        bcc     @14
        ldy     #0
@next:
        dec     $36
        sty     $1800
        bne     @transmit_buffer
        dec     $C3       ; Did we read all blocks?
        bne     @9
        jmp     $F418     ; Set buffer status at $0001 to 01 (succesfull completion)

@transmit_buffer:
        ; 5 bytes of GCR data become 4 bytes of decoded data. But the GCR data will not be decoded
        ; into raw data, but directly decoded into values that can be written to VIA register $1800.
        ; In order to convert to register values, we will convert the 5 bytes GCR into 8 "quintets"
        ; of 5 bits that we will store at $55..$5D.
        ;
        ; A "quintet" can be convert to 4 bits of decoded data by a lookup table, but we are not
        ; going to generate decoded data, but VIA register values. We transmit two bytes at a time
        ; over the serial bus via the clock and data lines. Thus in order to transmit 4 bits, we need
        ; two VIA register values that will be transmited after each other.
        ;
        ; In other words, we need two 32 byte lookup tables. However, because in a GCR code, no two
        ; zeros can occur in a row, the first 8 values will never occur and we can limit ourselves
        ; to 24 byte lookup tables.
        ;
        ; Convert to nibbles:
        ldy     $C1
        lda     ($30),y
        lsr     a
        lsr     a
        lsr     a
        sta     $5C
        lda     ($30),y
        and     #$07
        sta     $5D
        iny
        bne     @16      ; Not end of regular buffer?
        iny              ; End of register buffer
        sty     $31
        ldy     #$BA     ; Continue from auxiliary buffer at $01BA
@16:    lda     ($30),y
        asl     a
        rol     $5D
        asl     a
        rol     $5D
        lsr     a
        lsr     a
        lsr     a
        sta     $5A
        lda     ($30),y
        lsr     a
        iny
        lda     ($30),y
        rol     a
        rol     a
        rol     a
        rol     a
        rol     a
        and     #$1F
        sta     $5B
        lda     ($30),y
        and     #$0F
        sta     $58
        iny
        lda     ($30),y
        asl     a
        rol     $58
        lsr     a
        lsr     a
        lsr     a
        sta     $59
        lda     ($30),y
        asl     a
        asl     a
        asl     a
        and     #$18
        sta     $56
        iny
        lda     ($30),y
        rol     a
        rol     a
        rol     a
        rol     a
        and     #$07
        ora     $56
        sta     $56
        lda     ($30),y
        and     #$1F
        sta     $57
        iny
        sty     $C1
        ; Transmit the 4-byte tuple to the C64
        ; $55..5D contain indexes into the tables with CIA register values
        ldy     #$08        ; Signal C64 with CLOCK OUT high, DATA OUT low
        sty     $1800
        ldx     $55,y
        ; Transmit bits 0-1 of the 4 bits of decoded data
@17:    lda     regvalue_lookup_01 - 8,x  ; - 8 because the table is only 24 rather than 32 bytes
        sta     $1800
        ; Transmit bits 2-3 of the 4 bits of decoded data
        lda     regvalue_lookup_23 - 8,x  ; - 8 because the table is only 24 rather than 32 bytes
        ldx     $54,y
        sta     $1800
        dey
        bne     @17
        jmp     @next

wait_for_header:
        ldx     #3
        stx     $31
@try_again:
        inx
        bne     @try
        jmp     $F40B    ; Read error

@try:   jsr     $F556    ; Wait for SYNC on disk (sets Y=0)
@1:     bvc     @1       ; Loop until byte ready
        clv
        lda     $1C01
        cmp     $24      ; Header block ID as expected?
        bne     @try_again
        rts

drivecode_load_initialize:
        ldx     #$00     ; CLOCK OUT low, DATA OUT low
        stx     $1800
        stx     $C2
        lda     $19      ; Sector number last read sector (first sector of program file)
        sta     $09      ; Buffer 1 sector
        lda     $18      ; Track of last read reactor  (first sector of program file)
        sta     $08      ; Buffer 1 track
        ; The drive code is in memory at $400, the address of buffer 1.
        ; So we want to send an execute command for buffer 1.
@2:     lda     #$E0     ; $E0 = read sector header and then execute code in buffer
        sta     $01
@1:     lda     $01      ; Wait until command has completed
        bmi     @1
        ;
        ; If the command has completed, it means the load has completed.
        ;
        cmp     #2       ; >=2 means error
        bcs     @error
        lda     $08
        bne     @2
        lda     #$02     ; DATA OUT high, CLOCK OUT low 
        sta     $1800
        jmp     $C194    ; Prepare status message

@error: inx
        ldy     #$0A     ; DATA out high, lock out high
        sty     $1800
        jmp     $E60A    ; 21, 'read error'

regvalue_lookup_01:
        .byte   0, 10, 10, 2
        .byte   0, 10, 10, 2
        .byte   0, 0, 8, 0
        .byte   0, 0, 8, 0
        .byte   0, 2, 8, 0
        .byte   0, 2, 8, 0
regvalue_lookup_23:
        .byte   0, 8, 10, 10
        .byte   0, 0, 2, 2
        .byte   0, 0, 10, 10
        .byte   0, 0, 2, 2
        .byte   0, 8, 8, 8
        .byte   0, 0, 0, 0
sector_links:
track_links := sector_links + 21
sector_order := track_links + 21

; ----------------------------------------------------------------
; drive code $0500
; ----------------------------------------------------------------
.segment "drive_code_save"

ram_code := $0150

drive_code_save:
        lda     L0612
        tax
        lsr     a
        adc     #3
        sta     $95
        sta     $31
        txa
        adc     #6
        sta     $32
LA510:  jsr     receive_byte
        beq     :+
        sta     $81
        tax
        inx
        stx     L0611
        lda     #0
        sta     $80
        beq     LA534

:       lda     $02FC
        bne     :+
        lda     $02FA ; XXX ORing the values together is shorter
        bne     :+
        lda     #$72
        jmp     $F969 ; DISK FULL

:       jsr     $F11E ; find and allocate free block
LA534:  ldy     #0
        sty     $94
        lda     $80
        sta     ($94),y
        iny
        lda     $81
        sta     ($94),y
        iny
LA542:  jsr     receive_byte
        sta     ($30),y
        iny
        cpy     L0611
        bne     LA542
        jsr     ram_code
        inc     $B6
        ldx     L0612
        lda     $81
        sta     $07,x
        lda     $80
        cmp     $06,x
        beq     LA510
        sta     $06,x
        jmp     $F418 ; set OK code

receive_byte:
        lda     #$00
        sta     $1800
        lda     #$04
:       bit     $1800
        bne     :-
        sta     $C0
drive_code_save_timing_selfmod1:
        sta     $C0
        lda     $1800
        asl     a
        nop
        nop
        ora     $1800
        asl     a
        asl     a
        asl     a
        asl     a
        sta     a:$C0 ; 16 bit address for timing!
        lda     $1800
        asl     a
        nop
L0589:
        nop
L058A:
        ora     $1800
        and     #$0F
        ora     $C0
        sta     $C0
        lda     #$02
        sta     $1800
        lda     $C0
        rts
L0589_end:
        nop ; filler, gets overwritten when L0589 gets copied down by 1 byte

L059C:
        lda     #$EA
        sta     drive_code_save_timing_selfmod1
        sta     drive_code_save_timing_selfmod1 + 1 ; insert 1 cycle into code
        ldx     #L0589_end - L0589 - 1
LA5A6:  lda     L0589,x
        sta     L058A,x ; insert 3 cycles into code
        dex
        bpl     LA5A6
L05AF:
        ldx     #$64
LA5B1:  lda     $F575 - 1,x; copy "write data block to disk" to RAM
        sta     ram_code - 1,x
        dex
        bne     LA5B1
        lda     #$60
        sta     ram_code + $64 ; add RTS at the end, just after GCR decoding
        inx
        stx     $82
        stx     $83
        jsr     $DF95
        inx
        stx     $1800
LA5CB:  inx
        bne     LA5CB
        sta     L0612 + 1
        asl     a
        sta     L0612
        tax
        lda     #$40
        sta     $02F9
LA5DB:  lda     $06,x
        beq     LA5FA
        sta     $0A
        lda     #$E0
        sta     $02
LA5E5:  lda     $02
        bmi     LA5E5
        cmp     #2
        bcc     LA5DB
        cmp     #$72
        bne     LA5F4
        jmp     $C1C8 ; set error message

LA5F4:  ldx     L0612 + 1
        jmp     $E60A

LA5FA:  ldx     #L0608_end - L0608
LA5FC:  lda     L0608 - 1,x
        sta     ram_code - 1,x
        dex
        bne     LA5FC
        jmp     ram_code

L0608:
        jsr     $DBA5 ; write directory entry
        jsr     $EEF4 ; write BAM
        jmp     $D227 ; close channel
L0608_end:

L0611:
        .byte   0
L0612:


; ----------------------------------------------------------------
; C64 IEC code
; ----------------------------------------------------------------
.segment "speeder_c"

LA612:  pha
        lda     FA
        jsr     LISTEN
        pla
        jmp     SECOND

LA61C:  lda     #$6F
        pha
        lda     FA
        jsr     TALK
        pla
        jmp     TKSA

LA628:  jsr     LA632
        jsr     $E716 ; KERNAL: output character to screen
        tya
        jmp     $E716 ; KERNAL: output character to screen

LA632:  pha
        and     #$0F
        jsr     LA63E
        tay
        pla
        lsr     a
        lsr     a
        lsr     a
        lsr     a
LA63E:  clc
        adc     #$F6
        bcc     LA645
        adc     #$06
LA645:  adc     #$3A
LA647:  rts

LA648:
        jsr     LA6C1
        bne     LA647
        lda     #7
        sta     $93
.import __drive_code_save_LOAD__
.import __drive_code_save_RUN__
        lda     #<__drive_code_save_LOAD__
        ldy     #>__drive_code_save_LOAD__
        ldx     #>__drive_code_save_RUN__
        jsr     transfer_code_to_drive
        lda     $0330
        cmp     #<_new_load
        beq     LA66A ; speeder enabled
        lda     #<L059C
        jsr     IECOUT
        lda     #>L059C
        bne     LA671

LA66A:  lda     #<L05AF
        jsr     IECOUT
        lda     #>L05AF
LA671:  jsr     IECOUT
        jsr     UNLSTN
        sei
        lda     $D015
        sta     $93
        sty     $D015
        lda     $DD00
        and     #$07
        sta     $A4
        ora     #$10
        sta     $A5
        sta     $DD00
        jmp     LA9F6

LA691:
        ldy     #0
        .byte   $2C
LA694:
        ldy     #8
        bit     $9D
        bpl     LA6A7
        jsr     LA6A8
        lda     $AF
        jsr     LA628
        lda     $AE
        jmp     LA628

LA6A7:  rts

LA6A8:  lda     s_from,y
        beq     LA6A7
        jsr     $E716 ; KERNAL: output character to screen
        iny
        bne     LA6A8

s_from: .byte   " FROM $", 0
        .byte   " TO $", 0

LA6C1:  jsr     LA61C
        jsr     IECIN ; first character, ASCII error code
        tay
LA6C8:  jsr     IECIN
        cmp     #CR
        bne     LA6C8 ; read until CR
        jsr     UNTALK
        cpy     #'0' ; = no error
        rts

transfer_code_to_drive:
        sta     $C3
        sty     $C4
        ldy     #0
LA6DB:  lda     #'W'
        jsr     LA707 ; send "M-W"
        tya
        jsr     IECOUT
        txa
        jsr     IECOUT
        lda     #$20
        jsr     IECOUT
LA6ED:  lda     ($C3),y
        jsr     IECOUT
        iny
        tya
        and     #$1F
        bne     LA6ED
        jsr     UNLSTN
        tya
        bne     LA6DB
        inc     $C4
        inx
        cpx     $93
        bcc     LA6DB
        lda     #'E' ; send "M-E"
LA707:  pha
        lda     #$6F
        jsr     LA612
        lda     #'M'
        jsr     IECOUT
        lda     #'-'
        jsr     IECOUT
        pla
        jmp     IECOUT

LA71B:
        ldy     #0
        sty     ST
        lda     FA
        jsr     $ED0C ; LISTEN
        lda     SA
        ora     #$F0
        jsr     $EDB9 ; SECLST
        lda     ST
        bpl     LA734
        pla
        pla
        jmp     $F707 ; DEVICE NOT PRESENT ERROR

LA734:  jsr     _load_FNADR_indy
        jsr     $EDDD ; KERNAL IECOUT
        iny
        cpy     $B7
        bne     LA734
        jmp     $F654 ; UNLISTEN

LA742:  jsr     $F82E ; cassette sense
        beq     LA764
        ldy     #$1B
LA749:  jsr     LA7B3
LA74C:  bit     $DC01
        bpl     LA766
        jsr     $F82E ; cassette sense
        bne     LA74C
        ldy     #$6A
        jmp     LA7B3

LA75B:  jsr     $F82E ; cassette sense
        beq     LA764
        ldy     #$2E
LA762: ; ???
        bne     LA749
LA764:  clc
        rts

LA766:  sec
        rts

print_found:
        lda     $9D
        bpl     LA7A7
        ldy     #$63 ; "FOUND"
        jsr     print_kernal_string
        ldy     #5
LA773:  lda     ($B2),y
        jsr     $E716 ; KERNAL: output character to screen
        iny
        cpy     #$15
        bne     LA773
        rts

LA77E:  jsr     LA7B1
        bmi     LA796
        rts

print_searching:
        lda     $9D
        bpl     LA7A7
        ldy     #$0C ; "SEARCHING"
        jsr     print_kernal_string
        lda     $B7
        beq     LA7A7
        ldy     #$17 ; "FOR"
        jsr     print_kernal_string
LA796:  ldy     $B7
        beq     LA7A7
        ldy     #0
LA79C:  jsr     _load_FNADR_indy
        jsr     $E716 ; KERNAL: output character to screen
        iny
        cpy     $B7
        bne     LA79C
LA7A7:  rts

print_loading:
        ldy     #$49 ; "LOADING"
        lda     $93
        beq     LA7B3
        ldy     #$59 ; "VERIFYING"
        .byte   $2C
LA7B1:  ldy     #$51 ; "SAVING"
LA7B3:  bit     $9D
        bpl     LA7C4
print_kernal_string:
        lda     $F0BD,y ; KERNAL strings
        php
        and     #$7F
        jsr     $E716 ; KERNAL: output character to screen
        iny
        plp
        bpl     print_kernal_string ; until MSB set
LA7C4:  clc
        rts

; ----------------------------------------------------------------
; tape related

.segment "tape"

; ??? unused?
        ldx     #load_ac_indy_end - load_ac_indy - 1
:       lda     load_ac_indy,x
        sta     L0110,x
        dex
        bpl     :-
        ldx     #5
        stx     $AB
        jsr     $FB8E ; copy I/O start address to buffer address
        jsr     LA75B
        bcc     :+
        lda     #0
        jmp     _disable_fc3rom
:       jsr     LA77E
        jsr     turn_screen_off
        jsr     LA999
        lda     SA
        clc
        adc     #1
        dex
        jsr     LA9BB
        ldx     #8
:       lda     $AC,y
        jsr     LA9BB
        ldx     #6
        iny
        cpy     #5
        nop
        bne     :-
        ldy     #0
        ldx     #2
LA808:  jsr     _load_FNADR_indy
        cpy     $B7
        bcc     :+
        lda     #$20
        dex
:       jsr     LA9BB
        ldx     #3
        iny
        cpy     #$BB
        bne     LA808
        lda     #2
        sta     $AB
        jsr     LA999
        tya
        jsr     LA9BB
        sty     $D7
        ldx     #5
LA82B:  jsr     L0110
        ldx     #3 ; used to be "#2" in 1988-05
        inc     $AC
        bne     :+
        inc     $AD
        dex
:       lda     $AC
        cmp     $AE
        lda     $AD
        sbc     $AF
        bcc     LA82B
LA841:  lda     $D7
        jsr     LA9BB
        ldx     #7
        dey
        bne     LA841
        jsr     LA912
        jmp     _disable_fc3rom

LA851:  jsr     LA8C9
        lda     $AB
        cmp     #2
        beq     LA862
        cmp     #1
        bne     LA851
        lda     SA
        beq     LA86C ; "LOAD"[...]",n,0" -> skip load address
LA862:  lda     $033C
        sta     $C3
        lda     $033D
        sta     $C4
LA86C:  jsr     print_found
        cli
        lda     $A1
        jsr     $E4E0 ; wait for CBM key
        sei
        lda     $01
        and     #$1F
        sta     $01
        ldy     $B7
        beq     LA88C
LA880:  dey
        jsr     _load_FNADR_indy
        cmp     $0341,y
        bne     LA851
        tya
        bne     LA880
LA88C:  sty     ST
        jsr     print_loading
        lda     $C3
        sta     $AC
        lda     $C4
        sta     $AD
        sec
        lda     $033E
        sbc     $033C
        php
        clc
        adc     $C3
        sta     $AE
        lda     $033F
        adc     $C4
        plp
        sbc     $033D
        sta     $AF
        jsr     LA8E5
        lda     $BD
        eor     $D7
        ora     ST
        clc
        beq     LA8C2
        sec
        lda     #$FF
        sta     ST
LA8C2:  ldx     $AE
        ldy     $AF
        jmp     _disable_fc3rom

LA8C9:  jsr     LA92B
        lda     $BD
        cmp     #0 ; XXX not needed
        beq     LA8C9
        sta     $AB
LA8D4:  jsr     LA96E
        lda     $BD
        sta     ($B2),y
        iny
        cpy     #$C0
        bne     LA8D4
        beq     LA913
LA8E2:  jmp     L0110

LA8E5:  jsr     LA92B
LA8E8:  jsr     LA96E
        cpy     $93
        bne     LA8E2
        lda     #$0B
        sta     $01
        lda     $BD
        sta     ($C3),y
        eor     $D7
        sta     $D7
        lda     #$0F
        sta     $01
LA8FF:
        inc     $C3
        bne     LA905
        inc     $C4
LA905:  lda     $C3
        cmp     $AE
        lda     $C4
        sbc     $AF
        bcc     LA8E8
        jsr     LA96E
LA912:  iny
LA913:  sty     $C0
        lda     #0
        sta     $02A0
        lda     $D011
        ora     #$10
        sta     $D011 ; turn screen on
        lda     $01
        ora     #$20
        sta     $01
        cli
        clc
        rts

LA92B:  jsr     LA742
        bcc     LA939
        pla
        pla
        pla
        pla
        lda     #0
        jmp     _disable_fc3rom

LA939:  jsr     turn_screen_off
        sty     $D7
        lda     #$07
        sta     $DD06
        ldx     #1
LA945:  jsr     LA97E
        rol     $BD
        lda     $BD
        cmp     #2
        beq     LA954
        cmp     #$F2
        bne     LA945
LA954:  ldy     #9
LA956:  jsr     LA96E
        lda     $BD
        cmp     #2
        beq     LA956
        cmp     #$F2
        beq     LA956
LA963:  cpy     $BD
        bne     LA945
        jsr     LA96E
        dey
        bne     LA963
        rts

LA96E:  lda     #8
        sta     $A3
LA972:  jsr     LA97E
        rol     $BD
        nop
        nop
        dec     $A3
        bne     LA972
        rts

LA97E:  lda     #$10
LA980:  bit     $DC0D
        beq     LA980
        lda     $DD0D
        stx     $DD07
        pha
        lda     #$19
        sta     $DD0F
        pla
        lsr     a
        lsr     a
        rts

        lda     #4
        sta     $AB
LA999:  ldy     #0
LA99B:  lda     #2
        jsr     LA9BB
        ldx     #7
        dey
        cpy     #9
        bne     LA99B
        ldx     #5
        dec     $AB
        bne     LA99B
LA9AD:  tya
        jsr     LA9BB
        ldx     #7
        dey
        bne     LA9AD
        dex
        dex
        sty     $D7
        rts

LA9BB:  sta     $BD
        eor     $D7
        sta     $D7
        lda     #8
        sta     $A3
LA9C5:  asl     $BD
        lda     $01
        and     #$F7
        jsr     LA9DD
        ldx     #$11
        nop
        ora     #8
        jsr     LA9DD
        ldx     #14
        dec     $A3
        bne     LA9C5
        rts

LA9DD:  dex
        bne     LA9DD
        bcc     LA9E7
        ldx     #11
LA9E4:  dex
        bne     LA9E4
LA9E7:  sta     $01
        rts

turn_screen_off:
        ldy     #0
        sty     $C0
        lda     $D011
        and     #$EF
        sta     $D011 ; turn screen off
LA9F6:  dex
        bne     LA9F6 ; delay (XXX waiting for $D012 == 0 would be cleaner)
        dey
        bne     LA9F6
        sei
        rts

; XXX junk
        sei
        rts
