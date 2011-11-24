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

::extension Class

-- Must review the extension mechanisms ! Not normal to have to do that...
::method pipe class
    use strict arg pipe, profile=.false
    if pipe~isa(.class) then pipe = pipe~new
    pipe~go(self, profile)
    return pipe

::extension Object

-- Must review the extension mechanisms ! Not normal to have to do that...
::method pipe class
    use strict arg pipe, profile=.false
    if pipe~isa(.class) then pipe = pipe~new
    pipe~go(self, profile)
    return pipe

::method pipe
    use strict arg pipe, profile=.false
    if pipe~isa(.class) then pipe = pipe~new
    pipe~go(self, profile)
    return pipe

::method pipeProfile
    use strict arg pipe
    return self~pipe(pipe, .true)


/******************************************************************************/
-- Convenience notation :
-- .index_value[index, value, index, value, ...]
-- .value_index[value, index, value, index, ...]
-- are useful with .inject and .do

::class "index_value" public

::method "[]" class
forward to (self) message("of")

::method of class
    use strict arg index, value, ...
    table = .Table~new -- potential problem : .Table is not an ordered collection
    do i = 1 to arg() by 2
        table[arg(i)] = arg(i+1)
    end
    return table


::class "value_index" public

::method "[]" class
forward to (self) message("of")

::method of class
    use strict arg value, index, ...
    table = .Table~new -- potential problem : .Table is not an ordered collection
    do i = 1 to arg() by 2
        table[arg(i+1)] = arg(i)
    end
    return table


/******************************************************************************/
-- An 'append' pipeStage to copy items from its primary input to its primary output,
-- and then invoke the producer passed as argument and write the items produced by
-- that producer to its primary output.

::class "append" public subclass pipeStage

::method initOptions
    expose producer
    producer = .nil    
    unknown = .array~new
    do a over arg(1, "a")
        if a~isA(.String) then nop
        else do
            if producer <> .nil then raise syntax 93.900 array(self~class~id ": Only one producer is supported")
            -- if doer then parse now, to detect possible errors before running the pipe.
            -- "actionDoer" not candidate here, we want a result.
            -- "functionDoer" : no need of args (called from ~eof, not from ~process).
            if a~hasMethod("functionDoer") then producer = a~functionDoer
            else if a~hasMethod("doer") then producer = a~doer
            else producer = a -- will be used as a supplier (if capable) or as a single value
            iterate
        end
        unknown~append(a)
    end
    if producer == .nil then raise syntax 93.900 array(self~class~id ": No producer specified")
    forward class (super) arguments (unknown)   -- forward the initialization to super to process the unknown options


::method eof
    expose producer
    if producer~hasMethod("do") then producer = producer~do
    -- Similar to .pipeStage~begin :
    if \producer~hasMethod("supplier") then do
        index = .pipeIndex~create(self~class~id, .nil, source, 1)
        self~process(producer, index)
    end
    else do
        supplier = producer~supplier
        do while supplier~available, \self~isEOP
            index = .pipeIndex~create(self~class~id, .nil, producer, supplier~index) -- always created (no alternative to forward)
            self~process(supplier~item, index)
            -- Similar to .pipeStage~begin :
            -- Matter of choice : should I stay on current item or get the next item before leaving ?
            -- Current choice works good for coactivities : no lost item when piping directly the coactivity
            -- to several pipes. But if you pass the same supplier to several pipes then you have to call
            -- ~next if you don't want to get the last processed item again.
            if self~isEOP then leave
            supplier~next -- get the next data item
        end
    end
    forward class(super) -- make sure we propagate the done message


/******************************************************************************/
-- An 'inject' pipeStage to inject the items produced by a producer in the pipeline.
-- The producer is calculated for each processed value bye a doer.
-- When using the option 'recursive.memorizeIndex', the intermediate indexes calculated
-- during recursive calls are pushed onto the initial index.
-- Format of an intermediate index :
--     current input value,
--     user-defined local indexes, (optional, single value or array of values, returned using .index_value or .value_index)
--     position of the current result calculated with the current input value.

::class "inject" public subclass pipeStage

::method init
expose allowCommand
use strict arg allowCommand=.false -- by default, the doer is a function whose result is never used as command
self~init:super

