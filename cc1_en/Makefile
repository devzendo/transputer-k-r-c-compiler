CC      = gcc
CFLAGS  = -x c -std=gnu89 \
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


#            -Wno-macro-redefined \
#           -Wno-incompatible-library-redeclaration \
#           -Wno-invalid-source-encoding \
#           -Wno-builtin-requires-header \
           #-Wno-deprecated-non-prototype \

#            -Wno-implicit-function-declaration  # calls before declaration
#            -Wno-return-type                    # fall-off-end functions
#            -Wno-int-conversion                 # char*/int* pointer aliasing
#            -Wno-strict-prototypes              # unprototyped parameter lists
#            -Wno-old-style-definition           # K&R parameter-declaration syntax
#            -Wno-knr-promoted-parameter         # char/short args promoted to int
#            -Wno-parentheses                    # assignment-as-condition (K&R idiom)
#            -fno-strict-aliasing                # char[] walked as struct fields
#            -Wno-builtin-requires-header

BUILDDIR = ../build

ALL = $(BUILDDIR) $(BUILDDIR)/cc1_native

.PHONY: all clean

all: $(ALL)


clean: $(BUILDDIR)/cc1_native
	rm $(BUILDDIR)/cc1_native

$(BUILDDIR):
	mkdir -p $(BUILDDIR)

# Build the English compiler (cc1_en) for the native platform.
$(BUILDDIR)/cc1_native: cc.c | $(BUILDDIR)
	echo Building $@
	$(CC) $(CFLAGS) -o $@ $<
	echo ""
	echo ""

