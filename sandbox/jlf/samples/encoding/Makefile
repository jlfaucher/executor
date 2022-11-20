samples = main_conversion main_concatenation

help:
	@echo "make [force] all"
	@for s in $(samples); do (echo "make [force]" $$s.output.txt); done
	@echo "make clean"

all:
	@for s in $(samples); do (make $$s.output.txt); done

force:
	@for s in $(samples); do (touch $$s.rex); done

%.output.txt : %.rex
	bash -i -c 'cat $< | oorexxshell demo fast > $@ 2>&1'
	-diff -q $*.output.reference.txt $@

clean:
	@for s in $(samples); do (rm -f $$s.output.txt); done


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
