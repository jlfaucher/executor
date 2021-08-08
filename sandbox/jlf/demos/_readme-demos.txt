Demonstration scripts.
ooRexxShell has a demo mode with slow display.

https://asciinema.org/              asciinema   Terminal session recorder
https://github.com/theZiz/aha       aha         Ansi HTML Adapter.

Current demos:
executor-demo-array.txt
executor-demo-classic_rexx.txt
executor-demo-extensions.txt
executor-demo-text-compatibility.txt
executor-demo-text-internal_checks.txt
executor-demo-text.txt
ooRexxShell-demo-helpers.txt
ooRexxShell-demo-interpreters.txt
ooRexxShell-demo-queries.txt

To create an asciinema cast:
cd demos
./demo array
./demo classic_rexx
etc...

To capture the output of a demo in html format, with colors:
cd demos
asciinema cat executor-demo-array.cast | aha > executor-demo-array-output.html
asciinema cat executor-demo-classic_rexx.cast | aha > executor-demo-classic_rexx-output.html
etc...

To capture the output of a demo in text format:
cd demos
cat executor-demo-array.txt | oorexxshell demo fast > executor-demo-array-output.txt 2>&1
cat executor-demo-classic_rexx.txt | oorexxshell demo fast > executor-demo-classic_rexx-output.txt 2>&1

This is automated with a Makefile:
make all
make cast
make html
make text
