include Makefile.variables

MLI=terminal.mli
MLSRC=terminal.ml
MLINIT=
CSRC=terminal_stub.c

LIBNAME=terminal
STUBLIBNAME=ml$(LIBNAME)

DEBUG=

OCAMLCFLAGS=$(and $(filter-out 0,$(DEBUG)),-g) -w +a
OCAMLOPTFLAGS=$(OCAMLCFLAGS)
CFLAGS=$(and $(filter-out 0,$(DEBUG)),-g$(DEBUG)) -Wall -Wextra \
       -Wno-unused-result

CCLIB=
LDFLAGS=
LDLIB=

include Makefile.rules
