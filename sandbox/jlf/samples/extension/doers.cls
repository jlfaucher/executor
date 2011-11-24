/*
This script needs a modified ooRexx interpreter which support extension of predefined ooRexx classes.
*/

--::options trace i
::options NOMACROSPACE
::requires "concurrency/coactivity.cls"


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

-- By default (no tag) the executable is a routine.
-- This routine is created by the interpreter when parsing the literal source (immediate parsing).
source = {use strict arg name, greetings; say "hello" name || greetings}
say source~class -- The RexxContextualSource class
say source~executable -- a Routine
doer = source~doer -- no cost, returns directly the executable created by the interpreter at parsing time.
say doer~class -- The Routine class
doer~do("John", ", how are you ?") -- hello John, how are you ?
say

-- Here, ::method is a tag to indicate that the executable must be a method
-- The first argument passed with ~do is the object, available in self.
-- The rest of the ~do's arguments are passed to the method as arg(1), arg(2), ...
-- Minimal abbreviation is ::m
doer = {::method use strict arg greetings; say "hello" self || greetings}~doer
say doer~class -- The Method class
doer~do("John", ", how are you ?") -- hello John, how are you ?
say

-- Here, ::coactivity is a tag to indicate that the doer must be a coactivity (whose executable is a routine by default).
-- Minimal abbreviation is ::c
doer = {::coactivity
        say "hello" arg(1) || arg(2)
        arg = .yield[]
        say "good bye" arg[1] || arg[2]
       }~doer
say doer~class -- The Coactivity class
say doer~executable -- a Routine
doer~do("John", ", how are you ?") -- hello John, how are you ?
doer~do("Kathie", ", see you soon.") -- good bye Kathie, see you soon.
doer~do("Keith") -- <nothing done, the coactivity is ended>
say

-- ::routine.coactive (coactive routine) is equivalent to ::coactivity.
-- Minimal abbreviation is ::r.c
doer = {::routine.coactive
        say "hello" arg(1) || arg(2)
        arg = .yield[]
        say "good bye" arg[1] || arg[2]
       }~doer
say doer~class -- The Coactivity class
say doer~executable -- a Routine
doer~do("John", ", how are you ?") -- hello John, how are you ?
doer~do("Kathie", ", see you soon.") -- good bye Kathie, see you soon.
doer~do("Keith") -- <nothing done, the coactivity is ended>
say

-- Here, ::method.coactive is a tag to indicate that the doer must be a coactivity whose executable is a method.
-- The object on which the method is run is passed using the ~doer method.
-- Minimal abbreviation is ::m.c
doer = {::method.coactive
        say self 'says "hello' arg(1) || arg(2)'"'
        arg = .yield[]
        say self 'says "good bye' arg[1] || arg[2]'"'
       }~doer("The boss")
say doer~class -- The Coactivity class
say doer~executable -- A Method
doer~do("John", ", how are you ?") -- The boss says "hello John, how are you ?"
doer~do("Kathie", ", see you soon.") -- The boss says "good bye Kathie, see you soon."
doer~do("Keith") -- <nothing done, the coactivity is ended>
say

-- By default, a string is a message
doer = "length"~doer
say doer~class -- The String class
say doer~do("John") -- 4
say

-- If you want to use a string as source holder, then you must call sourceDoer
doer = 'use strict arg name; say "hello" name'~sourceDoer
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
--    use strict arg x ; options "NOCOMMANDS" ; x~length
--    return result
doer = {x~length}~sourceDoer('use strict arg x ; options NOCOMMANDS', "return result")
say doer~class -- The Routine class
say doer~do("John") -- 4
say

-- The method sourceDoer takes care of the expose instruction : keep it always as first instruction
-- The original source
--    ::method expose a b ; x*(a+b)
-- becomes :
--    expose a b  ; use strict arg x ; options "NOCOMMANDS"; x*(a+b)
--    return result
doer = {::method expose a b ; x*(a+b)}~sourceDoer('use strict arg x ; options "NOCOMMANDS"', "return result")
say doer~class -- The Method class
say doer~source~tostring
say

