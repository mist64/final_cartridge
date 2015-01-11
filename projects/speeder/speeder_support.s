.segment        "LOADADDR"
.addr   *+2

.import new_load
.import new_save

.segment "speeder_entry"
    lda #<new_load
    sta $0330
    lda #>new_load
    sta $0331
    lda #<new_save
    sta $0332
    lda #>new_save
    sta $0333
    rts

.segment "speeder_support"
.global _disable_rom
_disable_rom:
.global _disable_rom_set_01
_disable_rom_set_01:
.global _load_FILENAME_indy
_load_FILENAME_indy:
.global _load_ac_indy
_load_ac_indy:
.global _new_load
_new_load:
    rts