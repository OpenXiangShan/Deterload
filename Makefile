.NOTINTERMEDIATE:

PYSVGs=$(subst _dot.py,_py.svg,$(shell find docs/ -name "*_dot.py"))
EXTRACTMDs=docs/reference/default_extract.md
doc: $(shell find . -name "*.md") ${PYSVGs} ${EXTRACTMDs}
	mdbook build

%_py.dot: %_dot.py docs/designs/builders/images/common.py
	python3 $<
%.svg: %.dot
	dot -Tsvg $< -o $@
	# css can only recognize intrinsic size in px
	# https://developer.mozilla.org/en-US/docs/Glossary/Intrinsic_Size
	sed -i 's/\([0-9]\+\)pt/\1px/g' $@

docs/reference/default_extract.md: ./docs/extract_comments.py default.nix
	$^ $@
