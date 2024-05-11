#######################################
# GNUmakefile for make (Macos, Linux) #
#######################################

# Keep this name!
# Under Macos and Linux, make will use in priority GNUmakefile.
# Under Windows, nmake will ignore GNUmakefile and use Makefile.

# ooRexx scripts in the current directory
scriptsFiles = class method

mainFiles = main_array_literal

help:
	@echo "make all"
	@for f in $(scriptsFiles); do (echo "make" $$f); done
	@for f in $(mainFiles); do (echo "make" $$f); done
	@echo "make clean"

all:
	@for f in $(scriptsFiles); do (make $$f); done
	@for f in $(mainFiles); do (make $$f); done

$(scriptsFiles) :
	bash -i -c 'rexx $@.rex > $@.output.txt 2>&1'
	diff -q $@.output.reference.txt $@.output.txt

$(mainFiles) :
	bash -i -c 'cat $@.rex | oorexxshell test regression > $@.output.txt 2>&1'
	diff -q $@.output.reference.txt $@.output.txt

clean:
	@for f in $(scriptsFiles); do (rm -f $$f.output.txt); done
	@for f in $(mainFiles); do (rm -f $$f.output.txt); done


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
