;   The Final Cartridge 3
;
;   - 4 16K ROM Banks at $8000/$a000 (=64K)
;
;        Bank 0:  BASIC, Monitor, Disk-Turbo
;        Bank 1:  Notepad, BASIC (Menu Bar)
;        Bank 2:  Desktop, Freezer/Print
;        Bank 3:  Freezer, Compression
;
;   - the cartridges uses the entire io1 and io2 range
;
;   - one register at $DFFF:
;
;    7      Hide this register (1 = hidden)
;    6      NMI line   (0 = low = active) *1)
;    5      GAME line  (0 = low = active) *2)
;    4      EXROM line (0 = low = active)
;    2-3    unassigned (usually set to 0)
;    0-1    number of bank to show at $8000
;
;    1) if either the freezer button is pressed, or bit 6 is 0, then
;       an NMI is generated
;
;    2) if the freezer button is pressed, GAME is also forced low
;
;    - the rest of io1/io2 contain a mirror of the last 2 pages of the
;      currently selected rom bank (also at $dfff, contrary to what some
;      other documents say)

        .setcpu "6502"
        .include "kernal.i"
        .include "persistent.i"

.global set_io_vectors
.global set_io_vectors_with_hidden_rom

; from format
.import fast_format
.import init_read_disk_name
.import init_write_bam

; from editor
.import print_screen

; from desktop_helper
.import perform_desktop_disk_operation

; from basic
.import bar_flag

; ----------------------------------------------------------------
; Bank 2 (Desktop, Freezer/Print) Symbols
; ----------------------------------------------------------------
L8000           := $8000
LBFFA           := $BFFA

; variables

.segment "A000_vectors"

        .addr   entry ; FC3 entry
        .addr   $FE5E ; default cartridge soft reset entry point
        .byte   $C3,$C2,$CD,"80" ; 'cbm80'

entry:  jmp     entry2

; this vector is called from other banks
        jmp     perform_desktop_disk_operation

.global do_fast_format
do_fast_format: ; monitor calls this
        jmp     fast_format

; this vector is called from other banks
        jmp     init_read_disk_name
        jmp     init_write_bam
        jmp     init_vectors_jmp_bank_2
        jmp     go_basic
        jmp     print_screen
        jmp     init_load_and_basic_vectors

; ----------------------------------------------------------------
; startup and vectors
; ----------------------------------------------------------------

.segment "basic_init"

; ??? unused?
        jsr     set_io_vectors_with_hidden_rom
        lda     #$43 ; bank 2
        jmp     _jmp_bank

init_load_and_basic_vectors:
        jsr     init_load_save_vectors
.global init_basic_vectors
init_basic_vectors:
        ldx     #$09
L8031:  lda     basic_vectors,x ; overwrite BASIC vectors
        sta     $0302,x
        dex
        bpl     L8031
        rts

init_vectors_jmp_bank_2:
        jsr     init_load_save_vectors
        jsr     init_basic_vectors
        lda     #>(LBFFA - 1)
        pha
        lda     #<(LBFFA - 1) ; ???
        pha
        lda     #$42 ; bank 2
        jmp     _jmp_bank

entry2: 
        ; short-circuit startup, skipping memory test
        jsr     $FDA3 ; init I/O
        lda     $D011
        pha
        lda     $DC01
        pha
        lda     #$00 ; clear pages 0, 2, 3
        tay
L805A:  sta     $02,y
        sta     $0200,y
        sta     $0300,y
        iny
        bne     L805A
        ldx     #<$A000
        ldy     #>$A000
        jsr     $FE2D ; set memtop
        lda     #$08
        sta     $0282 ; start of BASIC $0800
        lda     #$04
        sta     $0288 ; start of screen RAM $0400
        lda     #<$033C
        sta     $B2
        lda     #>$033C
        sta     $B3 ; datasette buffer
        jsr     $FD15 ; init I/O (same as RESTOR)
        jsr     $FF5B ; video reset (same as CINT)
        jsr     $E453 ; assign $0300 BASIC vectors
        jsr     init_load_and_basic_vectors
        cli
        pla ; $ D
        tax
        pla
        cpx     #$7F ; $DC01 value
        beq     L80C4 ; 1988-13 changes this to "bne" to start into BASIC
        cpx     #$DF
        beq     go_desktop
        and     #$7F
        beq     go_desktop
        ldy     #$03
L809D:  lda     $CFFC,y
        cmp     mg87_signature,y
        bne     L80AA
        dey
        bpl     L809D
        bmi     go_desktop ; MG87 found
L80AA:  jmp     ($A000)

mg87_signature:
        .byte   "MG87"

.global go_desktop
go_desktop:
        lda     #$80 ; bar on
        sta     bar_flag
        jsr     $E3BF ; init BASIC, print banner
        lda     #>(L8000 - 1)
        pha
        lda     #<(L8000 - 1)
        pha
        lda     #$42 ; bank 2
        jmp     _jmp_bank ; jump to desktop

L80C4:  ldx     #'M'
        cpx     $CFFC
        bne     go_basic
        dec     $CFFC ; destroy signature
.global go_basic
go_basic:
        ldx     #<$A000
        ldy     #>$A000
        jsr     $FE2D ; set MEMTOP
        lda     #>($E397 - 1)
        pha
        lda     #<($E397 - 1) ; BASIC start
        pha
        jmp     _disable_rom

load_save_vectors:
        .addr   _new_load       ; $0330 LOAD
        .addr   _new_save       ; $0332 SAVE
basic_vectors:
        .addr   _new_mainloop   ; $0302 IMAIN  BASIC direct mode
        .addr   _new_tokenize   ; $0304 ICRNCH tokenization
        .addr   _new_detokenize ; $0306 IQPLOP token decoder
        .addr   _new_execute    ; $0308 IGONE  execute instruction
        .addr   _new_expression ; $030A IEVAL  execute expression

; update the load and save vectors only if all hardware vectors are
; the KERNAL defaults
.global cond_init_load_save_vectors
cond_init_load_save_vectors:
        ldy     #$1F
L80EE:  lda     $0314,y
        cmp     $FD30,y
        bne     L810F ; rts
        dey
        bpl     L80EE

.global init_load_save_vectors
init_load_save_vectors:
        jsr     set_io_vectors_with_hidden_rom
        ldy     #$03
L80FE:  lda     load_save_vectors,y ; overwrite LOAD and SAVE vectors
        sta     $0330,y
        dey
        bpl     L80FE
        lda     $02A6
        beq     L810F
        inc     $0330
L810F:  rts
