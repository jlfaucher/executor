/*
This script needs a modified ooRexx interpreter which support extension of predefined ooRexx classes.
*/

--::options trace i

-----------------------------------------------------------------------------
-- Mixin.
/*
A DoerFactory is an object who knows how to create a doer.
A doer can be created from :
- a source (String or RexxContextualSource) :
  Can be costly since the interpreter must parse the source and create an AST.
  But you do it only once... After, you get an executable in your hands, which you can use
  as a target for the 'do' message.
- an executable (Routine or Method) : 
  No cost, this is for convenience, the doer is the executable itself.
  
Examples :

doer = {use arg name; say "hello" name}~doer
say doer~class -- The Routine class
doer~do("John") -- hello John
say

-- Here, ::method is a tag to indicate that the executable must be a method
doer = {::method say "hello" self}~doer
say doer~class -- The Method class
doer~do("John") -- hello John
say

-- By default, a string is a message
doer = "length"~doer
say doer~class -- The String class
say doer~do("John") -- 4
say

-- If you want to use a string as source holder, then you must call sourceDoer
doer = 'use arg name; say "hello" name'~sourceDoer
say doer~class -- The Routine class
doer~do("John") -- hello John
say

doer = '::method say "hello" self'~sourceDoer
say doer~class -- The Method class
doer~do("John") -- hello John
say

-- Implicit arguments and implicit return.
-- The original source
--    x~length
-- becomes :
--    use arg x ; options NOCOMMANDS ; x~length
--    return result
doer = {x~length}~sourceDoer("use arg x ; options NOCOMMANDS", "return result")
say doer~class -- The Routine class
say doer~do("John") -- 4
say

-- The method sourceDoer takes care of the expose instruction : keep it always as first instruction
-- The original source
--    ::method expose a b ; x*(a+b)
-- becomes :
--    expose a b  ; use arg x ; options NOCOMMANDS; x*(a+b)
--    return result
doer = {::method expose a b ; x*(a+b)}~sourceDoer("use arg x ; options NOCOMMANDS", "return result")
say doer~class -- The Method class
say doer~source~tostring
say

-- The method functionDoer (which calls sourceDoer) takes care of the implicit return
doer = {x~length}~functionDoer("use arg x")
say doer~class -- The Routine class
say doer~do("John") -- 4

*/

::class DoerFactory mixinclass Object public

::method doer abstract

::method sourceDoer -- Helper to create a doer from a source, after transformation of the source if needed/requested
    use strict arg before="", after="", context=.nil
    if context == .nil then context = self~package -- lookup scope

    sourceArray = self~source -- always an array, even if empty or just one line
    if sourceArray~items == 0 then raise syntax 93.900 array("No source available")
    clauseSupplier = .ClauseSupplier~new(sourceArray) -- yes, the supplier works directly on the source array (no copy)
    
    -- If the first word of the source is ::method then remove this word and remember it's a method.
    -- If the first word of the source is ::routine then remove this word and remember it's a routine.
    isRoutine = \ self~isA(.method) -- routine by default, unless self is a method
    if clauseSupplier~available then do
        clause = clauseSupplier~item
        parse var clause word rest
        if word~caselessEquals("::method")  then do ; clauseSupplier~item = rest ; isRoutine = .false ; end
        if word~caselessEquals("::routine") then do ; clauseSupplier~item = rest ; isRoutine = .true ; end
    end
    
    -- Insert the 'before' source fragment, if any
    if before <> "" then do
        -- If the next word is "expose" then must ensure that this clause remains the first clause.
        if clauseSupplier~available then do
            clause = clauseSupplier~item
            parse var clause word rest
            if word~caselessEquals("expose") then clauseSupplier~item = clause ";" before
                                             else clauseSupplier~item = before ";" clause
        end
        else sourceArray~append(before)
    end
    
    -- Insert the 'after' source fragment, if any
    if after <> "" then sourceArray~append(after)
    
    -- Returns the executable
    if isRoutine then return .Routine~new("", sourceArray, context)
                 else return .Method~new("", sourceArray, context)


