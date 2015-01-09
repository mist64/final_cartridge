.include "kernal.i"

.include "persistent.i"
.include "fc3.i"

; ----------------------------------------------------------------
; Monitor (~4750 bytes)
; ----------------------------------------------------------------

; PETSCII
CR              := $0D
CSR_DOWN        := $11
CSR_HOME        := $13
CSR_RIGHT       := $1D
CSR_UP          := $91

reg_pc_hi       := ram_code_end + 5
reg_pc_lo       := ram_code_end + 6
reg_p           := ram_code_end + 7

registers       := ram_code_end + 8
reg_a           := ram_code_end + 8
reg_x           := ram_code_end + 9
reg_y           := ram_code_end + 10
reg_s           := ram_code_end + 11

irq_lo          := ram_code_end + 12
irq_hi          := ram_code_end + 13

entry_type      := ram_code_end + 14
command_index   := ram_code_end + 15 ; command index from "command_names", or 'C'/'S' in EC/ES case
bank            := ram_code_end + 16
disable_f_keys  := ram_code_end + 17
tmp1            := ram_code_end + 18
tmp2            := ram_code_end + 19
cartridge_bank  := ram_code_end + 20

.segment "monitor1"

.import __monitor_ram_code_LOAD__
.import __monitor_ram_code_RUN__

.global monitor
monitor: ; $AB00
        lda     #<brk_entry
        sta     $0316
        lda     #>brk_entry
        sta     $0317 ; BRK vector
        lda     #'C'
        sta     entry_type
        lda     #$37
        sta     bank ; bank 7
        lda     #$70
        sta     cartridge_bank ; by default, hide cartridge
        ldx     #ram_code_end - ram_code - 1
:       lda     __monitor_ram_code_LOAD__,x
        sta     __monitor_ram_code_RUN__,x
        dex
        bpl     :-
        brk ; <- nice!

.segment "monitor_ram_code"
; code that will be copied to $0220
ram_code:
; read from memory with a specific ROM and cartridge config
        sta     $DFFF ; set cartridge config
        pla
        sta     $01 ; set ROM config
        lda     ($C1),y ; read
enable_all_roms:
        pha
        lda     #$37
        sta     $01 ; restore ROM config
        lda     #$40
        sta     $DFFF ; resture cartridge config
        pla
        rts

disable_rom_rti:
        jsr     _disable_rom
        sta     $01
        lda     reg_a
        rti

brk_entry:
        jsr     enable_all_roms
        jmp     brk_entry2
ram_code_end:

; XXX ram_code is here - why put it between ROM code, so we have to jump over it?

.segment "monitor2"

brk_entry2:
        cld ; <- important :)
        pla
        sta     reg_y
        pla
        sta     reg_x
        pla
        sta     reg_a
        pla
        sta     reg_p
        pla
        sta     reg_pc_lo
        pla
        sta     reg_pc_hi
        tsx
        stx     reg_s
        jsr     set_irq_vector
        jsr     set_io_vectors
        jsr     print_cr
        lda     entry_type
        cmp     #'C'
        bne     :+
        .byte   $2C ; XXX bne + skip = beq + 2
:       lda     #'B'
        ldx     #'*'
        jsr     print_a_x
        clc
        lda     reg_pc_lo
        adc     #$FF
        sta     reg_pc_lo
        lda     reg_pc_hi
        adc     #$FF
        sta     reg_pc_hi ; decrement PC
        lda     $BA
        and     #$FB
        sta     $BA
        lda     #'B'
        sta     entry_type
        lda     #$80
        sta     $028A ; enable key repeat for all keys
        bne     dump_registers ; always

; ----------------------------------------------------------------
; "R" - dump registers
; ----------------------------------------------------------------
cmd_r:
        jsr     basin_cmp_cr
        bne     syntax_error
dump_registers:
        ldx     #0
:       lda     s_regs,x ; "PC  IRQ  BK AC XR YR SP NV#BDIZC"
        beq     dump_registers2
        jsr     BSOUT
        inx
        bne     :-
dump_registers2:
        ldx     #';'
        jsr     print_dot_x
        lda     reg_pc_hi
        jsr     print_hex_byte2 ; address hi
        lda     reg_pc_lo
        jsr     print_hex_byte2 ; address lo
        jsr     print_space
        lda     irq_hi
        jsr     print_hex_byte2 ; IRQ hi
        lda     irq_lo
        jsr     print_hex_byte2 ; IRQ lo
        jsr     print_space
        lda     bank
        bpl     :+
        lda     #'D'
        jsr     BSOUT
        lda     #'R'
        jsr     BSOUT
        bne     LABEB ; negative bank means drive ("DR")
:       and     #$0F
        jsr     print_hex_byte2 ; bank
LABEB:  ldy     #0
:       jsr     print_space
        lda     registers,y
        jsr     print_hex_byte2 ; registers...
        iny
        cpy     #$04
        bne     :-
        jsr     print_space
        lda     reg_p
        jsr     print_bin
        beq     input_loop ; always

syntax_error:
        lda     #'?'
        .byte   $2C
print_cr_then_input_loop:
        lda     #CR
        jsr     BSOUT

input_loop:
        ldx     reg_s
        txs
        lda     #0
        sta     disable_f_keys
        jsr     print_cr_dot
input_loop2:
        jsr     basin_if_more
        cmp     #'.'
        beq     input_loop2 ; skip dots
        cmp     #' '
        beq     input_loop2 ; skip spaces
        ldx     #$1A
LAC27:  cmp     command_names,x
        bne     LAC3B
        stx     command_index
        txa
        asl     a
        tax
        lda     function_table+1,x
        pha
        lda     function_table,x
        pha
        rts
LAC3B:  dex
        bpl     LAC27
        bmi     syntax_error ; always

; ----------------------------------------------------------------
; "EC"/"ES"/"D" - dump character or sprite data
; ----------------------------------------------------------------
cmd_e:
        jsr     BASIN
        cmp     #'C'
        beq     cmd_mid2
        cmp     #'S'
        beq     cmd_mid2
        jmp     syntax_error

fill_kbd_buffer_with_csr_right:
        lda     #CSR_UP
        ldx     #CR
        jsr     print_a_x
        lda     #CSR_RIGHT
        ldx     #0
:       sta     $0277,x ; fill kbd buffer with 7 CSR RIGHT characters
        inx
        cpx     #$07
        bne     :-
        stx     $C6 ; 7
        jmp     input_loop2

cmd_mid2:
        sta     command_index ; write 'C' or 'S'

; ----------------------------------------------------------------
; "M"/"I"/"D" - dump 8 hex byes, 32 ASCII bytes, or disassemble
;               ("EC" and "ES" also end up here)
; ----------------------------------------------------------------
cmd_mid:
        jsr     get_hex_word
        jsr     basin_cmp_cr
        bne     LAC80 ; second argument
        jsr     copy_c3_c4_to_c1_c2
        jmp     LAC86

is_h:   jmp     LAEAC

; ----------------------------------------------------------------
; "F"/"H"/"C"/"T" - find, hunt, compare, transfer
; ----------------------------------------------------------------
cmd_fhct:
        jsr     get_hex_word
        jsr     basin_if_more
LAC80:  jsr     swap_c1_c2_and_c3_c4
        jsr     get_hex_word3
LAC86:  lda     command_index
        beq     is_mie ; 'M' (hex dump)
        cmp     #$17
        beq     is_mie ; 'I' (ASCII dump)
        cmp     #$01
        beq     is_d ; 'D' (disassemble)
        cmp     #$06
        beq     is_f ; 'F' (fill)
        cmp     #$07
        beq     is_h ; 'H' (hunt)
        cmp     #'C'
        beq     is_mie ; 'EC'
        cmp     #'S'
        beq     is_mie ; 'ES'
        jmp     LAE88

LACA6:  jsr     LB64D
        bcs     is_mie
LACAB:  jmp     fill_kbd_buffer_with_csr_right

is_mie:
        jsr     print_cr
        lda     command_index
        beq     LACC4 ; 'M'
        cmp     #'S'
        beq     LACD0
        cmp     #'C'
        beq     LACCA
        jsr     dump_ascii_line
        jmp     LACA6

