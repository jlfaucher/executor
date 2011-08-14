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
    source = self
    if \source~hasMethod("supplier") then source = .array~of(source)
    pipe~go(source, profile)
    return pipe

::extension Object

-- Must review the extension mechanisms ! Not normal to have to do that...
::method pipe class
    use strict arg pipe, profile=.false
    if pipe~isa(.class) then pipe = pipe~new
    source = self
    if \source~hasMethod("supplier") then source = .array~of(source)
    pipe~go(source, profile)
    return pipe

::method pipe
    use strict arg pipe, profile=.false
    if pipe~isa(.class) then pipe = pipe~new
    source = self
    if \source~hasMethod("supplier") then source = .array~of(source)
    pipe~go(source, profile)
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
    table = .table~new
    do i = 1 to arg() by 2
        table[arg(i)] = arg(i+1)
    end
    return table


::class "value_index" public

::method "[]" class
forward to (self) message("of")

::method of class
    use strict arg value, index, ...
    table = .table~new
    do i = 1 to arg() by 2
        table[arg(i+1)] = arg(i)
    end
    return table


/******************************************************************************/
-- An append pipeStage to copy items from its primary input to its primary output,
-- and then invoke the supplier passed as argument and write the items produced by
-- that supplier to its primary output.

::class "append" public subclass pipeStage

::method initOptions
    expose supplier
    use strict arg producer
    if producer~hasMethod("doer") then producer = producer~doer~do
    if \producer~hasMethod("supplier") then producer = .array~of(producer) -- for convenience, accept a non-supplier
    supplier = producer~supplier
    -- No need to : forward class (super) arguments (unknown)


::method eof
    expose supplier
    do while supplier~available, \self~isEOP
      -- The index is passed as an array, because some pipeStage may create
      -- additional indexes that will be appended.
      self~process(supplier~item, .array~of(supplier~index))
      -- Matter of choice : should I stay on current item or get the next item before leaving ?
      -- Current choice works good for coactivities : no lost item when piping directly the coactivity
      -- to several pipes. But if you pass the same supplier to several pipes then you have to call
      -- ~next if you don't want to get the last processed item again.
      if self~isEOP then leave
      supplier~next -- get the next data item (even if self is now EOP, that way the supplier is ready for continuation)
    end
    forward class(super) -- make sure we propagate the done message


/******************************************************************************/
-- An inject pipeStage to inject the items produced by a supplier in the pipeline.
-- The supplier is calculated for each processed value.
-- When using the option 'pushIndex', the history of indexes is kept : assuming
-- that the current value has index i, and the supplier produces the items (i1,v1),
-- (i2,v2) etc... then the injected values will be (i.i1, v1), (i.i2, v2) etc...
-- When using the option 'append', the processed value itself is written in the
-- pipeline before injecting the items produced by the supplier.

::class "inject" public subclass pipeStage

::method init
expose allowCommand
use strict arg allowCommand=.false -- by default, the doer is a function whose result is never used as command
self~init:super

::method initOptions
    expose allowCommand doer recursive limit depthFirst append pushIndex detectCycles unique debug trace
    doer = .nil
    recursive = .false
    limit = -1
    depthFirst = .true
    detectCycles = .false
    append = .false
    pushIndex = .false
    unique = .false
    debug = .false
    trace = .false
    unknown = .array~new
    do a over arg(1, "a")
        if a~isA(.String) then do
            parse var a first "." rest
            if "recursive"~caselessAbbrev(first, 3) then do
                -- recursive[.limit|.depthFirst|.breadthFirst|.cycles]*
                recursive = .true
                do while rest <> ""
                    parse var rest first "." rest
                    if first~dataType("W") then limit = first
                    else if "depthFirst"~caselessAbbrev(first, 1) then depthFirst = .true
                    else if "breadthFirst"~caselessAbbrev(first, 1) then depthFirst = .false
                    else if "cycles"~caselessAbbrev(first, 1) then detectCycles = .true
                    else raise syntax 93.900 array(self~class~id ": Expected 'depthFirst' or 'breadthFirst' or 'cycles' after "first". in "a)
                end
                iterate
            end
            if "append"~caselessAbbrev(a, 1) then do ; append = .true ; iterate ; end
            if "replace"~caselessAbbrev(a, 3) then do ; append = .false ; iterate ; end
            if "pushIndex"~caselessAbbrev(a, 1) then do ; pushIndex = .true ; iterate ; end
            if "unique"~caselessAbbrev(a, 1) then do ; unique = .true ; iterate ; end
            if "debug"~caselessAbbrev(a, 1) then do ; debug = .true ; iterate ; end
            if "trace"~caselessAbbrev(a, 1) then do ; trace = .true ; iterate ; end
            unknown~append(a)
            iterate -- do that now, otherwise you will enter in the doer section
        end
        if a~hasMethod("doer") then do
            if doer <> .nil then raise syntax 93.900 array(self~class~id ": Only one producer is supported")
            if allowCommand, a~hasMethod("actionDoer") then doer = a~actionDoer("use arg value, index")
            else if a~hasMethod("functionDoer") then doer = a~functionDoer("use arg value, index")
            else doer = a~doer
            iterate
        end
        unknown~append(a)
    end
    if doer == .nil then raise syntax 93.900 array(self~class~id ": No producer specified")
    forward class (super) arguments (unknown) -- forward the initialization to super to process the unknown options

