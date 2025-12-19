#######################################
# GNUmakefile for make (Macos, Linux) #
#######################################

# Keep this name!
# Under Macos and Linux, make will use in priority GNUmakefile.
# Under Windows, nmake will ignore GNUmakefile and use Makefile.

md2md = ../md2md.rex

mainFiles = md2md-test_without_error \
            md2md-test_with_errors

help:
	@echo "make all"
	@for f in $(mainFiles); do (echo "make" $$f); done
	@echo "make clean"

all:
	@for f in $(mainFiles); do (make $$f); done

md2md-test_without_error :
	rexx $(md2md) $@.md > $@-output.md 2>&1
	diff -q $@-reference.md $@-output.md

md2md-test_with_errors :
	-rexx $(md2md) $@.md > $@-output.md 2>&1
	diff -q $@-reference.md $@-output.md
	-rexx $(md2md) -v $@.md > $@-output-v.md 2>&1
	diff -q $@-reference-v.md $@-output-v.md
	-rexx $(md2md) -v -fu $@.md > $@-output-v-fu.md 2>&1
	diff -q $@-reference-v-fu.md $@-output-v-fu.md
	-rexx $(md2md) -fu $@.md > $@-output-fu.md 2>&1
	diff -q $@-reference-fu.md $@-output-fu.md

clean:
	rm -f md2md-test_without_error-output.md
	rm -f md2md-test_with_errors-output.md
	rm -f md2md-test_with_errors-output-v.md
	rm -f md2md-test_with_errors-output-v-fu.md
	rm -f md2md-test_with_errors-output-fu.md
