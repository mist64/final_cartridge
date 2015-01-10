ca65 main.s &&
ca65 init.s &&
ca65 basic.s &&
ca65 drive.s &&
ca65 desktop_helper.s && 
ca65 speeder.s && 
ca65 monitor.s && 
ca65 wrappers.s && 
ca65 editor.s && 
ca65 printer.s && 
ca65 format.s && 
ca65 freezer.s && 
ca65 persistent.s && 
ld65 -C fc3.cfg main.o init.o basic.o drive.o desktop_helper.o speeder.o monitor.o wrappers.o editor.o printer.o format.o freezer.o persistent.o -o fc3.bin &&
(
hexdump -C fc3-orig.bin > /tmp/fc3-orig.bin.txt; hexdump -C fc3.bin > /tmp/fc3.bin.txt; diff -u /tmp/fc3-orig.bin.txt /tmp/fc3.bin.txt
)
