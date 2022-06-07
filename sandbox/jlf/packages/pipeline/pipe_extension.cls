::requires "pipeline/pipe.cls"
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

::routine pipe private
    use strict arg object, pipe /* .pipeStage|.doer */, profile /* .true|.false*/, memorize /* .true|.false */

    -- case 1 : permuting combinator, to reverse the normal order of evaluation.
    -- the expression read consistently from left to right.
    -- f(x~m1) can be rewritten x~m1~pipe{f(item)}
    if pipe~isA(.doer) then do
        doer = pipe~doer
        doer~do(      object,-
                item: object)
        if var("result") then return result -- trush Txy = yx : reverse evaluation.
        return object                       -- kestrel Kxy = x : return a constant function.
    end

    -- case 2 : normal pipe.
    if pipe~isa(.class) then pipe = pipe~new
    pipe~go(object, profile, memorize)
    return pipe


::routine copipe private
    use strict arg object, pipe /* .pipeStage|.doer */, profile /* .true|.false*/, memorize /* .true|.false */
    return {::coactivity
            expose object pipe profile memorize
            object~pipe(pipe, profile, memorize)
            -- remember : don't return something here. The only way to "return" something is by using yield.
            drop result
           }~doer


::extension Object

::method pipe class unguarded
    use strict arg pipe
    use strict named arg profile=.false, memorize(3)=.false -- mem allowed to be consistent with the option "memorize" that can be abbreviated to 3 characters
    return pipe(self, pipe, profile, memorize)


::method copipe class unguarded
    use strict arg pipe
    use strict named arg profile=.false, memorize(3)=.false -- mem allowed to be consistent with the option "memorize" that can be abbreviated to 3 characters
    return copipe(self, pipe, profile, memorize)


::method pipe unguarded
    use strict arg pipe
    use strict named arg profile=.false, memorize(3)=.false -- mem allowed to be consistent with the option "memorize" that can be abbreviated to 3 characters
    return pipe(self, pipe, profile, memorize)


::method copipe unguarded
    use strict arg pipe
    use strict named arg profile=.false, memorize(3)=.false -- mem allowed to be consistent with the option "memorize" that can be abbreviated to 3 characters
    return copipe(self, pipe, profile, memorize)


::method pipeProfile unguarded
    use strict arg pipe
    return self~pipe(pipe, profile:.true, memorize:.false)


::method copipeProfile unguarded
    use strict arg pipe
    return copipe(self, pipe, profile:.true, memorize:.false)


/******************************************************************************/
-- A 'yield' pipeStage, to yield the current item.
-- Works only from a coactive pipe.
-- This is a convenience pipeStage, equivalent to .do {.yield[item]}
-- Options: (['index'] ['item'] [<expression-doer>])*

-- Assumption: The class "yield" is already defined
::extension yield inherit pipeStage

::method init
    use strict arg -- none
    forward class (super)


::method initOptions
    expose actions showPool showTags
    actions = .array~new
    unknown = .array~new
    do a over arg(1, "a")
        if a~isA(.String) then do
            if "index"~caselessAbbrev(a, 1) then do
                actions~append("yieldIndex")
                iterate
            end
            if "item"~caselessAbbrev(a, 1) then do
                actions~append("yieldItem")
                iterate
            end
        end
        else if a~hasMethod("doer") then do
            function = a~doer
            actions~append(function)
            iterate
        end
        unknown~append(a)
    end
    forward class (super) arguments (unknown)   -- forward the initialization to super to process the unknown options


::method process
    expose actions
    use strict arg pipeContext, item, index, dataflow
    args = arg(1, "a") -- save the current arguments array because .yield will overwrite it
    if actions~items == 0 then do
        .yield[item] -- default action
        use strict arg -- none
    end
    else do action over actions
        if action == "yieldIndex" then .yield[index]
        else if action == "yieldItem" then .yield[item]
        else do
            action~do(      item,        index,           dataflow,-
                      item: item, index: index, dataflow: dataflow)
            if \var("result") then do
                -- No result returned, nothing to yield, but the yield must be done, synchronisation is important !
                .yield[]
            end
            else .yield[result]
        end
        use strict arg -- none
    end
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
            -- no need of args (called from ~eof, not from ~process).
            if a~hasMethod("doer") then producer = a~doer
            else producer = a -- will be used as a supplier (if capable) or as a single item
            iterate
        end
        unknown~append(a)
    end
    if .nil == producer then raise syntax 93.900 array(self~class~id ": No producer specified")
    forward class (super) arguments (unknown)   -- forward the initialization to super to process the unknown options


