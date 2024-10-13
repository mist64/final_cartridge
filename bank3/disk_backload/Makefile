all: backup_loader.prg

basic_stub.bin: basic_stub.bas
		petcat -w2 -l 0x0801 -o $@ $<

backup_loader.o: backup_loader.s basic_stub.bin
		ca65 --target c64 -l backup_loader.lst -o $@ $<

backup_loader.prg: backup_loader.o
		cl65 -m backup_loader.map  -C backup_loader.cfg -o $@ $<

clean:
		rm -f *.o *.bin *.prg *.hexdump *.map *.lst
