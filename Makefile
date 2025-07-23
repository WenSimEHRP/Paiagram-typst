EXAMPLES_SRC := $(wildcard examples/*.typ)
EXAMPLES_BIN := $(EXAMPLES_SRC:.typ=.pdf)

.PHONY: build_examples clean_examples

build_examples: $(EXAMPLES_BIN)

clean_examples:
	rm -f $(EXAMPLES_BIN)

%.pdf: %.typ $(wildcard src/**/*)
	typst compile $<
