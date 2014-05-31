::requires "pipeline/pipe.rex"
::requires "extension/extensions.cls"
--::options trace i

/*
I wanted to support something like that : "a"|.upper|.console
where the first '|' is an overriden operator which injects any object in the pipe.
But can't do that because :
- extension does not override existing methods ('|' already exists on .String).
- even if '|' overriding was possible, the injection wouldn't be possible from the
  overriden '|' because it's too early... The expression above is in fact
  ("a"|.upper)|.console
  so an injection made by ("a"|.upper) wouldn't reach |.console.
So I added the 'pipe' method which injects the object in the pipe :
"a"~pipe(.upper|.console)
*/

::routine pipe
    use strict arg object, pipe, profile

    -- case 1 : permuting combinator, to reverse the normal order of evaluation.
    -- the expression read consistently from left to right.
    -- f(x~m1) can be rewritten x~m1~pipe{f(item)}
    if pipe~isA(.doer) then do
        if pipe~hasMethod("functionDoer") then doer = pipe~functionDoer("use arg item")~arity(1)
                                            else doer = pipe~doer
        doer~do(object)
        if var("result") then return result -- trush Txy = yx : reverse evaluation.
        return object                       -- kestrel Kxy = x : return a constant function.
    end

    -- case 2 : normal pipe.
    if pipe~isa(.class) then pipe = pipe~new
    pipe~go(object, profile)
    return pipe

::routine coactivePipe
    use strict arg object, pipe, profile
    return {::closure.coactive
            expose object pipe profile
            return object~pipe(pipe, profile)
           }~doer


::extension Class

-- Must review the extension mechanisms ! Not normal to have to do that...
::method pipe class unguarded
    use strict arg pipe, profile=.false
    return pipe(self, pipe, profile)

-- Must review the extension mechanisms ! Not normal to have to do that...
::method coactivePipe class unguarded
    use strict arg pipe, profile=.false
    return coactivePipe(self, pipe, profile)

::extension Object

-- Must review the extension mechanisms ! Not normal to have to do that...
::method pipe class unguarded
    use strict arg pipe, profile=.false
    return pipe(self, pipe, profile)

-- Must review the extension mechanisms ! Not normal to have to do that...
::method coactivePipe class unguarded
    use strict arg pipe, profile=.false
    return coactivePipe(self, pipe, profile)

::method pipe unguarded
    use strict arg pipe, profile=.false
    return pipe(self, pipe, profile)

::method coactivePipe unguarded
    use strict arg pipe, profile=.false
    return coactivePipe(self, pipe, profile)

::method pipeProfile unguarded
    use strict arg pipe
    return self~pipe(pipe, .true)

::method coactivePipeProfile unguarded
    use strict arg pipe
    return coactivePipe(self, pipe, .true)


/******************************************************************************/
-- A 'yield' pipeStage, to yield the current item.
-- Works only from a coactive pipe.
-- This is a convenience pipeStage, equivalent to .do {.yield[item]}

::extension yield inherit pipeStage

::method process
use strict arg item, index, dataflow        -- get the data item
args = arg(1, "a") -- save the current arguments array because .yield will overwrite it
.yield[item]
forward class (super) arguments (args)


/******************************************************************************/
-- An 'append' pipeStage to copy items from its primary input to its primary output,
-- and then invoke the producer passed as argument and write the items produced by
-- that producer to its primary output.

/*
Unlike .inject, there is no input value for .append, so iterateBefore is not needed.
The option iterate (no need of 'After') is automatically activated when the producer is a coactivity :
1~pipe(.append {::coactivity i=10; do 5; .yield[i]; i+=1; end} | .console)
    1 : 1
    1 : 10
    2 : 11
    3 : 12
    4 : 13
    5 : 14
*/
::class "append" public subclass pipeStage

::method initOptions
    expose iterate producer
    iterate = .false
    producer = .nil
    unknown = .array~new
    do a over arg(1, "a")
        if a~isA(.String) then do
            if "iterate"~caselessAbbrev(a, 1) then do ; iterate = .true ; iterate ; end
        end
        else do
            if .nil <> producer then raise syntax 93.900 array(self~class~id ": Only one producer is supported")
            -- if doer then parse now, to detect possible errors before running the pipe.
            -- "actionDoer" not candidate here, we want a result.
            -- "functionDoer" : no need of args (called from ~eof, not from ~process).
            if a~hasMethod("functionDoer") then producer = a~functionDoer
            else if a~hasMethod("doer") then producer = a~doer
            else producer = a -- will be used as a supplier (if capable) or as a single item
            iterate
        end
        unknown~append(a)
    end
    if .nil == producer then raise syntax 93.900 array(self~class~id ": No producer specified")
    forward class (super) arguments (unknown)   -- forward the initialization to super to process the unknown options


::method eof
    expose iterate producer
    if producer~isA(.coactivity) then iterate = .true
    else if producer~hasMethod("do") then do
            producer~do
            if var("result") then producer = result
        end
    -- Similar to .pipeStage~begin :
    if iterate, producer~hasMethod("supplier") then do
        supplier = producer~supplier
        do while supplier~available, \self~isEOP
            self~process(supplier~item, supplier~index, .nil)
            -- Similar to .pipeStage~begin :
            -- Matter of choice : should I stay on current item or get the next item before leaving ?
            -- Current choice works good for coactivities : no lost item when piping directly the coactivity
            -- to several pipes. But if you pass the same supplier to several pipes then you have to call
            -- ~next if you don't want to get the last processed item again.
            if self~isEOP then leave
            supplier~next -- get the next data item
        end
    end
    else do
        self~process(producer, 1, .nil)
    end
    forward class(super) -- make sure we propagate the done message


/******************************************************************************/
-- An 'inject' pipeStage to inject the items generated by a producer in the pipeline.
-- The producer is calculated for each processed item by a doer.
-- When using the option 'recursive.memorize', the intermediate dataflows calculated
-- during recursive calls are pushed onto the initial dataflow.

::class "inject" public subclass pipeStage

::method init
expose allowCommands
use strict arg allowCommands=.false -- by default, the doer is a function whose result is never used as command
self~init:super

::method initOptions
    expose after allowCommands before detectCycles doer iterateBefore iterateAfter limit once recursive depthFirst recursiveMemorize trace
    after = .false
    before = .false
    depthFirst = .true
    detectCycles = .false
    doer = .nil
    iterateBefore = .false
    iterateAfter = .false
    limit = -1
    once = .false
    recursive = .false
    recursiveMemorize = .false
    trace = .false
    unknown = .array~new
    do a over arg(1, "a")
        if a~isA(.String) then do
            parse var a first "." rest
            if "after"~caselessAbbrev(a, 1) then do ; after = .true ; iterate ; end
            if "before"~caselessAbbrev(a, 1) then do ; before = .true ; iterate ; end
            if "iterateBefore"~caselessAbbrev(a, 8) then do ; iterateBefore = .true ; iterate ; end
            if "iterateAfter"~caselessAbbrev(a, 8) then do ; iterateAfter = .true ; iterate ; end
            if "once"~caselessAbbrev(a, 1) then do ; once = .true ; iterate ; end
            if "recursive"~caselessAbbrev(first, 1) then do
                -- recursive[.limit|.depthFirst|.breadthFirst|.cycles|.memorize]*
                recursive = .true
                do while rest <> ""
                    parse var rest first "." rest
                    if first~dataType("W") then limit = first
                    else if "breadthFirst"~caselessAbbrev(first, 1) then depthFirst = .false
                    else if "cycles"~caselessAbbrev(first, 1) then detectCycles = .true
                    else if "depthFirst"~caselessAbbrev(first, 1) then depthFirst = .true
                    else if "memorize"~caselessAbbrev(first, 3) then do ; recursiveMemorize = .true ; self~memorize = .true ; end
                    else raise syntax 93.900 array(self~class~id ": Expected 'breadthFirst' or 'cycles' or 'depthFirst' or 'memorize' after "first". in "a)
                end
                iterate
            end
            if "trace"~caselessAbbrev(a, 1) then do ; trace = .true ; iterate ; end
            unknown~append(a)
            iterate -- do that now, otherwise you will enter in the doer section
        end
        if allowCommands, a~hasMethod("actionDoer") then do
            if .nil <> doer then raise syntax 93.900 array(self~class~id ": Only one producer is supported")
            doer = a~actionDoer("use arg item, index, dataflow")
            iterate
        end
        if a~hasMethod("functionDoer") then do
            if .nil <> doer then raise syntax 93.900 array(self~class~id ": Only one producer is supported")
            doer = a~functionDoer("use arg item, index, dataflow")~arity(3)
            iterate
        end
        if a~hasMethod("doer") then do
            if .nil <> doer then raise syntax 93.900 array(self~class~id ": Only one producer is supported")
            doer = a~doer
            iterate
        end
        unknown~append(a)
    end
    if .nil == doer then raise syntax 93.900 array(self~class~id ": No producer specified")
    forward class (super) arguments (unknown) -- forward the initialization to super to process the unknown options

::method newDataflow
    -- Overload default method, called by ~write and ~writeSecondary
    expose initialDataflow recursiveMemorize trace
    -- not a block do...end, to not see the 'end' in the trace output
    if trace then .traceOutput~say("       >I> Method .inject~newDataflow")
    if trace then trace i
    use strict arg previousDataflow, item, index
    if recursiveMemorize then do
        newDataflow = .dataflow~create(previousDataflow, self, item, index)
    end
    else do
        newDataflow = initialDataflow
        if self~memorize then newDataflow = .dataflow~create(initialDataflow, self, item, index)
    end
    return newDataflow

::method processDepthFirst.3 private
    expose detectCycles limit once recursive trace
    -- not a block do...end, to not see the 'end' in the trace output
    if trace then .traceOutput~say("       >I> Method .inject~processDepthFirst.3")
    if trace then trace i
    use strict arg item, index, dataflow, previousItems, stack, depth
    if once, previousItems~hasItem(item) then do -- don't send twice an item
        -- Send it to secondary output, which receives the abandonned items
        self~writeSecondary(item, index, dataflow)
        if .nil <> result then dataflow = result
        self~checkEOP(self~next, self~secondary)
        return
    end
    if recursive & depth <> limit then do
        if detectCycles then do
            if \ stack~hasItem(item) then do -- Recurse only if not already processed
                self~write(item, index, dataflow)
                if .nil <> result then dataflow = result
                self~checkEOP(self~next, self~secondary)
                if once then previousItems~append(item)
                stack~push(item)
                self~processDepthFirst.1(item, index, dataflow, previousItems, stack, depth+1)
                stack~pull
            end
            else do
                -- Send it to secondary output, which receives the abandonned items
                -- Here, no management of "once".
                self~writeSecondary(item, index, dataflow)
                if .nil <> result then dataflow = result
                self~checkEOP(self~next, self~secondary)
                return
            end
        end
        else do
            self~write(item, index, dataflow)
            if .nil <> result then dataflow = result
            self~checkEOP(self~next, self~secondary)
            if once then previousItems~append(item)
            self~processDepthFirst.1(item, index, dataflow, previousItems, stack, depth+1)
        end
    end
    else do
        self~write(item, index, dataflow)
        if .nil <> result then dataflow = result
        self~checkEOP(self~next, self~secondary)
        if once then previousItems~append(item)
    end

::method processDepthFirst.2 private
    expose doer iterateAfter passIndex trace
    -- not a block do...end, to not see the 'end' in the trace output
    if trace then .traceOutput~say("       >I> Method .inject~processDepthFirst.2")
    if trace then trace i
    if self~isEOP then return
    use strict arg item, index, dataflow, previousItems, stack, depth
    doer~do(item, index, dataflow)
    if \ var("result") then return -- no result returned, nothing to inject
    doResult = result
    -- Similar to .pipeStage~begin :
    if iterateAfter, doResult~hasMethod("supplier") then do
        supplier = doResult~supplier
        do while supplier~available, \self~isEOP
            self~processDepthFirst.3(supplier~item, supplier~index, dataflow, previousItems, stack, depth)
            supplier~next
        end
    end
    else self~processDepthFirst.3(doResult, index, dataflow, previousItems, stack, depth)

::method processDepthFirst.1 private
    expose iterateBefore trace
    -- not a block do...end, to not see the 'end' in the trace output
    if trace then .traceOutput~say("       >I> Method .inject~processDepthFirst.1")
    if trace then trace i
    use strict arg item, index, dataflow, previousItems, stack, depth=0
    if iterateBefore, item~hasMethod("supplier") then do
        supplier = item~supplier
        do while supplier~available, \self~isEOP
            self~processDepthFirst.2(supplier~item, supplier~index, dataflow, previousItems, stack, depth)
            supplier~next
        end
    end
    else self~processDepthFirst.2(item, index, dataflow, previousItems, stack, depth)


::method processBreadthFirst.3 private
    expose detectCycles limit once recursive trace
    -- not a block do...end, to not see the 'end' in the trace output
    if trace then .traceOutput~say("       >I> Method .inject~processBreadthFirst.3")
    if trace then trace i
    use strict arg item, index, dataflow, toprocess, previousItems, stack, depth
    if once, previousItems~hasItem(item) then do -- don't send twice an item
        -- Send it to secondary output, which receives the abandonned items
        self~writeSecondary(item, index, dataflow)
        if .nil <> result then dataflow = result
        self~checkEOP(self~next, self~secondary)
        return
    end
    if recursive & depth <> limit then do
        if detectCycles then do
            if \ stack~hasItem(item) then do -- Recurse only if not already processed
                self~write(item, index, dataflow)
                if .nil <> result then dataflow = result
                self~checkEOP(self~next, self~secondary)
                if once then previousItems~append(item)
                stack~push(item)
                toprocess~queue(item)
                toprocess~queue(index)
                toprocess~queue(dataflow)
                toprocess~queue(stack~copy) -- must remember the stack to detect cycles
                stack~pull
            end
            else do
                -- Send it to secondary output, which receives the abandonned items
                -- Here, no management of "once".
                self~writeSecondary(item, index, dataflow)
                if .nil <> result then dataflow = result
                self~checkEOP(self~next, self~secondary)
            end
        end
        else do
            self~write(item, index, dataflow)
            if .nil <> result then dataflow = result
            self~checkEOP(self~next, self~secondary)
            if once then previousItems~append(item)
            toprocess~queue(item)
            toprocess~queue(index)
            toprocess~queue(dataflow)
            toprocess~queue(depth+1)
        end
    end
    else do
        self~write(item, index, dataflow)
        if .nil <> result then dataflow = result
        self~checkEOP(self~next, self~secondary)
        if once then previousItems~append(item)
    end

::method processBreadthFirst.2 private
    expose doer iterateAfter trace
    -- not a block do...end, to not see the 'end' in the trace output
    if trace then .traceOutput~say("       >I> Method .inject~processBreadthFirst.2")
    if trace then trace i
    use strict arg item, index, dataflow, toprocess, previousItems, stack, depth
    doer~do(item, index, dataflow)
    if \ var("result") then return -- no result returned, nothing to inject
    doResult = result
    -- Similar to .pipeStage~begin :
    if iterateAfter, doResult~hasMethod("supplier") then do
        supplier = doResult~supplier
        do while supplier~available, \self~isEOP
            self~processBreadthFirst.3(supplier~item, supplier~index, dataflow, toprocess, previousItems, stack, depth)
            supplier~next
        end
    end
    else do
        self~processBreadthFirst.3(doResult, index, dataflow, toprocess, previousItems, stack, depth)
    end

::method processBreadthFirst.1 private
    expose detectCycles iterateBefore trace
    -- not a block do...end, to not see the 'end' in the trace output
    if trace then .traceOutput~say("       >I> Method .inject~processBreadthFirst.1")
    if trace then trace i
    use strict arg item, index, dataflow, previousItems, stack
    toprocess = .queue~new
    depth = 0
    do while \self~isEOP
        if iterateBefore, item~hasMethod("supplier") then do
            supplier = item~supplier
            do while supplier~available, \self~isEOP
                self~processBreadthFirst.2(supplier~item, supplier~index, dataflow, toprocess, previousItems, stack, depth)
                supplier~next
            end
        end
        else self~processBreadthFirst.2(item, index, dataflow, toprocess, previousItems, stack, depth)
        if self~isEOP then leave
        if toprocess~isEmpty then leave
        item = toprocess~pull
        index = toprocess~pull
        dataflow = toprocess~pull
        if detectCycles then do
            stack = toprocess~pull
            depth = stack~items
        end
        else depth = toprocess~pull
    end

::method process
    expose after before depthFirst detectCycles doer initialDataflow once trace
    -- not a block do...end, to not see the 'end' in the trace output
    if trace then .traceOutput~say("       >I> Method .inject~process")
    if trace then do -- additional info
        .traceOutput~say("-"~copies(20))
        .traceOutput~say(doer~source~tostring)
        .traceOutput~say("-"~copies(20))
    end
    if trace then trace i
    use strict arg item, index, initialDataflow
    if after then do
        self~write(item, 1, initialDataflow)
        self~checkEOP(self~next, self~secondary)
    end
    if self~isEOP then return
    previousItems = .nil
    if once then previousItems = .array~new
    stack = .nil
    if detectCycles then stack = .queue~new
    if depthFirst then self~processDepthFirst.1(item, index, initialDataflow, previousItems, stack)
                  else self~processBreadthFirst.1(item, index, initialDataflow, previousItems, stack)
    if self~isEOP then return
    if before then do
        self~write(item, 1, initialDataflow)
        self~checkEOP(self~next, self~secondary)
    end


/******************************************************************************/
-- A 'do' pipeStage to execute an action passed as argument.
-- CAREFULL ! There is NO automatic insertion of the "return" instruction, and
-- the commands are authorized here, so DON'T FORGET the "return" instruction
-- if you want to return a value !!!!
-- Ex : assuming item==10
-- .do {2*item} will not insert 20 in the pipeline, but will instead run the command "20".

