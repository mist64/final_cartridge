; ----------------------------------------------------------------
; BASIC Extension and Speeder Initialization
; ----------------------------------------------------------------

.include "kernal.i"
.include "persistent.i"

; from basic
.import bar_flag

; from printer
.import set_io_vectors_with_hidden_rom

.global entry
.global init_load_and_basic_vectors
.global init_vectors_jmp_bank_2
.global init_basic_vectors
.global go_desktop
.global go_basic
.global cond_init_load_save_vectors
.global init_load_save_vectors

; Bank 2 (Desktop, Freezer/Print) Symbols
desktop_entry   := $8000
LBFFA           := $BFFA

.segment "basic_init"

; ??? unused?
        jsr     set_io_vectors_with_hidden_rom
        lda     #$43 ; bank 2
        jmp     _jmp_bank

init_load_and_basic_vectors:
        jsr     init_load_save_vectors
init_basic_vectors:
        ldx     #basic_vectors_end - basic_vectors - 1
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

entry:
        ; short-circuit startup, skipping memory test
        jsr     $FDA3 ; init I/O
        lda     $D011
        pha
        lda     $DC01
        pha
        lda     #0 ; clear pages 0, 2, 3
        tay
L805A:  sta     $02,y
        sta     $0200,y
        sta     $0300,y
        iny
        bne     L805A
        ldx     #<$A000
        ldy     #>$A000
        jsr     $FE2D ; set memtop
        lda     #>$0800
        sta     $0282 ; start of BASIC $0800
        lda     #>$0400
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
        ldy     #mg87_signature_end - mg87_signature - 1
L809D:  lda     $CFFC,y
        cmp     mg87_signature,y
        bne     L80AA
        dey
        bpl     L809D
        bmi     go_desktop ; MG87 found
L80AA:  jmp     ($A000)

mg87_signature:
        .byte   "MG87"
mg87_signature_end:

go_desktop:
        lda     #$80 ; bar on
        sta     bar_flag
        jsr     $E3BF ; init BASIC, print banner
        lda     #>(desktop_entry - 1)
        pha
        lda     #<(desktop_entry - 1)
        pha
        lda     #$42 ; bank 2
        jmp     _jmp_bank ; jump to desktop

L80C4:  ldx     #'M'
        cpx     $CFFC
        bne     go_basic
        dec     $CFFC ; destroy signature
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
load_save_vectors_end:
basic_vectors:
        .addr   _new_mainloop   ; $0302 IMAIN  BASIC direct mode
        .addr   _new_tokenize   ; $0304 ICRNCH tokenization
        .addr   _new_detokenize ; $0306 IQPLOP token decoder
        .addr   _new_execute    ; $0308 IGONE  execute instruction
        .addr   _new_expression ; $030A IEVAL  execute expression
basic_vectors_end:

; update the load and save vectors only if all hardware vectors are
; the KERNAL defaults
cond_init_load_save_vectors:
        ldy     #$1F
L80EE:  lda     $0314,y
        cmp     $FD30,y
        bne     L810F ; rts
        dey
        bpl     L80EE

init_load_save_vectors:
        jsr     set_io_vectors_with_hidden_rom
        ldy     #load_save_vectors_end - load_save_vectors - 1
L80FE:  lda     load_save_vectors,y ; overwrite LOAD and SAVE vectors
        sta     $0330,y
        dey
        bpl     L80FE
        lda     $02A6
        beq     L810F
        inc     $0330
L810F:  rts
