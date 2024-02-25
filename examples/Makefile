BUILD:=$(shell $(CC) -dumpmachine)
HOST=$(BUILD)
TARGET=$(HOST)

PROGRAMPREFIX=$(addsuffix -,$(filter-out $(BUILD),$(TARGET)))

OCAMLC=$(PROGRAMPREFIX)ocamlc
OCAMLOPT=$(or $(filter-out $(OCAMLC),$(OCAMLC:c=opt)),$(PROGRAMPREFIX)ocamlopt)
RLWRAP?=

OCAMLCFLAGS=
OCAMLOPTFLAGS=$(OCAMLCFLAGS)

BUILDSUFFIX=.noindex
BUILDDIR=$(TARGET)$(BUILDSUFFIX)
TERMINAL_BUILDDIR=$(BUILDDIR)/terminal$(BUILDSUFFIX)

BINLN=$(and $(filter $(BUILD),$(TARGET)), \
        $(if $(findstring mingw,$(BUILD))$(findstring msys,$(BUILD)),,bin))

EXAMPLES1=$(basename $(wildcard *.ml))
EXAMPLES=$(EXAMPLES1) vs

.PHONY: all check interactive man clean # $(TESTS)

all: \
	$(and $(OCAMLC),$(patsubst %,$(BUILDDIR)/%.byte.exe,$(EXAMPLES))) \
	$(and $(OCAMLOPT),$(patsubst %,$(BUILDDIR)/%.opt.exe,$(EXAMPLES))) \
	$(BINLN)

$(BUILDDIR)/%.byte.exe: %.ml $(BUILDDIR)/terminal.cma
	$(OCAMLC) -c $(OCAMLCFLAGS) -o $(BUILDDIR)/$*.cmo -I $(BUILDDIR) $<
	$(OCAMLC) -o $@ -I $(BUILDDIR) unix.cma terminal.cma $(BUILDDIR)/$*.cmo

$(BUILDDIR)/%.opt.exe: %.ml $(BUILDDIR)/terminal.cmxa
	$(OCAMLOPT) -c $(OCAMLOPTFLAGS) -o $(BUILDDIR)/$*.cmx -I $(BUILDDIR) $<
	$(OCAMLOPT) -o $@ -I $(BUILDDIR) unix.cmxa terminal.cmxa $(BUILDDIR)/$*.cmx

$(BUILDDIR)/%.byte.exe: basicmagazine/%.ml $(BUILDDIR)/terminal.cma
	$(OCAMLC) -c $(OCAMLCFLAGS) -o $(BUILDDIR)/$*.cmo -I $(BUILDDIR) $<
	$(OCAMLC) -o $@ -I $(BUILDDIR) unix.cma terminal.cma $(BUILDDIR)/$*.cmo

$(BUILDDIR)/%.opt.exe: basicmagazine/%.ml $(BUILDDIR)/terminal.cmxa
	$(OCAMLOPT) -c $(OCAMLOPTFLAGS) -o $(BUILDDIR)/$*.cmx -I $(BUILDDIR) $<
	$(OCAMLOPT) -o $@ -I $(BUILDDIR) unix.cmxa terminal.cmxa $(BUILDDIR)/$*.cmx

check: all # $(TESTS)

interactive: $(BUILDDIR)/terminal.cma
	$(RLWRAP) ocaml $(OCAMLCFLAGS) -I $(BUILDDIR) unix.cma terminal.cma

$(and $(OCAMLC),$(BUILDDIR)/terminal.cma) \
$(and $(OCAMLOPT),$(BUILDDIR)/terminal.cmxa)&: \
		../source/terminal*
	$(MAKE) $(strip \
		-C ../source install \
		BUILDDIR=$(abspath $(TERMINAL_BUILDDIR)) \
		INSTALLDIR=$(abspath $(BUILDDIR)))

man: ../source/terminal.mli
	-mkdir $(TMPDIR)/man3
	ocamldoc -man -man-mini -d $(TMPDIR)/man3 $<
	MANPATH=$(TMPDIR) man Terminal

$(BINLN):
	ln -s $(BUILDDIR) $@

clean:
	-$(and $(BINLN),[ -h "$(BINLN)" ] && rm "$(BINLN)")
	-$(MAKE) $(strip \
		-C ../source clean uninstall \
		BUILDDIR=$(abspath $(TERMINAL_BUILDDIR)) \
		INSTALLDIR=$(abspath $(BUILDDIR)))
	-rm $(BUILDDIR)/*.exe $(BUILDDIR)/*.cm? $(BUILDDIR)/*.o
	-rmdir $(BUILDDIR)/stublibs
	-rmdir $(BUILDDIR)