LACC4:  jsr     dump_hex_line
        jmp     LACA6

; EC
LACCA:  jsr     dump_char_line
        jmp     LACA6

; ES
LACD0:  jsr     dump_sprite_line
        jmp     LACA6

LACD6:  jsr     LB64D
        bcc     LACAB
is_d:   jsr     print_cr
        jsr     dump_assembly_line
        jmp     LACD6

is_f:   jsr     basin_if_more
        jsr     get_hex_byte
        jsr     LB22E
        jmp     print_cr_then_input_loop

dump_sprite_line:
        ldx     #']'
        jsr     print_dot_x
        jsr     print_hex_16
        jsr     print_space
        ldy     #0
LACFD:  jsr     load_byte
        jsr     print_bin
        iny
        cpy     #$03
        bne     LACFD
        jsr     print_8_spaces
        tya ; 3
        jmp     add_a_to_c1_c2

dump_char_line:
        ldx     #'['
        jsr     print_dot_x
        jsr     print_hex_16
        jsr     print_space
        ldy     #0
        jsr     load_byte
        jsr     print_bin
        jsr     print_8_spaces
        jmp     inc_c1_c2

dump_hex_line:
        ldx     #':'
        jsr     print_dot_x
        jsr     print_hex_16
        jsr     dump_8_hex_bytes
        jsr     print_space
        jmp     dump_8_ascii_characters

dump_ascii_line:
        ldx     #$27  ; "'"
        jsr     print_dot_x
        jsr     print_hex_16
        jsr     print_space
        ldx     #$20
        jmp     dump_ascii_characters

dump_assembly_line:
        ldx     #','
LAD4B:  jsr     print_dot_x
        jsr     disassemble_line; XXX why not inline?
        jsr     print_8_spaces
        lda     $0205
        jmp     LB028

disassemble_line:
        jsr     print_hex_16
        jsr     print_space
        jsr     LAF62
        jsr     LAF40
        jsr     LAFAF
        jmp     LAFD7

; ----------------------------------------------------------------
; "[" - input character data
; ----------------------------------------------------------------
cmd_leftbracket:
        jsr     get_hex_word
        jsr     copy_c3_c4_to_c1_c2
        jsr     basin_skip_spaces_if_more
        jsr     LB4DB
        ldy     #0
        jsr     store_byte
        jsr     print_up
        jsr     dump_char_line
        jsr     print_cr_dot
        jsr     fill_kbd_buffer_leftbracket
        jmp     input_loop2

; ----------------------------------------------------------------
; "]" - input sprite data
; ----------------------------------------------------------------
cmd_rightbracket:
        jsr     get_hex_word
        jsr     copy_c3_c4_to_c1_c2
        jsr     basin_skip_spaces_if_more
        jsr     LB4DB
        ldy     #0
        beq     LAD9F
LAD9C:  jsr     get_bin_byte
LAD9F:  jsr     store_byte
        iny
        cpy     #$03
        bne     LAD9C
        jsr     print_up
        jsr     dump_sprite_line
        jsr     print_cr_dot
        jsr     fill_kbd_buffer_rightbracket
        jmp     input_loop2

; ----------------------------------------------------------------
; "'" - input 32 ASCII characters
; ----------------------------------------------------------------
cmd_singlequote:
        jsr     get_hex_word
        jsr     read_ascii
        jsr     print_up
        jsr     dump_ascii_line
        jsr     print_cr_dot
        jsr     fill_kbd_buffer_singlequote
        jmp     input_loop2

; ----------------------------------------------------------------
; ":" - input 8 hex bytes
; ----------------------------------------------------------------
cmd_colon:
        jsr     get_hex_word
        jsr     read_8_bytes
        jsr     print_up
        jsr     dump_hex_line
        jsr     print_cr_dot
        jsr     fill_kbd_buffer_semicolon
        jmp     input_loop2

; ----------------------------------------------------------------
; ";" - set registers
; ----------------------------------------------------------------
cmd_semicolon:
        jsr     get_hex_word
        lda     $C4
        sta     reg_pc_hi
        lda     $C3
        sta     reg_pc_lo
        jsr     basin_if_more
        jsr     get_hex_word3
        lda     $C3
        sta     irq_lo
        lda     $C4
        sta     irq_hi
        jsr     basin_if_more ; skip upper nybble of bank
        jsr     basin_if_more
        cmp     #'D' ; "drive"
        bne     LAE12
        jsr     basin_if_more
        cmp     #'R'
        bne     LAE3D
        ora     #$80 ; XXX why not lda #$80?
        bmi     LAE1B ; always
LAE12:  jsr     get_hex_byte2
        cmp     #$08
        bcs     LAE3D ; syntax error
        ora     #$30
LAE1B:  sta     bank
        ldx     #0
LAE20:  jsr     basin_if_more
        jsr     get_hex_byte
        sta     registers,x ; registers
        inx
        cpx     #$04
        bne     LAE20
        jsr     basin_if_more
        jsr     get_bin_byte
        sta     reg_p
        jsr     print_up
        jmp     dump_registers2

LAE3D:  jmp     syntax_error

; ----------------------------------------------------------------
; "," - input up to three hex values
; ----------------------------------------------------------------
cmd_comma:
        jsr     get_hex_word3
        ldx     #$03
        jsr     LB5E7
        lda     #$2C
        jsr     LAE7C
        jsr     fill_kbd_buffer_comma
        jmp     input_loop2

; ----------------------------------------------------------------
; "A" - assemble
; ----------------------------------------------------------------
cmd_a:
        jsr     get_hex_word
        jsr     LB030
        jsr     LB05C
        ldx     #0
        stx     $0206
LAE61:  ldx     reg_s
        txs
        jsr     LB08D
        jsr     LB0AB
        jsr     swap_c1_c2_and_c3_c4
        jsr     LB0EF
        lda     #'A'
        jsr     LAE7C
        jsr     fill_kbd_buffer_a
        jmp     input_loop2

LAE7C:  pha
        jsr     print_up
        pla
        tax
        jsr     LAD4B
        jmp     print_cr_dot

LAE88:  jsr     LB655
        bcs     LAE90
        jmp     syntax_error

LAE90:  sty     $020A
        jsr     basin_if_more
        jsr     get_hex_word3
        lda     command_index
        cmp     #$08 ; 'C'
        beq     LAEA6
        jsr     LB1CB
        jmp     print_cr_then_input_loop

LAEA6:  jsr     LB245
        jmp     input_loop

LAEAC:  jsr     basin_if_more
        ldx     #0
        stx     $020B
        jsr     basin_if_more
        cmp     #$22
        bne     LAECF
LAEBB:  jsr     basin_cmp_cr
        beq     LAEE7
        cmp     #$22
        beq     LAEE7
        sta     $0200,x
        inx
        cpx     #$20
        bne     LAEBB
        jmp     syntax_error

LAECF:  jsr     get_hex_byte2
        bcs     LAEDC
LAED4:  jsr     basin_cmp_cr
        beq     LAEE7
        jsr     get_hex_byte
LAEDC:  sta     $0200,x
        inx
        cpx     #$20
        bne     LAED4
LAEE4:  jmp     syntax_error

LAEE7:  stx     command_index
        txa
        beq     LAEE4
        jsr     LB293
        jmp     input_loop

; ----------------------------------------------------------------
; "G" - run code
; ----------------------------------------------------------------
cmd_g:
        jsr     basin_cmp_cr
        beq     LAF03
        jsr     get_hex_word2
        jsr     basin_cmp_cr
        beq     LAF06
        jmp     syntax_error

LAF03:  jsr     copy_pc_to_c3_c4_and_c1_c2
LAF06:  lda     bank
        bmi     LAF2B ; drive
        jsr     set_irq_vector
        jsr     set_io_vectors_with_hidden_rom
        ldx     reg_s
        txs
        lda     $C4
        pha
        lda     $C3
        pha
        lda     reg_p
        pha
        ldx     reg_x
        ldy     reg_y
        lda     bank
        jmp     disable_rom_rti