-----------------------------------------------------------------------------
-- Mixin.
-- A Doer is an object who knows how to execute itself (understands "do")
-- This is an abstraction of routine, method and message.

::class Doer mixinclass Object public inherit DoerFactory

::method needsObject abstract
::method do abstract
::method doWith abstract


-----------------------------------------------------------------------------
-- Mixin.

::class RoutineDoer mixinclass Object public inherit Doer

::method doer
    use strict arg -- none
    return self

::method needsObject
    return .false -- No need to pass an object as first argument when calling do or doWith

::method do
    self~callWith(arg(1,"a"))
    if var("result") then return result

::method doWith
    use strict arg array
    self~callWith(array)
    if var("result") then return result


-----------------------------------------------------------------------------
-- Mixin.

/*
To investigate :
The method 'run' is a private method. So can be called only from another method of object...
"hello"~run({::method say self}~doer) --> Error : Object "hello" does not understand message "RUN" (ok, 'run' is private)
{::method say self}~doer~do("hello") --> No error, display "hello" (so the private method is visible ?)
*/
::class MethodDoer mixinclass Object public inherit Doer

::method doer
    use strict arg -- none
    return self

::method needsObject
    return .true -- Must pass an object as first argument when calling do or doWith

::method do
    use strict arg object, ...
    object~run(self, "a", arg(2,"a"))
    if var("result") then return result

::method doWith
    use strict arg object, array
    object~run(self, "a", array)
    if var("result") then return result


-----------------------------------------------------------------------------
-- Mixin.

::class StringDoer mixinclass Object public inherit Doer

::method doer
    use strict arg -- none
    return self -- When used as a doer factory, a string is a message

::method needsObject
    return .true -- Must pass an object as first argument when calling do or doWith

::method do
    use strict arg object, ...
    object~sendWith(self, arg(2,"a"))
    if var("result") then return result

::method doWith
    use strict arg object, array
    object~sendWith(self, array)
    if var("result") then return result

-- Using a string as source holder is no longer necessary,
-- because RexxContextualSource is now available.
-- But I keep the possibility, just in case...
::method source
    return .array~of(self)

