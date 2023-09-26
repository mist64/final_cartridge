; ----------------------------------------------------------------
; I/O Area ROM
; ----------------------------------------------------------------
; This is a max. 512 byte section that lives at $1E00-$1FFF of
; bank 0 of the ROM, and will also be mapped into the I/O extension
; area at $DE00-$DFFF, so it's always visible.
; It mostly contains wrappers around BASIC, KERNAL or cartridge
; functions that switch the ROM config in addition.

.include "kernal.i"
.include "fc3ioreg.i"

; from printer
.import new_clrch
.import new_clall
.import new_bsout
.import new_ckout

; from basic
.import reset_warmstart
.import new_tokenize
.import new_execute
.import new_expression
.import new_detokenize
.import new_mainloop

; from editor
.import kbd_handler

; from wrapper
.import disable_rom_then_warm_start

; from speeder
.import new_save
.import new_load

; from desktop_helper
.import load_and_run_program

chrget                         = $0073
basic_relink                   = $A533
basic_search_line              = $A613
basic_set_TXTPTR_to_TXTTAB     = $A68E
basic_list_print_non_token_byte =$A6F3
basic_detokenize               = $A724
basic_execute_next_statement   = $A7AE
basic_continue_execute         = $A7EF
basic_check_stop               = $A82C
basic_string_to_word           = $A96B
basic_print_char               = $AB47
basic_continue_arithmic_element= $AE8D
basic_floatptr22_to_fac1       = $BBA6
basic_add_a_to_fac1            = $BD7E		; Add a as signed integer to float accu
basic_LINPRT                   = $BDCD		; Print 16 bit number in AX
basic_FRMNUM                   = $AD8A
basic_GETADR                   = $B7F7
basic_ay_to_fac1               = $B395
kernal_get_filename            = $E257
kernal_basic_warmstart         = $E37B		; Kernal basic warm start entry
kernel_print_startup_messages  = $E422
kernel_keyboard_handler        = $EB42
kernal_check_modifier_keys     = $EB48

.segment        "romio"

LDE00:  .byte   $40

;
; Jump into a bank of the FC3 ROM
;
; Jumps to a routine in the FC3 ROM of which the address is on the stack
; and the bank number in A.
;

.global _jmp_bank
_jmp_bank:
        sta     fcio_reg
        rts

;
; Makes bank 0 of the FC3 ROM visible at $8000..$AFFF
;

.global _enable_fcbank0
_enable_fcbank0: ; $DE05
        pha
        lda     #fcio_bank_0|fcio_c64_16kcrtmode|fcio_nmi_line
a_to_fcio_pla:
        sta     fcio_reg
        pla
        rts

;
; _disable_fc3rom:			Hides the FC3 ROMS from memory
; _disable_fc3rom_set_01:	Stores Y into $01 and hides the FC3 ROMS from memory
;

.global _disable_fc3rom_set_01
_disable_fc3rom_set_01:; $DE0D
        sty     $01
.global _disable_fc3rom
_disable_fc3rom: ; $DE0F
        pha
        lda     #fcio_bank_0|fcio_c64_crtrom_off|fcio_nmi_line
        bne     a_to_fcio_pla		; always taken


;
; Disable the FC3 ROMS and jump to the basic warm start
;

.global _basic_warm_start
_basic_warm_start: ; $DE14
        jsr     _disable_fc3rom
        jmp     kernal_basic_warmstart

enable_all_roms:  
        ora     #$07
        sta     $01
        bne     _enable_fcbank0		; always taken


;
; KERNAL LOAD routine. Vector $330/$331 points here (ROM original at $F4A5)
;

.global _new_load
_new_load: ; $DE20
        ; The least significant bit of $0330 indicates wether to use PAL or NTSC timing.
        ; This double tay simply handles that the vector may point to either $DE20 or
        ; $DE21. Deeper into the load code, in receive_4_bytes, the bit is tested and
        ; appropriate timing for PAL and NTSC is chosen.
        tay
        tay
        lda     $01
        pha
        jsr     enable_all_roms
        jsr     new_load
        ; common for load/save
pull_to_cpuport_fcromoff:
        tax
        pla
        sta     $01
        txa
        ldx     $AE
        jmp     _disable_fc3rom

;
; KERNAL SAVE routine. Vector $330/$331 points here (ROM original at $F5ED)
;

.global _new_save
_new_save: ; $DE35
        lda     $01
        pha
        jsr     enable_all_roms
        jsr     new_save
        jmp     pull_to_cpuport_fcromoff

;
; BASIC idle loop. Vector $302/303 points here (ROM original at $A483)
;

