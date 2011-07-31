::requires "pipeline/pipe.rex"
::requires "extension/doers.cls"
::requires "concurrency/coactivity.cls"
::requires "rgf_util2/rgf_util2_wrappers"
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

::extension Object

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

::class index_value public

::method "[]" class
forward to (self) message("of")

::method of class
    use strict arg index, value, ...
    table = .table~new
    do i = 1 to arg() by 2
        table[arg(i)] = arg(i+1)
    end
    return table


::class value_index public

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

::class append public subclass pipeStage

::method initOptions
    expose supplier
    use strict arg producer
    if producer~hasMethod("doer") then producer = producer~doer~do
    if \producer~hasMethod("supplier") then producer = .array~of(producer) -- for convenience, accept a non-supplier
    supplier = producer~supplier

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

::class inject public subclass pipeStage

::method init
expose allowCommand
use strict arg allowCommand=.false -- by default, the doer is a function whose result is never used as command
self~init:super

::method initOptions
    expose allowCommand doer recursive limit depthFirst append pushIndex detectCycles
    doer = .nil
    recursive = .false
    limit = -1
    depthFirst = .true
    detectCycles = .false
    append = .false
    pushIndex = .false
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
            unknown~append(a) ; iterate -- do that now, otherwise you will enter in the doer section
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
    expose pushIndex
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
    expose recursive limit detectCycles
    use strict arg value, index, stack=(.queue~new), level=0
    if recursive & level <> limit then do
        if detectCycles then do
            if \ stack~hasItem(value) then do -- Recurse only if not already processed
                self~write(value, index)
                stack~push(value)
                self~processDepthFirst(value, index, stack, level+1)
                stack~pull
            end
        end
        else do
            self~write(value, index)
            self~processDepthFirst(value, index, stack, level+1)
        end
    end
    else self~write(value, index)

::method processDepthFirst
    expose doer pushIndex
    use strict arg value, index, stack=(.queue~new), level=0
    doer~do(value, index)
    if \ var("result") then return -- no result returned, nothing to inject
    if \ result~hasMethod("supplier") then result = .array~of(result) -- for convenience, accept a non-supplier result
    supplier = result~supplier
    do while supplier~available, self~next <> .nil, \self~next~isEOP
        newindex = self~newIndex(index, supplier~index)
        item = supplier~item
        self~processDepthFirstCurrent(item, newindex, stack, level)
        supplier~next
    end

 
::method processBreadthFirstCurrent
    expose doer recursive limit pushIndex detectCycles
    use strict arg value, index, toprocess, stack, level
    doer~do(value, index)
    if \ var("result") then return -- no result returned, nothing to inject
    if \ result~hasMethod("supplier") then result = .array~of(result) -- for convenience, accept a non-supplier result
    supplier = result~supplier
    do while supplier~available, self~next <> .nil, \self~next~isEOP
        newindex = self~newIndex(index, supplier~index)
        if recursive & level <> limit then do
            if detectCycles then do
                if \ stack~hasItem(supplier~item) then do -- Recurse only if not already processed
                    self~write(supplier~item, newindex)
                    stack~push(supplier~item)
                    toprocess~queue(supplier~item)
                    toprocess~queue(newindex)
                    toprocess~queue(stack~copy)
                    stack~pull
                end
            end
            else do
                self~write(supplier~item, newindex)
                toprocess~queue(supplier~item)
                toprocess~queue(newindex)
                toprocess~queue(level+1)
            end
        end
        else do
            self~write(supplier~item, newindex)
            toprocess~queue(supplier~item)
            toprocess~queue(newindex)
            toprocess~queue(level+1)
        end
        supplier~next
    end

 
::method processBreadthFirst
    expose detectCycles
    use strict arg value, index
    stack = .queue~new
    toprocess = .queue~new
    self~processBreadthFirstCurrent(value, index, toprocess, stack, 0)
    do while \toprocess~isEmpty
        supplier_item = toprocess~pull
        newindex = toprocess~pull
        if detectCycles then stack = toprocess~pull
        else level = toprocess~pull
        self~processBreadthFirstCurrent(supplier_item, newindex, toprocess, stack, level)
    end

 
::method process
    expose doer depthFirst append
    use strict arg value, index
    if append then self~write(value, index)
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

::class do public subclass inject

::method init
use strict arg -- none
self~init:super(.true) -- allow commands


/******************************************************************************/
-- A select pipeStage to execute a boolean filter passed as argument.

::class select public subclass pipeStage

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

::class fileTree public subclass inject

::method initOptions
    doer = .context~package~findRoutine("fileTreeFind")
    args = arg(1, "a")
    args~append(doer)
    forward class (super) arguments (args)


::routine fileTreeFind
    use arg value, index
    if \value~isA(.File) then value = .File~new(value~string)
    childs = value~listFiles
    if childs <> .nil then return childs

