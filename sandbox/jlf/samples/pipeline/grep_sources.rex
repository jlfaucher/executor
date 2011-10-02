/*
Description :
    For each source file found in the current directory and its subdirectories (recursively),
    list the lines which contain the requested string.
    The last line gives the number of matches.
Usage :
    cd <the root directory of the source files"
    rexx grep_sources "my string"    -- case sensitive by default
    rexx grep_sources "-i my string" -- for a case insensitive grep
*/

use strict arg string
caseless = ""
if string~left(3) == "-i " then do
    caseless = "caseless"
    string = string~substr(4)
end

"."~pipe(.filetree recursive | .select {isSourceFile(value)} | .getFiles mem | .all[string] caseless | .console | .lineCount | .console)

::routine isSourceFile
    use strict arg file -- a .File object
    if \ file~isFile then return .false
    name = filespec("name", file~name)~lower
    if "makefile"~caselessEquals(name) then return .true
    ext = filespec("extension", name)~lower
    return "am c cls cpp def fnc frm h hpp html mak orx readme rc rex sgml txt xml"~caselessWordPos(ext) <> 0


::requires "pipeline/pipe_extension.cls"