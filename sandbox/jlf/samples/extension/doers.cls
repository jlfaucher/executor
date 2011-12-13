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
See doers-samples.rex
*/

::class "DoerFactory" mixinclass Object public

::method doer abstract

/*
Helper to create a doer from a source, after transformation of the source if requested.
Possible transformations :
- Insert a clause at the begining (takes care of the expose instruction, keep it always as
  first instruction).
- Insert a clause at the end.
*/
::method sourceDoer unguarded
    use strict arg clauseBefore="", clauseAfter="", context=.nil, objectSpecified = .false, object = .nil
    if context == .nil then context = self~package -- lookup scope

    kind = self~kind
    rawExecutable = self~rawExecutable
    if clauseBefore <> "" | clauseAfter <> "" | rawExecutable == .nil then do
        sourceArray = self~source -- always an array, even if empty or just one line
        if sourceArray~items == 0 then raise syntax 93.900 array("No source available")
        clauser = .Clauser~new(sourceArray)
        kind = .SourceLiteralParser~kind(clauser)
        
        -- If the clause is an "expose" clause then skip it (must remain the first clause, always)
        if clauser~clauseAvailable then do
            clause = clauser~clause
            parse lower var clause word rest
            if word == "expose" & \ isAssignment(rest) then clauser~nextClause
        end
    
        -- Insert the 'clauseBefore', if any
        if clauseBefore <> "" then do
            if clauser~clauseAvailable then clauser~clause = clauseBefore ";" clauser~clause
            else sourceArray~append(clauseBefore)
        end
    
        -- Insert the 'clauseAfter', if any
        if clauseAfter <> "" then sourceArray~append(clauseAfter)
        
        rawExecutable = .SourceLiteralParser~rawExecutable(kind, sourceArray, context)
    end

    -- Returns the executable
    if kind == "r" then return rawExecutable
    else if kind == "r.c" then return .Coactivity~new(rawExecutable)
    else if kind == "m" then return rawExecutable
    else if kind == "m.c" then do
        if \objectSpecified then raise syntax 93.900 array("No object specified")
        return .Coactivity~new(rawExecutable, , object)
    end
    else if kind == "cl" then return .Closure~new(self~variables, rawExecutable)
    else if kind == "cl.c" then return .Coactivity~new(.Closure~new(self~variables, rawExecutable))
    return .nil -- should never happen


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


-----------------------------------------------------------------------------
-- Mixin.
-- A Doer is an object who knows how to execute itself (understands "do")
-- This is an abstraction of routine, method, message, coactivity.

::class "Doer" mixinclass Object public inherit DoerFactory

::method needsObject abstract
::method do abstract
::method doWith abstract

-- Tilde call
::method "~()" unguarded
    forward message "do" to (self~doer)


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

-- Needed if you want to run sourceDoer on a string.
::method rawExecutable
    return .nil -- no raw executable

-- Needed if you want to run sourceDoer on a string
::method kind
    return "" -- unknown


-----------------------------------------------------------------------------
-- Mixin.

::class "RexxContextualSourceDoer" mixinclass Object public inherit Doer

::method doer unguarded
    use strict arg object=.nil -- optional object, needed when the source is tagged ::method.coactive
    if self~executable <> .nil then return self~executable
    objectSpecified = arg(1, "e") -- object explicitely passed ?
    self~executable = self~sourceDoer( , , , objectSpecified, object)
    return self~executable

-- Could be defined on DoerFactory to give access to this functionality from any doer,
-- but that's probably a bad idea. Other doers are directly executable (except String
-- when using sourceDoer - but that's deprecated) and I consider that the "shortest source"
-- criteria doesn't apply to them. So they will have already the right arguments and an
-- explicit return, if needed.
::method functionDoer unguarded
    use strict arg clauseBefore="", clauseAfter="", object=.nil-- optional object, needed when the source is tagged ::method.coactive
    objectSpecified = arg(3, "e") -- object explicitely passed ?
    -- Don't activate next line ! You may have an executable because the code is parsable, but which needs transformations anyway
    -- if self~executable <> .nil then return self~executable
    clauseBefore ||= ' ; options "NOCOMMANDS"'
    clauseAfter ||= ' ; if var("result") then return result'
    self~executable = self~sourceDoer(clauseBefore, clauseAfter, , objectSpecified, object)
    return self~executable

-- Same remark as above.
::method actionDoer unguarded
    use strict arg clauseBefore="", clauseAfter="", object=.nil-- optional object, needed when the source is tagged ::method.coactive
    objectSpecified = arg(3, "e") -- object explicitely passed ?
    -- Don't activate next line ! You may have an executable because the code is parsable, but which needs transformations anyway
    -- if self~executable <> .nil then return self~executable
    self~executable = self~sourceDoer(clauseBefore, clauseAfter, , objectSpecified, object)
    return self~executable

::method needsObject unguarded
    forward to (self~doer)

::method do unguarded
    forward to (self~doer)

::method doWith unguarded
    forward to (self~doer)


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
-- (assuming that only closures by reference are real closures...)
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

::method setMethod public -- override the private setMethod inherited from Object to make it public
    forward class (super)

::method doer unguarded
    use strict arg -- none
    return self

::method needsObject unguarded
    return .false -- The closure itself is the object

::method doWith unguarded
    use strict arg array
    forward message "do" arguments (array)

