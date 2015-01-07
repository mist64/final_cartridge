ca65 fc3a-new.s && ld65 -C fc3a.cfg fc3a-new.o -o fc3a-new.bin &&
(
hexdump -C fc3a.bin > /tmp/fc3a.bin.txt; hexdump -C fc3a-new.bin > /tmp/fc3a-new.bin.txt; diff -u /tmp/fc3a.bin.txt /tmp/fc3a-new.bin.txt
)
