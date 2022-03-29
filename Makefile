# Path to paper file
ARTICLE = paper.rst

# Path to resources like logos, csl style file, etc.
RESOURCE_PATH = resources
# Data path, containing configs, filters.
DATA_PATH = data
# The pandoc executable
PANDOC = pandoc
# Folder in which the outputs will be placed
TARGET_FOLDER = publishing-artifacts

FORMATS = jats latex native pdf

.PHONY: all
all: $(FORMATS)

.PHONY: $(FORMATS)
jats:	$(TARGET_FOLDER)/paper.jats
latex: $(TARGET_FOLDER)/paper.latex
native: $(TARGET_FOLDER)/paper.native
pdf: $(TARGET_FOLDER)/paper.pdf

$(TARGET_FOLDER)/paper.%: $(ARTICLE) \
		$(DATA_PATH)/scipy-conf-rst.lua \
		$(DATA_PATH)/defaults/%.yaml \
		$(TARGET_FOLDER)
	INARA_ARTIFACTS_PATH=$(TARGET_FOLDER)/ $(PANDOC) \
	  --data-dir=$(DATA_PATH) \
	  --defaults=shared \
	  --defaults=$*.yaml \
	  --resource-path=.:$(RESOURCE_PATH):$(dir $(ARTICLE)) \
	  --output=$@ \
	  $<

$(TARGET_FOLDER):
	mkdir -p $(TARGET_FOLDER)

.PHONY: clean
clean:
	rm -rf $(foreach f,$(FORMATS),$(TARGET_FOLDER)/paper.$(f))