-- Needed if you want to run sourceDoer on a string.
-- Most of the time, the package returned by this method will not answer to your
-- needs, because a routine/method created with this package as context will have
-- a lookup scope limited to the doers package. Of course, you can pass explicitely
-- another package to sourceDoer (typically the caller's package), but that's tedious
-- to do that each time.
-- Thats's why RexxContextualSource has been added, it holds a reference to the package
-- that defined it.
::method package
    return .context~package


-----------------------------------------------------------------------------
-- Mixin.

::class RexxContextualSourceDoer mixinclass Object public inherit Doer

::method doer
    use strict arg -- none
    return self~sourceDoer

-- Could be defined on DoerFactory to give access to this functionality from any doer,
-- but that's probably a bad idea. Other doers are directly executable (except String
-- when using sourceDoer - but that's deprecated) and I consider that the "shortest source"
-- criteria doesn't apply to them. So they will have already the right arguments and an
-- explicit return, if needed.
::method functionDoer
    use strict arg before="", after=""
    before ||= ' ; options "NOCOMMANDS"'
    after ||= ' ; if var("result") then return result'
    return self~sourceDoer(before, after)

-- Same remark as above.
::method actionDoer
    use strict arg before="", after=""
    return self~sourceDoer(before, after)


-----------------------------------------------------------------------------
-- Helper for source analysis & transformation.

/*
The ClauseSupplier works directly on the source array passed at creation.
It returns only non-empty clauses (unless you modify a clause, see below).
You can modify the source array by replacing the current clause by a new one :
    mySupplier~item = mySourceFragment
The new clause is inserted as-is and not iterated over by the supplier.
Of course, you can create a new clause supplier using the modified source, and
then you will iterate over your modified clauses.
While you don't call ~next, ~item will return the last assigned value, which
can be anything, like an empty string or a string containing several clauses.  

Exemple :

------------------------------------
csource = {
    clause1

    clause2 ; clause3
    clause4 ; ;
}
sourceArray = csource~source -- Each time you call this method, you get a copy of the original source literal

say "Iterate over the original source :"
i = 1
do sourceLine over sourceArray
    say i '"'sourceLine'"'
    i +=1
end

say
say "Iterate over the clauses, modify clause2 and remove clause3:"
clauseSupplier = .ClauseSupplier~new(sourceArray) -- The supplier works directly on this source array, no copy
i = 1
do while clauseSupplier~available
    clause = clauseSupplier~item
    if clause~strip == "clause2" then clauseSupplier~item = "clause2 before ; "clause" ; clause2 after"
    if clause~strip == "clause3" then clauseSupplier~item = ""
    say i '"'clause'" --> "'clauseSupplier~item'"'
    clauseSupplier~next
    i += 1
end

say
say "Iterate over the modified source :"
i = 1
do sourceLine over sourceArray
    say i '"'sourceLine'"'
    i += 1
end

say
say "Iterate over the clauses of the modified source :"
clauseSupplier = .ClauseSupplier~new(sourceArray)
i = 1
do while clauseSupplier~available
    clause = clauseSupplier~item
    say i '"'clause'"'
    clauseSupplier~next
    i += 1
end
------------------------------------
Output :
Iterate over the original source :
1 ""
2 "    clause1"
3 ""
4 "    clause2 ; clause3"
5 "    clause4 ; ;"

Iterate over the clauses, modify clause2 and remove clause3:
1 "    clause1" --> "    clause1"
2 "    clause2 " --> "clause2 before ;     clause2  ; clause2 after"
3 " clause3" --> ""
4 "    clause4 " --> "    clause4 "

Iterate over the modified source :
1 ""
2 "    clause1"
3 ""
4 "clause2 before ;     clause2  ; clause2 after;"
5 "    clause4 ; ;"

Iterate over the clauses of the modified source :
1 "    clause1"
2 "clause2 before "
3 "     clause2  "
4 " clause2 after"
5 "    clause4 "
*/

::class ClauseSupplier public

::method init
    expose sourceArray lineNum clauseStart clauseEnd
    use strict arg sourceArray
    lineNum = sourceArray~first
    clauseStart = 1
    clauseEnd = -1 -- indicator of first call to next
    self~next

::method available
    expose lineNum
    return lineNum <> .nil

::method index
    expose lineNum clauseStart
    if \ self~available then raise syntax 937
    return lineNum clauseStart

::method item
    expose clause
    if \ self~available then raise syntax 937
    return clause

::method "item=" -- replace the current clause by the new source fragment (black box, can be several clauses, won't be scanned)
    expose sourceArray lineNum clauseStart clauseEnd clause
    if \ self~available then raise syntax 937
    use strict arg newSourceFragment
    oldLength = clause~length
    newLength = newSourceFragment~length
    sourceLine = sourceArray[lineNum]
    sourceArray[lineNum] = sourceLine~replaceAt(newSourceFragment, clauseStart, oldLength)
    if clauseEnd > 0 then clauseEnd += newLength - oldLength -- yes, continue AFTER the new source fragment
    clause = newSourceFragment -- If you recall ~item then you will get the modified clause
    
::method next -- non empty clause
    expose sourceArray lineNum clauseStart clauseEnd clause
    do while lineNum <> .nil
        if clauseEnd == 0 then do
            clauseStart = 1
            lineNum = sourceArray~next(lineNum)
        end
        else if clauseEnd > 0 then clauseStart = clauseEnd + 1
        if lineNum == .nil then leave
        sourceLine = sourceArray[lineNum]
        clauseEnd = sourceLine~pos(";", clauseStart)
        if clauseEnd == 0 then clauseLength = sourceLine~length - clauseStart + 1
                          else clauseLength = clauseEnd - clauseStart
        clause = sourceLine~substr(clauseStart, clauseLength)
        if clause~strip <> "" then return
    end

