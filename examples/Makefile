BUILD:=$(shell $(CC) -dumpmachine)
HOST=$(BUILD)
TARGET=$(HOST)

PROGRAMPREFIX=$(addsuffix -,$(filter-out $(BUILD),$(TARGET)))

OCAMLC=$(PROGRAMPREFIX)ocamlc
OCAMLOPT=$(or $(filter-out $(OCAMLC),$(OCAMLC:c=opt)),$(PROGRAMPREFIX)ocamlopt)
RLWRAP?=

ifndef OCAML_VERSION_MAJOR
 OCAML_VERSION_MAJOR:=$(basename \
                        $(basename \
                          $(shell $(or $(OCAMLC),$(OCAMLOPT)) -version)))
endif

DEBUG=
ASSERT=1

OCAMLCFLAGS=$(and $(filter-out 0,$(DEBUG)),-g)
OCAMLOPTFLAGS=$(OCAMLCFLAGS)
OCAMLCFLAGS_EXE=$(and $(filter-out 0,$(DEBUG)),-g)
OCAMLOPTFLAGS_EXE=$(OCAMLCFLAGS_EXE) $(addprefix -ccopt ,$(LDFLAGS))
OCAML_INCLUDE_FLAGS=$(and $(filter 5,$(OCAML_VERSION_MAJOR)),-I +unix)
LDFLAGS?=

BUILDSUFFIX=.noindex
BUILDDIR=$(TARGET)$(BUILDSUFFIX)
TERMINAL_BUILDDIR=$(BUILDDIR)/terminal$(BUILDSUFFIX)

BINLN=$(and $(filter $(BUILD),$(TARGET)), \
        $(if $(findstring mingw,$(BUILD))$(findstring msys,$(BUILD)),,bin))

EXAMPLES1=$(basename $(wildcard *.ml))
EXAMPLES=$(EXAMPLES1) vs

.PHONY: all check interactive man clean # $(TESTS)

all \
: $(and $(OCAMLC),$(patsubst %,$(BUILDDIR)/%.byte.exe,$(EXAMPLES))) \
  $(and $(OCAMLOPT),$(patsubst %,$(BUILDDIR)/%.opt.exe,$(EXAMPLES))) $(BINLN)

$(BUILDDIR)/%.byte.exe: %.ml $(BUILDDIR)/terminal.cma
	$(OCAMLC) $(strip \
		-c $(OCAMLCFLAGS) \
		-o $(BUILDDIR)/$*.cmo $(OCAML_INCLUDE_FLAGS) -I $(BUILDDIR) $<)
	$(OCAMLC) $(strip \
		$(OCAMLCFLAGS_EXE) \
		-o $@ $(OCAML_INCLUDE_FLAGS) unix.cma -I $(BUILDDIR) terminal.cma \
		$(BUILDDIR)/$*.cmo)

$(BUILDDIR)/%.opt.exe: %.ml $(BUILDDIR)/terminal.cmxa
	$(OCAMLOPT) $(strip \
		-c $(OCAMLOPTFLAGS) \
		-o $(BUILDDIR)/$*.cmx $(OCAML_INCLUDE_FLAGS) -I $(BUILDDIR) $<)
	$(OCAMLOPT) $(strip \
		$(OCAMLOPTFLAGS_EXE) \
		-o $@ $(OCAML_INCLUDE_FLAGS) unix.cmxa -I $(BUILDDIR) terminal.cmxa \
		$(BUILDDIR)/$*.cmx)

$(BUILDDIR)/%.byte.exe: basicmagazine/%.ml $(BUILDDIR)/terminal.cma
	$(OCAMLC) $(strip \
		-c $(OCAMLCFLAGS) \
		-o $(BUILDDIR)/$*.cmo $(OCAML_INCLUDE_FLAGS) -I $(BUILDDIR) $<)
	$(OCAMLC) $(strip \
		$(OCAMLCFLAGS_EXE) \
		-o $@ $(OCAML_INCLUDE_FLAGS) unix.cma -I $(BUILDDIR) terminal.cma \
		$(BUILDDIR)/$*.cmo)

$(BUILDDIR)/%.opt.exe: basicmagazine/%.ml $(BUILDDIR)/terminal.cmxa
	$(OCAMLOPT) $(strip \
		-c $(OCAMLOPTFLAGS) \
		-o $(BUILDDIR)/$*.cmx $(OCAML_INCLUDE_FLAGS) -I $(BUILDDIR) $<)
	$(OCAMLOPT) $(strip \
		$(OCAMLOPTFLAGS_EXE) \
		-o $@ $(OCAML_INCLUDE_FLAGS) unix.cmxa -I $(BUILDDIR) terminal.cmxa \
		$(BUILDDIR)/$*.cmx)

check: all # $(TESTS)

interactive: $(BUILDDIR)/terminal.cma
	$(RLWRAP) ocaml $(strip \
		$(OCAML_INCLUDE_FLAGS) unix.cma -I $(BUILDDIR) terminal.cma)

$(and $(OCAMLC),$(BUILDDIR)/terminal.cma) \
$(and $(OCAMLOPT),$(BUILDDIR)/terminal.cmxa) \
&: ../source/terminal*
	$(MAKE) $(strip \
		-C ../source install \
		BUILDDIR=$(abspath $(TERMINAL_BUILDDIR)) \
		INSTALLDIR=$(abspath $(BUILDDIR)) \
		ASSERT=$(ASSERT))

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
