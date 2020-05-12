HOST:=$(shell $(CC) -dumpmachine)
TARGET=$(HOST)

BUILDDIR=../$(TARGET).noindex

ITEMS=$(basename $(wildcard *.ml))

all: all-opt

all-opt: $(addprefix $(BUILDDIR)/,$(addsuffix .opt.exe,$(ITEMS)))

$(BUILDDIR)/%.opt.exe: %.ml
	make -C .. EXAMPLESPREFIX=basicmagazine/ $(patsubst ../%,%,$@)