.global _new_mainloop
_new_mainloop: ; $DE41
        lda     $01
        jsr     enable_all_roms
        jmp     new_mainloop

;
; BASIC token decoder. Vector $306/307 points here (ROM original at $A71A)
;

.global _new_detokenize
_new_detokenize: ; $DE49
        jsr     _enable_fcbank0
        jmp     new_detokenize

;
; BASIC read expression next item. Vector $30A/30B points here (ROM original at $AE86)
;

.global _new_expression
_new_expression: ; $DE4F
        jsr     _enable_fcbank0
        jmp     new_expression

;
; Keyboard handler. Vector $28F/290 sometimes points here by the BASIC menu bar code
; (ROM original at $EB487)
;

.global _kbd_handler
_kbd_handler:
        lda     $02A7
        beq     @1
        jmp     kernel_keyboard_handler ; LDA #$7F : STA $DC00 : RTS

@1:     lda     $A000
        jmp     kbd_handler_part2

.global _load_ac_indy
_load_ac_indy: ; $DE63
        sta     $01
        lda     ($AC),y
        inc     $01
        inc     $01
        rts

.global _load_FNADR_indy
_load_FNADR_indy: ; $DE6C
        dec     $01
        lda     (FNADR),y
        inc     $01
        rts

;
; BASIC execute statement. Vector $308/$309 points here (ROM original at $A7E4)
;

.global _new_execute
_new_execute: ; $DE73
        jsr     _CHRGET
        jsr     new_execute
        jsr     _disable_fc3rom
        jmp     basic_execute_next_statement

;
; new_execute an jump here
;

.global _execute_statement
_execute_statement: ; $DE7F
        jsr     _disable_fc3rom
        jmp     basic_continue_execute

.global _add_a_to_fac1
_add_a_to_fac1: ; $DE85
        jsr     _disable_fc3rom
        jsr     basic_add_a_to_fac1
        jmp     _enable_fcbank0

.global _expression_cont
_expression_cont: ; $DE8E
        jsr     _disable_fc3rom
        jmp     basic_continue_arithmic_element

.global _get_int
_get_int: ; $DE94
        jsr     _disable_fc3rom
        jsr     basic_FRMNUM ; FRMNUM eval expression, make sure it's numeric
        jsr     basic_GETADR ; GETADR convert FAC into 16 bit int
        jmp     _enable_fcbank0

.global _new_warmstart
_new_warmstart:
        jsr     _enable_fcbank0
        jsr     reset_warmstart
        jmp     disable_rom_then_warm_start

.global _evaluate_modifier
_evaluate_modifier: ; $DEA9
        jsr     _disable_fc3rom
        jmp     kernal_check_modifier_keys ; evaluate SHIFT/CTRL/C=

.global _basic_string_to_word
_basic_string_to_word: ; $DEAF
        jsr     _disable_fc3rom
        jsr     basic_string_to_word
        jmp     _enable_fcbank0

.global _basic_bsout
_basic_bsout: ; $DEB8
        jsr     _disable_fc3rom
        jsr     basic_print_char
        jmp     _enable_fcbank0

.global _set_txtptr_to_start
_set_txtptr_to_start: ; $DEC1
        jsr     _disable_fc3rom
        jsr     basic_set_TXTPTR_to_TXTTAB ; set TXTPTR to start of program
        jmp     _enable_fcbank0

.global _check_for_stop
_check_for_stop: ; $DECA
        jsr     _disable_fc3rom
        jsr     basic_check_stop ; check for RUN/STOP
        jmp     _enable_fcbank0

.global _relink
_relink: ; $DED3
        jsr     _disable_fc3rom
        jsr     basic_relink ; rebuild BASIC line chaining
        beq     LDEE1 ; branch always?

.global _get_filename
_get_filename: ; $DEDB
        jsr     _disable_fc3rom
        jsr     kernal_get_filename ; get string from BASIC line, set filename
LDEE1:  jmp     _enable_fcbank0

.global _int_to_ascii
_int_to_ascii: ; $DEE4
        jsr     _disable_fc3rom
        jsr     $BC49 ; FLOAT UNSIGNED VALUE IN FAC+1,2
        jsr     $BDDD ; convert FAC to ASCII
        jmp     _enable_fcbank0

.global _ay_to_fac1
_ay_to_fac1: ; $DEF0
        jsr     _disable_fc3rom
        jsr     basic_ay_to_fac1
        jmp     LDEFF

.global _int_to_fac1
_int_to_fac1: ; $DEF9
        jsr     _disable_fc3rom
        jsr     $BBA6 ; convert $22/$23 to FAC
