HOST:=$(shell $(CC) -dumpmachine)
TARGET=$(HOST)

ifneq ($(HOST),$(TARGET))
PROGRAMPREFIX=$(TARGET)-
ifneq ($(filter default environment undefined,$(origin CC)),)
override CC=$(PROGRAMPREFIX)gcc
endif
else
PROGRAMPREFIX=
endif

ifneq ($(findstring mingw,$(TARGET)),)
DLLSUFFIX=.dll
LD=flexlink -show-imports -show-exports -noentry -chain mingw
DEFAULTLIB=$(addprefix -defaultlib ,$(1))
else
DLLSUFFIX=.so
ifneq ($(findstring darwin,$(TARGET)),)
LD=$(PROGRAMPREFIX)ld -bundle -flat_namespace -undefined suppress /usr/lib/bundle1.o
else
LD=$(PROGRAMPREFIX)ld -shared
ifneq ($(findstring bsd,$(TARGET))$(findstring linux,$(TARGET)),)
DLLCFLAGS=-fPIC
endif
endif
DEFAULTLIB=$(1)
endif

AR=$(PROGRAMPREFIX)ar
OCAMLC=$(PROGRAMPREFIX)ocamlc
OCAMLOPT=$(OCAMLC:c=opt)
OCAMLMKLIB=$(OCAMLC:c=mklib)

OCAMLLIBDIR:=$(shell $(OCAMLC) -where)

PREFIX=$(abspath $(OCAMLLIBDIR)/../..)
DESTDIR=
INSTALLDIR=$(addsuffix /,$(DESTDIR))$(PREFIX)/lib/ocaml
DLLPREFIX=$(patsubst $(addsuffix /,$(DESTDIR))%,%,$(INSTALLDIR))/stublibs

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

OCAMLMKLIBFLAGS=
CCLIB=
LDFLAGS=

$(BUILDDIR)/terminal.cmo: $(BUILDDIR)/terminal.cmi
########

ifeq ($(DLLPREFIX),$(OCAMLLIBDIR)/stublibs)
DLLIB=$(addprefix -dllib -l,$(STUBLIBNAME))
else
DLLIB=$(addprefix -dllib $(DLLPREFIX)/dll,$(addsuffix $(DLLSUFFIX),$(STUBLIBNAME)))
endif

MLCMO=$(addprefix $(BUILDDIR)/,$(addsuffix .cmo,$(basename $(MLSRC) $(MLINIT))))
MLCMX=$(addprefix $(BUILDDIR)/,$(addsuffix .cmx,$(basename $(MLSRC))))
MLOBJ=$(addprefix $(BUILDDIR)/,$(addsuffix .o,$(basename $(MLSRC))))
MLCMI=$(addprefix $(BUILDDIR)/,$(addsuffix .cmi,$(sort $(basename $(MLI) $(MLSRC) $(MLINIT)))))

COBJ=$(addprefix $(BUILDDIR)/,$(addsuffix .o,$(basename $(CSRC))))

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

ifeq ($(STUBLIBNAME),)
$(BUILDDIR)/$(LIBNAME).cma: $(MLCMI) $(MLCMO)
	$(OCAMLC) -a -o $(BUILDDIR)/$(LIBNAME).cma $(MLCMO)
$(BUILDDIR)/$(LIBNAME).cmxa: $(MLCMI) $(MLCMX)
	$(OCAMLOPT) -a -o $(BUILDDIR)/$(LIBNAME).cmxa $(MLCMX)
else
ifneq ($(and $(OCAMLMKLIB),$(filter $(OCAMLLIBDIR)/stublibs,$(DLLPREFIX))),)
ifneq ($(OCAMLOPT),)
$(BUILDDIR)/$(LIBNAME).cma: $(COBJ) $(MLCMI) $(MLCMO) $(MLCMX)
	cd $(BUILDDIR) && $(OCAMLMKLIB) -ocamlc $(OCAMLC) -ocamlopt $(OCAMLOPT) -o $(LIBNAME) -oc $(STUBLIBNAME) $(notdir $(COBJ) $(MLCMO) $(MLCMX)) $(OCAMLMKLIBFLAGS)
else
$(BUILDDIR)/$(LIBNAME).cma: $(COBJ) $(MLCMI) $(MLCMO)
	cd $(BUILDDIR) && $(OCAMLMKLIB) -ocamlc $(OCAMLC) -o $(LIBNAME) -oc $(STUBLIBNAME) $(notdir $(COBJ) $(MLCMO)) $(OCAMLMKLIBFLAGS)
endif
else
$(BUILDDIR)/$(LIBNAME).cma: $(COBJ) $(MLCMI) $(MLCMO)
	$(OCAMLC) -a -o $(BUILDDIR)/$(LIBNAME).cma $(MLCMO) -cclib -l$(STUBLIBNAME) $(CCLIB) $(DLLIB)
	$(LD) -o $(BUILDDIR)/dll$(STUBLIBNAME)$(DLLSUFFIX) $(COBJ) $(LDFLAGS)
$(BUILDDIR)/$(LIBNAME).cmxa: $(COBJ) $(MLCMI) $(MLCMX)
	$(OCAMLOPT) -a -o $(BUILDDIR)/$(LIBNAME).cmxa $(MLCMX) -cclib -l$(STUBLIBNAME) $(CCLIB)
	$(AR) rcs $(BUILDDIR)/lib$(STUBLIBNAME).a $(COBJ)
endif
endif

$(BUILDDIR):
	mkdir -p $@

clean:
	-rm $(BUILDDIR)/$(LIBNAME).cma
	-rm $(BUILDDIR)/$(LIBNAME).a
	-rm $(BUILDDIR)/$(LIBNAME).cmxa
	-rm $(BUILDDIR)/dll$(STUBLIBNAME)$(DLLSUFFIX)
	-rm $(BUILDDIR)/lib$(STUBLIBNAME).a
	-rm $(COBJ) $(MLCMI) $(MLCMO) $(MLCMX) $(MLOBJ)
ifeq ($(BUILDDIR),$(TARGET)$(BUILDSUFFIX))
	-rmdir $(BUILDDIR)
endif

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
