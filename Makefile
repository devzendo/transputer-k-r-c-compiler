# Note this only works on 32-bit systems currently
# due to pointer/int length differences in tc2.c
# e.g. Debian Bookworm Intel.

CC      = gcc
CFLAGS  = -std=gnu90 \
           -Wno-implicit-int \
           -Wno-implicit-function-declaration \
           -Wno-return-type \
           -Wno-int-conversion \
           -Wno-strict-prototypes \
           -Wno-old-style-definition \
           -Wno-old-style-declaration \
           -Wno-parentheses \
           -fno-strict-aliasing

BUILDDIR = build

ALL = $(BUILDDIR)/tc2_linux \
		$(BUILDDIR)/tc2_es_orig_linux \
		$(BUILDDIR)/tasm_modern_linux \
		$(BUILDDIR)/tc2.asm \
		$(BUILDDIR)/tasm.asm \
		$(BUILDDIR)/iserverstdio.asm \
		$(BUILDDIR)/tc2.bin \
		$(BUILDDIR)/tasm.bin

#		$(BUILDDIR)/tasm_linux \
#		$(BUILDDIR)/tc2.bin \
#		$(BUILDDIR)/tasm_modern.bin

.PHONY: all clean

all: $(BUILDDIR) $(ALL)

$(BUILDDIR):
	mkdir -p $(BUILDDIR)

# Build the English compiler (tc2) and the Spanish compiler (tc2_es_orig) for Linux.

$(BUILDDIR)/tc2_linux: tc2.c | $(BUILDDIR)
	echo Building $@
	$(CC) $(CFLAGS) -o $@ $<

$(BUILDDIR)/tc2_es_orig_linux: tc2_es_orig.c | $(BUILDDIR)
	echo Building $@
	$(CC) $(CFLAGS) -o $@ $<

#$(BUILDDIR)/tasm_linux: tasm.c | $(BUILDDIR)
#	echo Building $@
#	$(CC) $(CFLAGS) -o $@ $<

# Build the modern assembler (tasm_modern) for Linux. It's not in Small-C, so can't be built for Transputer.

$(BUILDDIR)/tasm_modern_linux: tasm_modern.c | $(BUILDDIR)
	echo Building $@
	$(CC) -std=gnu99 -o $@ $<

# Using the English Linux compiler, compile itself into .asm.

$(BUILDDIR)/tc2.asm: $(BUILDDIR)/tc2_linux
	echo Building $@
	$(BUILDDIR)/tc2_linux < tc2.in

# Using the English Linux compiler, compile iserverstdio.c into .asm.

$(BUILDDIR)/iserverstdio.asm: $(BUILDDIR)/tc2_linux
	echo Building $@
	$(BUILDDIR)/tc2_linux < iserverstdio.in
	cat $(BUILDDIR)/iserverstdio.asmx | egrep -v "^(START:|j ENTRY)" | sed '/ENTRY:/,$$d' > $(BUILDDIR)/iserverstdio.asm

# Using the modern assembler for Linux, assemble the English compiler's .asm into a .bin (there are undefined symbols that don't fail the build yet)

$(BUILDDIR)/tc2.bin: $(BUILDDIR)/tc2.asm
	echo Building $@
	$(BUILDDIR)/tasm_modern_linux $(BUILDDIR)/tc2.asm $(BUILDDIR)/tc2.bin $(BUILDDIR)/iserverstdio.asm

#$(BUILDDIR)/tc2.bin: $(BUILDDIR)/tc2.asm
#	echo Building $@
#	$(BUILDDIR)/tasm_linux < tc2_bin.in

# Using the English Linux compiler, compile the assembler into .asm

$(BUILDDIR)/tasm.asm: $(BUILDDIR)/tc2_linux
	echo Building $@
	$(BUILDDIR)/tc2_linux < tasm.in

# Using the modern assembler for Linux, assemble the assembler's .asm into a .bin.

$(BUILDDIR)/tasm.bin: $(BUILDDIR)/tasm.asm
	echo Building $@
	$(BUILDDIR)/tasm_modern_linux $(BUILDDIR)/tasm.asm $(BUILDDIR)/tasm.bin  $(BUILDDIR)/iserverstdio.asm

#$(BUILDDIR)/tasm.bin: $(BUILDDIR)/tasm.asm
#	echo Building $@
#	$(BUILDDIR)/tasm_linux $(BUILDDIR)/tasm.asm $(BUILDDIR)/tasm.bin


clean:
	rm -rf $(BUILDDIR)

