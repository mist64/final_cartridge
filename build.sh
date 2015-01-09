ca65 fc3.s &&
ca65 monitor.s && 
ca65 persistent.s && 
ld65 -C fc3.cfg fc3.o monitor.o persistent.o -o fc3.bin &&
(
hexdump -C fc3-orig.bin > /tmp/fc3-orig.bin.txt; hexdump -C fc3.bin > /tmp/fc3.bin.txt; diff -u /tmp/fc3-orig.bin.txt /tmp/fc3.bin.txt
)
