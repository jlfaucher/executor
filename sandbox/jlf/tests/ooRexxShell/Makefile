################################
# Makefile for nmake (Windows) #
################################

# Keep this name!
# Under Macos and Linux, make will use in priority GNUmakefile.
# Under Windows, nmake will ignore GNUmakefile and use Makefile.

testFiles = classQueries \
            classQueriesShort \
            methodQueries \
            methodQueriesShort \
            packageQueries \
            packageQueriesShort \
            routineQueries \
            routineQueriesShort

NMAKE = nmake /c /f Makefile

# https://gnuwin32.sourceforge.net/packages/diffutils.htm
DIFF = diff

# fc is native Windows but returns sometimes the code '0x1', whereas both files are identical (line ends differ)
# DIFF = fc /W

help:
	@echo.
	@echo If using ooRexx ^>= 5.0, pass OOREXX_VERSION=5 to compare the output
	@echo with reference files specific to this version.
	@echo nmake target OOREXX_VERSION=5
	@echo Current value of OOREXX_VERSION is '$(OOREXX_VERSION)'
	@echo.
	@echo nmake all [OOREXX_VERSION=5]
	@-for %%f in ($(testFiles)) do @echo nmake %%f [OOREXX_VERSION=5]
	@echo nmake clean

all:
	@-for %%f in ($(testFiles)) do @$(NMAKE) %%f

$(testFiles) :
	( type $@.rex & echo RC = 0 ) | oorexxshell test regression > $@.output$(OOREXX_VERSION).backslash.txt 2>&1
	$(DIFF) $@.output$(OOREXX_VERSION).backslash.reference.txt $@.output$(OOREXX_VERSION).backslash.txt > nul

clean:
	@-for %%f in ($(testFiles)) do @del /f %%f.output.backslash.txt
	@-for %%f in ($(testFiles)) do @del /f %%f.output.slash.txt
	@-for %%f in ($(testFiles)) do @del /f %%f.output5.backslash.txt
	@-for %%f in ($(testFiles)) do @del /f %%f.output5.slash.txt