-- The method functionDoer (which calls sourceDoer) takes care of the implicit return
doer = {x~length}~functionDoer("use strict arg x")
say doer~class -- The Routine class
say doer~do("John") -- 4
say

-- closure by value
-- Minimal abbreviation is ::cl
-- Output is :
--   RexxContextualSource:266663584 --> Closure:266674100 --> 1 4
--   RexxContextualSource:266663628 --> Closure:266685776 --> 2 4
--   RexxContextualSource:266663672 --> Closure:266697452 --> 3 4
--   RexxContextualSource:266663716 --> Closure:266709128 --> 4 4
-- i contains a non mutable value (different value captured at each iteration).
-- literalSources contains a reference to a mutableValue (same value captured at each iteration).
literalSources = .array~new
do i=1 to 4
    literalSources[i] = {::closure 
                         expose literalSources i
                         use strict arg source, doer
                         call charout , source~class~id":"source~identityHash
                         call charout , " --> "
                         call charout , doer~class~id":"doer~identityHash
                         call charout , " --> "
                         call charout , i literalSources~items
                         say
                        }
end
do literalSource over literalSources
    doer = literalSource~doer
    doer~do(literalSource, doer)
end
say

-- Coactive closure
-- Minimal abbreviation is ::cl.c
v = 1
w = 2
doer = {::closure.coactive expose v w ; .yield[v] ; .yield[w]}~doer
say doer~class -- The Coactivity class
say doer~executable -- a Closure
say doer~do -- 1
say doer~do -- 2
doer~do -- no result
say
*/

::class "DoerFactory" mixinclass Object public

::method doer abstract

