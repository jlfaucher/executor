if arg() <> 1 then do ; call help ; return ; end
use strict arg string
string = string~strip -- You need that !!! you have a trailing space when redirecting like that : grep_sources mystring > results.txt
caseless = ""
if string~left(3) == "-i " then do
    caseless = "caseless"
    string = string~substr(4)
end

"."~pipe(.filetree recursive memorize | .select {isSourceFile(item)} | .fileLines memorize | .all[string] caseless | .console {dataflow["fileTree"]~item":"index item} | .lineCount | .console)

::routine isSourceFile
    use strict arg file -- a .File object
    if \ file~isFile then return .false
    name = filespec("name", file~name)~lower
    if "makefile"~caselessEquals(name) then return .true
    ext = filespec("extension", name)~lower
    return "am c cls cpp def fnc frm h hpp html mak orx readme rc rex sgml txt xml"~caselessWordPos(ext) <> 0

::routine help
    say 'Description :'
    say '    For each source file found in the current directory and its subdirectories (recursively),'
    say '    list the lines which contain the requested string.'
    say '    The last line gives the number of matches.'
    say 'Usage :'
    say '    cd <the root directory of the source files>'
    say '    rexx grep_sources "my string"    -- case sensitive by default'
    say '    rexx grep_sources "-i my string" -- for a case insensitive grep'

::requires "pipeline/pipe_extension.cls"