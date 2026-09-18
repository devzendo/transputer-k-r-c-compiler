CC      = gcc
CFLAGS  = -x c -std=gnu89 \
           -Wno-implicit-function-declaration \
           -Wno-return-type \
           -Wno-int-conversion \
           -Wno-strict-prototypes \
           -Wno-old-style-definition \
           -Wno-deprecated-non-prototype \
           -Wno-parentheses \
           -fno-strict-aliasing \
           -Wno-builtin-requires-header \
           -Wno-invalid-source-encoding \
           -Wno-deprecated-declarations \
           -Wno-pointer-sign \
           -Wno-incompatible-library-redeclaration \
           -Wno-empty-body \
           -Wno-macro-redefined


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

ALL = $(BUILDDIR)/cc1_native

# Build the English compiler (cc1_en) for the native platform.

$(BUILDDIR)/cc1_native: cc.c | $(BUILDDIR)
	echo Building $@
	$(CC) $(CFLAGS) -o $@ $<
	echo ""
	echo ""

