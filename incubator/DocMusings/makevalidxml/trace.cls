/*
Debug helper.
It's not possible to step into a method when tracing. I use this helper
to activate some trace points at runtime.
This is a collection of strings associated to a trace option.

Programing usage :
if .t~istraced("mykey") then call trace .t~traceoption("mykey")
or
if .t~istraced(.context) then call trace .t~traceoption(.context)

With the second approach, the key is filename:line.
Ex : "myfile.rex:17"

Debug usage :
.t~on("key") --default trace when key is reached
.t~on("key","?n") -- trace ?n when key is reached
.t~off("key") -- trace not activated when key is reached
.t~list -- list the trace points
*/
.t~locations = .properties~new
.t~default = "?i"
.t~verbose = .false

::class t public --trace
::attribute locations class
::attribute default class -- default trace option
::attribute verbose class -- assign .true to see the calls to istraced

::method on class
    use strict arg key,option=(self~default)
    self~locations~setEntry(key, option)

::method off class
    use strict arg key
    self~locations~setEntry(key, .nil)
    
::method list class
    do i over self~locations
        say i" "self~locations~entry(i)
    end
    
::method istraced class
    use strict arg key_or_context
    return self~traceoption(key_or_context, self~verbose) <> .nil

::method traceoption class
    use strict arg key_or_context, verbose=.false
    if key_or_context~isA(.RexxContext) then do
        context = key_or_context
        key = filespec("name", context~package~name) || ":" || context~line
    end
    else do
        key = key_or_context
    end
    if verbose then say "[traceoption] "key" = "self~locations~entry(key)
    return self~locations~entry(key)

