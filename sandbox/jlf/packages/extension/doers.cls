/*
This script needs a modified ooRexx interpreter which support extension of predefined ooRexx classes.
*/

--::options trace i
::options NOMACROSPACE
::requires "concurrency/coactivity.cls"


-----------------------------------------------------------------------------
-- Mixin.
/*
    A DoerFactory is an object which knows how to create a doer.
    A doer can be created from :
    - a RexxBlock :
      At parse-time, the interpreter creates a raw executable (always a routine) from the source.
      At runtime, an executable is created using the raw executable.
      No cost if the executable is a routine, slight cost if the executable is a Coactivity or a Closure, to create the wrapper.
    - an executable (Routine or Method) :
      No cost, this is for convenience, the doer is the executable itself.
    - a wrapper of executable (Coactivity, Closure) :
      No cost, this is for convenience, the doer is the wrapper itself.

    Examples :
    See doers-samples.rex
*/

::class "DoerFactory" mixinclass Object public

::method doer abstract


-----------------------------------------------------------------------------
-- Mixin.
-- A Doer is an object which knows how to execute itself (understands "do")
-- This is an abstraction of routine, method, message, coactivity, closure.

::class "Doer" mixinclass Object public inherit DoerFactory

::method needsObject abstract
::method do abstract
::method doWith abstract
::method source abstract


-- Used by higher-order functions, to decide which arguments to pass
::method arity unguarded
    expose arity
    if arg() <> 0 then do
        guard on
        use strict arg arity -- store the arity
        return self -- for convenience, return the doer itself
    end
    else if \var("arity") then return -1 -- unknown arity
    else return arity


-- Tilde call
::method "~()" unguarded
    forward message "do"


-- This method allows to pass named arguments without using the dedicated syntax.
-- I use it in rgf_util2.rex and pipe.rex to keep then compatible with ooRexx 4.2
-- Note that offical ooRexx5 supports the dedicated syntax, but only because it's
-- the syntax for namespaces. So nothing to see with named arguments!
::method doWithNamedArguments unguarded
    use arg key, value, ...
    array = .array~new
    directory = .directory~new
    -- The same arguments are passed as positional and named arguments.
    -- The callee is free to use what's the most convenient for him.
    do i = 1 to arg() by 2
        key = arg(i)
        value = arg(i+1)
        array~append(value)
        directory[key] = value
    end
    forward message "do" arguments (array) namedArguments (directory)


::method go unguarded
    --return self~startWith("do", .context~args, n:.context~namedArgs)
    forward message "startWith" array("do", .context~args, n:.context~namedArgs)


::method goWith unguarded
    --return self~startWith("doWith", .context~args, n:.context~namedArgs)
    forward message "startWith" array("doWith", .context~args, n:.context~namedArgs)


/*
http://en.wikipedia.org/wiki/Tail_call#Through_trampolining
A trampoline is a technique to transform recursive calls into a sequence of calls
to doers. Instead of returning the result, the doer returns a doer which returns
the result. While the result returned by the doer is a doer, the result is called.
The loop is ended when the result is not a doer.

Ex :
    say {say "one" ; return {say "two" ; return "three"}}~trampoline -- one two three

Ex :
    factorial = {
        use strict arg n, accu=1
        if n <= 1 then return accu
        executable = .context~executable
        return {
            expose n accu executable
            return executable~(n-1, n*accu)
        }
    }
    say factorial~trampoline(1000000) -- 8.26394406E+5565708
*/

::method trampoline unguarded
    doer = self
    forward message "do" to (doer) continue -- any number of arguments supported for the first call
    if \var("result") then return
    v = result
    -- The test \v~needsObject lets eliminate the StringDoers (and the MethodDoers, but the point is on StringDoers) :
    -- when you return a String, you don't want the error "Not enough arguments in method; 1 expected".
    do while v~isA(.Doer), \v~needsObject
        v~do -- here, no args. Most of the time, v will be a closure which holds all the needed informations.
        if \var("result") then return
        v = result
    end
    return v


