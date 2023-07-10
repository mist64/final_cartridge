; TED-specific KERNAL symbols

FETCHL := $FC7F ; banking
LE50C  := $D83B ; set cursor position
LE716  := $DC49 ; screen CHROUT
LE96C  := $DA5E ; insert line at top of screen
LEA31  := $CE0E ; default contents of CINV vector
LF0BD  := $EB58 ; string "I/O ERROR"
LF333  := $EF0C ; default contents of CLRCHN vector
LF646  := $F215 ; IEC close

ICLRCH := $0320 ; CLRCHN vector
IBSOUT := $0324 ; CHROUT vector

ST     := $90
FNLEN  := $AB
LA     := $AC
SA     := $AD
FA     := $AE
FNADR  := $AF
FETPTR := $BE
RVS    := $C2
PNT    := $C8
PNTR   := $CA
QTSW   := $CB
TBLX   := $CD
INSRT  := $CF
NDX    := $EF

BUF    := $0200
KEYD   := $0527
KEYIDX := $055E
KYNDX  := $055D
PKYBUF := $0567
RPTFLG := $0540
BITABL := $07EE

