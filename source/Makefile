HOST:=$(shell $(CC) -dumpmachine)
TARGET=$(HOST)

ifneq ($(TARGET),$(HOST))
PROGRAMPREFIX=$(TARGET)-
ifneq ($(filter default environment undefined,$(origin CC)),)
override CC=$(PROGRAMPREFIX)gcc
endif
else
PROGRAMPREFIX=
endif

ifneq ($(findstring mingw,$(TARGET)),)
DLLSUFFIX=.dll
DLLLD=flexlink -show-imports -show-exports -noentry -chain mingw
DEFAULTLIB=$(addprefix -defaultlib ,$(1))
else
DLLSUFFIX=.so
ifneq ($(findstring darwin,$(TARGET)),)
DLLLD=$(CC) -shared -flat_namespace -undefined suppress
else
DLLLD=$(CC) -shared
ifneq ($(findstring bsd,$(TARGET))$(findstring linux,$(TARGET)),)
DLLCFLAGS=-fPIC
endif
endif
DEFAULTLIB=$(1)
endif

AR=$(PROGRAMPREFIX)ar
OCAMLC=$(PROGRAMPREFIX)ocamlc
OCAMLOPT=$(OCAMLC:c=opt)

OCAMLLIBDIR:=$(shell $(OCAMLC) -where)

PREFIX=$(abspath $(OCAMLLIBDIR)/../..)
DESTDIR=
INSTALLDIR=$(addsuffix /,$(DESTDIR))$(PREFIX)/lib/ocaml

BUILDSUFFIX=.noindex
BUILDDIR=$(TARGET)$(BUILDSUFFIX)

all:

########
MLI=terminal.mli
MLSRC=terminal.ml
MLINIT=
CSRC=terminal_stub.c

LIBNAME=terminal
STUBLIBNAME=ml$(LIBNAME)

OCAMLCFLAGS=-w +a
CFLAGS=-O2 -Wall -Wextra -Wno-unused-result

CCLIB=
LDFLAGS=

$(BUILDDIR)/terminal.cmo: $(BUILDDIR)/terminal.cmi
$(BUILDDIR)/terminal.cmx: $(BUILDDIR)/terminal.cmi
########

DLLPREFIX=$(patsubst $(addsuffix /,$(DESTDIR))%,%,$(INSTALLDIR))/stublibs
ifeq ($(DLLPREFIX),$(OCAMLLIBDIR)/stublibs)
DLLIB=$(addprefix -dllib -l,$(STUBLIBNAME))
else
DLLIB=$(addprefix -dllib $(DLLPREFIX)/dll,$(addsuffix $(DLLSUFFIX),$(STUBLIBNAME)))
endif
SLLIB=$(addprefix -cclib -l,$(STUBLIBNAME))

MLCMO=$(addprefix $(BUILDDIR)/,$(addsuffix .cmo,$(basename $(MLSRC) $(MLINIT))))
MLCMX=$(addprefix $(BUILDDIR)/,$(addsuffix .cmx,$(basename $(MLSRC))))
MLOBJ=$(addprefix $(BUILDDIR)/,$(addsuffix .o,$(basename $(MLSRC))))
MLCMI=$(addprefix $(BUILDDIR)/,$(addsuffix .cmi,$(sort $(basename $(MLI) $(MLSRC) $(MLINIT)))))

COBJ=$(addprefix $(BUILDDIR)/,$(addsuffix .o,$(basename $(CSRC))))
CDLL=$(addprefix $(BUILDDIR)/dll,$(addsuffix $(DLLSUFFIX),$(STUBLIBNAME)))
CSLL=$(addprefix $(BUILDDIR)/lib,$(addsuffix .a,$(STUBLIBNAME)))

.PHONY: all clean install uninstall

ifneq ($(OCAMLOPT),)
all: $(BUILDDIR) $(BUILDDIR)/$(LIBNAME).cma $(BUILDDIR)/$(LIBNAME).cmxa
else
all: $(BUILDDIR) $(BUILDDIR)/$(LIBNAME).cma
endif