/*
http://en.wikipedia.org/wiki/Partial_application
Returns a closure which remembers the arguments passed to ~partial.
When this closure is called with the remaining arguments, a whole positional argument array is
built from both positional argument lists (partial and remaining) and passed to the target of
~partial.

Ex :
    add10 = "+"~partial(10)
    say add10~(1) -- 11

Ex :
    /*
    The ~partial method takes care of the omitted positional arguments.
    In this example, "-"~partial(, 10), a partial array is created, which keeps the first arg omitted :
    +---+----+
    |   | 10 |
    +---+----+
    When you do sub10~(1) then 1 goes into the first free cell :
    +---+----+
    | 1 | 10 |
    +---+----+
    */

    sub10 = "-"~partial(, 10)
    say sub10~(1) -- -9

    /*
    That's the same principle with more omitted positional arguments :
    - any omitted argument when calling ~partial will create an empty cell.
    - any omitted argument when calling a partial closure (returned by ~partial) will remain an omitted argument :
      the first free cell remains empty and the next empty cell becomes the first free cell.
    - a non empty cell is always skipped.
    */
        block = {do a over arg(1, "a") ; .output~charout(a" ") ; end; say}
        partial1 = block~partial( , , 3, , , 6, , , 9)
        -- +---+---+---+---+---+---+---+---+---+
        -- |   |   | 3 |   |   | 6 |   |   | 9 |
        -- +---+---+---+---+---+---+---+---+---+
        partial1~() -- 3 6 9
        partial2 = partial1~partial( , 2, , 5, , 8, , 11)
        -- +---+---+---+---+---+---+---+---+---+----+----+
        -- |   | 2 | 3 |   | 5 | 6 |   | 8 | 9 |    | 11 |
        -- +---+---+---+---+---+---+---+---+---+----+----+
        partial2~() -- 2 3 5 6 8 9 11
        partial2~(1, 4, 7, 10, 12) -- 1 2 3 4 5 6 7 8 9 10 11 12
        -- +---+---+---+---+---+---+---+---+---+----+----+----+
        -- | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
        -- +---+---+---+---+---+---+---+---+---+----+----+----+

Ex :
    myArguments = .context~package~findRoutine("myArguments")
    p1 = myArguments~partial(1,,3,,5)
    p1~()                               -- 1:1 3:3 5:5
    p1~(2,,6)                           -- 1:1 2:2 3:3 5:5 6:6
    p1~(2,4,6,,8)                       -- 1:1 2:2 3:3 4:4 5:5 6:6 8:8
    p2 = myArguments~partial(,,3,4)
    p2~()                               -- 3:3 4:4
    p2~(2,,6)                           -- 1:2 3:3 4:4 5:6
    p2~(2,4,6,,8)                       -- 1:2 2:4 3:3 4:4 5:6 7:8
    ::routine myArguments
        arg(1, "a")~each{call charout, index":"item" "}
        say
    ::requires "extension/extensions.cls"
*/

::method partial unguarded
    args1 = .context~args
    namedArgs1 = .context~namedArgs
    return {expose args1 namedArgs1 self
            args2 = .context~args
            namedArgs2 = .context~namedArgs
            args = partialMergeArrays(args1, args2)
            namedArgs = mergeDirectoriesInPlace(namedArgs1, namedArgs2)
            -- Must forward explicitely to (self) otherwise stack overflow because forwarded to the closure itself.
            forward message "do" arguments (args) namedArguments (namedArgs) to (self)
           }~doer


