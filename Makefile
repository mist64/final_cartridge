AS=ca65
LD=ld65

ASFLAGS=--include-dir core

SOURCES=core/vectors.s core/init.s core/basic.s core/drive.s core/desktop_helper.s core/speeder.s core/monitor.s core/wrappers.s core/editor.s core/printer.s core/format.s core/freezer.s core/persistent.s

DEPS=core/kernal.i core/persistent.i

OBJECTS=$(SOURCES:.s=.o)

all: fc3.bin

clean:
	rm -f core/*.o projects/monitor/*.o *.bin *.prg *.hexdump

test: fc3.bin
	@dd if=bin/Final_Cartridge_3_1988-12.bin bs=16384 count=1 2> /dev/null | hexdump -C > fc3-orig.bin.hexdump
	@hexdump -C fc3.bin > fc3.bin.hexdump
	@diff -u fc3-orig.bin.hexdump fc3.bin.hexdump

fc3.bin: $(OBJECTS) core/fc3.cfg
	$(LD) -C core/fc3.cfg $(OBJECTS) -o $@

monitor.prg: core/monitor.o projects/monitor/monitor_support.o projects/monitor/monitor.cfg
	$(LD) -C projects/monitor/monitor.cfg core/monitor.o projects/monitor/monitor_support.o -o $@

%.o: %.s $(DEPS)
	$(AS) $(ASFLAGS) $< -o $@

