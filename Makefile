
# Override this for a different location
INPUT_FILE?=document.md
INPUT_DIR=$(dir $(abspath ${INPUT_FILE} ))

# the template sources is with the makefile
SOURCE=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))

TEMPLATEDIR=${SOURCE}/templates
METADATA=${TEMPLATEDIR}/metadata.yaml

# Output folders
HTMLOUT:=$(abspath ./out/html)
PDFOUT:=$(abspath ./out/pdf)

DOT_SOURCES:=$(shell find ${INPUT_DIR} -name '*.dot')
DOT_SOURCES:=$(foreach fname, ${DOT_SOURCES}, $(shell realpath --relative-to ${INPUT_DIR} ${fname}))
MD_SOURCES:=$(shell find $(INPUT_DIR) -name '*.md')
TEMPLATE_SOURCES:=$(shell find $(TEMPLATEDIR) )

# All targets depend on Makfiles, metadta, sources, templates
.EXTRA_PREREQS:=$(abspath $(lastword $(MAKEFILE_LIST))) ${METADATA} ${MD_SOURCES} ${TEMPLATE_SOURCES}

export TEXINPUTS:=.:${SOURCE}:${TEMPLATEDIR}:${TEXINPUTS}:

all: html pdf

# Intetermediate TARGETS

troubleshoot:
	@echo "PREREQS=${.EXTRA_PREREQS}"
	@echo "TEXINPUTS=${TEXINPUTS}"

HTML_DOT+=$(addprefix $(HTMLOUT)/,$(DOT_SOURCES:%.dot=%.svg))
${HTMLOUT}/%.svg : ${INPUT_DIR}/%.dot
	-mkdir -p $(dir $@)
	dot -Tsvg -o $@ $<
PDF_DOT+=$(addprefix $(PDFOUT)/,$(DOT_SOURCES:%.dot=%.pdf))
${PDFOUT}/%.pdf : ${INPUT_DIR}/%.dot
	-mkdir -p $(dir $@)
	dot -Tpdf -o $@ $<

# TARGETS
PANDOC_ARGS=--csl=${TEMPLATEDIR}/ieee.csl --filter pandoc-xnos --metadata-file=${METADATA} --citeproc -f markdown+smart

ifndef DRAFT
	PANDOC_ARGS+= --fail-if-warning
endif

PANDOC_PDFARGS=--template=${TEMPLATEDIR}/template.tex --resource-path=${PDFOUT} --default-image-extension=pdf --pdf-engine=lualatex --listings 
${PDFOUT}/document.pdf: ${PDF_DOT}
	pandoc ${PANDOC_ARGS} ${PANDOC_PDFARGS} -t latex -o $@ ${INPUT_FILE}
pdf: ${PDFOUT}/document.pdf
${PDFOUT}/document.tex: ${PDF_DOT}
	pandoc ${PANDOC_ARGS} ${PANDOC_PDFARGS} -t latex -o $@ ${INPUT_FILE}
tex: ${PDFOUT}/document.tex


export GLADTEX_OUTPUT:=${HTMLOUT}
PANDOC_HTMLARGS = --self-contained --filter=${TEMPLATEDIR}/pandoc-gladtex --number-sections --template=${TEMPLATEDIR}/template.html --resource-path=${HTMLOUT} --default-image-extension=svg --standalone --css=${TEMPLATEDIR}/html.css 

${HTMLOUT}/document.html: ${HTML_DOT}
	# Convert document to pandoc json AST, filter formulas via gladtex and then
	# through pandoc to get html
	pandoc ${PANDOC_ARGS} ${PANDOC_HTMLARGS} -t html -o $@ ${INPUT_FILE}
html: ${HTMLOUT}/document.html

${HTMLOUT}/document.epub: ${HTMLOUT}/document.html
	ebook-convert $< $@ --page-breaks-before="/" --level1-toc="h1"
epub: ${HTMLOUT}/document.epub


watchhtml:
	# The call to -f is a bit of an hack to allow for out of source builds
	while true; do \
		$(MAKE) -f $(lastword $(MAKEFILE_LIST)) DRAFT=1 INPUT_FILE=${INPUT_FILE} html ; \
		inotifywait -qre close_write ${INPUT_DIR} ${MAKEFILE_LIST} ; sleep 1 ; \
	done

watchpdf:
	# The call to -f is a bit of an hack to allow for out of source builds
	while true; do \
		$(MAKE) -f $(lastword $(MAKEFILE_LIST)) DRAFT=1 INPUT_FILE=${INPUT_FILE} pdf ; \
		inotifywait -qre close_write ${INPUT_DIR} ${MAKEFILE_LIST} ; sleep 1 ; \
	done

.PHONY: html pdf epub watchpdf watchhtml