::method compose class
    use named arg verbose=.false
    if verbose then trace i
    if arg() == 0 then return .nil
    doers = .queue~new
    do i=1 to arg()
        if arg(i, "e") then doers~push(arg(i))
    end
    return {
        expose doers verbose
        if verbose then trace i
        doer = doers~pull
        -- The first doer can take any number of positional & named arguments
        -- If no named argument "item" has been passed, then at least one positional argument is needed
        namedArgs = .context~namedArgs
        if \ namedArgs~hasIndex("ITEM") then do
            -- By convention, the first positional argument is also passed as the named argument "item"
            use strict arg item, ...
            namedArgs["ITEM"] = item
        end
        if arg() >= 1 then do
            arg1 = arg(1)
            if arg1 <> item then raise syntax 93.900 array ("When the positional parameter ITEM is provided then it must be equal to the first positional argument")
            arg1a = arg(1, "a")
            arg2a = arg(2, "a")
        end
        else do
            arg1 = item
            arg1a = .array~of(item)
            arg2a = .array~of()
        end
        if doer~needsObject then doer~doWith(arg1, arg2a, n:namedArgs)
        else doer~doWith(arg1a, n:namedArgs)
        r = arg1
        if var("result") then r = result
        if .nil == r then return .nil -- stop now
        doer = doers~pull
        -- The following doers take only one positional argument: the result returned by the previous doer
        do while .nil <> doer
            doer~do(r, item:r)
            -- use the current result if any, otherwise use the previous result (that allow to use a doer to display intermediate value, for example)
            if var("result") then r = result
            if .nil == r then return .nil -- stop now
            doer = doers~pull
        end
        return r
    }


::routine partialMergeArrays
    use strict arg args1, args2
    size2 = args2~size
    if size2 == 0 then args = args1
    else do
        args = args1~copy
        index1 = 1
        index2 = 1
        do while index2 <= size2
            do while args~hasIndex(index1)
                index1 += 1
            end
            if args2~hasIndex(index2) then args[index1] = args2[index2]
            index1 += 1
            index2 += 1
        end
    end
    return args


::routine mergeDirectoriesInPlace
    -- dir1 is updated in place with the elements of dir2
    use strict arg dir1, dir2
    size2 = dir2~items
    if size2 == 0 then return dir1
    dir2indexes = dir2~allIndexes
    dir2items = dir2~allItems
    do i=1 to size2
        dir1~put(dir2items[i], dir2indexes[i])
    end
    return dir1


-----------------------------------------------------------------------------
-- Mixin.

::class "RoutineDoer" mixinclass Object public inherit Doer

::method doer unguarded
    use strict arg -- none
    return self


::method needsObject unguarded
    return .false -- No need to pass an object as first argument when calling do or doWith


::method do unguarded
    forward message "call"


::method doWith unguarded
    forward message "callWith"


/*
    Inspired by http://mvanier.livejournal.com/2897.html.
    Y = λf.(λx.f (λv.((x x) v))) (λx.f (λv.((x x) v)))

    (define Y
      (lambda (f)
        ( (lambda (x) (f (lambda (v) ((x x) v))))
          (lambda (x) (f (lambda (v) ((x x) v)))))))

    Equivalent form:

    (define Y
      (lambda (f)
        ( (lambda (a) (a a))
          (lambda (x) (f (lambda (v) ((x x) v)))))))

    The Y combinator allows recursion to be defined as a set of rewrite rules.
    It takes a single argument, which is a function that isn't recursive (JLF: here, no argument, use self which is a Doer).
    It returns a version of the function which is recursive.

    Example :
        say {use arg f; return {expose f; use arg n; if n==0 then return 1; else return n * f~(n-1) } }~Y~(10)

    Remember: ooRexx supports anonymous recursion, no need of the Y combinator in the real life...
        say { use arg n; if n==0 then return 1; else return n * .context~executable~(n-1)}~(10)
*/
::method Y unguarded
    use named arg verbose=.false
    if verbose then trace i

    -- lambda_f
    f = self -- to be closer to the notation (would be passed by parameter to lambda_f when implemented by a function instead of a method)
    YnamedArgs = .context~namedArgs

    lambda_x = {
        expose f verbose YnamedArgs
        if verbose then trace i
        use strict arg x
        lambda_v = {
                     expose x verbose
                     if verbose then trace i
                     --use strict arg v
                     v = arg(1, "a")
                     return x~(x)~doWith(v, n:.context~namedArgs)
                }
        return f ~ doWith(.array~of(lambda_v), n:YnamedArgs)
    }
    return lambda_x ~ (lambda_x)


