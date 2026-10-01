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
CFLAGS_OLD = -x c -g -std=gnu89 \
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

ALL = $(BUILDDIR)/tasm \
		$(BUILDDIR)/cc1 \
		$(BUILDDIR)/iserverstdio.asm \
		$(BUILDDIR)/cc1.asm # segfault \
#		$(BUILDDIR)/tasm.asm \
#		$(BUILDDIR)/cc1.bin \
#		$(BUILDDIR)/tasm.bin \
#		$(BUILDDIR)/iserver_putchar_example.asm \
#		$(BUILDDIR)/iserver_putchar_example.bin

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

# Build the K&R Compiler. It's in K&R C (no extern/static).
$(BUILDDIR)/cc1: cc1/CC.c cc1/CCvars.c cc1/CCinter.c cc1/CCanasin.c cc1/CCvarios.c cc1/CCexpr.c cc1/CCgencod.c | $(BUILDDIR) $(PATCH_STAMP)
	echo Building $@
	$(CC) $(CFLAGS_OLD) -o $@ $<
	echo ""
	echo ""


# A target without prerequisites and a recipe, and there is no file named `FORCE`.
# `make` will always run this and any other target that depends on it.
FORCE:

# Build the assembler natively. Could be built with cc1?
$(BUILDDIR)/tasm: tasm.c | $(BUILDDIR)
	echo Building $@
	$(CC) -std=gnu99 -o $@ $<
	echo ""
	echo ""

# Compile the compiler itself into .asm.
# This currently gives a segmentation fault.
$(BUILDDIR)/cc1.asm: $(BUILDDIR)/cc1
	echo Building $@
	cat cc1/CC2.c iserverstdio.c > $(BUILDDIR)/cc1-all.c
	(cd cc1; ../$(BUILDDIR)/cc1 < ../cc1.in)
	echo ""
	echo ""

# Using the English Linux compiler, compile iserverstdio.c into .asm.
$(BUILDDIR)/iserverstdio.asm: $(BUILDDIR)/cc1
	echo Building $@
	$(BUILDDIR)/cc1 < iserverstdio.in
	# The compiler adds these START, j ENTRY and ENTRY: sections to every
	# output, assuming it's a 'main', which we don't want for a 'library' we
	# include in real 'main's.
	cat $(BUILDDIR)/iserverstdio.asmx | egrep -v "^(START:|j ENTRY)" | sed '/ENTRY:/,$$d' > $(BUILDDIR)/iserverstdio.asm
	# The .asmx file is a temporary, and can be removed.
	rm $(BUILDDIR)/iserverstdio.asmx
	echo ""
	echo ""

# Using the assembler, assemble the compiler's .asm into a .bin (there are undefined symbols that don't fail the build yet)
$(BUILDDIR)/cc1.bin: $(BUILDDIR)/cc1.asm
	echo Building $@
	$(BUILDDIR)/tasm $(BUILDDIR)/cc1.asm $(BUILDDIR)/cc1.bin $(BUILDDIR)/iserverstdio.asm
	echo ""
	echo ""

# Compile the assembler into .asm
$(BUILDDIR)/tasm.asm: $(BUILDDIR)/cc1
	echo Building $@
	$(BUILDDIR)/cc1 < tasm.in
	echo ""
	echo ""

# Using the assembler, assemble the assembler's .asm into a .bin.
$(BUILDDIR)/tasm.bin: $(BUILDDIR)/tasm.asm
	echo Building $@
	$(BUILDDIR)/tasm $(BUILDDIR)/tasm.asm $(BUILDDIR)/tasm.bin  $(BUILDDIR)/iserverstdio.asm
	echo ""
	echo ""


# Examples

$(BUILDDIR)/iserver_putchar_example.asm: $(BUILDDIR)/cc1
	echo Compiling $@
	echo 'Y\nY\niserver_putchar_example.c\nbuild/iserver_putchar_example.asm\n\n' | $(BUILDDIR)/cc1
	echo ""
	echo ""

$(BUILDDIR)/iserver_putchar_example.bin: $(BUILDDIR)/iserver_putchar_example.asm
	echo Building $@
	$(BUILDDIR)/tasm $(BUILDDIR)/iserver_putchar_example.asm $(BUILDDIR)/iserver_putchar_example.bin $(BUILDDIR)/iserverstdio.asm
	echo ""
	echo ""



clean:
	rm -rf $(BUILDDIR)
	(cd cc1; git checkout -- *)

