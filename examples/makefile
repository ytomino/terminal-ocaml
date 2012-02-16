BUILDDIR=build

ifneq ($(shell rlwrap --version),)
RLWRAP=rlwrap
endif

export CAML_LD_LIBRARY_PATH=$(BUILDDIR)/stublibs

.PHONY: all test-colors test-cursor test-info test-tinyless interactive clean

all: \
	$(BUILDDIR)/colors.byte.exe \
	$(BUILDDIR)/cursor.byte.exe \
	$(BUILDDIR)/info.byte.exe \
	$(BUILDDIR)/tinyless.byte.exe

test-colors: $(BUILDDIR)/colors.byte.exe
	$<

test-cursor: $(BUILDDIR)/cursor.byte.exe
	$<

test-info: $(BUILDDIR)/info.byte.exe
	$<

test-tinyless: $(BUILDDIR)/tinyless.byte.exe
	$< tinyless.ml

$(BUILDDIR)/%.byte.exe: %.ml $(BUILDDIR)/terminal.cma
	ocamlc -c -o $(BUILDDIR)/$(<:.ml=.cmo) -I $(BUILDDIR) $<
	ocamlc -o $@ -I $(BUILDDIR) unix.cma $(BUILDDIR)/terminal.cma $(BUILDDIR)/$(<:.ml=.cmo)

interactive: $(BUILDDIR)/terminal.cma
	$(RLWRAP) ocaml -I $(BUILDDIR) unix.cma terminal.cma

$(BUILDDIR)/terminal.cma: $(wildcard ../source/terminal*)
	make -C ../source -f makefile install DESTDIR=$(abspath $(BUILDDIR))

clean:
	make -C ../source clean
	-rm -rf $(BUILDDIR)
