SHELL        = /bin/sh
SGR_OFF     := $(shell printf \\x1B[0m)
SGR_UL      := $(shell printf \\x1B[4m)

stylesheet  := index.css
preview-doc := preview.html
submodule   := source/.git
ttf-fonts   := $(shell find source -type f -name '*.ttf')
woff2-fonts := $(addprefix fonts/,$(patsubst %.ttf,%.woff2,$(notdir $(ttf-fonts))))

all: $(woff2-fonts) $(stylesheet)

# Convert a TrueType file to WOFF2 format
fonts/%.woff2: source/%.ttf
	@[ -d fonts ] || mkdir fonts;
	@(woff2_compress $^) >/dev/null 2>&1;
	@mv source/$*.woff2 $@
	@echo "Compressed -> $(SGR_UL)$@$(SGR_OFF)"

# Regenerate @font-face rules
$(stylesheet): $(woff2-fonts)
	@./update.pl --css-file=$@ --html-file=$(preview-doc) $(ttf-fonts)
	@echo "Generated HTML preview: $(SGR_UL)$(preview-doc)$(SGR_OFF)"

# Checkout missing submodules
install: $(submodule)
$(submodule):
	@status="Fetching TrueType sources from %s%s%s\\n"; \
	git config --list --file .gitmodules |\
		grep -E ^submodule\.source\.url= |\
		cut -d'=' -f2 | xargs -J % printf "$$status" $(SGR_UL) % $(SGR_OFF);
	@git submodule update --init
	@echo "Checkout complete. Run \`make all\` to generate target files."

# Torch all generated or junk files
clean:
	@rm -rf fonts index.css
	@(cd source; git checkout -- . && git clean -fd)
.PHONY: clean

# Pull any updates from URW++/GhostScript sources, regenerating files if needed
update: update-submodules clean $(woff2-fonts) $(stylesheet)
update-submodules:
	@git submodule foreach git pull origin master
.PHONY: update update-submodules
