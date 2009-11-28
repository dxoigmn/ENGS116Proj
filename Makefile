ROOTDIR := /Developer/GPU\ Computing/C/common
BINDIR := .

PROJECTS := $(shell find src -name Makefile)

%.ph_build:
	make -C $(dir $*)

%.ph_clean:
	make -C $(dir $*) clean

all: $(addsuffix .ph_build,$(PROJECTS))
	@echo "Finished building all"

clean: $(addsuffix .ph_clean,$(PROJECTS))
	@echo "Finished cleaning all"