::method eof
    expose iterate producer
    use strict arg pipeContext
    if producer~isA(.coactivity) then iterate = .true
    else if producer~hasMethod("do") then do
            producer~do
            if var("result") then producer = result
        end
    -- Similar to .pipeStage~begin :
    if iterate, producer~hasMethod("supplier") then do
        supplier = producer~supplier
        do while \self~isEOP, supplier~available
            self~process(pipeContext, supplier~item, supplier~index, .nil, "eof")
            -- Similar to .pipeStage~begin :
            -- Matter of choice : should I stay on current item or get the next item before leaving ?
            -- Current choice works good for coactivities : no lost item when piping directly the coactivity
            -- to several pipes. But if you pass the same supplier to several pipes then you have to call
            -- ~next if you don't want to get the last processed item again.
            if \self~isEOP then supplier~next -- when the supplier is a coactivity supplier, it's important to not read the next item
        end
    end
    else do
        self~process(pipeContext, producer, 1, .nil, "eof")
    end
    forward class(super) -- make sure we propagate the done message


/******************************************************************************/
-- An 'inject' pipeStage to inject the items generated by a producer in the pipeline.
-- The producer is calculated for each processed item by a doer.
-- When using the option 'recursive.memorize', the intermediate dataflows calculated
-- during recursive calls are pushed onto the initial dataflow.

::class "inject" public subclass pipeStage

::method init
self~init:super


::method initOptions
    expose after before detectCycles doer iterateBefore iterateAfter limit once recursive depthFirst recursiveMemorize trace
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
                    else raise syntax 93.900 array(self~class~id ": Expected a recursion limit or 'breadthFirst' or 'cycles' or 'depthFirst' or 'memorize', got "first".")
                end
                iterate
            end
            if "trace"~caselessAbbrev(a, 1) then do ; trace = .true ; iterate ; end
            unknown~append(a)
            iterate -- do that now, otherwise you will enter in the doer section
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


::method processDepthFirst.3 private
    expose detectCycles limit once recursive recursiveMemorize trace
    -- not a block do...end, to not see the 'end' in the trace output
    if trace then .traceOutput~say("       >I> Method .inject~processDepthFirst.3")
    if trace then trace i
    use strict arg pipeContext, item, index, dataflow, previousItems, stack, depth
    if once, previousItems~hasItem(item) then do -- don't send twice an item
        -- Send it to secondary output, which receives the abandonned items
        self~writeSecondary(pipeContext, item, index, dataflow)
        if .nil <> result & recursiveMemorize then dataflow = result
        self~checkEOP(self~next, self~secondary)
        return
    end
    if recursive & depth <> limit then do
        if detectCycles then do
            if \ stack~hasItem(item) then do -- Recurse only if not already processed
                self~write(pipeContext, item, index, dataflow)
                if .nil <> result & recursiveMemorize then dataflow = result
                self~checkEOP(self~next, self~secondary)
                if once then previousItems~append(item)
                stack~push(item)
                self~processDepthFirst.1(pipeContext, item, index, dataflow, previousItems, stack, depth+1)
                stack~pull
            end
            else do
                -- Send it to secondary output, which receives the abandonned items
                -- Here, no management of "once".
                self~writeSecondary(pipeContext, item, index, dataflow)
                if .nil <> result & recursiveMemorize then dataflow = result
                self~checkEOP(self~next, self~secondary)
                return
            end
        end
        else do
            self~write(pipeContext, item, index, dataflow)
            if .nil <> result & recursiveMemorize then dataflow = result
            self~checkEOP(self~next, self~secondary)
            if once then previousItems~append(item)
            self~processDepthFirst.1(pipeContext, item, index, dataflow, previousItems, stack, depth+1)
        end
    end
    else do
        self~write(pipeContext, item, index, dataflow)
        if .nil <> result & recursiveMemorize then dataflow = result
        self~checkEOP(self~next, self~secondary)
        if once then previousItems~append(item)
    end


::method processDepthFirst.2 private
    expose doer iterateAfter passIndex trace
    -- not a block do...end, to not see the 'end' in the trace output
    if trace then .traceOutput~say("       >I> Method .inject~processDepthFirst.2")
    if trace then trace i
    if self~isEOP then return
    use strict arg pipeContext, item, index, dataflow, previousItems, stack, depth
    doer~do(      item,        index,           dataflow,-
            item: item, index: index, dataflow: dataflow)
    if \ var("result") then return -- no result returned, nothing to inject
    doResult = result
    -- Similar to .pipeStage~begin :
    if iterateAfter, doResult~hasMethod("supplier") then do
        supplier = doResult~supplier
        do while \self~isEOP, supplier~available
            self~processDepthFirst.3(pipeContext, supplier~item, supplier~index, dataflow, previousItems, stack, depth)
            if \self~isEOP then supplier~next -- when the supplier is a coactivity supplier, it's important to not read the next item
        end
    end
    else do
        -- Bad idea to replace index by 1, that breaks the oorexxShell queries. Was: index is 1 to be consistent with iterateAfter where the index is NOT the previous index
        self~processDepthFirst.3(pipeContext, doResult, index, dataflow, previousItems, stack, depth)
    end


::method processDepthFirst.1 private
    expose iterateBefore trace
    -- not a block do...end, to not see the 'end' in the trace output
    if trace then .traceOutput~say("       >I> Method .inject~processDepthFirst.1")
    if trace then trace i
    use strict arg pipeContext, item, index, dataflow, previousItems, stack, depth=0
    if iterateBefore, item~hasMethod("supplier") then do
        supplier = item~supplier
        do while \self~isEOP, supplier~available
            self~processDepthFirst.2(pipeContext, supplier~item, supplier~index, dataflow, previousItems, stack, depth)
            if \self~isEOP then supplier~next -- when the supplier is a coactivity supplier, it's important to not read the next item
        end
    end
    else do
        -- Bad idea to replace index by 1, that breaks the oorexxShell queries. Was: index is 1 to be consistent with iterateBefore where the index is NOT the previous index
        self~processDepthFirst.2(pipeContext, item, index, dataflow, previousItems, stack, depth)
    end


::method processBreadthFirst.3 private
    expose detectCycles limit once recursive recursiveMemorize trace
    -- not a block do...end, to not see the 'end' in the trace output
    if trace then .traceOutput~say("       >I> Method .inject~processBreadthFirst.3")
    if trace then trace i
    use strict arg pipeContext, item, index, dataflow, toprocess, previousItems, stack, depth
    if once, previousItems~hasItem(item) then do -- don't send twice an item
        -- Send it to secondary output, which receives the abandonned items
        self~writeSecondary(pipeContext, item, index, dataflow)
        if .nil <> result & recursiveMemorize then dataflow = result
        self~checkEOP(self~next, self~secondary)
        return
    end
    if recursive & depth <> limit then do
        if detectCycles then do
            if \ stack~hasItem(item) then do -- Recurse only if not already processed
                self~write(pipeContext, item, index, dataflow)
                if .nil <> result & recursiveMemorize then dataflow = result
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
                self~writeSecondary(pipeContext, item, index, dataflow)
                if .nil <> result & recursiveMemorize then dataflow = result
                self~checkEOP(self~next, self~secondary)
            end
        end
        else do
            self~write(pipeContext, item, index, dataflow)
            if .nil <> result & recursiveMemorize then dataflow = result
            self~checkEOP(self~next, self~secondary)
            if once then previousItems~append(item)
            toprocess~queue(item)
            toprocess~queue(index)
            toprocess~queue(dataflow)
            toprocess~queue(depth+1)
        end
    end
    else do
        self~write(pipeContext, item, index, dataflow)
        if .nil <> result & recursiveMemorize then dataflow = result
        self~checkEOP(self~next, self~secondary)
        if once then previousItems~append(item)
    end


::method processBreadthFirst.2 private
    expose doer iterateAfter trace
    -- not a block do...end, to not see the 'end' in the trace output
    if trace then .traceOutput~say("       >I> Method .inject~processBreadthFirst.2")
    if trace then trace i
    use strict arg pipeContext, item, index, dataflow, toprocess, previousItems, stack, depth
    doer~do(      item,        index,           dataflow,-
            item: item, index: index, dataflow: dataflow)
    if \ var("result") then return -- no result returned, nothing to inject
    doResult = result
    -- Similar to .pipeStage~begin :
    if iterateAfter, doResult~hasMethod("supplier") then do
        supplier = doResult~supplier
        do while \self~isEOP, supplier~available
            self~processBreadthFirst.3(pipeContext, supplier~item, supplier~index, dataflow, toprocess, previousItems, stack, depth)
            if \self~isEOP then supplier~next -- when the supplier is a coactivity supplier, it's important to not read the next item
        end
    end
    else do
        -- Bad idea to replace index by 1, that breaks the oorexxShell queries. Was: index is 1 to be consistent with iterateAfter where the index is NOT the previous index
        self~processBreadthFirst.3(pipeContext, doResult, index, dataflow, toprocess, previousItems, stack, depth)
    end


::method processBreadthFirst.1 private
    expose detectCycles iterateBefore trace
    -- not a block do...end, to not see the 'end' in the trace output
    if trace then .traceOutput~say("       >I> Method .inject~processBreadthFirst.1")
    if trace then trace i
    use strict arg pipeContext, item, index, dataflow, previousItems, stack
    toprocess = .queue~new
    depth = 0
    do while \self~isEOP
        if iterateBefore, item~hasMethod("supplier") then do
            supplier = item~supplier
            do while \self~isEOP, supplier~available
                self~processBreadthFirst.2(pipeContext, supplier~item, supplier~index, dataflow, toprocess, previousItems, stack, depth)
                if \self~isEOP then supplier~next -- when the supplier is a coactivity supplier, it's important to not read the next item
            end
        end
        else do
            -- Bad idea to replace index by 1, that breaks the oorexxShell queries. Was: index is 1 to be consistent with iterateBefore where the index is NOT the previous index
            self~processBreadthFirst.2(pipeContext, item, index, dataflow, toprocess, previousItems, stack, depth)
        end
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
    expose after before depthFirst detectCycles doer once trace
    -- not a block do...end, to not see the 'end' in the trace output
    if trace then .traceOutput~say("       >I> Method .inject~process")
    if trace then do -- additional info
        .traceOutput~say("-"~copies(20))
        .traceOutput~say(doer~source~tostring)
        .traceOutput~say("-"~copies(20))
    end
    if trace then trace i
    use strict arg pipeContext, item, index, dataflow
    if after then do
        self~write(pipeContext, item, index, dataflow, "->-") -- was hardcoded 1, now use index
        self~checkEOP(self~next, self~secondary)
    end
    if self~isEOP then return
    previousItems = .nil
    if once then previousItems = .array~new
    stack = .nil
    if detectCycles then stack = .queue~new
    if depthFirst then self~processDepthFirst.1(pipeContext, item, index, dataflow, previousItems, stack)
                  else self~processBreadthFirst.1(pipeContext, item, index, dataflow, previousItems, stack)
    if self~isEOP then return
    if before then do
        self~write(pipeContext, item, index, dataflow, "->-") -- was hardcoded 1, now use index
        self~checkEOP(self~next, self~secondary)
    end


/******************************************************************************/
-- A 'do' pipeStage to execute an action passed as argument.
-- Same as 'inject', but sometimes the name '.do' is better than ".inject".

::class "do" public subclass inject

::method init
use strict arg -- none
self~init:super


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
            if .nil <> doer then raise syntax 93.900 array(self~class~id ": Only one filter is supported")
            doer = a~doer
            iterate
        end
        unknown~append(a)
    end
    if .nil == doer then raise syntax 93.900 array(self~class~id ": No filter specified")
    forward class (super) arguments (unknown)   -- forward the initialization to super to process the unknown options


::method process
    expose doer
    use strict arg pipeContext, item, index, dataflow
    if doer~do(      item,        index,           dataflow,-
               item: item, index: index, dataflow: dataflow) then do   -- apply the filter to the data item
        self~write(pipeContext, item, index, dataflow)       -- the selected items are sent
    end
    else do
        self~writeSecondary(pipeContext, item, index, dataflow) -- send all not selected items down the other branch, if there
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
    }
    args = arg(1, "a")
    args~append(producer)
    args~append("iterateAfter")
    forward class (super) arguments (args)


/******************************************************************************/
-- A 'superClasses' pipeStage to get the superClasses of the current item.
-- The input item must be a .Class instance.
-- By default, return the immediate superclasses.
-- Use the option 'recursive' to get all the superclasses up to the root .Object.

::class "superClasses" public subclass inject

::method initOptions
    producer = {use arg item ; return item~superclasses}
    args = arg(1, "a")
    args~append(producer)
    args~append("iterateAfter")
    forward class (super) arguments (args)


/******************************************************************************/
-- A 'subClasses' pipeStage to get the subClasses of the current item.
-- The input item must be a .Class instance.
-- By default, return the immediate subclasses.
-- Use the option 'recursive' to get all the subclasses up to the leaves.

::class "subClasses" public subclass inject

::method initOptions
    producer = {use arg item ; return item~subclasses}
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
    producer = {use arg item ; return item~methods(.nil)}
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
    producer = {use arg item ; return item~instanceMethods(item~class)}
    args = arg(1, "a")
    args~append(producer)
    args~append("iterateAfter")
    forward class (super) arguments (args)


/******************************************************************************/
-- An 'importedPackages' pipeStage to get the packages imported by the current item.
-- The input item must be a .Package instance.

::class "importedPackages" public subclass inject

::method initOptions
    producer = {use arg item ; return item~importedPackages}
    args = arg(1, "a")
    args~append(producer)
    args~append("iterateAfter")
    forward class (super) arguments (args)