LAF2B:  lda     #'E' ; send M-E to drive
        jsr     send_m_dash2
        lda     $C3
        jsr     IECOUT
        lda     $C4
        jsr     IECOUT
        jsr     UNLSTN
        jmp     print_cr_then_input_loop

; ----------------------------------------------------------------
; assembler/disassembler
; ----------------------------------------------------------------
LAF40:  pha
        ldy     #0
LAF43:  cpy     $0205
        beq     LAF52
        bcc     LAF52
        jsr     print_space
        jsr     print_space
        bcc     LAF58
LAF52:  jsr     load_byte
        jsr     print_hex_byte2
LAF58:  jsr     print_space
        iny
        cpy     #$03
        bne     LAF43
        pla
        rts

LAF62:  ldy     #0
        jsr     load_byte
LAF67:  tay
        lsr     a
        bcc     LAF76
        lsr     a
        bcs     LAF85
        cmp     #$22
        beq     LAF85
        and     #$07
        ora     #$80
LAF76:  lsr     a
        tax
        lda     asmtab1,x
        bcs     LAF81
        lsr     a
        lsr     a
        lsr     a
        lsr     a
LAF81:  and     #$0F
        bne     LAF89
LAF85:  ldy     #$80
        lda     #0
LAF89:  tax
        lda     asmtab2,x
        sta     $0207
        and     #$03
        sta     $0205
        tya
        and     #$8F
        tax
        tya
        ldy     #$03
        cpx     #$8A
        beq     LAFAB
LAFA0:  lsr     a
        bcc     LAFAB
        lsr     a
LAFA4:  lsr     a
        ora     #$20
        dey
        bne     LAFA4
        iny
LAFAB:  dey
        bne     LAFA0
        rts

LAFAF:  tay
        lda     nmemos1,y
        sta     $020A
        lda     nmemos2,y
        sta     $0208
        ldx     #$03
LAFBE:  lda     #0
        ldy     #$05
LAFC2:  asl     $0208
        rol     $020A
        rol     a
        dey
        bne     LAFC2
        adc     #$3F
        jsr     BSOUT
        dex
        bne     LAFBE
        jmp     print_space

LAFD7:  ldx     #$06
LAFD9:  cpx     #$03
        bne     LAFF4
        ldy     $0205
        beq     LAFF4
LAFE2:  lda     $0207
        cmp     #$E8
        php
        jsr     load_byte
        plp
        bcs     LB00B
        jsr     print_hex_byte2
        dey
        bne     LAFE2
LAFF4:  asl     $0207
        bcc     LB007
        lda     asmtab3,x
        jsr     BSOUT
        lda     asmtab4,x
        beq     LB007
        jsr     BSOUT
LB007:  dex
        bne     LAFD9
        rts

LB00B:  jsr     LB01C
        tax
        inx
        bne     LB013
        iny
LB013:  tya
        jsr     print_hex_byte2
        txa
        jmp     print_hex_byte2

LB01B:  sec
LB01C:  ldy     $C2
        tax
        bpl     LB022
        dey
LB022:  adc     $C1
        bcc     LB027
        iny
LB027:  rts

LB028:  jsr     LB01B
        sta     $C1
        sty     $C2
        rts

LB030:  ldx     #0
        stx     $0211
LB035:  jsr     basin_if_more
        cmp     #$20
        beq     LB030
        sta     $0200,x
        inx
        cpx     #$03
        bne     LB035
LB044:  dex
        bmi     LB05B
        lda     $0200,x
        sec
        sbc     #$3F
        ldy     #$05
LB04F:  lsr     a
        ror     $0211
        ror     $0210
        dey
        bne     LB04F
        beq     LB044
LB05B:  rts

LB05C:  ldx     #$02
LB05E:  jsr     BASIN
        cmp     #CR
        beq     LB089
        cmp     #$3A
        beq     LB089
        cmp     #$20
        beq     LB05E
        jsr     LB61C
        bcs     LB081
        jsr     get_hex_byte3
        ldy     $C1
        sty     $C2
        sta     $C1
        lda     #$30
        sta     $0210,x
        inx
LB081:  sta     $0210,x
        inx
        cpx     #$17
        bcc     LB05E
LB089:  stx     $020A
        rts

LB08D:  ldx     #0
        stx     $0204
        lda     $0206
        jsr     LAF67
        ldx     $0207
        stx     $0208
        tax
        lda     nmemos2,x
        jsr     LB130
        lda     nmemos1,x
        jmp     LB130

LB0AB:  ldx     #$06
LB0AD:  cpx     #$03
        bne     LB0C5
        ldy     $0205
        beq     LB0C5
LB0B6:  lda     $0207
        cmp     #$E8
        lda     #$30
        bcs     LB0DD
        jsr     LB12D
        dey
        bne     LB0B6
LB0C5:  asl     $0207
        bcc     LB0D8
        lda     asmtab3,x
        jsr     LB130
        lda     asmtab4,x
        beq     LB0D8
        jsr     LB130
LB0D8:  dex
        bne     LB0AD
        beq     LB0E3
LB0DD:  jsr     LB12D
        jsr     LB12D
LB0E3:  lda     $020A
        cmp     $0204
        beq     LB0EE
        jmp     LB13B

LB0EE:  rts

LB0EF:  ldy     $0205
        beq     LB123
        lda     $0208
        cmp     #$9D
        bne     LB11A
        jsr     LB655
        bcc     LB10A
        tya
        bne     LB12A
        ldx     $0209
        bmi     LB12A
        bpl     LB112
LB10A:  iny
        bne     LB12A
        ldx     $0209
        bpl     LB12A
LB112:  dex
        dex
        txa
        ldy     $0205
        bne     LB11D
LB11A:  lda     $C2,y
LB11D:  jsr     store_byte
        dey
        bne     LB11A
LB123:  lda     $0206
        jsr     store_byte
        rts

LB12A:  jmp     input_loop

LB12D:  jsr     LB130
LB130:  stx     $0203
        ldx     $0204
        cmp     $0210,x
        beq     LB146
LB13B:  inc     $0206
        beq     LB143
        jmp     LAE61

LB143:  jmp     input_loop

LB146:  inx
        stx     $0204
        ldx     $0203
        rts

; ----------------------------------------------------------------
; "$" - convert hex to decimal
; ----------------------------------------------------------------
cmd_dollar:
        jsr     get_hex_word
        jsr     print_up_dot
        jsr     copy_c3_c4_to_c1_c2
        jsr     print_dollar_hex_16
        jsr     LB48E
        jsr     print_hash
        jsr     LBC50
        jmp     input_loop

; ----------------------------------------------------------------
; "#" - convert decimal to hex
; ----------------------------------------------------------------
cmd_hash:
        ldy     #0
        sty     $C1
        sty     $C2
        jsr     basin_skip_spaces_if_more
LB16F:  and     #$0F
        clc
        adc     $C1
        sta     $C1
        bcc     LB17A
        inc     $C2
LB17A:  jsr     BASIN
        cmp     #$30
        bcc     LB19B
        pha
        lda     $C1
        ldy     $C2
        asl     a
        rol     $C2
        asl     a
        rol     $C2
        adc     $C1
        sta     $C1
        tya
        adc     $C2
        asl     $C1
        rol     a
        sta     $C2
        pla
        bcc     LB16F
LB19B:  jsr     print_up_dot
        jsr     print_hash
        lda     $C1
        pha
        lda     $C2
        pha
        jsr     LBC50
        pla
        sta     $C2
        pla
        sta     $C1
        jsr     LB48E
        jsr     print_dollar_hex_16
        jmp     input_loop

; ----------------------------------------------------------------
; "X" - exit monitor
; ----------------------------------------------------------------
cmd_x:
        jsr     set_irq_vector
        jsr     set_io_vectors_with_hidden_rom
        lda     #0
        sta     $028A
        ldx     reg_s
        txs
        jmp     _basic_warm_start

