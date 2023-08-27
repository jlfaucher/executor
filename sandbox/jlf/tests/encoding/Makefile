# ooRexxShell scripts in the current directory
testFiles = main_conversion main_concatenation diary_examples

# The demos can be used as non-regression tests
demos = ../../demos
demoFiles = demo-text demo-text-internal_checks demo-text-unicode demo-text-compatibility

# ooRexx scripts in the current directory
scriptsFiles = test_character_index

# Some Unicode scripts can be used as non-regression tests
uscripts = ../../unicode/scripts
uscriptsFiles = list_invalid_utf8 test_convert test_encoding_combinations test_replacement_characters

help:
	@echo "make all"
	@for f in $(testFiles); do (echo "make" $$f); done
	@for f in $(demoFiles); do (echo "make" $$f); done
	@for f in $(scriptsFiles); do (echo "make" $$f); done
	@for f in $(uscriptsFiles); do (echo "make" $$f); done
	@echo "make clean"

all:
	@for f in $(testFiles); do (make $$f); done
	@for f in $(demoFiles); do (make $$f); done
	@for f in $(scriptsFiles); do (make $$f); done
	@for f in $(uscriptsFiles); do (make $$f); done

$(testFiles) :
	bash -i -c 'cat $@.rex | oorexxshell demo fast > $@.output.txt 2>&1'
	-diff -q $@.output.reference.txt $@.output.txt

$(demoFiles) :
	@# Don't display the current address in the prompt
	bash -i -c 'echo prompt off address | cat - $(demos)/executor-$@.rex | oorexxshell demo fast > executor-$@.output.txt 2>&1'
	-diff -q executor-$@.output.reference.txt executor-$@.output.txt

$(scriptsFiles) :
	bash -i -c 'rexx $@.rex > $@.output.txt 2>&1'
	-diff -q $@.output.reference.txt $@.output.txt

$(uscriptsFiles) :
	bash -i -c 'rexx $(uscripts)/$@.rex > $@.output.txt 2>&1'
	-diff -q $@.output.reference.txt $@.output.txt

clean:
	@for f in $(testFiles); do (rm -f $$f.output.txt); done
	@for f in $(demoFiles); do (rm -f executor-$$f.output.txt); done
	@for f in $(scriptsFiles); do (rm -f $$f.output.txt); done
	@for f in $(uscriptsFiles); do (rm -f $$f.output.txt); done


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
