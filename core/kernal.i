; ----------------------------------------------------------------
; KERNAL Symbols
; ----------------------------------------------------------------
CINT            := $FF81
IOINIT          := $FF84
RAMTAS          := $FF87
RESTOR          := $FF8A
VECTOR          := $FF8D
SETMSG          := $FF90
SECOND          := $FF93
TKSA            := $FF96
MEMTOP          := $FF99
MEMBOT          := $FF9C
SCNKEY          := $FF9F
SETTMO          := $FFA2
IECIN           := $FFA5
IECOUT          := $FFA8
UNTALK          := $FFAB
UNLSTN          := $FFAE
LISTEN          := $FFB1
TALK            := $FFB4
READST          := $FFB7
SETLFS          := $FFBA
SETNAM          := $FFBD
OPEN            := $FFC0
CLOSE           := $FFC3
CHKIN           := $FFC6
CKOUT           := $FFC9
CLRCH           := $FFCC
BASIN           := $FFCF
BSOUT           := $FFD2
LOAD            := $FFD5
SAVE            := $FFD8
SETTIM          := $FFDB
RDTIM           := $FFDE
STOP            := $FFE1
GETIN           := $FFE4
CLALL           := $FFE7
UDTIM           := $FFEA
SCREEN          := $FFED
PLOT            := $FFF0
IOBASE          := $FFF3

CHRGET          := $0073
CHRGOT          := $0079

; PETSCII
CR              := $0D
CSR_DOWN        := $11
CSR_HOME        := $13
CSR_RIGHT       := $1D
CSR_UP          := $91
KEY_STOP        := $03
KEY_F3          := $86
KEY_F5          := $87
KEY_F7          := $88

; C64 Memory Map
; http://www.c64.ch/programming/memorymap.php
R6510           := $01   ; 6510 I/O register
TXTPTR          := $7A   ; current byte of BASIC text
ST              := $90   ; kernal I/O status
FNLEN           := $B7   ; length of current file name
LA              := $B8   ; logical file number
SA              := $B9   ; secondary address
FA              := $BA   ; device number
FNADR           := $BB   ; file name
NDX             := $C6   ; number of characters in keyboard buffer
RVS             := $C7   ; print reverse characters flag
BLNSW           := $CC   ; cursor blink enable
GDBLN           := $CE   ; character under cursor
BLNON           := $CF   ; cursor blink phase
PNT             := $D1   ; current screen line address
PNTR            := $D3   ; cursor column
QTSW            := $D4   ; quote mode flag
TBLX            := $D6   ; cursor line
INSRT           := $D8   ; insert mode counter
LDTB1           := $D9   ; screen line link table

BUF             := $0200 ; system input buffer
KEYD            := $0277 ; keyboard buffer
RPTFLG          := $028A ; key repeat flag