LB1CB:  lda     $C3
        cmp     $C1
        lda     $C4
        sbc     $C2
        bcs     LB1FC
        ldy     #0
        ldx     #0
LB1D9:  jsr     load_byte
        pha
        jsr     swap_c1_c2_and_c3_c4
        pla
        jsr     store_byte
        jsr     swap_c1_c2_and_c3_c4
        cpx     $020A
        bne     LB1F1
        cpy     $0209
        beq     LB1FB
LB1F1:  iny
        bne     LB1D9
        inc     $C2
        inc     $C4
        inx
        bne     LB1D9
LB1FB:  rts

LB1FC:  clc
        ldx     $020A
        txa
        adc     $C2
        sta     $C2
        clc
        txa
        adc     $C4
        sta     $C4
        ldy     $0209
LB20E:  jsr     load_byte
        pha
        jsr     swap_c1_c2_and_c3_c4
        pla
        jsr     store_byte
        jsr     swap_c1_c2_and_c3_c4
        cpy     #0
        bne     LB229
        cpx     #0
        beq     LB22D
        dec     $C2
        dec     $C4
        dex
LB229:  dey
        jmp     LB20E

LB22D:  rts

LB22E:  ldy     #0
LB230:  jsr     store_byte
        ldx     $C1
        cpx     $C3
        bne     LB23F
        ldx     $C2
        cpx     $C4
        beq     LB244
LB23F:  jsr     inc_c1_c2
        bne     LB230
LB244:  rts

LB245:  jsr     print_cr
        clc
        lda     $C1
        adc     $0209
        sta     $0209
        lda     $C2
        adc     $020A
        sta     $020A
        ldy     #0
LB25B:  jsr     load_byte
        sta     command_index
        jsr     swap_c1_c2_and_c3_c4
        jsr     load_byte
        pha
        jsr     swap_c1_c2_and_c3_c4
        pla
        cmp     command_index
        beq     LB274
        jsr     print_space_hex_16
LB274:  jsr     STOP
        beq     LB292
        lda     $C2
        cmp     $020A
        bne     LB287
        lda     $C1
        cmp     $0209
        beq     LB292
LB287:  inc     $C3
        bne     LB28D
        inc     $C4
LB28D:  jsr     inc_c1_c2
        bne     LB25B
LB292:  rts

LB293:  jsr     print_cr
LB296:  jsr     LB655
        bcc     LB2B3
        ldy     #0
LB29D:  jsr     load_byte
        cmp     $0200,y
        bne     LB2AE
        iny
        cpy     command_index
        bne     LB29D
        jsr     print_space_hex_16
LB2AE:  jsr     inc_c1_c2
        bne     LB296
LB2B3:  rts

; ----------------------------------------------------------------
; memory load/store
; ----------------------------------------------------------------

; loads a byte at ($C1),y from drive RAM
LB2B4:  lda     #'R' ; send M-R to drive
        jsr     send_m_dash2
        jsr     iec_send_c1_c2_plus_y
        jsr     UNLSTN
        jsr     talk_cmd_channel
        jsr     IECIN ; read byte
        pha
        jsr     UNTALK
        pla
        rts

; stores a byte at ($C1),y in drive RAM
LB2CB:  lda     #'W' ; send M-W to drive
        jsr     send_m_dash2
        jsr     iec_send_c1_c2_plus_y
        lda     #$01
        jsr     IECOUT
        pla
        pha
        jsr     IECOUT
        jsr     UNLSTN
        pla
        rts

        lda     ($C1),y
        rts

        pla
        sta     ($C1),y
        rts

; loads a byte at ($C1),y from RAM with the correct ROM config
load_byte:
        sei
        lda     bank
        bmi     LB2B4 ; drive
        clc
        pha
        lda     cartridge_bank
        jmp     ram_code ; "lda ($C1),y" with ROM and cartridge config

; stores a byte at ($C1),y in RAM with the correct ROM config
store_byte:
        sei
        pha
        lda     bank
        bmi     LB2CB ; drive
        cmp     #$35
        bcs     LB306 ; I/O on
        lda     #$33 ; ROM at $A000, $D000 and $E000
        sta     $01 ; ??? why?
LB306:  pla
        sta     ($C1),y ; store
        pha
        lda     #$37
        sta     $01 ; restore ROM config
        pla
        rts

; ----------------------------------------------------------------
; "B" - set cartridge bank (0-3) to be visible at $8000-$BFFF
;       without arguments, this turns off cartridge visibility
; ----------------------------------------------------------------
cmd_b:  jsr     basin_cmp_cr
        beq     LB326 ; without arguments, set $70
        cmp     #' '
        beq     cmd_b ; skip spaces
        cmp     #'0'
        bcc     LB32E ; syntax error
        cmp     #'4'
        bcs     LB32E ; syntax error
        and     #$03 ; XXX no effect
        ora     #$40 ; make $40 - $43
        .byte   $2C
LB326:  lda     #$70 ; by default, hide cartridge
        sta     cartridge_bank
        jmp     print_cr_then_input_loop

LB32E:  jmp     syntax_error

; ----------------------------------------------------------------
; "O" - set bank
;       0 to 7 map to a $01 value of $30-$37, "D" switches to drive
;       memory
; ----------------------------------------------------------------
cmd_o:
        jsr     basin_cmp_cr
        beq     LB33F ; without arguments: bank 7
        cmp     #' '
        beq     cmd_o
        cmp     #'D'
        beq     LB34A ; disk
        .byte   $2C
LB33F:  lda     #$37 ; bank 7
        cmp     #$38
        bcs     LB32E ; syntax error
        cmp     #$30
        bcc     LB32E ; syntax error
        .byte   $2C
LB34A:  lda     #$80 ; drive
        sta     bank
        jmp     print_cr_then_input_loop

listen_command_channel:
        lda     #$6F
        jsr     init_and_listen
        lda     $90
        bmi     LB3A6
        rts

LB35C:  lda     #$16
        sta     $0326
        lda     #$E7
        sta     $0327
        lda     #$33
        sta     $0322
        lda     #$F3
        sta     $0323
        rts

; ----------------------------------------------------------------
; "L"/"S" - load/save file
; ----------------------------------------------------------------
cmd_ls:
        ldy     #$02
        sty     $BC
        dey
        sty     $B9
        dey
        sty     $B7
        lda     #$08
        sta     $BA
        lda     #$10
        sta     $BB
        jsr     basin_skip_spaces_cmp_cr
        bne     LB3B6
LB388:  lda     command_index
        cmp     #$0B ; 'L'
        bne     LB3CC
LB38F:  jsr     LB35C
        jsr     set_irq_vector
        ldx     $C1
        ldy     $C2
        jsr     LB42D
        php
        jsr     set_io_vectors
        jsr     set_irq_vector
        plp
LB3A4:  bcc     LB3B3
LB3A6:  ldx     #0
LB3A8:  lda     $F0BD,x ; "I/O ERROR"
        jsr     BSOUT
        inx
        cpx     #$0A
        bne     LB3A8
LB3B3:  jmp     input_loop

LB3B6:  cmp     #$22
        bne     LB3CC
LB3BA:  jsr     basin_cmp_cr
        beq     LB388
        cmp     #$22
        beq     LB3CF
        sta     ($BB),y
        inc     $B7
        iny
        cpy     #$10
        bne     LB3BA
LB3CC:  jmp     syntax_error

LB3CF:  jsr     basin_cmp_cr
        beq     LB388
        cmp     #$2C
LB3D6:  bne     LB3CC
        jsr     get_hex_byte
        and     #$0F
        beq     LB3CC
        cmp     #$01
        beq     LB3E7
        cmp     #$04
        bcc     LB3CC
LB3E7:  sta     $BA
        jsr     basin_cmp_cr
        beq     LB388
        cmp     #$2C
LB3F0:  bne     LB3D6
        jsr     get_hex_word3
        jsr     swap_c1_c2_and_c3_c4
        jsr     basin_cmp_cr
        bne     LB408
        lda     command_index
        cmp     #$0B ; 'L'
        bne     LB3F0
        dec     $B9
        beq     LB38F
