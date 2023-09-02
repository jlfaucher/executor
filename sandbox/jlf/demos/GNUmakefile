#######################################
# GNUmakefile for make (Macos, Linux) #
#######################################

# Keep this name!
# Under Macos and Linux, make will use in priority GNUmakefile.
# Under Windows, nmake will ignore GNUmakefile and use Makefile.

demoFiles = executor-demo-array \
            executor-demo-classic_rexx \
            executor-demo-extensions \
            executor-demo-text \
            executor-demo-text-internal_checks \
            executor-demo-text-unicode \
            executor-demo-text-compatibility \
            ooRexxShell-demo-helpers \
            ooRexxShell-demo-interpreters \
            ooRexxShell-demo-queries

help:
	@echo "make all"
	@echo "make cast"
	@echo "make html"
	@echo "make txt"
	@echo "make force"

all: cast html txt

cast:
	@for d in $(demoFiles); do (make $$d.cast); done

html:
	@for d in $(demoFiles); do (make $$d-output.html); done

txt:
	@for d in $(demoFiles); do (make $$d-output.txt); done

force:
	@for d in $(demoFiles); do (touch $$d.rex); done

%.cast : %.rex
	-asciinema rec -c "bash -i -c 'cat $? | oorexxshell --showInitialization'" --overwrite $@

%-output.html : %.cast
	asciinema cat $? | aha --title "$@" > $@

# 1) Remember! $ has special meaning in makefiles. If you want to use it in a
#    shell command, you have to double it.
# 2) asciinema replaces the invalid UTF-8 characters by the REPLACEMENT CHARACTER.
#    That's why I no longer find encoding errors in the output files.
# 3) See below for a detailled description of the perl regex
#    Used to remove the escape characters for colors.
%-output.txt : %.cast
	asciinema cat $? | perl -pe 's/\e([^\[\]]|\[.*?[a-zA-Z]|\].*?\a)//g' > $@

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

# https://superuser.com/questions/236930/how-to-clean-up-output-of-linux-script-command
#     cat typescript | perl -pe 's/\e([^\[\]]|\[.*?[a-zA-Z]|\].*?\a)//g' | col -b > typescript-processed
#
# here's some interpretation of the string input to perl:
#
# s/pattern//g means to do a substitution on the entire (the g option means do
# the entire thing instead of stopping on the first substitute) input string.
#
# here's some interpretation of the regex pattern:
#
# \e match the special "escape" control character (ASCII 0x1A)
#
# ( and ) are the beginning and end of a group
#
# | means the group can match one of N patterns. where the N patterns are
#     [^\[\]] or
#     \[.*?[a-zA-Z] or
#     \].*?\a
#
# [^\[\]] means: match a set of NOT characters where the not characters are [ and ]
#
# \[.*?[a-zA-Z] means:
#    match a string starting with [ then do a non-greedy .*?
#    until the first alpha character
#
# \].*?\a means:
#    match a string that starts with ] then do a non-greedy .*?
#    until you hit the special control character called
#    "the alert (bell) character"
