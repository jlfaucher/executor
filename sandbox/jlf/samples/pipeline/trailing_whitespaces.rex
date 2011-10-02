/*
Description :
    For each source file found in the current directory and its subdirectories (recursively),
    list the lines with trailing whitespaces and give the name of the author to blame.
Usage :
    cd <the root directory of the source files"
    rexx pipeline/trailing_whitespaces
Example of output :
    'svn blame "D:\local\Rexx\ooRexx\svn\main\trunk\extensions\rxmath\rxmath.cpp"',608 :   5206   XXXXX /*                      of range, e.g., RxCalcSin(1.1) -> nan       */   
*/

"."~pipe(.fileTree recursive |,
         .select {isSourceFile(value)} |,
         .getFiles mem |,
         .select {hasTrailingWhitespace(value)} | .take 1 {index~get("getFiles")~value} |, -- one line per file, to get the filename once
         .system {"svn blame" '"'index~get("getFiles")~value~absolutePath'"'} mem |, -- memorize to get the line number
         .select {hasTrailingWhitespace(value, .true)} |,
         .console {index~get("system")~show("2 3")} ":" value ) 
         -- display the 2nd and 3rd fields of the index created by .system (filepath and linenum),
         -- followed by the current value (the line with trailing space)


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


::requires "pipeline/pipe_extension.cls"