::method newIndex
    expose pushIndex trace
    if trace then do
        .traceOutput~say(">I> Method .inject~newIndex")
        trace i
    end
    use strict arg index1, index2
    if pushIndex then do
        newindex = index1~copy
        if \ index2~isA(.Array) then newindex~append(index2)
        else do i over index2
            newindex~append(i)
        end
    end
    else do
        newindex = index2
        if \ newindex~isA(.Array) then newindex = .array~of(newindex)
    end
    return newindex

::method processDepthFirstCurrent
    expose recursive limit detectCycles unique trace
    if trace then do
        .traceOutput~say(">I> Method .inject~processDepthFirstCurrent")
        trace i
    end
    use strict arg value, index, stack, level, previousValues
    if unique then do
        if previousValues~hasItem(value) then do
            self~writeSecondary(value, index)
            return
        end
        previousValues~append(value)
    end
    if recursive & level <> limit then do
        if detectCycles then do
            if \ stack~hasItem(value) then do -- Recurse only if not already processed
                self~write(value, index)
                stack~push(value)
                self~processDepthFirst(value, index, stack, level+1, previousValues)
                stack~pull
            end
            else do
                self~writeSecondary(value, index)
                return
            end
        end
        else do
            self~write(value, index)
            self~processDepthFirst(value, index, stack, level+1, previousValues)
        end
    end
    else self~write(value, index)

::method processDepthFirst
    expose doer trace
    if trace then do
        .traceOutput~say(">I> Method .inject~processDepthFirst")
        trace i
    end
    use strict arg value, index, stack=(.queue~new), level=0, previousValues=(.array~new)
    doer~do(value, index)
    if \ var("result") then return -- no result returned, nothing to inject
    if \ result~hasMethod("supplier") then result = .array~of(result) -- for convenience, accept a non-supplier result
    supplier = result~supplier
    do while supplier~available, \self~isEOP
        item = supplier~item
        if \ item~hasMethod("supplier") then do
            newindex = self~newIndex(index, .array~of(value, supplier~index))
            self~processDepthFirstCurrent(item, newindex, stack, level, previousValues)
        end
        else do
            supplier2 = item~supplier
            do while supplier2~available, \self~isEOP
                item2 = supplier2~item
                newindex2 = self~newIndex(index, .array~of(value, supplier2~index))
                self~processDepthFirstCurrent(item2, newindex2, stack, level, previousValues)
                supplier2~next
                self~checkEOP(self~next, self~secondary)
            end
        end
        supplier~next
        self~checkEOP(self~next, self~secondary)
    end

::method processBreadthFirstCurrent2
    expose recursive limit detectCycles trace
    if trace then do
        .traceOutput~say(">I> Method .inject~processBreadthFirstCurrent2")
        trace i
    end
    use strict arg value, index, toprocess, stack, level
    if recursive & level <> limit then do
        if detectCycles then do
            if \ stack~hasItem(value) then do -- Recurse only if not already processed
                self~write(value, index)
                stack~push(value)
                toprocess~queue(value)
                toprocess~queue(index)
                toprocess~queue(stack~copy)
                stack~pull
            end
            else do
                self~writeSecondary(value, index)
                return
            end
        end
        else do
            self~write(value, index)
            toprocess~queue(value)
            toprocess~queue(index)
            toprocess~queue(level+1)
        end
    end
    else do
        self~write(value, index)
        toprocess~queue(value)
        toprocess~queue(index)
        toprocess~queue(level+1)
    end

