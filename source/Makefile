include Makefile.variables

all:

MLI=terminal.mli
MLSRC=terminal.ml
MLINIT=
CSRC=terminal_stub.c

LIBNAME=terminal
STUBLIBNAME=ml$(LIBNAME)

OCAMLCFLAGS=-w +a
CFLAGS=-Wall -Wextra -Wno-unused-result

CCLIB=
LDFLAGS=
LDLIB=

$(BUILDDIR)/terminal.cmo: $(BUILDDIR)/terminal.cmi
$(BUILDDIR)/terminal.cmx: $(BUILDDIR)/terminal.cmi

include Makefile.rules
