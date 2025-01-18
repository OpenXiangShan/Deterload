.NOTINTERMEDIATE:

PYSVGs=$(subst _dot.py,_py.svg,$(shell find docs/ -name "*_dot.py"))
EXTRACTMKDs=docs/references/default_extract.mkd \
						docs/references/builders_extract.mkd \
						docs/references/openblas_extract.mkd \
						docs/references/spec2006_extract.mkd
MDs=$(shell find . -name "*.md")
doc: ${MDs} docs/SUMMARY.md ${PYSVGs} ${EXTRACTMKDs}
	mdbook build

docs/SUMMARY.md: ./docs/generate_summary.py $(filter-out %SUMMARY.md,${MDs})
	$< $(dir $<) > $@

%_py.dot: %_dot.py docs/designs/4.builders/images/common.py
	python3 $<
%.svg: %.dot
	dot -Tsvg $< -o $@
	# css can only recognize intrinsic size in px
	# https://developer.mozilla.org/en-US/docs/Glossary/Intrinsic_Size
	sed -i 's/\([0-9]\+\)pt/\1px/g' $@

docs/references/default_extract.mkd: ./docs/extract_comments.py default.nix
	$^ $@
docs/references/builders_extract.mkd: ./docs/extract_comments.py builders/default.nix
	$^ $@
docs/references/openblas_extract.mkd: ./docs/extract_comments.py examples/openblas/default.nix
	$^ $@
docs/references/spec2006_extract.mkd: ./docs/extract_comments.py examples/spec2006/default.nix
	$^ $@
