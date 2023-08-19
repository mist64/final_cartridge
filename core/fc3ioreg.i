fcio_bank_0            := $00
fcio_bank_1            := $01
fcio_bank_2            := $02
fcio_bank_3            := $03
fcio_unassigned_bit2   := $04
fcio_unassigned_bit3   := $08
fcio_c64_16kcrtmode    := $00		; FC3 rom at $8000..$bfff
fcio_c64_ultimaxmode   := $10		; Starts freezer
fcio_c64_8kcrtmode     := $20		; FC3 rom at $8000..$9fff
fcio_c64_crtrom_off    := $30		; only io1/io2 active
fcio_nmi_line          := $40		; 0 = generate nmi
fcio_kill              := $80       ; 1 = disable FC3 hardware

fcio_reg               := $DFFF		; Final Cartridge III io register
