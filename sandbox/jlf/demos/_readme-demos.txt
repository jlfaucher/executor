Demonstration scripts.
ooRexxShell has a demo mode with slow display.

https://asciinema.org/

Current demos:
executor-demo-array.txt
executor-demo-classic_rexx.txt
executor-demo-extensions.txt
executor-demo-text.txt
ooRexxShell-demo-helpers.txt
ooRexxShell-demo-interpreters.txt
ooRexxShell-demo-queries.txt

To create an asciinema cast:
cd demos
./demo array
./demo classic_rexx
etc...

To capture the output of a demo:
cd demos
cat executor-demo-array.txt | oorexxshell demo fast > executor-demo-array-output.txt 2>&1
cat executor-demo-classic_rexx.txt | oorexxshell demo fast > executor-demo-classic_rexx-output.txt 2>&1

This is automated with a Makefile:
make all
make casts
make outputs


Demos stored on asciinema.org:
https://asciinema.org/a/oyhrULNtbneuZ3neIvp9l2aZT
https://asciinema.org/a/SIW9ego7ky4RVYA99OcAKF7OB