LB408:  cmp     #$2C
LB40A:  bne     LB3F0
        jsr     get_hex_word3
        jsr     basin_skip_spaces_cmp_cr
        bne     LB40A
        ldx     $C3
        ldy     $C4
        lda     command_index
        cmp     #$0C ; 'S'
        bne     LB40A
        dec     $B9
        jsr     LB35C
        jsr     LB438
        jsr     set_io_vectors
        jmp     LB3A4

LB42D:  lda     #>(_enable_rom - 1)
        pha
        lda     #<(_enable_rom - 1)
        pha
        lda     #0
        jmp     LOAD

LB438:  lda     #>(_enable_rom - 1)
        pha
        lda     #<(_enable_rom - 1)
        pha
        lda     #$C1
        jmp     SAVE

; ----------------------------------------------------------------
; "@" - send drive command
;       without arguments, this reads the drive status
;       $ shows the directory
;       F does a fast format
; ----------------------------------------------------------------
cmd_at: 
        jsr     listen_command_channel
        jsr     basin_cmp_cr
        beq     print_drive_status
        cmp     #'$'
        beq     LB475
        cmp     #'F'
        bne     LB458
        jsr     fast_format
        lda     #'F'
LB458:  jsr     IECOUT
        jsr     basin_cmp_cr
        bne     LB458
        jsr     UNLSTN
        jmp     print_cr_then_input_loop

; just print drive status
print_drive_status:
        jsr     print_cr
        jsr     UNLSTN
        jsr     talk_cmd_channel
        jsr     cat_line_iec
        jmp     input_loop

; show directory
LB475:  jsr     UNLSTN
        jsr     print_cr
        lda     #$F0 ; sec address
        jsr     init_and_listen
        lda     #'$'
        jsr     IECOUT
        jsr     UNLSTN
        jsr     directory
        jmp     input_loop

LB48E:  jsr     print_space
        lda     #'='
        ldx     #' '
        bne     print_a_x

print_up:
        ldx     #CSR_UP
        .byte   $2C
print_cr_dot:
        ldx     #'.'
        lda     #CR
        .byte   $2C
print_dot_x:
        lda     #'.'
print_a_x:
        jsr     BSOUT
        txa
        jmp     BSOUT

print_up_dot:
        jsr     print_up
        lda     #'.'
        .byte   $2C
; XXX unused?
        lda     #CSR_RIGHT
        .byte   $2C
print_hash:
        lda     #'#'
        .byte   $2C
print_space:
        lda     #' '
        .byte   $2C
print_cr:
        lda     #CR
        jmp     BSOUT

basin_skip_spaces_if_more:
        jsr     basin_skip_spaces_cmp_cr
        jmp     LB4C5

; get a character; if it's CR, return to main input loop
basin_if_more:
        jsr     basin_cmp_cr
LB4C5:  bne     LB4CA ; rts
        jmp     input_loop

LB4CA:  rts

basin_skip_spaces_cmp_cr:
        jsr     BASIN
        cmp     #' '
        beq     basin_skip_spaces_cmp_cr ; skip spaces
        cmp     #CR
        rts

basin_cmp_cr:
        jsr     BASIN
        cmp     #CR
        rts

LB4DB:  pha
        ldx     #$08
        bne     LB4E6
get_bin_byte:
        ldx     #$08
LB4E2:  pha
        jsr     basin_if_more
LB4E6:  cmp     #'*'
        beq     LB4EB
        clc
LB4EB:  pla
        rol     a
        dex
        bne     LB4E2
        rts

; get a 16 bit ASCII hex number from the user, return it in $C3/$C4
get_hex_word:
        jsr     basin_if_more
get_hex_word2:
        cmp     #' ' ; skip spaces
        beq     get_hex_word
        jsr     get_hex_byte2
        bcs     LB500 ; ??? always
get_hex_word3:
        jsr     get_hex_byte
LB500:  sta     $C4
        jsr     get_hex_byte
        sta     $C3
        rts

; get a 8 bit ASCII hex number from the user, return it in A
get_hex_byte:
        lda     #0
        sta     tmp2 ; XXX not necessary?
        jsr     basin_if_more
get_hex_byte2:
        jsr     validate_hex_digit
get_hex_byte3:
        jsr     hex_digit_to_nybble
        asl     a
        asl     a
        asl     a
        asl     a
        sta     tmp2 ; low nybble
        jsr     get_hex_digit
        jsr     hex_digit_to_nybble
        ora     tmp2
        sec
        rts

hex_digit_to_nybble:
        cmp     #'9' + 1
        and     #$0F
        bcc     LB530
        adc     #'A' - '9'
LB530:  rts

        clc
        rts

; get character and check for legal ASCII hex digit
; XXX this also allows ":;<=>?" (0x39-0x3F)!!!
get_hex_digit:
        jsr     basin_if_more
validate_hex_digit:
        cmp     #'0'
        bcc     LB547 ; error
        cmp     #'@' ; XXX should be: '9' + 1
        bcc     LB546 ; ok
        cmp     #'A'
        bcc     LB547 ; error
        cmp     #'F' + 1
        bcs     LB547 ; error
LB546:  rts
LB547:  jmp     syntax_error

print_dollar_hex_16:
        lda     #'$'
        .byte   $2C
print_space_hex_16:
        lda     #' '
        jsr     BSOUT
print_hex_16:
        lda     $C2
        jsr     print_hex_byte2
        lda     $C1

print_hex_byte2:
        sty     tmp1
        jsr     print_hex_byte
        ldy     tmp1
        rts

print_bin:
        ldx     #$08
LB565:  rol     a
        pha
        lda     #'*'
        bcs     LB56D
        lda     #'.'
LB56D:  jsr     BSOUT
        pla
        dex
        bne     LB565
        rts

inc_c1_c2:
        clc
        inc     $C1
        bne     LB57D
        inc     $C2
        sec
LB57D:  rts

dump_8_hex_bytes:
        ldx     #$08
        ldy     #0
LB582:  jsr     print_space
        jsr     load_byte
        jsr     print_hex_byte2
        iny
        dex
        bne     LB582
        rts

dump_8_ascii_characters:
       ldx     #$08
dump_ascii_characters:
        ldy     #0
LB594:  jsr     load_byte
        cmp     #$20
        bcs     LB59F
        inc     $C7
        ora     #$40
LB59F:  cmp     #$80
        bcc     LB5AD
        cmp     #$A0
        bcs     LB5AD
        and     #$7F
        ora     #$60
        inc     $C7
LB5AD:  jsr     BSOUT
        lda     #0
        sta     $C7
        sta     $D4
        iny
        dex
        bne     LB594
        tya ; number of bytes consumed
        jmp     add_a_to_c1_c2

read_ascii:
        ldx     #$20
        ldy     #0
        jsr     copy_c3_c4_to_c1_c2
        jsr     basin_if_more
LB5C8:  sty     $0209
        ldy     $D3
        lda     ($D1),y
        php
        jsr     basin_if_more
        ldy     $0209
        plp
        bmi     LB5E0
        cmp     #$60
        bcs     LB5E0
        jsr     store_byte
LB5E0:  iny
        dex
        bne     LB5C8
        rts

read_8_bytes:
        ldx     #$08
LB5E7:  ldy     #0
        jsr     copy_c3_c4_to_c1_c2
        jsr     basin_skip_spaces_if_more
        jsr     get_hex_byte2
        jmp     LB607

LB5F5:  jsr     basin_if_more_cmp_space ; ignore character where space should be
        jsr     basin_if_more_cmp_space
        bne     LB604 ; not space
        jsr     basin_if_more_cmp_space
        bne     LB619 ; not space, error
        beq     LB60A ; always

LB604:  jsr     get_hex_byte2
LB607:  jsr     store_byte
LB60A:  iny
        dex
        bne     LB5F5
        rts

basin_if_more_cmp_space:
        jsr     basin_cmp_cr
        bne     LB616
        pla
        pla
LB616:  cmp     #' '
        rts

LB619:  jmp     syntax_error

LB61C:  cmp     #$30
        bcc     LB623
        cmp     #$47
        rts

