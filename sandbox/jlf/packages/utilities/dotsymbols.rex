/*
Display a unique sorted list of the dot symbols of the file <filename>.
Works only with the debug version of Executor

To limit the list of dot symbols to the current file, remove any ::requires
from the file, otherwise you will have also the dot symbols of the required files.

Note: it's not a problem if an error is raised because of the removed ::requires.
The goal is to have parsing informations only.
*/

use arg filename
if .file~new(filename)~exists  == .false then do
    say "file not found."
    return -1
end

("RXTRACE_PARSING=ON rexx" filename "2>&1")~pipe(.system | .all["DOTSYMBOL"] | .inject {lastWord = item~word(item~words); parse var lastWord 'token="' dotSymbol '"'; dotSymbol} | .sort "mem" | .take "first" {dataflow["sort"]~item} | .do {say item})

return 0

::requires "pipeline/pipe_extension.cls"


/*
================================================================================
Analyzing the source tokens
================================================================================

The debug version of Executor display parsing informations when
export RXTRACE_PARSING=ON


From a system shell:
To get all the dot symbols of the file byte_common.cls:
rexx sourceFile 2>&1 >/dev/null | grep DOTSYMBOL > out.txt

Example of output:
(Parsing)startLine=56 startCol=32 endLine=56 endCol=40 classId=TOKEN_SYMBOL subclass=SYMBOL_DOTSYMBOL numeric=0 token=".UNICODE"

The last word is token=".UNICODE"
To get just .UNICODE
parse var lastWord 'token="' dotSymbol '"'

*/