-- Y combinator with memoization
::method YM unguarded
    use named arg verbose=.false
    if verbose then trace i

    -- lambda_f
    f = self -- to be closer to the notation (would be passed by parameter to lambda_f when implemented by a function instead of a method)
    YnamedArgs = .context~namedArgs
    table = .Table~new

    lambda_x = {
        expose f verbose YnamedArgs table
        if verbose then trace i
        use strict arg x
        lambda_v = {
                     expose x verbose table
                     if verbose then trace i
                     --use strict arg v
                     v = arg(1, "a")
                     v_index = v~tostring
                     r = table[v_index]
                     if .nil <> r then return r
                     r = x~(x)~doWith(v, n:.context~namedArgs)
                     table[v_index] = r
                     return r
                }
        return f ~ doWith(.array~of(lambda_v), n:YnamedArgs)
    }
    return lambda_x ~ (lambda_x)


/*
    For illustration, a routine implemented like this Python implementation
    (copied from https://qntm.org/variadic)

    def Y(func):
        def Y2(x):
            def Y3(*args, **kwargs):
                return x(x)(*args, **kwargs)
            return func(Y3)
        return Y2(Y2)
*/
::routine Y public
    use strict arg func
    Y2 = {
        expose func
        use strict arg x
        Y3 = {
                     expose x
                     args = .context~args
                     kwargs = .context~namedArgs
                     return x~(x)~doWith(args, n:kwargs)
                }
        return func~(Y3)
    }
    return Y2~(Y2)

-----------------------------------------------------------------------------
-- Mixin.

/*
    Remember :
    The method 'run' is a private method. So can be called only from another method of object...
    "hello"~run(aMethod) --> Error: Object "hello" does not understand message "RUN" (ok, 'run' is private)
    aMethod~do("hello") --> No error, display "hello" (so the private method is visible ?)
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
    forward to (object) message "run" array (self, "a", arg(2,"a"), n:.context~namedArgs~~remove("ITEM"))


::method doWith unguarded
    use strict arg object, array
    use strict named arg namedArguments(1) = (.nil)
    forward to (object) message "run" array (self, "a", array, n:namedArguments)


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
    forward to (object) message "sendWith" array (self, arg(2,"a"), n:.context~namedArgs~~remove("ITEM"))


::method doWith unguarded
    use strict arg object, array
    use strict named arg namedArguments(1) = (.nil)
    forward to (object) message "sendWith" array (self, array, n:namedArguments)


::method source unguarded
    return self -- When used as a doer, a string is a message. Assume the message is the source.


-----------------------------------------------------------------------------
-- Mixin.

::class "RexxBlockDoer" mixinclass Object public inherit DoerFactory Doer

/*
    Big picture :

    a RexxSourceLiteral is an internal rexx object, created by the parser, not accessible from ooRexx scripts.
    a RexxSourceLiteral holds the following properties, shared by all the RexxBlock instances created from it :
    - source: the text between the curly brackets {...} as an array of lines, including the tag ::xxx if any.
    - package: the package which contain the source literal.
    - kind: kind of source, derived from the source's tag.
    - rawExecutable: routine or method created at parse-time (immediate parsing) after transformation of the source.
    The source is transformed to accept auto named arguments, and to return implicitely the result of the last evaluated expression.
    Source before transformation: ...
    Source after transformation: use auto name arg ; option "NOCOMMANDS";...;if var("result") then return result

    a RexxBlock is created each time the RexxSourceLiteral is evaluated, and is accessible from ooRexx scripts.
    a RexxBlock contains informations that depends on the evaluation context.
    In particular, when a RexxBlock is a closure's source, it will hold a snapshot of the context's variables.
    ~source: source of the RexxSourceLiteral before transformation.
    ~variables: snapshot of the context's variables (a directory), created only if the source starts with "expose".
    ~rawExecutable: the raw executable of the RexxSourceLiteral, created at parse-time (routine or method).
    ~executable: cached executable, managed by doers.cls.

    Example:
        blocks=.array~new
        loop i=1 to 10
            blocks~append{expose i; say i}          -- At each loop, the RexxSourceLiteral is evaluated and a new
                                                    -- instance of RexxBlock is created, with its own snapshot
                                                    -- of variables (the variable 'i' is different at each loop).
                                                    -- This snapshot is the closure.
        end
        blocks~each{item~()} -- display 1 to 10     -- here the closure is finalized by ~doer and cached on the RexxBlock.
        blocks~each{item~()} -- display 1 to 10     -- here the closure cached on the RexxBlock is reused.
*/

