#######################################
# GNUmakefile for make (Macos, Linux) #
#######################################

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

help:
	@echo
	@echo "If using ooRexx >= 5.0, pass OOREXX_VERSION=5 to compare the output"
	@echo "with reference files specific to this version."
	@echo "nmake target OOREXX_VERSION=5"
	@echo "Current value of OOREXX_VERSION is '$(OOREXX_VERSION)'"
	@echo
	@echo "make all [OOREXX_VERSION=5]"
	@for f in $(testFiles); do (echo "make $$f [OOREXX_VERSION=5]"); done
	@echo "make clean"

all:
	@for f in $(testFiles); do (make $$f); done

$(testFiles) :
	bash -i -c '( cat $@.rex ; echo RC = 0 ) | oorexxshell test regression > $@.output$(OOREXX_VERSION).slash.txt 2>&1'
	diff -q $@.output$(OOREXX_VERSION).slash.reference.txt $@.output$(OOREXX_VERSION).slash.txt

clean:
	@for f in $(testFiles); do (rm -f $$f.output.backslash.txt); done
	@for f in $(testFiles); do (rm -f $$f.output.slash.txt); done
	@for f in $(testFiles); do (rm -f $$f.output5.backslash.txt); done
	@for f in $(testFiles); do (rm -f $$f.output5.slash.txt); done


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
