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

# Flags for the K&R compiler cc1
CFLAGS_OLD = -x c -std=gnu89 \
           -Wno-implicit-function-declaration \
           -Wno-return-type \
           -Wno-int-conversion \
           -Wno-strict-prototypes \
           -Wno-old-style-definition \
           -Wno-parentheses \
           -fno-strict-aliasing \
           -Wno-deprecated-declarations \
           -Wno-pointer-sign \
           -Wno-empty-body \
           -Wno-builtin-declaration-mismatch

BUILDDIR = build

ALL = $(BUILDDIR)/tc2_linux \
		$(BUILDDIR)/tc2_es_orig_linux \
		$(BUILDDIR)/tasm_modern_linux \
		$(BUILDDIR)/cc1
#		$(BUILDDIR)/tc2.asm \
#		$(BUILDDIR)/tasm.asm \
#		$(BUILDDIR)/iserverstdio.asm \
#		$(BUILDDIR)/tc2.bin \
#		$(BUILDDIR)/tasm.bin \
#		$(BUILDDIR)/iserver_putchar_example.asm \
#		$(BUILDDIR)/iserver_putchar_example.bin

#		$(BUILDDIR)/tasm_linux \
#		$(BUILDDIR)/tc2.bin \
#		$(BUILDDIR)/tasm_modern.bin

.PHONY: all clean

all: $(BUILDDIR) $(ALL)

$(BUILDDIR):
	mkdir -p $(BUILDDIR)

PATCHES   := $(sort $(wildcard *.patch))
PATCH_STAMP := $(BUILDDIR)/patches-applied

$(PATCH_STAMP): $(PATCHES)
	echo Patching cc1
	$(if $(PATCHES),git apply $(PATCHES))
	git --version > $@

$(BUILDDIR)/cc1: cc1/CC2.c cc1/CCvars.c cc1/CCinter.c cc1/CCanasin.c cc1/CCvarios.c cc1/CCexpr.c cc1/CCgencod.c | $(BUILDDIR) $(PATCH_STAMP)
	echo Building $@
	$(CC) $(CFLAGS_OLD) -o $@ $<
	echo ""
	echo ""


# So things in this makefile can depend on it
$(BUILDDIR)/cc1_linux: cc1_en

# A target without prerequisites and a recipe, and there is no file named `FORCE`.
# `make` will always run this and any other target that depends on it.
FORCE:

# Build the English compiler (tc2) and the Spanish compiler (tc2_es_orig) for Linux.
# DEPRECATE
$(BUILDDIR)/tc2_linux: tc2.c | $(BUILDDIR)
	echo Building $@
	$(CC) $(CFLAGS) -o $@ $<
	echo ""
	echo ""

# DEPRECATE
$(BUILDDIR)/tc2_es_orig_linux: tc2_es_orig.c | $(BUILDDIR)
	echo Building $@
	$(CC) $(CFLAGS) -o $@ $<

#$(BUILDDIR)/tasm_linux: tasm.c | $(BUILDDIR)
#	echo Building $@
#	$(CC) $(CFLAGS) -o $@ $<

# Build the modern assembler (tasm_modern) for Linux. It's not in Small-C, so can't be built for Transputer. It does
# appear to be in K&R C so could be built with cc1?

$(BUILDDIR)/tasm_modern_linux: tasm_modern.c | $(BUILDDIR)
	echo Building $@
	$(CC) -std=gnu99 -o $@ $<
	echo ""
	echo ""

# Using the English Linux compiler, compile itself into .asm.

$(BUILDDIR)/tc2.asm: $(BUILDDIR)/tc2_linux
	echo Building $@
	$(BUILDDIR)/tc2_linux < tc2.in
	echo ""
	echo ""

# Using the English Linux compiler, compile iserverstdio.c into .asm.

$(BUILDDIR)/iserverstdio.asm: $(BUILDDIR)/tc2_linux
	echo Building $@
	$(BUILDDIR)/tc2_linux < iserverstdio.in
	# The compiler adds these START, j ENTRY and ENTRY: sections to every
	# output, assuming it's a 'main', which we don't want for a 'library' we
	# include in real 'main's.
	cat $(BUILDDIR)/iserverstdio.asmx | egrep -v "^(START:|j ENTRY)" | sed '/ENTRY:/,$$d' > $(BUILDDIR)/iserverstdio.asm
	# The .asmx file is a temporary, and can be removed.
	rm $(BUILDDIR)/iserverstdio.asmx
	echo ""
	echo ""

# Using the modern assembler for Linux, assemble the English compiler's .asm into a .bin (there are undefined symbols that don't fail the build yet)

$(BUILDDIR)/tc2.bin: $(BUILDDIR)/tc2.asm
	echo Building $@
	$(BUILDDIR)/tasm_modern_linux $(BUILDDIR)/tc2.asm $(BUILDDIR)/tc2.bin $(BUILDDIR)/iserverstdio.asm
	echo ""
	echo ""

#$(BUILDDIR)/tc2.bin: $(BUILDDIR)/tc2.asm
#	echo Building $@
#	$(BUILDDIR)/tasm_linux < tc2_bin.in

# Using the English Linux compiler, compile the assembler into .asm

$(BUILDDIR)/tasm.asm: $(BUILDDIR)/tc2_linux
	echo Building $@
	$(BUILDDIR)/tc2_linux < tasm.in
	echo ""
	echo ""

# Using the modern assembler for Linux, assemble the assembler's .asm into a .bin.

$(BUILDDIR)/tasm.bin: $(BUILDDIR)/tasm.asm
	echo Building $@
	$(BUILDDIR)/tasm_modern_linux $(BUILDDIR)/tasm.asm $(BUILDDIR)/tasm.bin  $(BUILDDIR)/iserverstdio.asm
	echo ""
	echo ""

#$(BUILDDIR)/tasm.bin: $(BUILDDIR)/tasm.asm
#	echo Building $@
#	$(BUILDDIR)/tasm_linux $(BUILDDIR)/tasm.asm $(BUILDDIR)/tasm.bin

# Examples

$(BUILDDIR)/iserver_putchar_example.asm: $(BUILDDIR)/tc2_linux
	echo Compiling $@
	echo 'Y\nY\niserver_putchar_example.c\nbuild/iserver_putchar_example.asm\n\n' | $(BUILDDIR)/tc2_linux 
	echo ""
	echo ""

$(BUILDDIR)/iserver_putchar_example.bin: $(BUILDDIR)/iserver_putchar_example.asm
	echo Building $@
	$(BUILDDIR)/tasm_modern_linux $(BUILDDIR)/iserver_putchar_example.asm $(BUILDDIR)/iserver_putchar_example.bin $(BUILDDIR)/iserverstdio.asm
	echo ""
	echo ""



clean:
	rm -rf $(BUILDDIR)
	(cd cc1; git checkout -- *)

