################################
# Makefile for nmake (Windows) #
################################

# Keep this name!
# Under Macos and Linux, make will use in priority GNUmakefile.
# Under Windows, nmake will ignore GNUmakefile and use Makefile.

# ooRexx scripts in the current directory
scriptsFiles = class method

mainFiles = main_array_literal

NMAKE = nmake /c /f Makefile

# https://gnuwin32.sourceforge.net/packages/diffutils.htm
DIFF = diff

# fc is native Windows but returns sometimes the code '0x1', whereas both files are identical (line ends differ)
# DIFF = fc /W

help:
	@echo make all
	@-for %%f in ($(scriptsFiles)) do @echo nmake %%f
	@-for %%f in ($(mainFiles)) do @echo nmake %%f
	@echo make clean

all:
	@-for %%f in ($(scriptsFiles)) do @$(NMAKE) %%f
	@-for %%f in ($(mainFiles)) do @$(NMAKE) %%f

$(scriptsFiles) :
	rexx $@.rex > $@.output.txt 2>&1
	$(DIFF) $@.output.reference.txt $@.output.txt > nul

$(mainFiles) :
	type $@.rex | oorexxshell test regression > $@.output.txt 2>&1
	$(DIFF) $@.output.reference.txt $@.output.txt > nul

clean:
	@-for %%f in ($(scriptsFiles)) do @del -f %%f.output.txt
	@-for %%f in ($(mainFiles)) do @del -f %%f.output.txt
