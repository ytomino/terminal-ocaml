HOST=$(shell gcc -dumpmachine)
TARGET=$(HOST)

ifneq ($(ComSpec),)
empty=
DIRSEP=\$(empty)
CMDSEP=&
RM=del $(subst /,$(DIRSEP),$(1))
CP=copy $(subst /,$(DIRSEP),$(1)) $(subst /,$(DIRSEP),$(2))
MKDIR=mkdir $(subst /,$(DIRSEP),$(1))
RMDIR=rmdir $(subst /,$(DIRSEP),$(1))
NOP=echo > NUL
else
DIRSEP=/
CMDSEP=;
RM=rm $(1)
CP=cp $(1) $(2)
MKDIR=mkdir $(1)
RMDIR=rmdir $(1)
NOP=echo > /dev/null
endif

ifneq ($(HOST),$(TARGET))
PROGRAMPREFIX=$(TARGET)-
DIRSUFFIX=-$(TARGET)
else
PROGRAMPREFIX=
DIRSUFFIX=
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
endif
DEFAULTLIB=$(1)
endif

AR=$(PROGRAMPREFIX)ar
GCC=$(PROGRAMPREFIX)gcc
OCAMLC=$(PROGRAMPREFIX)ocamlc
OCAMLOPT=$(OCAMLC:c=opt)
OCAMLMKLIB=$(OCAMLC:c=mklib)

ifneq ($(OCAMLLIB),)
OCAMLLIBDIR=$(OCAMLLIB)
else
OCAMLLIBDIR=$(shell $(OCAMLC) -where)
endif

DESTDIR=$(OCAMLLIBDIR)
BUILDDIR=build$(DIRSUFFIX)

all:

########
MLI=terminal.mli
MLSRC=terminal.ml
MLINIT=
CSRC=terminal_stub.c

LIBNAME=terminal
STUBLIBNAME=ml$(LIBNAME)

OCAMLCFLAGS=-w Aer
CFLAGS=-O2 -W -Wall

OCAMLMKLIBFLAGS=
CCLIB=
LDFLAGS=

$(BUILDDIR)/terminal.cmo: $(BUILDDIR)/terminal.cmi
########

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
	$(GCC) -c -isystem "$(OCAMLLIBDIR)" $(CFLAGS) -o $@ $<

ifeq ($(STUBLIBNAME),)
$(BUILDDIR)/$(LIBNAME).cma: $(MLCMI) $(MLCMO)
	$(OCAMLC) -a -o $(BUILDDIR)/$(LIBNAME).cma $(MLCMO)
$(BUILDDIR)/$(LIBNAME).cmxa: $(MLCMI) $(MLCMX)
	$(OCAMLOPT) -a -o $(BUILDDIR)/$(LIBNAME).cmxa $(MLCMX)
else
ifneq ($(OCAMLMKLIB),)
ifneq ($(OCAMLOPT),)
$(BUILDDIR)/$(LIBNAME).cma: $(COBJ) $(MLCMI) $(MLCMO) $(MLCMX)
	cd $(BUILDDIR) && $(OCAMLMKLIB) -ocamlc $(OCAMLC) -ocamlopt $(OCAMLOPT) -o $(LIBNAME) -oc $(STUBLIBNAME) $(notdir $(COBJ) $(MLCMO) $(MLCMX)) $(OCAMLMKLIBFLAGS)
else
$(BUILDDIR)/$(LIBNAME).cma: $(COBJ) $(MLCMI) $(MLCMO)
	cd $(BUILDDIR) && $(OCAMLMKLIB) -ocamlc $(OCAMLC) -o $(LIBNAME) -oc $(STUBLIBNAME) $(notdir $(COBJ) $(MLCMO)) $(OCAMLMKLIBFLAGS)
endif
else
$(BUILDDIR)/$(LIBNAME).cma: $(COBJ) $(MLCMI) $(MLCMO)
	$(OCAMLC) -a -o $(BUILDDIR)/$(LIBNAME).cma $(MLCMO) -dllib -l$(STUBLIBNAME) -cclib -l$(STUBLIBNAME) $(CCLIB)
	$(LD) -o $(BUILDDIR)/dll$(STUBLIBNAME)$(DLLSUFFIX) $(COBJ) $(LDFLAGS)
$(BUILDDIR)/$(LIBNAME).cmxa: $(COBJ) $(MLCMI) $(MLCMX)
	$(OCAMLOPT) -a -o $(BUILDDIR)/$(LIBNAME).cmxa $(MLCMX) -cclib -l$(STUBLIBNAME) $(CCLIB)
	$(AR) rcs $(BUILDDIR)/lib$(STUBLIBNAME).a $(COBJ)
endif
endif

$(BUILDDIR):
	$(call MKDIR,$@)

clean:
	-$(call RM,$(BUILDDIR)/$(LIBNAME).cma)
	-$(call RM,$(BUILDDIR)/$(LIBNAME).a)
	-$(call RM,$(BUILDDIR)/$(LIBNAME).cmxa)
	-$(call RM,$(BUILDDIR)/dll$(STUBLIBNAME)$(DLLSUFFIX))
	-$(call RM,$(BUILDDIR)/lib$(STUBLIBNAME).a)
	-$(foreach i,$(COBJ) $(MLCMI) $(MLCMO) $(MLCMX) $(MLOBJ),$(call RM,$(i)) $(CMDSEP)) $(NOP)
ifeq ($(BUILDDIR),build)
	-$(call RMDIR,$(BUILDDIR))
endif

install: all
	-$(call MKDIR,$(DESTDIR))
	$(foreach i,$(MLCMI),$(call CP,$(i),$(DESTDIR)) $(CMDSEP)) $(NOP)
	$(call CP,$(BUILDDIR)/$(LIBNAME).cma,$(DESTDIR))
ifneq ($(STUBLIBNAME),)
	-$(call MKDIR,$(DESTDIR)/stublibs)
	$(call CP,$(BUILDDIR)/dll$(STUBLIBNAME)$(DLLSUFFIX),$(DESTDIR)/stublibs)
endif
ifneq ($(OCAMLOPT),)
	$(call CP,$(BUILDDIR)/$(LIBNAME).a,$(DESTDIR))
	$(call CP,$(BUILDDIR)/$(LIBNAME).cmxa,$(DESTDIR))
ifneq ($(STUBLIBNAME),)
	$(call CP,$(BUILDDIR)/lib$(STUBLIBNAME).a,$(DESTDIR))
endif
endif

uninstall:
	-$(foreach i,$(MLCMI),$(call RM,$(DESTDIR)/$(notdir $(i))) $(CMDSEP)) $(NOP)
	-$(call RM,$(DESTDIR)/$(LIBNAME).cma)
ifneq ($(STUBLIBNAME),)
	-$(call RM,$(DESTDIR)/stublibs/dll$(STUBLIBNAME)$(DLLSUFFIX))
endif
ifneq ($(OCAMLOPT),)
	-$(call RM,$(DESTDIR)/$(LIBNAME).a)
	-$(call RM,$(DESTDIR)/$(LIBNAME).cmxa)
ifneq ($(STUBLIBNAME),)
	-$(call RM,$(DESTDIR)/lib$(STUBLIBNAME).a)
endif
endif
