/*
Invoke the md2pdf script with custom CSS
https://rexx.epbcn.com/rexx-parser/doc/utilities/md2pdf/
*/

parse arg args
arguments = "--size 09" -
            "--docclass book" -
            "--continue" -
            "--default" '"executor style=vim-light-zellner"' -
            args
.traceOutput~say("md2pdf" arguments)

if prepare_is_ok() then do
    call md2pdf arguments
end


-- Copy md2pdf4xtr/css/print/book-09pt.css to md2pdf's css/print folder
::routine prepare_is_ok
    cssfile = "book-09pt.css"

    parse source . . me
    myPath = FileSpec("Location",me)
    myName = FileSpec("Name",me)
    firstDot = myName~pos(".")
    if firstDot \== 0 then myName = myName~left(firstDot-1)
    source = myPath || myName"/" || "css/print/" || cssfile

    rexfile = "md2pdf.rex"
    him = .context~package~findProgram(rexfile)
    if .nil == him then do
        .error~say("Could not find" rexfile)
        return .false
    end

    hisPath = FileSpec("Location", him)
    hisPath = hisPath~left(hisPath~length - 1) -- Remove final /
    hisParentPath = FileSpec("Location", hisPath)
    destination = hisParentPath || "css/print/" || cssfile

    status = sysFileCopy(source, destination)
    if status \== 0 then do
        .error~say("Could not copy")
        .error~say("   " source)
        .error~say("   " "to" )
        .error~say("   " destination)
        .error~say("Error code" status SysGetErrorText(status))
        return .false
    end

    return .true