/*
Helper to create a doer from a source, after transformation of the source if needed/requested.
Possible transformations :
- Insert a clause at the begining (takes care of the expose instruction, keep it always as
  first instruction).
- Insert a clause at the end.
- Make the first clause (other than "expose" and "use [strict] arg") a pure expression, unless
  this clause is a "return" clause.
*/
::method sourceDoer unguarded
    use strict arg clauseBefore="", clauseAfter="", expression=.false, context=.nil, objectSpecified = .false, object = .nil
    if context == .nil then context = self~package -- lookup scope

    sourceArray = self~source -- always an array, even if empty or just one line
    if sourceArray~items == 0 then raise syntax 93.900 array("No source available")
    clauser = .Clauser~new(sourceArray)

    -- If the first word is ::cl[osure] then remove this word and remember it's a closure
    -- If the first word is ::cl[osure].coactive] then remove this word and remember it's a coactive closure
    -- If the first word is ::c[oactivity] then remove this word and remember it's a coactive routine.
    -- If the first word is ::m[ethod] then remove this word and remember it's a method.
    -- If the first word is ::m[ethod].c[oactive] then remove this word and remember it's a coactive method.
    -- If the first word is :[:routine] then remove this word and remember it's a routine.
    -- If the first word is :[:routine].c[oactive] then remove this word and remember it's a coactive routine.
    -- If the first word is ::[xxx] then raise an error (unknown tag)
    -- If the first word starts with ':' then remove this character and remember it's a routine
    kind = "r" -- routine by default
    if self~isA(.method) then kind = "m" -- unless self is a method
    if clauser~clauseAvailable then do
        clause = clauser~clause
        parse var clause word1 rest
        parse var word1 word "." option
        if "::closure"~caselessAbbrev(word, 4) then do
            clauser~clause = rest
            kind = "cl"
            if option <> "" then do
                if "coactive"~caselessAbbrev(option, 1) then kind = "cl.c"
                else raise syntax 93.900 array("Unknown option '"option"'")
            end
        end
        else if "::coactivity"~caselessAbbrev(word, 3) then do
            clauser~clause = rest
            kind = "r.c" -- routine by default
            if option <> "" then raise syntax 93.900 array("Unknown option '"option"'")
        end
        else if "::method"~caselessAbbrev(word, 3)  then do
            clauser~clause = rest
            kind = "m"
            if option <> "" then do
                if "coactive"~caselessAbbrev(option, 1) then kind = "m.c"
                else raise syntax 93.900 array("Unknown option '"option"'")
            end
        end
        else if "::routine"~caselessAbbrev(word, 1) then do
            clauser~clause = rest
            kind = "r"
            if option <> "" then do
                if "coactive"~caselessAbbrev(option, 1) then kind = "r.c"
                else raise syntax 93.900 array("Unknown option '"option"'")
            end
        end
        else if word~left(2) == "::" then raise syntax 93.900 array("Unknow tag '"word"'")
        else if word~left(1) == ":" then do; clauser~clause = clause~substr(2) ; kind = "r" ; end
    end

    -- If the clause is an "expose" clause then skip it (must remain the first clause, always)
    if clauser~clauseAvailable then do
        clause = clauser~clause
        parse lower var clause word rest
        if word == "expose" & \ isAssignment(rest) then clauser~nextClause
    end

    -- Make the current clause a pure expression, if requested and candidate
    expressionDone = .false
    if expression & clauser~clauseAvailable then do
        -- If the clause is a "return" clause then no need to make it a pure expression.
        parse lower var clause word rest
        if word == "return" & \ isAssignment(rest) then expression = .false
        if expression then do
            -- If the clause is a "use [strict] arg" clause then it's not candidate to become pure expression.
            parse lower var clause word1 word2 word3 .
            if \ (word1 == "use" & word2 == "strict" & word3 == "arg") & \ (word1 == "use" & word2 == "arg") then do
                clauser~clause = "(" clauser~clause ")"
                expressionDone = .true
            end
        end
    end

    -- Insert the 'clauseBefore', if any
    if clauseBefore <> "" then do
        if clauser~clauseAvailable then clauser~clause = clauseBefore ";" clauser~clause
        else sourceArray~append(clauseBefore)
    end

    -- If pure expression not yet done, then make next clause a pure expression
    if expression & \ expressionDone then do
        clauser~nextClause
        if clauser~clauseAvailable then clauser~clause = "(" clauser~clause ")"
    end

    if expression then do
        -- If the source has more clauses then it can't be a pure expression, unless it's a return clause
        clauser~nextClause
        if clauser~clauseAvailable then do
            parse lower var clause word rest
            if word == "return" & \ isAssignment(rest) then clauser~nextClause
            if clauser~clauseAvailable then raise syntax 93.900 array("Not an expression")
        end
    end

    -- Insert the 'clauseAfter', if any
    if clauseAfter <> "" then sourceArray~append(clauseAfter)

    -- Returns the executable
    if kind == "r" then return .Routine~new("", sourceArray, context)
    else if kind == "r.c" then return .Coactivity~new(.Routine~new("", sourceArray, context))
    else if kind == "m" then return .Method~new("", sourceArray, context)
    else if kind == "m.c" then do
        if \objectSpecified then raise syntax 93.900 array("No object specified")
        return .Coactivity~new(.Method~new("", sourceArray, context), , object)
    end
    else if kind == "cl" then return .Closure~new(self~variables, .Method~new("do", sourceArray, context))
    else if kind == "cl.c" then return .Coactivity~new(.Closure~new(self~variables, .Method~new("do", sourceArray, context)))


-----------------------------------------------------------------------------
-- Mixin.
-- A Doer is an object who knows how to execute itself (understands "do")
-- This is an abstraction of routine, method, message, coactivity.

::class "Doer" mixinclass Object public inherit DoerFactory

::method needsObject abstract
::method do abstract
::method doWith abstract


-----------------------------------------------------------------------------
-- Mixin.

::class "RoutineDoer" mixinclass Object public inherit Doer

::method doer unguarded
    use strict arg -- none
    return self

::method needsObject unguarded
    return .false -- No need to pass an object as first argument when calling do or doWith

