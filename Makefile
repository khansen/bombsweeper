bombswpr.nes: bombswpr.s bombswpr.tbl bombswpr.hdr bombswpr.o vectors.o graphics/bg.chr graphics/sprite.chr
	xlnk bombswpr.s

bombswpr.o: bombswpr.asm bombswpr.tbl pal.inc rnme.inc
	xasm bombswpr.asm

vectors.o: vectors.asm
	xasm vectors.asm

clean:
	rm -f bombswpr.o vectors.o bombswpr.nes