::method initOptions
    expose allowCommand doer recursive limit depthFirst before after recursiveMemorizeIndex detectCycles unique trace
    doer = .nil
    recursive = .false
    limit = -1
    depthFirst = .true
    detectCycles = .false
    before = .false
    after = .false
    recursiveMemorizeIndex = .false
    unique = .false
    trace = .false
    unknown = .array~new
    do a over arg(1, "a")
        if a~isA(.String) then do
            parse var a first "." rest
            if "after"~caselessAbbrev(a, 1) then do ; after = .true ; iterate ; end
            if "before"~caselessAbbrev(a, 1) then do ; before = .true ; iterate ; end
            if "recursive"~caselessAbbrev(first, 1) then do
                -- recursive[.limit|.depthFirst|.breadthFirst|.cycles]*
                recursive = .true
                do while rest <> ""
                    parse var rest first "." rest
                    if first~dataType("W") then limit = first
                    else if "breadthFirst"~caselessAbbrev(first, 1) then depthFirst = .false
                    else if "cycles"~caselessAbbrev(first, 1) then detectCycles = .true
                    else if "depthFirst"~caselessAbbrev(first, 1) then depthFirst = .true
                    else if "memorizeIndex"~caselessAbbrev(first, 3) then do ; recursiveMemorizeIndex = .true ; self~memorizeIndex = .true ; end
                    else raise syntax 93.900 array(self~class~id ": Expected 'breadthFirst' or 'cycles' or 'depthFirst' or 'memorizeIndex' after "first". in "a)
                end
                iterate
            end
            if "unique"~caselessAbbrev(a, 1) then do ; unique = .true ; iterate ; end
            if "trace"~caselessAbbrev(a, 1) then do ; trace = .true ; iterate ; end
            unknown~append(a)
            iterate -- do that now, otherwise you will enter in the doer section
        end
        if allowCommand, a~hasMethod("actionDoer") then do
            if doer <> .nil then raise syntax 93.900 array(self~class~id ": Only one producer is supported")
            doer = a~actionDoer("use arg value, index")
            iterate
        end
        if a~hasMethod("functionDoer") then do
            if doer <> .nil then raise syntax 93.900 array(self~class~id ": Only one producer is supported")
            doer = a~functionDoer("use arg value, index")
            iterate
        end
        if a~hasMethod("doer") then do
            if doer <> .nil then raise syntax 93.900 array(self~class~id ": Only one producer is supported")
            doer = a~doer
            iterate
        end
        unknown~append(a)
    end
    if doer == .nil then raise syntax 93.900 array(self~class~id ": No producer specified")
    forward class (super) arguments (unknown) -- forward the initialization to super to process the unknown options

::method newIndex
    expose recursiveMemorizeIndex initialIndex trace
    -- not a block do...end, to not see the 'end' in the trace output
    if trace then .traceOutput~say("       >I> Method .inject~newIndex")
    if trace then trace i
    use strict arg index, value, localIndex, ...
    if recursiveMemorizeIndex then do
        newIndex = .pipeIndex~create(self, index, value)
    end
    else do
        newIndex = initialIndex
        if self~memorizeIndex then newIndex = .pipeIndex~create(self, initialIndex, value)
    end
    if self~memorizeIndex then do
        do a = 3 to arg()
            localIndex = arg(a)
            if \ localIndex~isA(.Array) then newIndex~append(localIndex)
            else do i over localIndex
                newIndex~append(i)
            end
        end
    end
    return newindex

::method processDepthFirstCurrent
    expose recursive limit detectCycles unique trace
    -- not a block do...end, to not see the 'end' in the trace output
    if trace then .traceOutput~say("       >I> Method .inject~processDepthFirstCurrent")
    if trace then trace i
    if self~isEOP then return
    use strict arg value, index, stack, level, previousValues
    if unique then do
        if previousValues~hasItem(value) then do
            self~writeSecondary(value, index)
            self~checkEOP(self~next, self~secondary)
            return
        end
        previousValues~append(value)
    end
    if recursive & level <> limit then do
        if detectCycles then do
            if \ stack~hasItem(value) then do -- Recurse only if not already processed
                self~write(value, index)
                self~checkEOP(self~next, self~secondary)
                stack~push(value)
                self~processDepthFirst(value, index, stack, level+1, previousValues)
                stack~pull
            end
            else do
                self~writeSecondary(value, index)
                self~checkEOP(self~next, self~secondary)
                return
            end
        end
        else do
            self~write(value, index)
            self~checkEOP(self~next, self~secondary)
            self~processDepthFirst(value, index, stack, level+1, previousValues)
        end
    end
    else do
        self~write(value, index)
        self~checkEOP(self~next, self~secondary)
    end

