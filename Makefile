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

ALL      = $(BUILDDIR)/tc2_linux $(BUILDDIR)/tasm_linux \
		$(BUILDDIR)/tc2.asm

.PHONY: all clean

all: $(BUILDDIR) $(ALL)

$(BUILDDIR):
	mkdir -p $(BUILDDIR)

$(BUILDDIR)/tc2_linux: tc2.c | $(BUILDDIR)
	$(CC) $(CFLAGS) -o $@ $<

$(BUILDDIR)/tasm_linux: tasm.c | $(BUILDDIR)
	$(CC) -std=gnu99 -o $@ $<

$(BUILDDIR)/tc2.asm: $(BUILDDIR)/tc2_linux
	$(BUILDDIR)/tc2_linux < tc2.in

clean:
	rm -rf $(BUILDDIR)