::method init
    expose executable
    executable = .nil
    self~init:super


::method doer unguarded
    expose executable
    if .nil <> executable then return executable

    use strict arg -- none
    executable = self~sourceDoer

    -- The arity can be set on the RexxBlock before calling ~doer.
    -- If already set (<> -1) then this arity will be stored on the executable
    -- otherwise the arbitrary value 9999 is stored on the executable.
    -- The arity of the RexxBlock is unchanged.
    arity = self~arity
    if arity == -1 then arity = 9999
    executable~arity(arity)

    return executable


::method executable unguarded
    expose executable
    return executable


/*
    Helper to create a doer from a source, after transformation of the source if requested.
    Possible transformations :
    - Insert a clause at the begining (takes care of the expose instruction, keep it always as
      first instruction).
    - Insert a clause at the end.
*/
::method sourceDoer unguarded
    use strict arg clauseBefore="", clauseAfter="", context=.nil
    if .nil == context then context = self~package -- lookup scope

    kind = self~kind
    rawExecutable = self~rawExecutable -- set at parse time
    if clauseBefore <> "" | clauseAfter <> "" | .nil == rawExecutable then do
        sourceArray = self~source -- always an array, even if empty or just one line
        clauser = .Clauser~new(sourceArray)
        kind = clauser~kind(remove: .true) -- do that before the transformation, to remove the keywords that declares the kind of the source
        clauser~transformSource(clauseBefore, clauseAfter)
        rawExecutable = .Clauser~rawExecutable(kind, sourceArray, context)
        -- Note that the rawExecutable of the RexxBlock is unchanged.
    end

    -- Returns the executable
    if kind == "r" then return rawExecutable
    else if kind == "r.co" then return .Coactivity~new(rawExecutable)
    else if kind == "cl" then return .Closure~new(self~variables, rawExecutable)
    else if kind == "cl.co" then return .Coactivity~new(.Closure~new(self~variables, rawExecutable))
    return .nil -- should never happen


-- Even if unknown is defined, must explicitely provide a concrete implementation because abstract
::method needsObject unguarded
    forward to (self~doer)


-- Even if unknown is defined, must explicitely provide a concrete implementation because abstract
::method do unguarded
    forward to (self~doer)


-- Even if unknown is defined, must explicitely provide a concrete implementation because abstract
::method doWith unguarded
    forward to (self~doer)


/*
    I want to support that (no ~doer in the following expression) :
                                                                                                ****
        1~pipe(.inject {{::coactivity expose item ; do forever ; .yield[item] ; item += 1 ; end}} iterateAfter | .take 10 | .console)
                                                                                                ****
    In this example, the block passed to .inject returns another block whose doer is a coactivity.
    The option "iterateAfter" checks if the current item has the "supplier" method. If yes, then it iterates over the items returned by the supplier.
    A RexxBlock has no "supplier" method, but its doer may have one. This is the case in this example.
    Without this redefinition, I should write :
                                                                                                ****
        1~pipe(.inject {{::coactivity expose item ; do forever ; .yield[item] ; item += 1 ; end}~doer} iterateAfter | .take 10 | .console)
                                                                                                ****
*/
::method hasMethod unguarded
    use strict arg methodName
    if self~hasMethod:super(methodName) then return .true
    forward to (self~doer)


/*
    Normally, it's not a good idea to define an "unknown" method on a mixin class...
    But here, I think it's ok to do that...
    I find more natural to support directly blocks in the following samples (no need to send the message ~doer to the block) :
    {::coactivity i=1 ; do forever; .yield[i]; i += 1 ; end}~take(5)~iterator~each{say item}
    {::coactivity i=1 ; do forever; .yield[i]; i += 1 ; end}~select{item//2 == 0}~take(5)~iterator~each{say item}
*/
::method unknown unguarded
    use arg msg, args
    use named arg namedArguments(1)
    forward message (msg) arguments (args) namedArguments (namedArguments) to (self~doer)