::method processDepthFirst
    expose doer trace
    -- not a block do...end, to not see the 'end' in the trace output
    if trace then .traceOutput~say("       >I> Method .inject~processDepthFirst")
    if trace then trace i
    use strict arg value, index, stack=(.queue~new), level=0, previousValues=(.array~new)
    doer~do(value, index)
    if \ var("result") then return -- no result returned, nothing to inject
    doResult = result -- better to store in user-defined variable, no ?
    -- Similar to .pipeStage~begin :
    if \ doResult~hasMethod("supplier") then do
        newIndex = self~newIndex(index, value, 1)
        self~processDepthFirstCurrent(doResult, newIndex, stack, level, previousValues)
    end
    else do
        userDefined = doResult~isA(.Table) -- Will be .true is .index_value or .value_index has been used : a table is returned
        supplier = doResult~supplier
        do while supplier~available, \self~isEOP
            item = supplier~item
            if userDefined & item~hasMethod("supplier") then do
                -- We are in this case : .inject {.index_value["index", .array~of(...)]}
                -- The goal is to inject each item of the array
                supplier2 = item~supplier
                do while supplier2~available, \self~isEOP
                    item2 = supplier2~item
                    newindex2 = self~newIndex(index, value, supplier2~index, supplier~index)
                    self~processDepthFirstCurrent(item2, newindex2, stack, level, previousValues)
                    supplier2~next
                end
            end
            else do
                newindex = self~newIndex(index, value, supplier~index)
                self~processDepthFirstCurrent(item, newindex, stack, level, previousValues)
            end
            supplier~next
        end
    end

::method processBreadthFirstCurrent2
    expose recursive limit detectCycles trace
    -- not a block do...end, to not see the 'end' in the trace output
    if trace then .traceOutput~say("       >I> Method .inject~processBreadthFirstCurrent2")
    if trace then trace i
    use strict arg value, index, toprocess, stack, level
    if recursive & level <> limit then do
        if detectCycles then do
            if \ stack~hasItem(value) then do -- Recurse only if not already processed
                self~write(value, index)
                self~checkEOP(self~next, self~secondary)
                stack~push(value)
                toprocess~queue(value)
                toprocess~queue(index)
                toprocess~queue(stack~copy)
                stack~pull
            end
            else do
                self~writeSecondary(value, index)
                self~checkEOP(self~next, self~secondary)
            end
        end
        else do
            self~write(value, index)
            self~checkEOP(self~next, self~secondary)
            toprocess~queue(value)
            toprocess~queue(index)
            toprocess~queue(level+1)
        end
    end
    else do
        self~write(value, index)
        self~checkEOP(self~next, self~secondary)
    end

::method processBreadthFirstCurrent
    expose doer trace
    -- not a block do...end, to not see the 'end' in the trace output
    if trace then .traceOutput~say("       >I> Method .inject~processBreadthFirstCurrent")
    if trace then trace i
    use strict arg value, index, toprocess, stack, level
    doer~do(value, index)
    if \ var("result") then return -- no result returned, nothing to inject
    doResult = result -- better to store in user-defined variable, no ?
    -- Similar to .pipeStage~begin :
    if \ doResult~hasMethod("supplier") then do
        newIndex = self~newIndex(index, value, 1)
        self~processBreadthFirstCurrent2(doResult, newIndex, toprocess, stack, level)
    end
    else do
        userDefined = doResult~isA(.Table) -- Will be .true is .index_value or .value_index has been used : a table is returned
        supplier = doResult~supplier
        do while supplier~available, \self~isEOP
            item = supplier~item
            if userDefined & item~hasMethod("supplier") then do
                -- We are in this case : .inject {.index_value["index", .array~of(...)]}
                -- The goal is to inject each item of the array
                supplier2 = item~supplier
                do while supplier2~available, \self~isEOP
                    item2 = supplier2~item
                    newindex2 = self~newIndex(index, value, supplier2~index, supplier~index)
                    self~processBreadthFirstCurrent2(item2, newindex2, toprocess, stack, level)
                    supplier2~next
                end
            end
            else do
                newindex = self~newIndex(index, value, supplier~index)
                self~processBreadthFirstCurrent2(item, newindex, toprocess, stack, level)
            end
            supplier~next
        end
    end

::method processBreadthFirst
    expose detectCycles unique trace
    -- not a block do...end, to not see the 'end' in the trace output
    if trace then .traceOutput~say("       >I> Method .inject~processBreadthFirst")
    if trace then trace i
    use strict arg value, index
    stack = .queue~new
    toprocess = .queue~new
    previousValues = .array~new
    self~processBreadthFirstCurrent(value, index, toprocess, stack, 0)
    do while \toprocess~isEmpty, \self~isEOP
        supplier_item = toprocess~pull
        newindex = toprocess~pull
        if unique then do
            if previousValues~hasItem(supplier_item) then do
                self~writeSecondary(supplier_item, newindex)
                self~checkEOP(self~next, self~secondary)
                iterate
            end
            previousValues~append(supplier_item)
        end
        if detectCycles then stack = toprocess~pull
        else level = toprocess~pull
        self~processBreadthFirstCurrent(supplier_item, newindex, toprocess, stack, level)
    end

