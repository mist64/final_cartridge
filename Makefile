CC=ca65
LD=ld65

SOURCES=vectors.s init.s basic.s drive.s desktop_helper.s speeder.s monitor.s wrappers.s editor.s printer.s format.s freezer.s persistent.s
DEPS=kernal.i persistent.i

OBJECTS=$(SOURCES:.s=.o)

all: fc3.bin

clean:
	rm -f $(OBJECTS) fc3.bin fc3-orig.bin.txt fc3.bin.txt

test: fc3.bin
	@dd if=bin/Final_Cartridge_3_1988-12.bin bs=16384 count=1 2> /dev/null | hexdump -C > fc3-orig.bin.txt
	@hexdump -C fc3.bin > fc3.bin.txt
	@diff -u fc3-orig.bin.txt fc3.bin.txt

fc3.bin: $(OBJECTS)
	$(LD) -C fc3.cfg $(OBJECTS) -o $@

%.o: %.s $(DEPS)
	$(CC) $(CFLAGS) $< -o $@

