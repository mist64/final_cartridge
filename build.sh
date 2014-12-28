ca65 fc3a-new.s && ld65 -C fc3a.cfg fc3a-new.o -o fc3a-new.bin
ca65 fc3b-new.s && ld65 -C fc3b.cfg fc3b-new.o -o fc3b-new.bin
ca65 fc3x-new.s && ld65 -C fc3x.cfg fc3x-new.o -o fc3x-new.bin
hexdump -C fc3a.bin > /tmp/fc3a.bin.txt; hexdump -C fc3a-new.bin > /tmp/fc3a-new.bin.txt; diff -u /tmp/fc3a.bin.txt /tmp/fc3a-new.bin.txt
hexdump -C fc3b.bin > /tmp/fc3b.bin.txt; hexdump -C fc3b-new.bin > /tmp/fc3b-new.bin.txt; diff -u /tmp/fc3b.bin.txt /tmp/fc3b-new.bin.txt
hexdump -C fc3x.bin > /tmp/fc3x.bin.txt; hexdump -C fc3x-new.bin > /tmp/fc3x-new.bin.txt; diff -u /tmp/fc3x.bin.txt /tmp/fc3x-new.bin.txt
