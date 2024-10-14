include Makefile.variables

MLI=terminal.mli
MLSRC=terminal.ml
MLINIT=
CSRC=terminal_stub.c

LIBNAME=terminal
STUBLIBNAME=ml$(LIBNAME)

OCAML_VERSION_MAJOR?=4
# OCAML_VERSION_MAJOR is defined in Makefile.config of OCaml 5.x

DEBUG=
ASSERT=

OCAMLCFLAGS=$(and $(filter-out 0,$(DEBUG)),-g) $(if $(ASSERT),,-noassert) -w +a
OCAMLOPTFLAGS=$(OCAMLCFLAGS)
OCAML_INCLUDE_FLAGS=$(and $(filter 5,$(OCAML_VERSION_MAJOR)),-I +unix)
CFLAGS=$(and $(filter-out 0,$(DEBUG)),-g$(DEBUG)) \
       $(if $(ASSERT),-DDEBUG,-DNDEBUG) -Wall -Wextra -Wno-unused-result
C_INCLUDE_FLAGS=

CCLIB=
LDLIB=

include Makefile.rules