::method process
    expose doer depthFirst before after initialIndex trace
    -- not a block do...end, to not see the 'end' in the trace output
    if trace then .traceOutput~say("       >I> Method .inject~process")
    if trace then do -- additional info
        .traceOutput~say("-"~copies(20))
        .traceOutput~say(doer~source~tostring)
        .traceOutput~say("-"~copies(20))
    end
    if trace then trace i
    use strict arg value, initialIndex
    if after then do
        -- follow the same convention as for calculated values.
        -- here, it's like getting a single result from value (result == value, index == 1)
        newIndex = initialIndex
        if self~memorizeIndex then newIndex = .pipeIndex~create(self, initialIndex, value, 1)
        self~write(value, newIndex)
        self~checkEOP(self~next, self~secondary)
    end
    if self~isEOP then return
    if depthFirst then self~processDepthFirst(value, initialIndex)
                  else self~processBreadthFirst(value, initialIndex)
    if self~isEOP then return
    if before then do
        -- follow the same convention as for calculated values.
        -- here, it's like getting a single result from value (result == value, index == 1)
        newIndex = initialIndex
        if self~memorizeIndex then newIndex = .pipeIndex~create(self, initialIndex, value, 1)
        self~write(value, newIndex)
        self~checkEOP(self~next, self~secondary)
    end


/******************************************************************************/
-- A 'do' pipeStage to execute an action passed as argument.
-- CAREFULL ! There is NO automatic insertion of the "return" instruction, and
-- the commands are authorized here, so DON'T FORGET the "return" instruction
-- if you want to return a value !!!!
-- Ex : assuming value==10
-- .do {2*value} will not insert 20 in the pipeline, but will instead run the command "20".

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
            if a~hasMethod("functionDoer") then doer = a~functionDoer("use arg value, index")
                                           else doer = a~doer
            iterate
        end
        unknown~append(a)
    end
    if doer == .nil then raise syntax 93.900 array(self~class~id ": No filter specified")
    forward class (super) arguments (unknown)   -- forward the initialization to super to process the unknown options

::method process
    expose doer
    use strict arg value, index
    newIndex = index
    if self~memorizeIndex then newIndex = .pipeIndex~create(self, index, value)
    if doer~do(value, index) then do             -- apply the filter to the data item
        self~write(value, newIndex)              -- the selected items are sent
    end
    else do
        self~writeSecondary(value, newIndex)     -- send all not selected items down the other branch, if there
    end
    self~checkEOP(self~next, self~secondary)


/******************************************************************************/
-- A 'fileTree' pipeStage to get the childrens (files or directories) of the current value.
-- The input value can be a string (used as a path) or a .File instance.
-- Use the option 'recursive' to search subdirectories recursively.

::class "fileTree" public subclass inject

::method initOptions
    producer = {
        use arg value
        if \value~isA(.File) then value = .File~new(value~string)
        childs = value~listFiles
        if childs <> .nil then return childs
    }~doer -- get the doer now, to avoid application of functionDoer later
    args = arg(1, "a")
    args~append(producer)
    forward class (super) arguments (args)


/******************************************************************************/
-- A 'superClass' pipeStage to get the superClasses of the current value.
-- The input value must be a .Class instance.
-- By default, return the immediate superclasses.
-- Use the option 'recursive' to get all the superclasses up to the root .Object.

::class "superClasses" public subclass inject

::method initOptions
    producer = {use arg value ; return value~superclasses}~doer -- get the doer now, to avoid application of functionDoer later
    args = arg(1, "a")
    args~append(producer)
    forward class (super) arguments (args)


/******************************************************************************/
-- A 'subClass' pipeStage to get the subClasses of the current value.
-- The input value must be a .Class instance.
-- By default, return the immediate subclasses.
-- Use the option 'recursive' to get all the subclasses up to the leaves.

::class "subClasses" public subclass inject

::method initOptions
    producer = {use arg value ; return value~subclasses}~doer -- get the doer now, to avoid application of functionDoer later
    args = arg(1, "a")
    args~append(producer)
    forward class (super) arguments (args)


/******************************************************************************/
-- A 'methods' pipeStage to get the methods of the current value.
-- The input value must be a .Class instance.
-- Returns only the instance methods defined by the value.

::class "methods" public subclass inject

::method initOptions
    producer = {use arg value ; return value~methods(.nil)}~doer -- get the doer now, to avoid application of functionDoer later
    args = arg(1, "a")
    args~append(producer)
    forward class (super) arguments (args)


/******************************************************************************/
-- An 'instanceMethods' pipeStage to get the instanceMethods of the current value.
-- The input value can be any object.
-- Returns the instances methods defined by the value's class.

::class "instanceMethods" public subclass inject

::method initOptions
    producer = {use arg value ; return value~instanceMethods(value~class)}~doer -- get the doer now, to avoid application of functionDoer later
    args = arg(1, "a")
    args~append(producer)
    forward class (super) arguments (args)

