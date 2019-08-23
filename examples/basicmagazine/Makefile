HOST:=$(shell $(CC) -dumpmachine)
TARGET=$(HOST)

BUILDDIR=../$(TARGET).build

OCAMLOPT=$(PROGRAMPREFIX)ocamlopt

ITEMS=$(basename $(wildcard *.ml))

all: all-opt

all-opt: $(addprefix $(BUILDDIR)/,$(addsuffix .opt.exe,$(ITEMS)))

$(BUILDDIR)/%.opt.exe: %.ml $(BUILDDIR)/terminal.cmxa
	$(OCAMLOPT) -c -o $(BUILDDIR)/$(<:.ml=.cmx) -I $(BUILDDIR) $(OCAMLCFLAGS) $<
	$(OCAMLOPT) -o $@ -I $(BUILDDIR) unix.cmxa $(BUILDDIR)/terminal.cmxa $(BUILDDIR)/$(<:.ml=.cmx)

$(BUILDDIR)/terminal.cmxa:
	make -C .. $(patsubst ../%,%,$@)