-----------------------------------------------------------------------------
-- Mixin.

::class "CoactivityDoer" mixinclass Object public inherit Doer

::method doer unguarded
    use strict arg -- none
    return self


::method needsObject unguarded
    return .false -- No need to pass an object as first argument when calling do or doWith


::method do unguarded
    forward message "resume"


::method doWith unguarded
    use strict arg array
    use strict named arg namedArguments(1) = (.nil)
    forward message "resume" arguments (array) namedArguments(namedArguments)


::method source unguarded
    return self~executable~source


-----------------------------------------------------------------------------
-- Closure by value: not yet a real closure but useful anyway
-- (assuming that only closures by reference are real closures...)
-- good point, no risk of race conditions...

/*
A closure is an object, created from a block whose source first word after the optional tag is "expose".

A closure remembers the values of the variables defined in the outer environment of the block.
The behaviour of the closure is a method generated from the block, which is attached to
the closure under the name "do". The values of the captured variables are accessible from
this method "do" using expose. Updating a variable from the closure will have no impact on
the original context (hence the name "closure by value").
A closure can be passed as argument, or returned as result.


Examples :
    v = 1                      -- captured, belongs to the outer environment of the following blocks
    {expose v ; say v}~doer~do -- display 1
    {expose v ; say v}~do      -- display 1 (implicit call to ~doer)
    {expose v ; say v}~()      -- display 1 (alternative notation, more functional)


    range = { use arg min, max ; return { expose min max ; use arg num ; return min <= num & num <= max }}
    from5to8 = range~(5, 8)
    from20to30 = range~(20, 30)
    say from5to8~(6) -- 1
    say from5to8~(9) -- 0
    say from20to30~(6) -- 0
    say from20to30~(25) -- 1

    /*
    The first block can be rewritten as a routine, no more nested blocks, but the code is less compact,
    and the order less natural (you discover the definition of the routine after the place from where it's called).
    The inner block is an object (RexxBlock) returned by the routine.
    */
    from5to8 = range(5, 8) -- function call, here no tilde
    say from5to8~(6) -- from5to8 is a RexxBlock to which the message "~()" is sent
    ::routine range
    use arg min, max
    return { expose min max ; use arg num ; return min <= num & num <= max }
*/

::class "Closure" public inherit Doer

::method init
    expose !_closure.variableNames_!
    use strict arg variables=.nil, action=.nil
    if .nil <> variables then do
        !_closure.variableNames_! = ""
        do v over variables
            !_closure.variableNames_! ||= " "v
        end
        self~initVariables(variables)
    end
    if .nil <> action then do
        method = action~doer
        self~setMethod("do", method, "Object")
    end


::method initVariables
    expose !_closure.variableNames_! (!_closure.variableNames_!)
    -- Must use variable names that will not collide with user-defined variables
    use strict arg !_closure.variables_!
    !_closure.supplier_! = !_closure.variables_!~supplier
    do while !_closure.supplier_!~available
        call value !_closure.supplier_!~index, !_closure.supplier_!~item
        !_closure.supplier_!~next
    end


/*
::method setMethod public unguarded -- override the private setMethod inherited from Object to make it public
    forward class (super)
*/


::method doer unguarded
    use strict arg -- none
    return self


::method needsObject unguarded
    return .false -- The closure itself is the object


::method doWith unguarded
    use strict arg array
    use strict named arg namedArguments(1) = (.nil)
    forward message "do" arguments (array) namedArguments(namedArguments)


::method source unguarded
    doMethod = self~instanceMethod("do")
    if .nil == doMethod then return .nil
    return doMethod~source


::method variables unguarded -- must be unguarded otherwise deadlock when the closure is the executable of a running coactivity
    expose !_closure.variableNames_! (!_closure.variableNames_!)
    -- Must use variable names that will not collide with user-defined variables
    !_closure.directory_! = .Directory~new
    do !_closure.variableName_! over !_closure.variableNames_! ~ subwords
        !_closure.directory_! ~ put(value(!_closure.variableName_!), !_closure.variableName_!)
    end
    return !_closure.directory_!