::method do unguarded
    self~callWith(arg(1,"a"))
    if var("result") then return result

::method doWith unguarded
    use strict arg array
    self~callWith(array)
    if var("result") then return result


-----------------------------------------------------------------------------
-- Mixin.

/*
Remember :
The method 'run' is a private method. So can be called only from another method of object...
"hello"~run({::method say self}~doer) --> Error : Object "hello" does not understand message "RUN" (ok, 'run' is private)
{::method say self}~doer~do("hello") --> No error, display "hello" (so the private method is visible ?)
--> It's because the ~run method is called from the ~do method which has been added by extension.
*/
::class "MethodDoer" mixinclass Object public inherit Doer

::method doer unguarded
    use strict arg -- none
    return self

::method needsObject unguarded
    return .true -- Must pass an object as first argument when calling do or doWith

::method do unguarded
    use strict arg object, ...
    object~run(self, "a", arg(2,"a"))
    if var("result") then return result

::method doWith unguarded
    use strict arg object, array
    object~run(self, "a", array)
    if var("result") then return result


-----------------------------------------------------------------------------
-- Mixin.

::class "StringDoer" mixinclass Object public inherit Doer

::method doer unguarded
    use strict arg -- none
    return self -- When used as a doer factory, a string is a message

::method needsObject unguarded
    return .true -- Must pass an object as first argument when calling do or doWith

::method do unguarded
    use strict arg object, ...
    object~sendWith(self, arg(2,"a"))
    if var("result") then return result

::method doWith unguarded
    use strict arg object, array
    object~sendWith(self, array)
    if var("result") then return result

-- Using a string as source holder is no longer necessary,
-- because RexxContextualSource is now available.
-- But I keep the possibility, just in case...
::method source unguarded
    return .array~of(self)

