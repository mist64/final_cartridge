PROJECT ?= cartridge
MACHINE ?= c64

AS=ca65
LD=ld65

ASFLAGS=-g

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

SOURCES_B0=bank0/header.s bank0/vectors.s bank0/init.s bank0/basic.s bank0/drive.s bank0/desktop_helper.s bank0/speeder.s bank0/monitor.s bank0/wrappers.s bank0/editor.s bank0/printer.s bank0/format.s bank0/freezer.s bank0/persistent.s bank0/junk.s
SOURCES_B3=bank3/freezer_entry.s bank3/freezer_reset.s bank3/freezer_game.s bank3/freezer_backup.s bank3/screenshot.s bank3/persistent.s bank3/mysterycode.s

DEPS=core/kernal.i bank0/persistent.i

OBJECTS_B0=$(SOURCES_B0:.s=.o)
OBJECTS_B3=$(SOURCES_B3:.s=.o)

all: fc3full.crt

clean:
	rm -f bank0/*.o bank3/*.o projects/monitor/*.o projects/speeder/*.o *.bin *.prg *.hexdump fc3full.bin fc3full.crt
	make -C bank3/disk_backload clean
	make -C bank3/tape_backload clean

bank3/disk_backload/backup_loader.prg:
	make -C bank3/disk_backload

bank3/tape_backload/backup_loader.prg:
	make -C bank3/tape_backload

testb0: bank0.bin
	@dd if=bin/Final_Cartridge_3_1988-12.bin bs=16384 count=1 2> /dev/null | hexdump -C > fc3b0-orig.bin.hexdump
	@hexdump -C bank0.bin > bank0.bin.hexdump
	@diff -u fc3b0-orig.bin.hexdump bank0.bin.hexdump

testb3: bank3.bin
	@dd if=bin/Final_Cartridge_3_1988-12.bin bs=16384 skip=3 count=1 2> /dev/null | hexdump -C > fc3b3-orig.bin.hexdump
	@hexdump -C bank3.bin > bank3.bin.hexdump
	@diff -u fc3b3-orig.bin.hexdump bank3.bin.hexdump

bank0.bin: $(OBJECTS_B0) bank0/bank0.cfg
	$(LD) -mbank0.map -C bank0/bank0.cfg $(OBJECTS_B0) -o $@

bank3.bin: $(OBJECTS_B3) bank3/bank3.cfg
	$(LD) -mbank3.map -C bank3/bank3.cfg $(OBJECTS_B3) -o $@

monitor.prg: bank0/monitor.o projects/monitor/monitor_support.o projects/monitor/monitor.cfg
	$(LD) -C projects/monitor/monitor.cfg bank0/monitor.o projects/monitor/monitor_support.o -o $@ -Ln labels.txt

speeder.prg: bank0/speeder.o projects/speeder/speeder_support.o projects/speeder/speeder.cfg
	$(LD) -C projects/speeder/speeder.cfg bank0/speeder.o projects/speeder/speeder_support.o -o $@

%.o: %.s $(DEPS)
	$(AS) $(ASFLAGS) $< -o $@

bank3/freezer_backup.o: bank3/freezer_backup.s bank3/disk_backload/backup_loader.prg bank3/tape_backload/backup_loader.prg $(DEPS)
	$(AS) $(ASFLAGS) $< -o $@

fc3full.bin: bank0.bin bank3.bin
	cp bin/Final_Cartridge_3_1988-12.bin fc3full.bin
	dd if=bank0.bin of=fc3full.bin bs=16384 count=1 conv=notrunc
	dd if=bank3.bin of=fc3full.bin bs=8192 seek=6 count=1 conv=notrunc

fc3full.crt: fc3full.bin
	cartconv -i fc3full.bin -o fc3full.crt -t fc3