$(BUILDDIR)/%.cmi: %.mli
	$(OCAMLC) -c -I $(BUILDDIR) $(OCAMLCFLAGS) -o $@ $<

$(BUILDDIR)/%.cmo: %.ml
	$(OCAMLC) -c -I $(BUILDDIR) $(OCAMLCFLAGS) -o $@ $<

$(BUILDDIR)/%.cmx: %.ml
	$(OCAMLOPT) -c -I $(BUILDDIR) $(OCAMLCFLAGS) -o $@ $<

$(BUILDDIR)/%.o: %.c
	$(CC) -c -isystem "$(OCAMLLIBDIR)" $(CFLAGS) $(DLLCFLAGS) -o $@ $<

$(BUILDDIR)/$(LIBNAME).cma: $(MLCMI) $(MLCMO) $(CDLL)
	$(OCAMLC) -a -o $@ $(MLCMO) $(DLLIB) $(CCLIB)

$(BUILDDIR)/$(LIBNAME).cmxa: $(MLCMI) $(MLCMX) $(CSLL)
	$(OCAMLOPT) -a -o $@ $(MLCMX) $(SLLIB) $(CCLIB)

ifneq ($(STUBLIBNAME),)
$(BUILDDIR)/dll$(STUBLIBNAME)$(DLLSUFFIX): $(COBJ)
	$(DLLLD) -o $@ $< $(LDFLAGS)

ifneq ($(OCAMLOPT),)
$(BUILDDIR)/lib$(STUBLIBNAME).a: $(COBJ)
	$(AR) rcs $@ $<
endif
endif

$(BUILDDIR):
	mkdir -p $@

clean:
	-rm $(BUILDDIR)/$(LIBNAME).cma
	-rm $(BUILDDIR)/$(LIBNAME).a
	-rm $(BUILDDIR)/$(LIBNAME).cmxa
	-rm $(MLCMI) $(MLCMO) $(MLCMX) $(MLOBJ)
ifneq ($(STUBLIBNAME),)
	-rm $(BUILDDIR)/dll$(STUBLIBNAME)$(DLLSUFFIX)
	-rm $(BUILDDIR)/lib$(STUBLIBNAME).a
	-rm $(COBJ)
endif
	-rmdir $(BUILDDIR)

install: all
	-mkdir -p $(INSTALLDIR)
	cp $(MLCMI) $(INSTALLDIR)
	cp $(BUILDDIR)/$(LIBNAME).cma $(INSTALLDIR)
ifneq ($(STUBLIBNAME),)
	-mkdir $(INSTALLDIR)/stublibs
	cp $(BUILDDIR)/dll$(STUBLIBNAME)$(DLLSUFFIX) $(INSTALLDIR)/stublibs
endif
ifneq ($(OCAMLOPT),)
	cp $(MLCMX) $(INSTALLDIR)
	cp $(BUILDDIR)/$(LIBNAME).a $(INSTALLDIR)
	cp $(BUILDDIR)/$(LIBNAME).cmxa $(INSTALLDIR)
ifneq ($(STUBLIBNAME),)
	cp $(BUILDDIR)/lib$(STUBLIBNAME).a $(INSTALLDIR)
endif
endif

uninstall:
	-rm $(addprefix $(INSTALLDIR)/,$(notdir $(MLCMI)))
	-rm $(INSTALLDIR)/$(LIBNAME).cma
ifneq ($(STUBLIBNAME),)
	-rm $(INSTALLDIR)/stublibs/dll$(STUBLIBNAME)$(DLLSUFFIX)
endif
ifneq ($(OCAMLOPT),)
	-rm $(addprefix $(INSTALLDIR)/,$(notdir $(MLCMX)))
	-rm $(INSTALLDIR)/$(LIBNAME).a
	-rm $(INSTALLDIR)/$(LIBNAME).cmxa
ifneq ($(STUBLIBNAME),)
	-rm $(INSTALLDIR)/lib$(STUBLIBNAME).a
endif
endif
