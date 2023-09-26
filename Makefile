PROJECT ?= cartridge
MACHINE ?= c64

AS=ca65
LD=ld65

ASFLAGS=--include-dir core -g

ifeq ($(PROJECT), cartridge)
	ASFLAGS+=-D CART_FC3=1
endif

ifeq ($(MACHINE), c64)
	ASFLAGS+=-D MACHINE_C64=1
endif
ifeq ($(MACHINE), ted)
	ASFLAGS+=-D MACHINE_TED=1
endif

ifeq ($(CPU), 6502ill)
	ASFLAGS+=-D CPU_6502ILL=1
else
	ifeq ($(CPU), 65c02)
		ASFLAGS+=-D CPU_65C02=1
	else
		ASFLAGS+=-D CPU_6502=1
	endif
endif

SOURCES=core/header.s core/vectors.s core/init.s core/basic.s core/drive.s core/desktop_helper.s core/speeder.s core/monitor.s core/wrappers.s core/editor.s core/printer.s core/format.s core/freezer.s core/persistent.s core/junk.s

DEPS=core/kernal.i core/persistent.i

OBJECTS=$(SOURCES:.s=.o)

all: fc3.bin

clean:
	rm -f core/*.o projects/monitor/*.o projects/speeder/*.o *.bin *.prg *.hexdump fc3full.bin fc3full.crt

test: fc3.bin
	@dd if=bin/Final_Cartridge_3_1988-12.bin bs=16384 count=1 2> /dev/null | hexdump -C > fc3-orig.bin.hexdump
	@hexdump -C fc3.bin > fc3.bin.hexdump
	@diff -u fc3-orig.bin.hexdump fc3.bin.hexdump

fc3.bin: $(OBJECTS) core/fc3.cfg
	$(LD) -mfc3.map -C core/fc3.cfg $(OBJECTS) -o $@

monitor.prg: core/monitor.o projects/monitor/monitor_support.o projects/monitor/monitor.cfg
	$(LD) -C projects/monitor/monitor.cfg core/monitor.o projects/monitor/monitor_support.o -o $@ -Ln labels.txt

speeder.prg: core/speeder.o projects/speeder/speeder_support.o projects/speeder/speeder.cfg
	$(LD) -C projects/speeder/speeder.cfg core/speeder.o projects/speeder/speeder_support.o -o $@

%.o: %.s $(DEPS)
	$(AS) $(ASFLAGS) $< -o $@

fc3full.bin: fc3.bin
	cp bin/Final_Cartridge_3_1988-12.bin fc3full.bin
	dd if=fc3.bin of=fc3full.bin bs=16384 count=1 conv=notrunc

fc3full.crt: fc3full.bin
	cartconv -i fc3full.bin -o fc3full.crt -t fc3