::method processBreadthFirstCurrent
    expose doer trace
    if trace then do
        .traceOutput~say(">I> Method .inject~processBreadthFirstCurrent")
        trace i
    end
    use strict arg value, index, toprocess, stack, level
    doer~do(value, index)
    if \ var("result") then return -- no result returned, nothing to inject
    if \ result~hasMethod("supplier") then result = .array~of(result) -- for convenience, accept a non-supplier result
    supplier = result~supplier
    do while supplier~available, \self~isEOP
        item = supplier~item
        if \ item~hasMethod("supplier") then do
            newindex = self~newIndex(index, .array~of(value, supplier~index))
            self~processBreadthFirstCurrent2(item, newindex, toprocess, stack, level)
        end
        else do
            supplier2 = item~supplier
            do while supplier2~available, \self~isEOP
                item2 = supplier2~item
                newindex2 = self~newIndex(index, .array~of(value, supplier2~index))
                self~processBreadthFirstCurrent2(item2, newindex2, toprocess, stack, level)
                supplier2~next
                self~checkEOP(self~next, self~secondary)
            end
        end
        supplier~next
        self~checkEOP(self~next, self~secondary)
    end

::method processBreadthFirst
    expose detectCycles unique trace
    if trace then do
        .traceOutput~say(">I> Method .inject~processBreadthFirst")
        trace i
    end
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
                iterate
            end
            previousValues~append(supplier_item)
        end
        if detectCycles then stack = toprocess~pull
        else level = toprocess~pull
        self~processBreadthFirstCurrent(supplier_item, newindex, toprocess, stack, level)
    end

::method process
    expose doer depthFirst append trace debug
    if debug then do
        say "-"~copies(20)
        say doer~source~tostring
        say "-"~copies(20)
    end
    if trace then do
        .traceOutput~say(">I> Method .inject~process")
        trace i
    end
    use strict arg value, index
    if append then do
        -- follow the same convention as for calculated values.
        -- here, it's like getting a single result from value (result == value, index == 1)
        newIndex = self~newIndex(index, .array~of(value, 1))
        self~write(value, newIndex)
    end
    if depthFirst then self~processDepthFirst(value, index)
                  else self~processBreadthFirst(value, index)
    self~checkEOP(self~next)


/******************************************************************************/
-- A do pipeStage to execute an action passed as argument.
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
-- A select pipeStage to execute a boolean filter passed as argument.

::class "select" public subclass pipeStage

::method initOptions
    expose doer
    use strict arg filter
    if filter~hasMethod("functionDoer") then doer = filter~functionDoer("use arg value, index")
                                        else doer = filter~doer
::method process
    expose doer
    use strict arg value, index
    if doer~do(value, index) then do             -- apply the filter to the data item
        self~write(value, index)                 -- the selected items are sent
    end
    else do
        self~writeSecondary(value, index)        -- send all not selected items down the other branch, if there
    end
    self~checkEOP(self~next, self~secondary)


/******************************************************************************/
-- A fileTree pipeStage to get the childrens (files or directories) of the current value.
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
-- A superClass pipeStage to get the superClasses of the current value.
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
-- A subClass pipeStage to get the subClasses of the current value.
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
-- Implementation note :
-- The pipeStages methods and instanceMethods are very similar.
-- The only difference is the message sent to the object. Hence this class.
-- The implementation looks complex (3 classes, 4 methods) when compared to :
--     .inject {value~methods(value)}
--     .inject {value~instanceMethods(value)}
-- but that lets write :
--     .methods
--     .instanceMethods
-- which is shorter, and this is the opportunity to use a closure, so...

::class "queryByClass" public subclass inject

::method init private
    expose message class
    use strict arg message, class
    self~init:super

::method initOptions
    expose message class
    if .false then do
        -- For the moment, doesn't work... I have to implement the closures.
        producer = {
            expose message class
            use arg value
            ofclass = class
            if ofclass == .nil then ofclass = value~class
            return value~send(message, ofclass)
        }~doer -- get the doer now, to avoid application of functionDoer later
    end
    -- temporary partial implementation (assume class == .nil)
    else if message == "methods" then producer = {use arg value ; return value~methods(value)}
    else if message == "instanceMethods" then producer = {use arg value ; return value~instanceMethods(value)}
    args = arg(1, "a")
    args~append(producer)
    forward class (super) arguments (args)


/******************************************************************************/
-- A methods pipeStage to get the methods of the current value.
-- The input value can be any object.
-- By default, return the methods defined by the value's class.
-- You can pass another class as argument : .methods[class]

::class "methods" public subclass queryByClass

::method init
    use strict arg class=.nil
    self~init:super("methods", class)


/******************************************************************************/
-- An instanceMethods pipeStage to get the instanceMethods of the current value.
-- The input value can be any object.
-- By default, return the instances methods defined by the value's class.
-- You can pass another class as argument : .instanceMethods[class]

::class "instanceMethods" public subclass queryByClass

::method init
    use strict arg class=.nil
    self~init:super("instanceMethods", class)


