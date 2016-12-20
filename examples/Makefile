# cross compiling ex. make TARGET=i686-w64-mingw32 all-opt
HOST=$(shell gcc -dumpmachine)
TARGET=$(HOST)

ifneq ($(HOST),$(TARGET))
PROGRAMPREFIX=$(TARGET)-
BINLN=
else
PROGRAMPREFIX=
BINLN=bin
ifneq ($(shell rlwrap --version),)
RLWRAP=rlwrap
endif
endif

OCAMLC=$(PROGRAMPREFIX)ocamlc
OCAMLOPT=$(PROGRAMPREFIX)ocamlopt

ifneq ($(ComSpec),)
LINK=linkd $2 $1
UNLINK=linkd $1 /d
else
LINK=ln -s $1 $2
UNLINK=rm $1
endif

BUILDDIR=$(TARGET).build

export CAML_LD_LIBRARY_PATH=$(BUILDDIR)/stublibs

ITEMS=$(basename $(wildcard *.ml))

.PHONY: all all-byte all-opt interactive man clean $(addprefix test-,$(ITEMS))

ifneq ($(HOST),$(TARGET))
all: all-opt $(BINLN)
else
all: all-byte all-opt $(BINLN)
endif

all-byte: $(addprefix $(BUILDDIR)/,$(addsuffix .byte.exe,$(ITEMS)))
all-opt: $(addprefix $(BUILDDIR)/,$(addsuffix .opt.exe,$(ITEMS)))

test-colors: $(BUILDDIR)/colors.byte.exe
	$<

test-cursor: $(BUILDDIR)/cursor.byte.exe
	$<

test-event: $(BUILDDIR)/event.byte.exe
	$<

test-info: $(BUILDDIR)/info.byte.exe
	$<

test-tinyless: $(BUILDDIR)/tinyless.byte.exe
	$< tinyless.ml

test-utf8io: $(BUILDDIR)/utf8io.byte.exe
	$<

$(BUILDDIR)/%.byte.exe: %.ml $(BUILDDIR)/terminal.cma
	$(OCAMLC) -c -o $(BUILDDIR)/$(<:.ml=.cmo) -I $(BUILDDIR) $(OCAMLCFLAGS) $<
	$(OCAMLC) -o $@ -I $(BUILDDIR) unix.cma $(BUILDDIR)/terminal.cma $(BUILDDIR)/$(<:.ml=.cmo)

$(BUILDDIR)/%.opt.exe: %.ml $(BUILDDIR)/terminal.cmxa
	$(OCAMLOPT) -c -o $(BUILDDIR)/$(<:.ml=.cmx) -I $(BUILDDIR) $(OCAMLCFLAGS) $<
	$(OCAMLOPT) -o $@ -I $(BUILDDIR) unix.cmxa $(BUILDDIR)/terminal.cmxa $(BUILDDIR)/$(<:.ml=.cmx)

interactive: $(BUILDDIR)/terminal.cma
	$(RLWRAP) ocaml -I $(BUILDDIR) unix.cma terminal.cma

$(BUILDDIR) $(BUILDDIR)/terminal.cma $(BUILDDIR)/terminal.cmxa: $(wildcard ../source/terminal*)
	make -C ../source install DESTDIR=$(abspath $(BUILDDIR))

man: ../source/terminal.mli
	-mkdir $(TMPDIR)/man3
	ocamldoc -man -man-mini -d $(TMPDIR)/man3 $<
	MANPATH=$(TMPDIR) man Terminal

$(BINLN): | $(BUILDDIR)
	-$(call LINK,$(BUILDDIR),$(BINLN))

clean:
	make -C ../source clean
	-$(call UNLINK,$(BINLN))
	-rm -rf $(BUILDDIR)