LB623:  sec
        rts

swap_c1_c2_and_c3_c4:
        lda     $C4
        pha
        lda     $C2
        sta     $C4
        pla
        sta     $C2
        lda     $C3
        pha
        lda     $C1
        sta     $C3
        pla
        sta     $C1
        rts

copy_pc_to_c3_c4_and_c1_c2:
        lda     reg_pc_hi
        sta     $C4
        lda     reg_pc_lo
        sta     $C3

copy_c3_c4_to_c1_c2:
        lda     $C3
        sta     $C1
        lda     $C4
        sta     $C2
        rts

LB64D:  lda     $C2
        bne     LB655
        bcc     LB655
        clc
        rts

LB655:  jsr     STOP
        beq     LB66C
        lda     $C3
        ldy     $C4
        sec
        sbc     $C1
        sta     $0209 ; $C3 - $C1
        tya
        sbc     $C2 
        tay ; $C4 - $C2
        ora     $0209
        rts

LB66C:  clc
        rts

fill_kbd_buffer_comma:
        lda     #','
        .byte   $2C
fill_kbd_buffer_semicolon:
        lda     #':'
        .byte   $2C
fill_kbd_buffer_a:
        lda     #'A'
        .byte   $2C
fill_kbd_buffer_leftbracket:
        lda     #'['
        .byte   $2C
fill_kbd_buffer_rightbracket:
        lda     #']'
        .byte   $2C
fill_kbd_buffer_singlequote:
        lda     #$27 ; "'"
        sta     $0277 ; keyboard buffer
        lda     $C2
        jsr     byte_to_hex_ascii
        sta     $0278
        sty     $0279
        lda     $C1
        jsr     byte_to_hex_ascii
        sta     $027A
        sty     $027B
        lda     #' '
        sta     $027C
        lda     #$06 ; number of characters
        sta     $C6
        rts

; print 7x cursor right
print_7_csr_right:
        lda     #CSR_RIGHT
        ldx     #7
        bne     LB6AC ; always

; print 8 spaces - this is used to clear some leftover characters
; on the screen when re-dumping a line with proper spacing after the
; user may have entered it with condensed spacing
print_8_spaces:
        lda     #' '
        ldx     #8
LB6AC:  jsr     BSOUT
        dex
        bne     LB6AC
        rts

; ----------------------------------------------------------------
; IRQ logic to handle F keys and scrolling
; ----------------------------------------------------------------
set_irq_vector:
        lda     $0314
        cmp     #<irq_handler
        bne     LB6C1
        lda     $0315
        cmp     #>irq_handler
        beq     LB6D3
LB6C1:  lda     $0314
        ldx     $0315
        sta     irq_lo
        stx     irq_hi
        lda     #<irq_handler
        ldx     #>irq_handler
        bne     LB6D9 ; always
LB6D3:  lda     irq_lo
        ldx     irq_hi
LB6D9:  sei
        sta     $0314
        stx     $0315
        cli
        rts

irq_handler:
        lda     #>after_irq ; XXX shouldn't this be "-1"?
        pha
        lda     #<after_irq
        pha
        lda     #0 ; fill A/X/Y/P
        pha
        pha
        pha
        pha
        jmp     $EA31 ; run normal IRQ handler, then return to this code

after_irq:
        lda     disable_f_keys
        bne     LB6FA
        lda     $C6 ; number of characters in keyboard buffer
        bne     LB700
LB6FA:  pla ; XXX JMP $EA81
        tay
        pla
        tax
        pla
        rti

LB700:  lda     $0277 ; keyboard buffer
        cmp     #$88 ; F7 key
        bne     LB71C
        lda     #'@'
        sta     $0277
        lda     #'$'
        sta     $0278
        lda     #CR
        sta     $0279 ; store "@$' + CR into keyboard buffer
        lda     #$03 ; 3 characters
        sta     $C6
        bne     LB6FA ; always

LB71C:  cmp     #$87 ; F5 key
        bne     LB733
        ldx     #24
        cpx     $D6 ; cursor line
        beq     LB72E ; already on last line
        jsr     LB8D9
        ldy     $D3
        jsr     $E50C ; KERNAL set cursor position
LB72E:  lda     #CSR_DOWN
        sta     $0277 ; kbd buffer
LB733:  cmp     #$86
        bne     LB74A
        ldx     #0
        cpx     $D6
        beq     LB745
        jsr     LB8D9
        ldy     $D3
        jsr     $E50C ; KERNAL set cursor position
LB745:  lda     #CSR_UP
        sta     $0277 ; kbd buffer
LB74A:  cmp     #CSR_DOWN
        beq     LB758
        cmp     #CSR_UP
        bne     LB6FA
        lda     $D6 ; cursor line
        beq     LB75E ; top of screen
        bne     LB6FA
LB758:  lda     $D6 ; cursor line
        cmp     #24
        bne     LB6FA
LB75E:  jsr     LB838
        bcc     LB6FA
        jsr     LB897
        php
        jsr     LB8D4
        plp
        bcs     LB6FA
        lda     $D6
        beq     LB7E1
        lda     $020C
        cmp     #$2C
        beq     LB790
        cmp     #$5B
        beq     LB7A2
        cmp     #$5D
        beq     LB7AE
        cmp     #$27
        beq     LB7BC
        jsr     LB8C8
        jsr     print_cr
        jsr     dump_hex_line
        jmp     LB7C7

LB790:  jsr     LAF62
        lda     $0205
        jsr     LB028
        jsr     print_cr
        jsr     dump_assembly_line
        jmp     LB7C7

LB7A2:  jsr     inc_c1_c2
        jsr     print_cr
        jsr     dump_char_line
        jmp     LB7C7

LB7AE:  lda     #$03
        jsr     add_a_to_c1_c2
        jsr     print_cr
        jsr     dump_sprite_line
        jmp     LB7C7

LB7BC:  lda     #$20
        jsr     add_a_to_c1_c2
        jsr     print_cr
        jsr     dump_ascii_line
LB7C7:  lda     #CSR_UP
        ldx     #CR
        bne     LB7D1
LB7CD:  lda     #CR
        ldx     #CSR_HOME
LB7D1:  ldy     #0
        sty     $C6
        sty     disable_f_keys
        jsr     print_a_x
        jsr     print_7_csr_right
        jmp     LB6FA

LB7E1:  jsr     LB8FE
        lda     $020C
        cmp     #','
        beq     LB800
        cmp     #'['
        beq     LB817
        cmp     #']'
        beq     LB822
        cmp     #$27 ; "'"
        beq     LB82D
        jsr     LB8EC
        jsr     dump_hex_line
        jmp     LB7CD

LB800:  jsr     swap_c1_c2_and_c3_c4
        jsr     LB90E
        inc     $0205
        lda     $0205
        eor     #$FF
        jsr     LB028
        jsr     dump_assembly_line
        clc
        bcc     LB7CD
LB817:  lda     #$01
        jsr     LB8EE
        jsr     dump_char_line
        jmp     LB7CD

LB822:  lda     #$03
        jsr     LB8EE
        jsr     dump_sprite_line
        jmp     LB7CD

LB82D:  lda     #$20
        jsr     LB8EE
        jsr     dump_ascii_line
        jmp     LB7CD

LB838:  lda     $D1
        ldx     $D2
        sta     $C3
        stx     $C4
        lda     #$19
        sta     $020D
LB845:  ldy     #$01
        jsr     LB88B
        cmp     #':'
        beq     LB884
        cmp     #','
        beq     LB884
        cmp     #'['
        beq     LB884
        cmp     #']'
        beq     LB884
        cmp     #$27 ; "'"
        beq     LB884
        dec     $020D
        beq     LB889
        lda     $0277 ; kbd buffer
        cmp     #CSR_DOWN
        bne     LB877
        sec
        lda     $C3
        sbc     #40
        sta     $C3
        bcs     LB845
        dec     $C4
        bne     LB845
LB877:  clc
        lda     $C3
        adc     #$28
        sta     $C3
        bcc     LB845
        inc     $C4
        bne     LB845
