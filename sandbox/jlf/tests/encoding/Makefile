################################
# Makefile for nmake (Windows) #
################################

# Keep this name!
# Under Macos and Linux, make will use in priority GNUmakefile.
# Under Windows, nmake will ignore GNUmakefile and use Makefile.

# ooRexxShell scripts in the current directory
testFiles = main_conversion \
            main_concatenation \
            diary_examples

# The demos can be used as non-regression tests
demos = ..\..\demos
demoFiles = executor-demo-text \
            executor-demo-text-internal_checks \
            executor-demo-text-unicode \
            executor-demo-text-compatibility

# ooRexx scripts in the current directory
scriptsFiles = test_character_index

# Some Unicode scripts can be used as non-regression tests
uscripts = ../../unicode/scripts
uscriptsFiles = list_invalid_utf8 \
                test_convert \
                test_encoding_combinations \
                test_replacement_characters

NMAKE = nmake /c /f Makefile

# https://gnuwin32.sourceforge.net/packages/diffutils.htm
DIFF = diff

# fc is native Windows but returns sometimes the code '0x1', whereas both files are identical (line ends differ)
# DIFF = fc /W

help:
	@echo nmake all
	@-for %%f in ($(testFiles)) do @echo nmake %%f
	@-for %%f in ($(demoFiles)) do @echo nmake %%f
	@-for %%f in ($(scriptsFiles)) do @echo nmake %%f
	@-for %%f in ($(uscriptsFiles)) do @echo nmake %%f
	@echo nmake clean

all:
	@-for %%f in ($(testFiles)) do @$(NMAKE) %%f
	@-for %%f in ($(demoFiles)) do @$(NMAKE) %%f
	@-for %%f in ($(scriptsFiles)) do @$(NMAKE) %%f
	@-for %%f in ($(uscriptsFiles)) do @$(NMAKE) %%f

$(testFiles) :
	type $@.rex | oorexxshell test regression > $@.output.txt 2>&1
	$(DIFF) $@.output.reference.txt $@.output.txt > nul

$(demoFiles) :
	@:: Don't display the current address in the prompt
	(echo prompt off address & type $(demos)\$@.rex) | oorexxshell test regression > $@.output.txt 2>&1
	$(DIFF) $@.output.reference.txt $@.output.txt > nul

$(scriptsFiles) :
	rexx $@.rex > $@.output.txt 2>&1
	$(DIFF) $@.output.reference.txt $@.output.txt > nul

$(uscriptsFiles) :
	rexx $(uscripts)\$@.rex > $@.output.txt 2>&1
	$(DIFF) $@.output.reference.txt $@.output.txt > nul

clean:
	@-for %%f in ($(testFiles)) do @del -f %%f.output.txt
	@-for %%f in ($(demoFiles)) do @del -f %%f.output.txt
	@-for %%f in ($(scriptsFiles)) do @del -f %%f.output.txt
	@-for %%f in ($(uscriptsFiles)) do @del -f %%f.output.txt
	@del -f ill_formed_utf8.txt
	@del -f ill_formed_utf16.txt