-- Needed if you want to run sourceDoer on a string.
-- Most of the time, the package returned by this method will not answer to your
-- needs, because a routine/method created with this package as context will have
-- a lookup scope limited to the doers package. Of course, you can pass explicitely
-- another package to sourceDoer (typically the caller's package), but that's tedious
-- to do that each time.
-- Thats's why RexxContextualSource has been added, it holds a reference to the package
-- that defined it.
::method package unguarded
    return .context~package

-- Needed if you want to run sourceDoer on a string.
-- The directory of variables returned by this method is useless...
-- Thats's why RexxContextualSource has been added, it holds a directory of variables built
-- from the context that created the RexxContextualSource instance, needed for closures.
::method variables
    return .context~variables


-----------------------------------------------------------------------------
-- Mixin.

::class "RexxContextualSourceDoer" mixinclass Object public inherit Doer

::method doer unguarded
    use strict arg object=.nil -- optional object, needed when the source is tagged ::method
    if self~executable <> .nil then return self~executable
    objectSpecified = arg(1, "e") -- object explicitely passed ?
    return self~sourceDoer( , , , , objectSpecified, object)

-- Could be defined on DoerFactory to give access to this functionality from any doer,
-- but that's probably a bad idea. Other doers are directly executable (except String
-- when using sourceDoer - but that's deprecated) and I consider that the "shortest source"
-- criteria doesn't apply to them. So they will have already the right arguments and an
-- explicit return, if needed.
::method functionDoer unguarded
    use strict arg clauseBefore="", clauseAfter="", object=.nil-- optional object, needed when the source is tagged ::method
    objectSpecified = arg(3, "e") -- object explicitely passed ?
    -- Don't activate next line ! You may have an executable because the code is parsable, but which needs transformations anyway
    -- if self~executable <> .nil then return self~executable
    clauseBefore ||= ' ; options "NOCOMMANDS"'
    clauseAfter ||= ' ; if var("result") then return result'
    -- try first to parse the source as-is, because of that :
    -- say {if .true then 2}~functionDoer~do
    -- would display "IF 1 THEN 2" if the clause had been transformed to an expression.
    signal on syntax name syntax1
    return self~sourceDoer(clauseBefore, clauseAfter, , , objectSpecified, object)
    syntax1:
    -- The source as-is can't be parsed, try surrounding with round brackets...
    -- That lets support expressions like "arg()" which is otherwise an invalid expression :
    -- Missing expression following ( of parse template
    signal on syntax name syntax2
    return self~sourceDoer(clauseBefore, clauseAfter, .true, , objectSpecified, object)
    syntax2:
    -- The source is not a pure expression, fallback (again) to source as-is
    -- that will raise a syntax error, but this time, don't catch the error.
    return self~sourceDoer(clauseBefore, clauseAfter, , , objectSpecified, object)

-- Same remark as above.
::method actionDoer unguarded
    use strict arg clauseBefore="", clauseAfter="", object=.nil-- optional object, needed when the source is tagged ::method
    -- Don't activate next line ! You may have an executable because the code is parsable, but which needs transformations anyway
    -- if self~executable <> .nil then return self~executable
    return self~sourceDoer(clauseBefore, clauseAfter, , , objectSpecified, object)


-----------------------------------------------------------------------------
-- Mixin.

::class "CoactivityDoer" mixinclass Object public inherit Doer

::method doer unguarded
    use strict arg -- none
    return self

::method needsObject unguarded
    return .false -- No need to pass an object as first argument when calling do or doWith

::method do unguarded
    forward message ("resume")
    if var("result") then return result

::method doWith unguarded
    use strict arg array
    forward message ("resume") arguments (array)
    if var("result") then return result


-----------------------------------------------------------------------------
-- Closure by value : not yet a real closure
-- good point, no risk of race conditions...
 
::class "Closure" public inherit Doer

::method init
    expose !_variableNames_!
    variables = .nil
    action = .nil
    if arg() == 2 then use strict arg variables, action
    else if arg() == 1, arg(1)~isA(.doer) then use strict arg action
    else if arg() == 1, arg(1)~isA(.directory) then use strict arg variables
    else raise syntax 93.900 array("Closure : Invalid arguments")
    if variables == .nil, action <> .nil,  action~isA(.RexxContextualSource) then variables = action~context~variables
    if variables <> .nil then do
        !_variableNames_! = ""
        do v over variables
            !_variableNames_! ||= " "v
        end
        self~initVariables(variables)
    end
    if action <> .nil then do
        method = action~doer
        self~setMethod("do", method, "Object")
    end

::method initVariables
    expose !_variableNames_! (!_variableNames_!)
    use strict arg variables
    supplier = variables~supplier
    do while supplier~available
        call value supplier~index, supplier~item
        supplier~next
    end

::method setMethod public -- override the private setMethod inherited from Object
    forward class (super)

::method doer unguarded
    use strict arg -- none
    return self

::method needsObject unguarded
    return .false -- The closure itself is the object

::method doWith unguarded
    use strict arg array
    forward message "do" arguments (array)


-----------------------------------------------------------------------------
-- Helper for source analysis & transformation.

/*
The Clauser works directly on the source array passed at creation.
It returns only non-empty clauses (unless you modify a clause, see below).
You can modify the source array by replacing the current clause by a new one :
    myClauser~clause = mySourceFragment
The new clause is inserted as-is and not iterated over by the clauser.
Of course, you can create a new clauser using the modified source, and
then you will iterate over your modified clauses.
While you don't call ~nextClause, ~clause will return the last assigned value,
which can be anything, like an empty string or a string containing several clauses.

Exemple :

------------------------------------
csource = {
    clause1

    clause2 ; clause3
    clause4 ; ;
    clause5a, -- comment
    clause5b /* multiline
    comment */ clause5c ; clause6
}
sourceArray = csource~source -- Each time you call this method, you get a copy of the original source literal

say "Iterate over the original source :"
i = 1
do sourceLine over sourceArray
    say i '"'sourceLine'"'
    i +=1
end

say
say "Iterate over the clauses, surround clause2, remove clause3, shrink clause5:"
clauser = .Clauser~new(sourceArray) -- The clauser works directly on this source array, no copy
i = 1
do while clauser~clauseAvailable
    clause = clauser~clause
    if clause~match(1, "clause2") then clauser~clause = "clause2 before ; "clause" ; clause2 after"
    if clause~match(1, "clause3") then clauser~clause = ""
    if clause~match(1, "clause5") then clauser~clause = "clause5"
    say i '"'clause'" --> "'clauser~clause'"'
    clauser~nextClause
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
clauser = .Clauser~new(sourceArray)
i = 1
do while clauser~clauseAvailable
    clause = clauser~clause
    say i '"'clause'"'
    clauser~nextClause
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
6 "    clause5a, -- comment"
7 "    clause5b /* multiline"
8 "    comment */ clause5c ; clause6"

Iterate over the clauses, surround clause2, remove clause3, shrink clause5:
1 "clause1" --> "clause1"
2 "clause2" --> "clause2 before ; clause2 ; clause2 after"
3 "clause3" --> ""
4 "clause4" --> "clause4"
5 "clause5a     clause5b  clause5c" --> "clause5"
6 "clause6" --> "clause6"

Iterate over the modified source :
1 ""
2 "    clause1"
3 ""
4 "clause2 before ; clause2 ; clause2 after;"
5 "    clause4 ; ;"
6 "clause5"
7 ""
8 "; clause6"

Iterate over the clauses of the modified source :
1 "clause1"
2 "clause2 before"
3 "clause2"
4 "clause2 after"
5 "clause4"
6 "clause5"
7 "clause6"
*/

::class "Clauser" public

-- Special characters : Must be more than one char, to never be equal to a source char
::constant CLAUSEEND_EOF 10
::constant CLAUSEEND_EOL 11
::constant CONTINUATION 12

::constant TOKEN_EOC 1
::constant TOKEN_OTHER 2

::method init
    expose sourceArray buffer
    use strict arg sourceArray
    self~gotoLine(sourceArray~first)
    buffer = .MutableBuffer~new
    self~nextClause

::method clauseAvailable
    expose clause
    return clause <> .nil

::method clause
    expose clause
    if \ self~clauseAvailable then raise syntax 937
    return clause

-- Replace the current clause by the new source fragment (black box, can be several clauses, won't be scanned)
-- The new source fragment is always monoline
-- The new source fragment is always inserted in the first line of the current clause.
-- If the current clause is multiline, then the remaining lines are made empty.
::method "clause="
    expose sourceArray sourceLine lineNum lineOffset lineLength clauseStartLine clauseStartOffset clauseEndLine clauseEndOffset clause
    if \ self~clauseAvailable then raise syntax 937
    use strict arg newSourceFragment
    if clauseStartLine == clauseEndLine then do
        oldLength = clauseEndOffset - clauseStartOffset + 1
        newLength = newSourceFragment~length
        sourceArray[clauseStartLine] = sourceArray[clauseStartLine]~replaceAt(newSourceFragment, clauseStartOffset, oldLength)
        if lineNum == clauseStartLine then do
            lineOffset += newLength - oldLength -- continue AFTER the new source fragment
            self~gotoLine(lineNum, lineOffset)
        end
        clauseEndOffset = clauseStartOffset + newLength - 1
    end
    else do
        sourceArray[clauseStartLine] = sourceArray[clauseStartLine]~left(clauseStartOffset - 1) || newSourceFragment
        line = sourceArray~next(clauseStartLine)
        do while line <> .nil, line < clauseEndLine
            sourceArray[line] = ""
            line = sourceArray~next(line)
        end
        -- In the last line, remove the part of the current clause
        source = sourceArray[clauseEndLine]
        oldLength = source~length
        source = source~substr(clauseEndOffset + 1)
        newLength = source~length
        sourceArray[clauseEndLine] = source
        if lineNum == clauseEndLine then do
            lineOffset += newLength - oldLength -- continue AFTER the new source fragment
            self~gotoLine(lineNum, lineOffset)
        end
        -- The clause is now monoline
        clauseEndLine = clauseStartLine
        clauseEndOffset = sourceArray[clauseStartLine]~length
    end
    clause = newSourceFragment -- If you recall ~clause then you will get the modified clause

::method nextClause -- next non empty stripped clause
    expose lineNum lineOffset clauseStartLine clauseStartOffset buffer clause
    do while lineNum <> .nil
        buffer~delete(1)
        clauseStartLine = lineNum
        clauseStartOffset = lineOffset
        do until token == self~TOKEN_EOC
            token = self~sourceNextToken
        end
        clause = buffer~string~strip
        if clause <> "" then return
    end
    clause = .nil

::method gotoLine private
    expose sourceArray sourceLine lineNum lineOffset lineLength
    use strict arg lineNum, lineOffset=1
    if lineNum == .nil then return .false
    sourceLine = sourceArray[lineNum]
    lineLength = sourceLine~length
    return .true

::method gotoNextLine private
    expose sourceArray lineNum
    lineNum = sourceArray~next(lineNum)
    return self~gotoLine(lineNum)

-- ooRexx adaptation of method RexxSource::comment in interpreter/parser/scanner.cpp
::method skipComment private
    --Scan source to skip over a nest of comments
    expose sourceLine lineNum lineOffset lineLength
    level = 1 -- start the comment nesting
    lineOffset += 2 -- step over the comment start
    do while level > 0 --while still in a comment nest
        if lineOffset > lineLength then do -- hit the end of a line?
            if \ self~gotoNextLine then raise syntax 93.900 array("Unmatched comment delimiter /*)")
            iterate
        end
        inch = sourceLine~subchar(lineOffset)
        lineOffset += 1
        if inch == '*' & sourceLine~subchar(lineOffset) == '/' then do
            level -= 1
            lineOffset += 1
        end
        else if inch == '/' & sourceLine~subchar(lineOffset) == '*' then do
            level += 1
            lineOffset += 1
        end
    end

-- ooRexx adaptation of method RexxSource::locateToken in interpreter/parser/scanner.cpp
::method locateToken private
    -- Locate next significant token in source, skipping extra blanks and comments.
    expose sourceArray sourceLine lineNum lineOffset lineLength
    if lineNum == .nil then character = self~CLAUSEEND_EOF
    else if lineOffset > lineLength then character = self~CLAUSEEND_EOL
    else do
        do while lineOffset <= lineLength
            inch = sourceLine~subchar(lineOffset)
            if inch == ' ' | inch == '09'x then do
                character = ' '
                leave
            end
            -- possible continuation character?
            else if inch == ',' | inch == '-' then do
                -- line comment?
                if inch == '-' & sourceLine~subchar(lineOffset + 1) == '-' then do
                    lineOffset = lineLength + 1 -- skip the remaining characters of the line
                    leave
                end
                character = inch -- assume for now real character
                -- check for EOL (possibly following blanks and comments)
                startOffset = lineOffset
                startLine = lineNum
                lineOffset += 1
                do while lineOffset <= lineLength
                    inch2 = sourceLine~subchar(lineOffset)
                    if inch2 == '/' & sourceLine~subchar(lineOffset + 1) == '*' then do
                        self~skipComment
                        iterate
                    end
                    if inch2 == '-' & sourceLine~subchar(lineOffset + 1) == '-' then do
                        lineOffset = lineLength + 1
                        leave
                    end
                    if inch2 <> ' ' & inch2 <> '09'x then leave
                    lineOffset += 1
                end
                if lineOffset > lineLength then do -- continuation
                    nextLineNum = sourceArray~next(lineNum)
                    if nextLineNum <> .nil then do
                        self~gotoLine(nextLineNum)
                        character = self~CONTINUATION
                        leave
                    end
                end
                else do -- real character
                    self~gotoLine(startLine)
                    lineOffset = startOffset
                    character = inch
                    leave
                end
            end
            else if inch == '/' & sourceLine~subchar(lineOffset + 1) == '*' then self~skipComment
            else do
                character = inch -- this is a good character
                leave
            end
        end
        if lineOffset > lineLength then character = self~CLAUSEEND_EOL
    end
    return character

-- ooRexx adaptation of method RexxSource::nextSpecial in interpreter/parser/scanner.cpp
::method nextSpecial private
    -- Find the next special character and verify against a target
    expose sourceLine lineOffset
    use strict arg target
    inch = self~locateToken -- find the next token
    -- have something else on this line?
    if inch <> self~CLAUSEEND_EOF & inch <> self~CLAUSEEND_EOL then do
        if sourceLine~subchar(lineOffset) == target then do
            lineOffset +=1
            return .true
        end
    end
    return .false

-- ooRexx adaptation of a subset of method RexxSource::sourceNextToken in interpreter/parser/scanner.cpp
-- I don't need to get ALL the tokens, I just need to skip them correctly (in particular strings and
-- source literal). The comments and continuation characters are also properly supported.
-- Possible result : .nil (end of source), TOKEN_EOC (end of clause), TOKEN_OTHER
-- The clause is built incrementally, accumulating all the characters, except comments.
-- The line continuations are removed, replaced by a blank.
-- So a clause is always monoline, even if it's distributed on several lines in the source.
::method sourceNextToken
    expose sourceLine lineNum lineOffset lineLength clauseEndLine clauseEndOffset buffer
    do forever
        inch = self~locateToken
        if inch == self~CLAUSEEND_EOF then return .nil
        else if inch == self~CLAUSEEND_EOL then do
            clauseEndLine = lineNum
            clauseEndOffset = lineLength
            self~gotoNextLine
            return self~TOKEN_EOC
        end
        else if inch == self~CONTINUATION then do
            buffer~append(' ')
            return self~TOKEN_OTHER
        end
        else do
            -- [don't manage symbols, not needed]
            -- start of a quoted string? [don't manage the suffix type xXbB]
            if inch == "'" | inch == '"' then do
                buffer~append(inch)
                literalDelimiter = inch
                do forever
                    lineOffset += 1
                    if lineOffset > lineLength then do
                        -- Unmatched quote
                        if literalDelimiter == "'" then raise syntax 93.900 array("Unmatched single quote")
                        raise syntax 93.900 array("Unmatched double quote")
                    end
                    inch = sourceLine~subchar(lineOffset)
                    buffer~append(inch)
                    if literalDelimiter == inch then do
                        lineOffset += 1
                        if lineOffset > lineLength then leave
                        inch = sourceLine~subchar(lineOffset)
                        if inch <> literalDelimiter then leave
                        buffer~append(inch)
                    end
                end
            end
            else do
                lineOffset += 1
                if inch == '}' then raise syntax 93.900 array("Unexpected }")
                -- start of a source literal?
                else if inch == '{' then do
                    buffer~append(inch)
                    do forever
                        if self~nextSpecial('}') then do
                            buffer~append('}')
                            leave
                        end
                        if self~sourceNextToken == .nil then do
                            raise syntax 93.900 array("Curly bracket { requires a corresponding right curly bracket }")
                        end
                    end
                end
                else if inch == ';' then do
                    clauseEndLine = lineNum
                    clauseEndOffset = lineOffset - 2 -- the offset of the character before ';'
                    return self~TOKEN_EOC
                end
                else do
                    buffer~append(inch)
                end
            end
        end
        return self~TOKEN_OTHER
    end

::routine isAssignment
    use strict arg str
    left1 = str~left(1)
    left2 = str~left(2)
    left3 = str~left(3)
    if left2 == "==" then return .false
    if left1 == "=" then return .true
    if "+= -= *= /= %= &= |="~pos(left2) <> 0 then return .true
    if "//= ||= &&="~pos(left3) <> 0 then return .true
    return .false