LDEFF:  iny
        jsr     $BDD7 ; print FAC
        jmp     _enable_fcbank0


.global _print_ax_int
_print_ax_int: ; $DF06
        jsr     _disable_fc3rom
        jsr     basic_LINPRT ; LINPRT print A/X as integer
        jmp     _enable_fcbank0

.global _search_for_line
_search_for_line: ; $DF0F
        jsr     _disable_fc3rom
        jsr    basic_search_line
        php
        jsr     _enable_fcbank0
        plp
        rts

.global _CHRGET
_CHRGET: ; $DF1B
        jsr     _disable_fc3rom
        jsr     CHRGET
LDF21:  php
        jsr     _enable_fcbank0
        plp
        rts

.global _CHRGOT
_CHRGOT: ; $DF27
        jsr     _disable_fc3rom
        jsr     CHRGOT
        jmp     LDF21

.global _lda_5a_indy
_lda_5a_indy: ; $DF30
        jsr     _disable_fc3rom
        lda     ($5A),y
        jmp     _enable_fcbank0

.global _lda_5f_indy
_lda_5f_indy: ; $DF38
        jsr     _disable_fc3rom
        lda     ($5F),y
        jmp     _enable_fcbank0

.global _lda_ae_indx
_lda_ae_indx: ; $DF40
        jsr     _disable_fc3rom
        lda     ($AE,x)
        jmp     _enable_fcbank0

.global _lda_TXTPTR_indy
_lda_TXTPTR_indy: ; $DF48
        jsr     _disable_fc3rom
        lda     (TXTPTR),y
        jmp     _enable_fcbank0

.global _lda_TXTPTR_indx
_lda_TXTPTR_indx: ; DF50
        jsr     _disable_fc3rom
        lda     (TXTPTR,x)
        jmp     _enable_fcbank0

.global _lda_22_indy
_lda_22_indy: ; $DF58
        jsr     _disable_fc3rom
        lda     ($22),y
        jmp     _enable_fcbank0

.global _lda_8b_indy
_lda_8b_indy: ; $DF60
        jsr     _disable_fc3rom
        lda     ($8B),y
        jmp     _enable_fcbank0

_detokenize: ; $DF68
        jsr     _disable_fc3rom
        jmp     basic_detokenize ; detokenize

.global _list_print_non_token_byte
_list_print_non_token_byte: ; $DF6E
        jsr     _disable_fc3rom
        jmp     basic_list_print_non_token_byte ; part of LIST

.global _print_banner_load_and_run
_print_banner_load_and_run: ; $DF74
        jsr     _disable_fc3rom
        jsr     kernel_print_startup_messages ; print c64 banner
        jsr     _enable_fcbank0
        jmp     load_and_run_program

kbd_handler_part2:
        cmp     #$94 ; contents of $A000 in BASIC ROM
        bne     @1 ; BASIC ROM not visible
        jsr     _enable_fcbank0
        jmp     kbd_handler

@1:     jmp     kernal_check_modifier_keys ; default kdb vector

.global _new_tokenize
_new_tokenize: ; $DF8D
        jsr     _enable_fcbank0
        jsr     new_tokenize
        jmp     _disable_fc3rom

;padding
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF

; calls into banks 0+1
.global _new_ckout
_new_ckout: ; $DFC0
        jsr     _enable_fcbank0
        jsr     new_ckout
        jmp     _disable_fc3rom

.global _new_bsout
_new_bsout: ; $DFC9
        jsr     _enable_fcbank0
        jmp     new_bsout

.global _new_clall
_new_clall: ; $DFCF
        jsr     _enable_fcbank0
        jmp     new_clall

.global _new_clrch
_new_clrch: ; $DFD5
        jsr     _enable_fcbank0
        jmp     new_clrch


;$DFE0
;
;Note: Freeze handler does not jump here to $DFE0, because it activates bank 3 of the ROM,
;and thus jumps to $DFE0 of bank 3. The ROM contents of bank 3 are different.
;

.segment "romio_bar_irq"

        sei
        lda     #$42 ; bank 2 (Desktop, Freezer/Print)
        sta     fcio_reg
.global _bar_irq
_bar_irq:
        lda     LDE00 ; $40 ???
        pha
        lda     $A000 ; ???
        pha
        lda     #$41 ; bank 1 (Notepad, BASIC (Menu Bar))
        sta     fcio_reg

.global _a_colon_asterisk
_a_colon_asterisk:
        .byte   ':','*'
.global _a_colon_asterisk_end
_a_colon_asterisk_end:

; ----------------------------------------------------------------
; I/O Area ROM End
; ----------------------------------------------------------------
