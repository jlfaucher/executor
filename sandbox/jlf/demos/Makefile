executorDemos = array classic_rexx extensions text text-internal_checks text-unicode text-compatibility
ooRexxShellDemos = helpers interpreters queries

help:
	@echo "make all"
	@echo "make cast"
	@echo "make html"
	@echo "make txt"

all: cast html txt

cast::
	@for d in $(executorDemos); do (make executor-demo-$$d.cast); done

cast::
	@for d in $(ooRexxShellDemos); do (make ooRexxShell-demo-$$d.cast); done

html::
	@for d in $(executorDemos); do (make executor-demo-$$d-output.html); done

html::
	@for d in $(ooRexxShellDemos); do (make ooRexxShell-demo-$$d-output.html); done

txt::
	@for d in $(executorDemos); do (make executor-demo-$$d-output.txt); done

txt::
	@for d in $(ooRexxShellDemos); do (make ooRexxShell-demo-$$d-output.txt); done

force::
	@for d in $(executorDemos); do (touch executor-demo-$$d.rex); done

force::
	@for d in $(ooRexxShellDemos); do (touch ooRexxShell-demo-$$d.rex); done

%.cast : %.rex
	-asciinema rec -c "bash -i -c 'cat $? | oorexxshell --showInitialization'" --overwrite $@

%-output.html : %.cast
	asciinema cat $? | aha --title "$@" > $@

# 1) Remember! $ has special meaning in makefiles. If you want to use it in a shell command, you have to double it.
# 2) asciinema replaces the invalid UTF-8 characters by the REPLACEMENT CHARACTER.
#    That's why I no longer find encoding errors in the output files.
%-output.txt : %.cast
	asciinema cat $? | sed -e $$'s/\x1b\[[0-9;]*m//g' > $@

# No longer used because it's a re-execution instead of a simple cat
# %-output.txt : %.rex
# 	bash -i -c 'cat $? | oorexxshell demo fast > $@ 2>&1'


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
