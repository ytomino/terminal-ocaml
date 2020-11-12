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
endif

OCAMLC=$(PROGRAMPREFIX)ocamlc
OCAMLOPT=$(OCAMLC:c=opt)
RLWRAP?=

BUILDSUFFIX=.noindex
BUILDDIR=$(TARGET)$(BUILDSUFFIX)
TERMINAL_BUILDDIR=$(BUILDDIR)/terminal$(BUILDSUFFIX)

EXAMPLES1=$(basename $(notdir $(wildcard *.ml)))
EXAMPLES=$(EXAMPLES1) vs

.PHONY: all check interactive man clean

all: \
	$(patsubst %,$(BUILDDIR)/%.byte.exe,$(EXAMPLES)) \
	$(if $(OCAMLOPT),$(patsubst %,$(BUILDDIR)/%.opt.exe,$(EXAMPLES))) \
	$(BINLN)

$(BUILDDIR)/%.byte.exe: %.ml $(BUILDDIR)/terminal.cma
	$(OCAMLC) -c -o $(BUILDDIR)/$*.cmo -I $(BUILDDIR) $(OCAMLCFLAGS) $<
	$(OCAMLC) -o $@ -I $(BUILDDIR) unix.cma terminal.cma $(BUILDDIR)/$*.cmo

ifneq ($(OCAMLOPT),)
$(BUILDDIR)/%.opt.exe: %.ml $(BUILDDIR)/terminal.cmxa
	$(OCAMLOPT) -c -o $(BUILDDIR)/$*.cmx -I $(BUILDDIR) $(OCAMLCFLAGS) $<
	$(OCAMLOPT) -o $@ -I $(BUILDDIR) unix.cmxa terminal.cmxa $(BUILDDIR)/$*.cmx
endif

$(BUILDDIR)/%.byte.exe: basicmagazine/%.ml $(BUILDDIR)/terminal.cma
	$(OCAMLC) -c -o $(BUILDDIR)/$*.cmo -I $(BUILDDIR) $(OCAMLCFLAGS) $<
	$(OCAMLC) -o $@ -I $(BUILDDIR) unix.cma terminal.cma $(BUILDDIR)/$*.cmo

ifneq ($(OCAMLOPT),)
$(BUILDDIR)/%.opt.exe: basicmagazine/%.ml $(BUILDDIR)/terminal.cmxa
	$(OCAMLOPT) -c -o $(BUILDDIR)/$*.cmx -I $(BUILDDIR) $(OCAMLCFLAGS) $<
	$(OCAMLOPT) -o $@ -I $(BUILDDIR) unix.cmxa terminal.cmxa $(BUILDDIR)/$*.cmx
endif

check: all $(TESTS)

interactive: $(BUILDDIR)/terminal.cma
	$(RLWRAP) ocaml -I $(BUILDDIR) $(OCAMLCFLAGS) unix.cma terminal.cma

$(BUILDDIR)/terminal.cma $(if $(OCAMLOPT),$(BUILDDIR)/terminal.cmxa): $(wildcard ../source/terminal*)
	$(MAKE) -C ../source install \
		BUILDDIR=$(abspath $(TERMINAL_BUILDDIR)) \
		INSTALLDIR=$(abspath $(BUILDDIR))

man: ../source/terminal.mli
	-mkdir $(TMPDIR)/man3
	ocamldoc -man -man-mini -d $(TMPDIR)/man3 $<
	MANPATH=$(TMPDIR) man Terminal

$(BINLN):
	ln -s $(BUILDDIR) $@

clean:
	-$(MAKE) -C ../source clean uninstall \
		BUILDDIR=$(abspath $(TERMINAL_BUILDDIR)) \
		INSTALLDIR=$(abspath $(BUILDDIR))
	-rm $(BUILDDIR)/*.exe $(BUILDDIR)/*.cm? $(BUILDDIR)/*.o
	-[ -h "$(BINLN)" ] && rm "$(BINLN)"
	-rmdir $(BUILDDIR)/stublibs
	-rmdir $(BUILDDIR)