LB884:  sec
        sta     $020C
        rts

LB889:  clc
        rts

LB88B:  lda     ($C3),y
        iny
        and     #$7F
        cmp     #$20
        bcs     LB896
        ora     #$40
LB896:  rts

LB897:  cpy     #$16
        bne     LB89D
        sec
        rts

LB89D:  jsr     LB88B
        cmp     #$20
        beq     LB897
        dey
        jsr     LB8B1
        sta     $C2
        jsr     LB8B1
        sta     $C1
        clc
        rts

LB8B1:  jsr     LB88B
        jsr     hex_digit_to_nybble
        asl     a
        asl     a
        asl     a
        asl     a
        sta     $020B
        jsr     LB88B
        jsr     hex_digit_to_nybble
        ora     $020B
        rts

LB8C8:  lda     #$08
add_a_to_c1_c2:
        clc
        adc     $C1
        sta     $C1
        bcc     LB8D3
        inc     $C2
LB8D3:  rts

LB8D4:  lda     #$FF
        sta     disable_f_keys
LB8D9:  lda     #$FF
        sta     $CC
        lda     $CF
        beq     LB8EB ; rts
        lda     $CE
        ldy     $D3
        sta     ($D1),y
        lda     #0
        sta     $CF
LB8EB:  rts

LB8EC:  lda     #$08
LB8EE:  sta     $020E
        sec
        lda     $C1
        sbc     $020E
        sta     $C1
        bcs     LB8FD
        dec     $C2
LB8FD:  rts

LB8FE:  ldx     #0
        jsr     $E96C ; insert line at top of screen
        lda     #$94
        sta     $D9
        sta     $DA
        lda     #CSR_HOME
        jmp     BSOUT

LB90E:  lda     #$10
        sta     $020D
LB913:  sec
        lda     $C3
        sbc     $020D
        sta     $C1
        lda     $C4
        sbc     #0
        sta     $C2
LB921:  jsr     LAF62
        lda     $0205
        jsr     LB028
        jsr     LB655
        beq     LB936
        bcs     LB921
        dec     $020D
        bne     LB913
LB936:  rts

; ----------------------------------------------------------------
; assembler tables
; ----------------------------------------------------------------
asmtab1:
        .byte   $40,$02,$45,$03,$D0,$08,$40,$09
        .byte   $30,$22,$45,$33,$D0,$08,$40,$09
        .byte   $40,$02,$45,$33,$D0,$08,$40,$09
        .byte   $40,$02,$45,$B3,$D0,$08,$40,$09
        .byte   $00,$22,$44,$33,$D0,$8C,$44,$00
        .byte   $11,$22,$44,$33,$D0,$8C,$44,$9A
        .byte   $10,$22,$44,$33,$D0,$08,$40,$09
        .byte   $10,$22,$44,$33,$D0,$08,$40,$09
        .byte   $62,$13,$78,$A9
asmtab2:
        .byte   $00,$21,$81,$82,$00,$00,$59,$4D
        .byte   $91,$92,$86,$4A,$85

asmtab3:
        .byte   $9D ; CSR LEFT
        .byte   ',', ')', ',', '#', '('

asmtab4:
        .byte   '$', 'Y', 0, 'X', '$', '$', 0

; encoded mnemos:
; every combination of a byte of nmemos1 and nmemos2
; encodes 3 ascii characters
nmemos1:
        .byte   $1C,$8A,$1C,$23,$5D,$8B,$1B,$A1
        .byte   $9D,$8A,$1D,$23,$9D,$8B,$1D,$A1
        .byte   $00,$29,$19,$AE,$69,$A8,$19,$23
        .byte   $24,$53,$1B,$23,$24,$53,$19,$A1
        .byte   $00,$1A,$5B,$5B,$A5,$69,$24,$24
        .byte   $AE,$AE,$A8,$AD,$29,$00,$7C,$00
        .byte   $15,$9C,$6D,$9C,$A5,$69,$29,$53
        .byte   $84,$13,$34,$11,$A5,$69,$23,$A0
nmemos2:
        .byte   $D8,$62,$5A,$48,$26,$62,$94,$88
        .byte   $54,$44,$C8,$54,$68,$44,$E8,$94
        .byte   $00,$B4,$08,$84,$74,$B4,$28,$6E
        .byte   $74,$F4,$CC,$4A,$72,$F2,$A4,$8A
        .byte   $00,$AA,$A2,$A2,$74,$74,$74,$72
        .byte   $44,$68,$B2,$32,$B2,$00,$22,$00
        .byte   $1A,$1A,$26,$26,$72,$72,$88,$C8
        .byte   $C4,$CA,$26,$48,$44,$44,$A2,$C8

; ----------------------------------------------------------------

s_regs: .byte   CR, "   PC  IRQ  BK AC XR YR SP NV#BDIZC", CR, 0

; ----------------------------------------------------------------

command_names:
        .byte   "MD:AGXFHCTRLS,O@$#*PE[]I';B"

function_table:
        .word   cmd_mid-1
        .word   cmd_mid-1
        .word   cmd_colon-1
        .word   cmd_a-1
        .word   cmd_g-1
        .word   cmd_x-1
        .word   cmd_fhct-1
        .word   cmd_fhct-1
        .word   cmd_fhct-1
        .word   cmd_fhct-1
        .word   cmd_r-1
        .word   cmd_ls-1
        .word   cmd_ls-1
        .word   cmd_comma-1
        .word   cmd_o-1
        .word   cmd_at-1
        .word   cmd_dollar-1
        .word   cmd_hash-1
        .word   cmd_asterisk-1
        .word   cmd_p-1
        .word   cmd_e-1
        .word   cmd_leftbracket-1
        .word   cmd_rightbracket-1
        .word   cmd_mid-1
        .word   cmd_singlequote-1
        .word   cmd_semicolon-1
        .word   cmd_b-1

; ----------------------------------------------------------------

LBA8C:  jmp     syntax_error

; ----------------------------------------------------------------
; "*R"/"*W" - read/write sector
; ----------------------------------------------------------------
cmd_asterisk:
        jsr     listen_command_channel
        jsr     UNLSTN
        jsr     BASIN
        cmp     #'W'
        beq     LBAA0
        cmp     #'R'
        bne     LBA8C ; syntax error
LBAA0:  sta     $C3 ; save 'R'/'W' mode
        jsr     basin_skip_spaces_if_more
        jsr     get_hex_byte2
        bcc     LBA8C
        sta     $C1
        jsr     basin_if_more
        jsr     get_hex_byte
        bcc     LBA8C
        sta     $C2
        jsr     basin_cmp_cr
        bne     LBAC1
        lda     #$CF
        sta     $C4
        bne     LBACD
LBAC1:  jsr     get_hex_byte
        bcc     LBA8C
        sta     $C4
        jsr     basin_cmp_cr
        bne     LBA8C
LBACD:  jsr     LBB48
        jsr     swap_c1_c2_and_c3_c4
        lda     $C1
        cmp     #'W'
        beq     LBB25
        lda     #'1'
        jsr     LBB6E
        jsr     talk_cmd_channel
        jsr     IECIN
        cmp     #'0'
        beq     LBB00 ; no error
        pha
        jsr     print_cr
        pla
LBAED:  jsr     $E716 ; KERNAL: output character to screen
        jsr     IECIN
        cmp     #CR ; print drive status until CR (XXX redundant?)
        bne     LBAED
        jsr     UNTALK
        jsr     close_2
        jmp     input_loop

LBB00:  jsr     IECIN
        cmp     #CR ; receive all bytes (XXX not necessary?)
        bne     LBB00
        jsr     UNTALK
        jsr     LBBAE
        ldx     #$02
        jsr     CHKIN
        ldy     #0
        sty     $C1
LBB16:  jsr     IECIN
        jsr     store_byte ; receive block
        iny
        bne     LBB16
        jsr     CLRCH
        jmp     LBB42 ; close 2 and print drive status

LBB25:  jsr     LBBAE
        ldx     #$02
        jsr     CKOUT
        ldy     #0
        sty     $C1
