
ifeq ($(OS),Windows_NT)
    CC      = cl
    CFLAGS_TASM = -TC -wd4013 -wd4033 -wd4716 -wd4024 -wd4047 -wd4133
	CFLAGS_CC1 = -TC -Zi -wd4013 -wd4033 -wd4716 -wd4024 -wd4047 -wd4133 -wd4996
    OUTFLAG := -Fe
    EXE     := .exe
else
	CC      = gcc
	CFLAGS_TASM  = -std=gnu90 \
           -Wno-implicit-int \
           -Wno-implicit-function-declaration \
           -Wno-return-type \
           -Wno-int-conversion \
           -Wno-strict-prototypes \
           -Wno-old-style-definition \
           -Wno-parentheses \
           -fno-strict-aliasing
	CFLAGS_CC1 = -x c -g -std=gnu89 \
           -Wno-implicit-function-declaration \
           -Wno-return-type \
           -Wno-int-conversion \
           -Wno-strict-prototypes \
           -Wno-old-style-definition \
           -Wno-parentheses \
           -fno-strict-aliasing \
           -Wno-deprecated-declarations \
           -Wno-pointer-sign \
           -Wno-empty-body
	OUTFLAG := -o
    EXE     :=
endif


BUILDDIR = build

ALL = $(BUILDDIR)/tasm$(EXE) \
		$(BUILDDIR)/cc1$(EXE) \
		$(BUILDDIR)/iserverstdio.asm \
		$(BUILDDIR)/iserver_putchar_example.asm
#		$(BUILDDIR)/cc1.asm \
#		$(BUILDDIR)/tasm.asm \
#		$(BUILDDIR)/cc1.bin \
#		$(BUILDDIR)/tasm.bin \
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

# A target without prerequisites and a recipe, and there is no file named `FORCE`.
# `make` will always run this and any other target that depends on it.
FORCE:

# Native builds.

# Build the K&R Compiler natively. It's in K&R C (no extern/static).
$(BUILDDIR)/cc1$(EXE): cc1/CC.c cc1/CCvars.c cc1/CCinter.c cc1/CCanasin.c cc1/CCvarios.c cc1/CCexpr.c cc1/CCgencod.c | $(BUILDDIR) $(PATCH_STAMP)
	echo Building $@
	$(CC) $(CFLAGS_CC1) $(OUTFLAG)$@ $<
	echo ""
	echo ""

# Build the assembler natively. Could be built with cc1?
$(BUILDDIR)/tasm$(EXE): tasm.c | $(BUILDDIR)
	echo Building $@
	$(CC) $(CFLAGS_TASM) $(OUTFLAG)$@ $<
	echo ""
	echo ""


# Compile into assembler files.

# Compile the compiler itself into .asm.
$(BUILDDIR)/cc1.asm: $(BUILDDIR)/cc1
	echo Building $@
	cat cc1/CC2.c iserverstdio.c > $(BUILDDIR)/cc1-all.c
	(cd cc1; ../$(BUILDDIR)/cc1 < ../cc1.in)
	echo ""
	echo ""

# Compile iserverstdio.c into .asm.
# It doesn't actually get used like this, as it gets included into any compilation, rather than as a standalone asm
# - there's no linker, and there will be duplicate prologue/epilogue in here. But useful to see the compiler's output
# of this on its own.
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

# Compile the assembler into .asm
# Current failures:
#   tasm contains includes of <stdio.h> and others that don't exist.
#   tasm contains arrays of zero length that cc1 doesn't like.
$(BUILDDIR)/tasm.asm: $(BUILDDIR)/cc1
	echo Building $@
	$(BUILDDIR)/cc1 < tasm.in
	echo ""
	echo ""


# Transputer binaries.

# Using the assembler, assemble the compiler+iserverstdio's .asm into a .bin (there are undefined symbols that don't fail the build yet)
# Current failures:
# tasm doesn't understand iserverstdio's use of the extended 'terminate' instruction.
#   Use a db in an asm block instead?
#   Assemble with tmasm instead (boot loader needs that anyway)?
# No malloc/free in iserverstdio (should be elsewhere).
$(BUILDDIR)/cc1.bin: $(BUILDDIR)/cc1.asm
	echo Building $@
	$(BUILDDIR)/tasm $(BUILDDIR)/cc1.asm $(BUILDDIR)/cc1.bin
	echo ""
	echo ""

# Using the assembler, assemble the assembler's .asm into a .bin.
# We're a way off this yet.
$(BUILDDIR)/tasm.bin: $(BUILDDIR)/tasm.asm
	echo Building $@
	$(BUILDDIR)/tasm $(BUILDDIR)/tasm.asm $(BUILDDIR)/tasm.bin  $(BUILDDIR)/iserverstdio.asm
	echo ""
	echo ""


# Examples

# Need to include iserverstdio.c in here, hack up the startup linkage and assemble with tmasm + bootloader.
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

