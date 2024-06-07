#######################################
# GNUmakefile for make (Macos, Linux) #
#######################################

# Keep this name!
# Under Macos and Linux, make will use in priority GNUmakefile.
# Under Windows, nmake will ignore GNUmakefile and use Makefile.

# ooRexxShell scripts in the current directory
testFiles = main_conversion \
            main_concatenation \
            diary_examples

# The demos can be used as non-regression tests
demos = ../../demos
demoFiles = executor-demo-text \
            executor-demo-text-internal_checks \
            executor-demo-text-unicode \
            executor-demo-text-compatibility \
            executor-demo-text-compatibility-auto-conv

# ooRexx scripts in the current directory
scriptsFiles = test_character_index

# Some Unicode scripts can be used as non-regression tests
uscripts = ../../unicode/scripts
uscriptsFiles = list_invalid_utf8 \
                test_convert \
                test_encoding_combinations \
                test_replacement_characters

help:
	@echo "make all"
	@echo "make html"
	@echo "---------- testFiles"
	@for f in $(testFiles); do echo "make" $$f; done
	@echo "---------- demoFiles"
	@for f in $(demoFiles); do echo "make" $$f; done
	@echo "---------- scriptsFiles"
	@for f in $(scriptsFiles); do echo "make" $$f; done
	@echo "---------- uscriptsFiles"
	@for f in $(uscriptsFiles); do echo "make" $$f; done
	@echo "---------- html"
	@for f in $(testFiles); do echo "make" $$f.output.html; done
	@echo "----------"
	@echo "make clean"

all:
	@for f in $(testFiles); do make $$f; done
	@for f in $(demoFiles); do make $$f; done
	@for f in $(scriptsFiles); do make $$f; done
	@for f in $(uscriptsFiles); do make $$f; done
	@echo
	@echo "To be launched separately: make html"

# Not in the 'all' target because I don't know how to redirect the output of asciinema to /dev/null
# Without such a redirection, it's difficult to see if some errors were raised during make all.
html:
	@for f in $(testFiles); do make $$f.output.html; done

$(testFiles) :
	bash -i -c '( cat $@.rex ; echo RC = 0 ) | oorexxshell test regression > $@.output.txt 2>&1'
	diff -q $@.output.reference.txt $@.output.txt

$(demoFiles) :
	@# Don't display the current address in the prompt
	bash -i -c '( echo prompt off address ; cat $(demos)/$@.rex ; echo RC = 0 ) | oorexxshell test regression > $@.output.txt 2>&1'
	diff -q $@.output.reference.txt $@.output.txt

$(scriptsFiles) :
	bash -i -c 'rexx $@.rex > $@.output.txt 2>&1'
	diff -q $@.output.reference.txt $@.output.txt

$(uscriptsFiles) :
	bash -i -c 'rexx $(uscripts)/$@.rex > $@.output.txt 2>&1'
	diff -q $@.output.reference.txt $@.output.txt

%.cast : %.rex
	-asciinema rec -c "bash -i -c 'echo prompt off address | cat $< | oorexxshell --showInitialization test regression'" --overwrite $@

.PHONY: always
%.output.html : %.cast always
	asciinema cat $< | aha --title "$@" > $@

clean:
	@for f in $(testFiles); do rm -f $$f.output.txt; done
	@for f in $(testFiles); do rm -f $$f.output.html; done
	@for f in $(demoFiles); do rm -f $$f.output.txt; done
	@for f in $(scriptsFiles); do rm -f $$f.output.txt; done
	@for f in $(uscriptsFiles); do rm -f $$f.output.txt; done
	@rm -f ill_formed_utf8.txt
	@rm -f ill_formed_utf16.txt


# bash -i -c 'command" is a trick to bypass the SIP hell:
# The variable DYLD_LIBRARY_PATH is unset because of System Integrity Protection.
# Without this variable, BSF4ooRexx is not loaded by ooRexxShell, because I don't
# put BSF4ooRExx in a trusted directory and because I don't want to hack the
# binaries with install_name_tool.
# By using an interactive bash, I have this sequence:
# - execution of ~/.bashrc which calls ~/.bash_env
# - execution of ~/.bash_env which calls : . "$REXX_ENVIRONMENT"
# where the file $REXX_ENVIRONMENT is created like that when initializing the environment:
#     echo "export LD_LIBRARY_PATH=`echo $LD_LIBRARY_PATH`" >> "$REXX_ENVIRONMENT"
#     echo "export DYLD_LIBRARY_PATH=`echo $DYLD_LIBRARY_PATH`" >> "$REXX_ENVIRONMENT"
# These 2 variables are made available to the rexx process, and BSF4ooRexx is loaded.
