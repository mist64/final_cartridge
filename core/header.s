; ----------------------------------------------------------------
; $8000 Vectors
; ----------------------------------------------------------------
; This is put at $8000, it contains the "cbm80" header with the
; cartridge cold and warm start vectors.

.segment "header"

.import jentry

.assert * = $8000, error, "cbm80 header must be at $8000!"

        .addr   jentry ; cartridge hard reset entry point: cartridge init
        .addr   $FE5E  ; cartridge soft reset entry point: default value
        .byte   $C3, $C2, $CD, "80" ; "cbm80"

