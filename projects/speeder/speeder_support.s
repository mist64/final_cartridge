.segment        "LOADADDR"
.addr   *+2

.include "kernal.i"

.global _new_load

.import new_load
.import new_save

.segment "speeder_entry"
    lda #<_new_load
    sta $0330
    lda #>_new_load
    sta $0331
    lda #<_new_save
    sta $0332
    lda #>_new_save
    sta $0333
    rts

_new_load:
        tay
        tay
        lda     $01
        pha
        jsr     new_load
LDE2B:  tax
        pla
        sta     $01
        txa
        ldx     $AE
        rts

_new_save: ; $DE35
        lda     $01
        pha
        jsr     new_save
        jmp     LDE2B

.segment "speeder_support"
.global _disable_rom
_disable_rom:
.global _disable_rom_set_01
_disable_rom_set_01:
    rts
.global _load_FILENAME_indy
_load_FILENAME_indy:
        dec     $01
        lda     (FILENAME),y
        inc     $01
        rts

.global _load_ac_indy
        sta     $01
        lda     ($AC),y
        inc     $01
        inc     $01
        rts
_load_ac_indy:

