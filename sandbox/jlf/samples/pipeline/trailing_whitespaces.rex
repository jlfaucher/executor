/*
Example of output :
'svn blame "D:\local\Rexx\ooRexx\svn\main\trunk\extensions\rxmath\rxmath.cpp"',608 :   5206   XXXXX /*                      of range, e.g., RxCalcSin(1.1) -> nan       */'   
*/

if arg() <> 1 then do ; call help ; return ; end
if \ .file~new(arg(1))~isDirectory then do
    say "Not a directory:" arg(1)
    return
end

arg(1)~pipe(.fileTree recursive mem |,
         .select {isSourceFile(item)} |,
         .fileLines |,
         .select {hasTrailingWhitespace(item)} | .take 1 {dataflow["fileTree"]~item} |, -- one line per file, to get the filename once
         .system {"svn blame" '"'dataflow["fileTree"]~item~absolutePath'"'} mem |, -- memorize to get the line number
         .select {hasTrailingWhitespace(item, .true)} |,
         .console {dataflow["system"]~index~ppRepresentation} ":" item ) 
         -- display the index created by .system (array~of(command, linenum)),
         -- followed by the current item (the line with trailing space)


::routine isSourceFile
    use strict arg file -- a .File object
    if \ file~isFile then return .false
    name = filespec("name", file~name)~lower
    if "makefile"~caselessEquals(name) then return .true
    ext = filespec("extension", name)~lower
    return "am c cls cpp def fnc frm h hpp html mak orx readme rc rex sgml txt xml"~caselessWordPos(ext) <> 0


::routine hasTrailingWhitespace
    use strict arg line, svnBlameOutput=.false
    start = 1
    if svnBlameOutput then do
        -- The line is like that : rev author text
        -- After the author, there is a space, must ignore this one.
        start = line~wordindex(2) + line~wordlength(2) + 1
    end
    line = line~substr(start)
    -- rather surprising : line~right(1, "") raises an error, so no way to disable the padding ?
    length = line~length
    if length == 0 then return .false
    return line~right(1) == " "

::routine help
    say 'Description :'
    say '    For each source file found in <directory> and its subdirectories (recursively),'
    say '    list the lines with trailing whitespaces and give the name of the author to blame.'
    say 'Usage :'
    say '    rexx pipeline/trailing_whitespaces <directory>'

::requires "pipeline/pipe_extension.cls"