::class "do" public subclass inject

::method init
use strict arg -- none
self~init:super(.true) -- allow commands


/******************************************************************************/
-- A 'select' pipeStage to execute a boolean filter passed as argument.

::class "select" public subclass pipeStage

::method initOptions
    expose doer
    doer = .nil
    unknown = .array~new
    do a over arg(1, "a")
        if a~isA(.String) then nop
        else do
            -- "actionDoer" not candidate here, we want a result.
            if a~hasMethod("functionDoer") then doer = a~functionDoer("use arg item, index, dataflow")~arity(3)
                                           else doer = a~doer
            iterate
        end
        unknown~append(a)
    end
    if .nil == doer then raise syntax 93.900 array(self~class~id ": No filter specified")
    forward class (super) arguments (unknown)   -- forward the initialization to super to process the unknown options

::method process
    expose doer
    use strict arg item, index, dataflow
    if doer~do(item, index, dataflow) then do   -- apply the filter to the data item
        self~write(item, index, dataflow)       -- the selected items are sent
    end
    else do
        self~writeSecondary(item, index, dataflow) -- send all not selected items down the other branch, if there
    end
    self~checkEOP(self~next, self~secondary)


/******************************************************************************/
-- A 'fileTree' pipeStage to get the childrens (files or directories) of the current item.
-- The input item can be a string (used as a path) or a .File instance.
-- Use the option 'recursive' to search subdirectories recursively.

::class "fileTree" public subclass inject

::method initOptions
    producer = {
        use arg item -- index, dataflow : not needed
        if \item~isA(.File) then item = .File~new(item~string)
        childs = item~listFilesIfNotSymbolicLink -- don't dereference symbolic links
        if .nil <> childs then return childs
    }~doer -- get the doer now, to avoid application of functionDoer later
    args = arg(1, "a")
    args~append(producer)
    args~append("iterateAfter")
    forward class (super) arguments (args)


/******************************************************************************/
-- A 'superClass' pipeStage to get the superClasses of the current item.
-- The input item must be a .Class instance.
-- By default, return the immediate superclasses.
-- Use the option 'recursive' to get all the superclasses up to the root .Object.

::class "superClasses" public subclass inject

::method initOptions
    producer = {use arg item ; return item~superclasses}~doer -- get the doer now, to avoid application of functionDoer later
    args = arg(1, "a")
    args~append(producer)
    args~append("iterateAfter")
    forward class (super) arguments (args)


/******************************************************************************/
-- A 'subClass' pipeStage to get the subClasses of the current item.
-- The input item must be a .Class instance.
-- By default, return the immediate subclasses.
-- Use the option 'recursive' to get all the subclasses up to the leaves.

::class "subClasses" public subclass inject

::method initOptions
    producer = {use arg item ; return item~subclasses}~doer -- get the doer now, to avoid application of functionDoer later
    args = arg(1, "a")
    args~append(producer)
    args~append("iterateAfter")
    forward class (super) arguments (args)


/******************************************************************************/
-- A 'class.instanceMethods' pipeStage to get the methods of the current item.
-- The input item must be a .Class instance.
-- Returns only the instance methods defined by the item.

-- The initial name was "methods" but this class name hidded the .methods environment symbol.
::class "class.instanceMethods" public subclass inject

::method initOptions
    producer = {use arg item ; return item~methods(.nil)}~doer -- get the doer now, to avoid application of functionDoer later
    args = arg(1, "a")
    args~append(producer)
    args~append("iterateAfter")
    forward class (super) arguments (args)


/******************************************************************************/
-- An 'instanceMethods' pipeStage to get the instanceMethods of the current item.
-- The input item can be any object.
-- Returns the instances methods defined by the item's class.

::class "instanceMethods" public subclass inject

::method initOptions
    producer = {use arg item ; return item~instanceMethods(item~class)}~doer -- get the doer now, to avoid application of functionDoer later
    args = arg(1, "a")
    args~append(producer)
    args~append("iterateAfter")
    forward class (super) arguments (args)


/******************************************************************************/
-- An 'importedPackages' pipeStage to get the packages imported by the current item.
-- The input item must be a .Package instance.

::class "importedPackages" public subclass inject

::method initOptions
    producer = {use arg item ; return item~importedPackages}~doer -- get the doer now, to avoid application of functionDoer later
    args = arg(1, "a")
    args~append(producer)
    args~append("iterateAfter")
    forward class (super) arguments (args)

