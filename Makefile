SHELL = /bin/sh

stylesheet  := index.css
preview-doc := preview.html
submodules  := $(addsuffix /.git,source)
ttf-fonts   := $(shell find source -type f -name '*.ttf')
woff2-fonts := $(addprefix fonts/,$(patsubst %.ttf,%.woff2,$(notdir $(ttf-fonts))))

all: $(submodules) $(woff2-fonts) $(stylesheet)

# Convert a TrueType file to WOFF2 format
fonts/%.woff2: source/%.ttf
	@echo "Compressing -> $@";
	@[ -d fonts ] || mkdir fonts;
	@(woff2_compress $^) >/dev/null 2>&1;
	@mv source/$*.woff2 $@

# Regenerate @font-face rules
$(stylesheet): $(woff2-fonts)
	@./update.pl --css-file=$@ --html-file=$(preview-doc) $(ttf-fonts)

# Checkout registered submodules
$(submodules):
	@git submodule update --init

# Torch all generated or junk files
clean:
	@rm -rf fonts index.css
	@(cd source; git checkout -- . && git clean -fd)
.PHONY: clean
