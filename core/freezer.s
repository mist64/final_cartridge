; ----------------------------------------------------------------
; Freezer Entry
; ----------------------------------------------------------------
; In Ultimax mode, we have the following memory layout:
; $8000-$9FFF: bank 0 lo
; $E000-$FFFF: bank 0 hi
; This code is mapped into bank 0 hi, and the vectors appear
; at the very end of this bank.
; The code here only does some minimal saving of state, then
; jumps to a different bank.

.include "persistent.i"
.include "fc3ioreg.i"

.segment "freezer"

freezer:
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

        ; Activate Ultimax mode and bank 3, NMI line stays active
        lda     #fcio_bank_3|fcio_c64_ultimaxmode
        sta     fcio_reg ; NMI = 1, GAME = 1, EXROM = 0

        lda     $DC0B ; CIA 1 TOD hours
        lda     $DD0B ; CIA 2 TOD hours (???)
        txa
        pha ; save X
        tya
        pha ; save Y
        lda     $02A1 ; RS-232 interrupt enabled
        pha
        ldx     #10
LBFC7:  lda     $02,x ; copy $02 - $0C onto stack
        pha
        dex
        bpl     LBFC7
        lda     $DD0E ; CIA 2 Timer A Control
        pha
        lda     $DD0F ; CIA 2 Timer B Control
        pha
        lda     #0
        sta     $DD0E ; disable CIA 2 Timer A
        sta     $DD0F ; disable CIA 2 Timer B
        lda     #$7C
        sta     $DD0D ; disable some NMIs? (???)
        
        ; Note: Bank3 is active. Note that the IOROM at $DE00..$DFFF is also affected by bank
        ; switching. The IOROM of Bank3 is different than that of bank 0 (code persistent.s) 
        ldx     #fcio_bank_3 ; NMI line stays active
        jmp     $DFE0
        
        ; The code at $DFE0 of bank 3 (also at offset $DFE0 in FC3 ROM image) that follows is:
        ;
        ; 9FE0 8E FF DF STX $DFFF  (fcio_reg)
        ; 9FE3 8D 0D DD STA $DD0D
        ; 9FE6 4C 00 80 JMP $8000

.segment "freezer_vectors"

; catch IRQ, NMI, RESET
        .word freezer ; NMI
        .word freezer ; RESET
        .word freezer ; IRQ

