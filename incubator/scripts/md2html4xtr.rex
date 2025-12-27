/*
Invoke the md2html script with custom helpers
https://rexx.epbcn.com/rexx-parser/doc/utilities/md2html/
*/

parse source . . me
myPath = FileSpec("Location",me)
myName = FileSpec("Name",me)
firstDot = myName~pos(".")
if firstDot \== 0 then myName = myName~left(firstDot-1)

parse arg args
call md2html "--path" mypath"/"myname "--css https://jlfaucher.github.io/css" args