LBB31:  jsr     load_byte
        jsr     IECOUT ; send block
        iny
        bne     LBB31
        jsr     CLRCH
        lda     #'2'
        jsr     LBB6E
LBB42:  jsr     close_2
        jmp     print_drive_status

LBB48:  lda     #$02
        tay
        ldx     $BA
        jsr     SETLFS
        lda     #$01
        ldx     #$CF
        ldy     #$BB
        jsr     SETNAM
        jmp     OPEN

close_2:
        lda     #$02
        jmp     CLOSE

LBB61:  ldx     #$30
        sec
LBB64:  sbc     #$0A
        bcc     LBB6B
        inx
        bcs     LBB64
LBB6B:  adc     #$3A
        rts

LBB6E:  pha
        ldx     #0
LBB71:  lda     s_u1,x
        sta     $0200,x
        inx
        cpx     #s_u1_end - s_u1
        bne     LBB71
        pla
        sta     $0201
        lda     $C3
        jsr     LBB61
        stx     $0207
        sta     $0208
        lda     #$20
        sta     $0209
        lda     $C4
        jsr     LBB61
        stx     $020A
        sta     $020B
        jsr     listen_command_channel
        ldx     #0
LBBA0:  lda     $0200,x
        jsr     IECOUT
        inx
        cpx     #$0C
        bne     LBBA0
        jmp     UNLSTN

LBBAE:  jsr     listen_command_channel
        ldx     #0
LBBB3:  lda     s_bp,x
        jsr     IECOUT
        inx
        cpx     #s_bp_end - s_bp
        bne     LBBB3
        jmp     UNLSTN

s_u1:
        .byte   "U1:2 0 "
s_u1_end:
s_bp:
        .byte   "B-P 2 0"
s_bp_end:
        .byte   "#" ; ???

send_m_dash2:
        pha
        lda     #$6F
        jsr     init_and_listen
        lda     #'M'
        jsr     IECOUT
        lda     #'-'
        jsr     IECOUT
        pla
        jmp     IECOUT

iec_send_c1_c2_plus_y:
        tya
        clc
        adc     $C1
        php
        jsr     IECOUT
        plp
        lda     $C2
        adc     #0
        jmp     IECOUT

LBBF4:  jmp     syntax_error

; ----------------------------------------------------------------
; "P" - set output to printer
; ----------------------------------------------------------------
cmd_p:
        lda     bank
        bmi     LBBF4 ; drive? syntax error
        ldx     #$FF
        lda     $BA ; device number
        cmp     #$04
        beq     LBC11 ; printer
        jsr     basin_cmp_cr
        beq     LBC16 ; no argument
        cmp     #','
        bne     LBBF4 ; syntax error
        jsr     get_hex_byte
        tax
LBC11:  jsr     basin_cmp_cr
        bne     LBBF4
LBC16:  sta     $0277; kbd buffer
        inc     $C6
        lda     #$04
        cmp     $BA
        beq     LBC39 ; printer
        stx     $B9
        sta     $BA ; set device 4
        sta     $B8
        ldx     #0
        stx     $B7
        jsr     CLOSE
        jsr     OPEN
        ldx     $B8
        jsr     CKOUT
        jmp     input_loop2

LBC39:  lda     $B8
        jsr     CLOSE
        jsr     CLRCH
        lda     #$08
        sta     $BA
        lda     #0
        sta     $C6
        jmp     input_loop

LBC4C:  stx     $C1
        sta     $C2
LBC50:  lda     #$31
        sta     $C3
        ldx     #$04
LBC56:  dec     $C3
LBC58:  lda     #$2F
        sta     $C4
        sec
        ldy     $C1
        .byte   $2C
LBC60:  sta     $C2
        sty     $C1
        inc     $C4
        tya
        sbc     LBC83,x
        tay
        lda     $C2
        sbc     LBC88,x
        bcs     LBC60
        lda     $C4
        cmp     $C3
        beq     LBC7D
        jsr     $E716 ; KERNAL: output character to screen
        dec     $C3
LBC7D:  dex
        beq     LBC56
        bpl     LBC58
        rts

LBC83:  ora     ($0A,x)
        .byte   $64
        inx
        .byte   $10
LBC88:  brk
        brk
        brk
        .byte   $03
        .byte   $27

init_and_listen:
        pha
        jsr     init_drive
        jsr     LISTEN
        pla
        jmp     SECOND

talk_cmd_channel:
        lda     #$6F
init_and_talk:
        pha
        jsr     init_drive
        jsr     TALK
        pla
        jmp     TKSA

cat_line_iec:
        jsr     IECIN
        jsr     $E716 ; KERNAL: output character to screen
        cmp     #CR
        bne     cat_line_iec
        jmp     UNTALK

print_hex_byte:
        jsr     byte_to_hex_ascii
        jsr     BSOUT
        tya
        jmp     BSOUT

; convert byte into hex ASCII in A/Y
byte_to_hex_ascii:
        pha
        and     #$0F
        jsr     LBCC8
        tay
        pla
        lsr     a
        lsr     a
        lsr     a
        lsr     a
LBCC8:  clc
        adc     #$F6
        bcc     LBCCF
        adc     #$06
LBCCF:  adc     #$3A
        rts

directory:
        lda     #$60
        sta     $B9
        jsr     init_and_talk
        jsr     IECIN
        jsr     IECIN ; skip load address
LBCDF:  jsr     IECIN
        jsr     IECIN ; skip link word
        jsr     IECIN
        tax
        jsr     IECIN ; line number (=blocks)
        ldy     $90
        bne     LBD2F ; error
        jsr     LBC4C ; print A/X decimal
        lda     #' '
        jsr     $E716 ; KERNAL: output character to screen
        ldx     #$18
LBCFA:  jsr     IECIN
LBCFD:  ldy     $90
        bne     LBD2F ; error
        cmp     #CR
        beq     LBD09 ; convert $0D to $1F
        cmp     #$8D
        bne     LBD0B ; also convert $8D to $1F
LBD09:  lda     #$1F ; ???BLUE
LBD0B:  jsr     $E716 ; KERNAL: output character to screen
        inc     $D8
        jsr     GETIN
        cmp     #$03
        beq     LBD2F ; STOP
        cmp     #' '
        bne     LBD20
LBD1B:  jsr     GETIN
        beq     LBD1B ; space pauses until the next key press
LBD20:  dex
        bpl     LBCFA
        jsr     IECIN
        bne     LBCFD
        lda     #CR
        jsr     $E716 ; KERNAL: output character to screen
LBD2D:  bne     LBCDF ; next line
LBD2F:  jmp     $F646 ; CLOSE

init_drive:
        lda     #0
        sta     $90 ; clear status
        lda     #$08
        cmp     $BA ; drive 8 and above ok
        bcc     LBD3F
LBD3C:  sta     $BA ; otherwise set drive 8
LBD3E:  rts

LBD3F:  lda     #$09
        cmp     $BA
        bcs     LBD3E
        lda     #$08
LBD47:
        bne     LBD3C
        lda     $FF
LBD4B:  ldy     $90
        bne     LBD7D
        cmp     #CR
        beq     LBD57
        cmp     #$8D
        bne     LBD59
LBD57:  lda     #$1F
LBD59:  jsr     $E716 ; KERNAL: output character to screen
        inc     $D8
        jsr     GETIN
        cmp     #$03
        beq     LBD7D
        cmp     #$20
        bne     LBD6E
LBD69:  jsr     GETIN
        beq     LBD69
LBD6E:  dex
        bpl     LBD47 + 1 ; ??? XXX
        jsr     IECIN
        bne     LBD4B
        lda     #CR
        jsr     $E716 ; KERNAL: output character to screen
        bne     LBD2D
LBD7D:  jmp     $F646 ; CLOSE

        lda     #0
        sta     $90
        lda     #$08
        cmp     $BA
        bcc     LBD8D
LBD8A:  sta     $BA
LBD8C:  rts

LBD8D:  lda     #$09
        cmp     $BA
        bcs     LBD8C
        lda     #$08
        bne     LBD8A ; always
