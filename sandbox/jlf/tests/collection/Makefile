################################
# Makefile for nmake (Windows) #
################################

# Keep this name!
# Under Macos and Linux, make will use in priority GNUmakefile.
# Under Windows, nmake will ignore GNUmakefile and use Makefile.

mainFiles = main_array

# The demos can be used as non-regression tests
demos = ..\..\demos
demoFiles = executor-demo-array

NMAKE = nmake /c /f Makefile

# https://gnuwin32.sourceforge.net/packages/diffutils.htm
DIFF = diff

# fc is native Windows but returns sometimes the code '0x1', whereas both files are identical (line ends differ)
# DIFF = fc /W

help:
	@echo make all
	@-for %%f in ($(mainFiles)) do @echo nmake %%f
	@-for %%f in ($(demoFiles)) do @echo nmake %%f
	@echo make clean

all:
	@-for %%f in ($(mainFiles)) do @$(NMAKE) %%f
	@-for %%f in ($(demoFiles)) do @$(NMAKE) %%f

$(mainFiles) :
	( type $@.rex & echo RC = 0 ) | oorexxshell test regression > $@.output.txt 2>&1
	$(DIFF) $@.output.reference.txt $@.output.txt > nul

$(demoFiles) :
	@:: Don't display the current address in the prompt
	( echo prompt off address & type $(demos)\$@.rex & echo RC = 0 ) | oorexxshell test regression > $@.output.txt 2>&1
	$(DIFF) $@.output.reference.txt $@.output.txt > nul

clean:
	@-for %%f in ($(mainFiles)) do @del -f %%f.output.txt
	@-for %%f in ($(demoFiles)) do @del -f %%f.output.txt
