################################
# Makefile for nmake (Windows) #
################################

# Keep this name!
# Under Macos and Linux, make will use in priority GNUmakefile.
# Under Windows, nmake will ignore GNUmakefile and use Makefile.

# ooRexx scripts in the current directory
scriptsFiles = doers-info \
               doers-samples \
               functional-test \
               named_arguments-test \
               named_arguments-test_with_extensions \
               package-test \
               test_extension_order

# The demos can be used as non-regression tests
demos = ..\..\demos
demoFiles = executor-demo-extensions

NMAKE = nmake /c /f Makefile

# https://gnuwin32.sourceforge.net/packages/diffutils.htm
DIFF = diff

# fc is native Windows but returns sometimes the code '0x1', whereas both files are identical (line ends differ)
# DIFF = fc /W

help:
	@echo nmake all
	@-for %%f in ($(scriptsFiles)) do @echo nmake %%f
	@-for %%f in ($(demoFiles)) do @echo nmake %%f
	@echo nmake clean

all:
	@-for %%f in ($(scriptsFiles)) do @$(NMAKE) %%f
	@-for %%f in ($(demoFiles)) do @$(NMAKE) %%f

$(scriptsFiles) :
	rexx $@.rex > $@.output.txt 2>&1
	$(DIFF) $@.output.reference.txt $@.output.txt > nul

$(demoFiles) :
	@:: Don't display the current address in the prompt
	( echo prompt off address & type $(demos)\$@.rex & echo RC = 0) | oorexxshell test regression > $@.output.txt 2>&1
	$(DIFF) $@.output.reference.txt $@.output.txt > nul

clean:
	@-for %%f in ($(scriptsFiles)) do @del -f %%f.output.txt
	@-for %%f in ($(demoFiles)) do @del -f %%f.output.txt
