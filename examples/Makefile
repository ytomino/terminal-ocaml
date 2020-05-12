# cross compiling ex. make TARGET=i686-w64-mingw32 all-opt
HOST:=$(shell $(CC) -dumpmachine)
TARGET=$(HOST)

ifneq ($(HOST),$(TARGET))
PROGRAMPREFIX=$(TARGET)-
BINLN=
else
PROGRAMPREFIX=
ifneq ($(findstring mingw,$(HOST))$(findstring msys,$(HOST)),)
BINLN=
else
BINLN=bin
endif
ifneq ($(shell rlwrap --version),)
RLWRAP=rlwrap
endif
endif

OCAMLC=$(PROGRAMPREFIX)ocamlc
OCAMLOPT=$(PROGRAMPREFIX)ocamlopt

BUILDSUFFIX=.noindex
BUILDDIR=$(TARGET)$(BUILDSUFFIX)
TERMINAL_BUILDDIR=$(BUILDDIR)/terminal$(BUILDSUFFIX)

ITEMS=$(basename $(notdir $(wildcard $(EXAMPLESPREFIX)*.ml)))

.PHONY: all all-byte all-opt check interactive man clean

ifneq ($(HOST),$(TARGET))
all: all-opt $(BINLN)
else
all: all-byte all-opt $(BINLN)
endif

all-byte: $(addprefix $(BUILDDIR)/,$(addsuffix .byte.exe,$(ITEMS)))
all-opt: $(addprefix $(BUILDDIR)/,$(addsuffix .opt.exe,$(ITEMS)))

$(BUILDDIR)/%.byte.exe: $(EXAMPLESPREFIX)%.ml $(BUILDDIR)/terminal.cma
	$(OCAMLC) -c -o $(BUILDDIR)/$*.cmo -I $(BUILDDIR) $(OCAMLCFLAGS) $<
	$(OCAMLC) -o $@ -I $(BUILDDIR) unix.cma $(BUILDDIR)/terminal.cma $(BUILDDIR)/$*.cmo

$(BUILDDIR)/%.opt.exe: $(EXAMPLESPREFIX)%.ml $(BUILDDIR)/terminal.cmxa
	$(OCAMLOPT) -c -o $(BUILDDIR)/$*.cmx -I $(BUILDDIR) $(OCAMLCFLAGS) $<
	$(OCAMLOPT) -o $@ -I $(BUILDDIR) unix.cmxa $(BUILDDIR)/terminal.cmxa $(BUILDDIR)/$*.cmx

check: all $(TESTS)

interactive: $(BUILDDIR)/terminal.cma
	$(RLWRAP) ocaml -I $(BUILDDIR) unix.cma terminal.cma

$(BUILDDIR) $(BUILDDIR)/terminal.cma $(BUILDDIR)/terminal.cmxa: $(wildcard ../source/terminal*)
	$(MAKE) -C ../source install \
		BUILDDIR=$(abspath $(TERMINAL_BUILDDIR)) \
		INSTALLDIR=$(abspath $(BUILDDIR))

man: ../source/terminal.mli
	-mkdir $(TMPDIR)/man3
	ocamldoc -man -man-mini -d $(TMPDIR)/man3 $<
	MANPATH=$(TMPDIR) man Terminal

$(BINLN): | $(BUILDDIR)
	ln -s $(BUILDDIR) $@

clean:
	-$(MAKE) -C ../source clean uninstall \
		BUILDDIR=$(abspath $(TERMINAL_BUILDDIR)) \
		INSTALLDIR=$(abspath $(BUILDDIR))
	-rm $(BUILDDIR)/*.exe $(BUILDDIR)/*.cm? $(BUILDDIR)/*.o
	-[ -h "$(BINLN)" ] && rm "$(BINLN)"
	-rmdir $(BUILDDIR)/stublibs
	-rmdir $(BUILDDIR)
