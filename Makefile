.PHONY: all build run wave clean help

PROJECTS := accumulator, efm, counter

all: clean run

build:
	@for p in $(PROJECTS); do \
		$(MAKE) -C $$p build; \
	done

run:
	@for p in $(PROJECTS); do \
		$(MAKE) -C $$p run; \
	done

wave:
	@for p in $(PROJECTS); do \
		$(MAKE) -C $$p wave; \
	done

clean:
	@for p in $(PROJECTS); do \
		$(MAKE) -C $$p clean; \
	done

help:
	@echo "Available targets:"
	@echo "  make build   - build all projects"
	@echo "  make run     - run all projects"
	@echo "  make wave    - open waveforms for all projects"
	@echo "  make clean   - clean all projects"
	@echo "  make help    - show this help"
	@echo ""
	@echo "Each project has its own Makefile inside its directory."
