include Makefile.variables

MLI=terminal.mli
MLSRC=terminal.ml
MLINIT=
CSRC=terminal_stub.c

LIBNAME=terminal
STUBLIBNAME=ml$(LIBNAME)

DEBUG=
ASSERT=

OCAMLCFLAGS=$(and $(filter-out 0,$(DEBUG)),-g) $(if $(ASSERT),,-noassert) -w +a
OCAMLOPTFLAGS=$(OCAMLCFLAGS)
CFLAGS=$(and $(filter-out 0,$(DEBUG)),-g$(DEBUG)) \
       $(and $(ASSERT),-DDEBUG -DNDEBUG) -Wall -Wextra -Wno-unused-result

CCLIB=
LDFLAGS=
LDLIB=

include Makefile.rules
