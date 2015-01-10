.include "persistent.i"

; ----------------------------------------------------------------
.segment "freezer"

; ----------------------------------------------------------------
; Freezer Entry
; ----------------------------------------------------------------
; In Ultimax mode, we have the following memory layout:
; $8000-$9FFF: bank 0 lo
; $E000-$FFFF: bank 0 hi

freezer: ; $FFA0
        sei
        pha
        lda     $00
        pha
        lda     #$2F
        sta     $00 ; default value of processor port DDR
        lda     $01
        ora     #$20 ; cassette motor off - but don't store
        pha
        lda     #$37
        sta     $01 ; processor port defaut value
        lda     #$13
        sta     $DFFF ; NMI = 1, GAME = 1, EXROM = 0
        lda     $DC0B ; CIA 1 TOD hours
        lda     $DD0B ; CIA 2 TOD hours (???)
        txa
        pha ; save X
        tya
        pha ; save Y
        lda     $02A1 ; RS-232 interrupt enabled
        pha
        ldx     #$0A
LBFC7:  lda     $02,x ; copy $02 - $0C onto stack
        pha
        dex
        bpl     LBFC7
        lda     $DD0E ; CIA 2 Timer A Control
        pha
        lda     $DD0F ; CIA 2 Timer B Control
        pha
        lda     #$00
        sta     $DD0E ; disable CIA 2 Timer A
        sta     $DD0F ; disable CIA 2 Timer B
        lda     #$7C
        sta     $DD0D ; disable some NMIs? (???)
        ldx     #$03
        jmp     LDFE0 ; ???

.segment "freezer_vectors"

; catch IRQ, NMI, RESET
        .word freezer ; NMI
        .word freezer ; RESET
        .word freezer ; IRQ

