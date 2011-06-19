::requires "pipeline/pipe.rex"
::requires "extension/doers.cls"
::requires "concurrency/coactivity.cls"
::requires "rgf_util2/rgf_util2_wrappers"
--::options trace i

/*
I wanted to support something like that : "a"|.upper|.displayer
where the first '|' is an overriden operator which injects any object in the pipe.
But can't do that because :
- extension does not override existing methods ('|' already exists on .String).
- even if '|' overriding was possible, the injection wouldn't be possible from the
  overriden '|' because it's too early... The expression above is in fact
  ("a"|.upper)|.displayer
  so an injection made by ("a"|.upper) wouldn't reach |.displayer.
So I added the 'pipe' method which injects the object in the pipe :
"a"~pipe(.upper|.displayer)
*/

::extension Object
::method pipe
    use strict arg pipe
    if pipe~isa(.class) then pipe = pipe~new
    pipe~go(.array~of(self))
    return self


::extension Collection
::method pipe
    use strict arg pipe
    if pipe~isa(.class) then pipe = pipe~new
    pipe~go(self)
    return self


::extension Supplier
::method pipe
    use strict arg pipe
    if pipe~isa(.class) then pipe = pipe~new
    pipe~go(self)
    return self


::extension Coactivity
::method pipe unguarded
    use strict arg pipe
    if pipe~isa(.class) then pipe = pipe~new
    pipe~go(self)
    return self


/******************************************************************************/
-- This class is defined in pipe.rex, to make it visible without requiring the
-- current file (I don't want to make pipe.rex dependent on extensions).
-- There is a test at runtime to see if 'installed' is present on the class.
::extension pipeExtensions

::method installed class
    return .true

-- A function always takes two parameters : value and index. They are automatically declared.
-- A function always return a result. The "return" instruction is automatically inserted, if missing.
-- A function is not allowed to run a command.
::method makeFunctionDoer public class
    use strict arg oneLinerFunction, context=.nil
    if oneLinerFunction~strip <> "" then do
        if oneLinerFunction~caselessPos("return ") == 0 then oneLinerFunction = "return" oneLinerFunction
        oneLinerFunction = "use arg value, index;" oneLinerFunction
    end
    doer = oneLinerFunction~doer(context)
    if doer~hasMethod("setSecurityManager") then doer~setSecurityManager(.CommandNotAllowed~new) -- A doer can be a message, which has not this method
    return doer

-- An action always takes two parameters : value and index. They are automatically declared.
-- An action can return optionnally a result, it's up to the user to insert the "return".
-- An action can run a command, so no security restriction.
::method makeActionDoer public class
    use strict arg oneLinerAction, context=.nil
    if oneLinerAction~strip <> "" then do
        oneLinerAction = "use arg value, index;" oneLinerAction
    end
    doer = oneLinerAction~doer(context)
    return doer


/******************************************************************************/
-- An append pipeStage to copy items from its primary input to its primary output,
-- and then invoke the supplier passed as argument and write the items produced by
-- that supplier to its primary output.
::class append public subclass pipeStage

::method init
    expose supplier
    use strict arg producer, context=.nil
    if producer~hasMethod("doer") then producer = .pipeExtensions~makeFunctionDoer(producer, context)~do
    if \producer~hasMethod("supplier") then supplier = .array~of(producer) -- for convenience, accept a non-supplier
    supplier = producer~supplier
    forward class (super)

::method eof
    expose supplier
    do while supplier~available, \self~isEOP
      -- The index is passed as an array, because some pipeStage may create
      -- additional indexes that will be appended.
      self~process(supplier~item, .array~of(supplier~index))
      supplier~next -- get the next data item (even if self is now EOP, that way the supplier is ready for continuation)
    end
    forward class(super) -- make sure we propagate the done message


/******************************************************************************/
-- An inject pipeStage to inject the items produced by a supplier in the pipeline.
-- The supplier is calculated for each processed value.
-- The history of indexes is kept : assuming that the current value has index i,
-- and the supplier produces the items (i1,v1), (i2,v2) etc... then the injected
-- values will be (i.i1, v1), (i.i2, v2) etc..
-- The processed value itself is written in the pipeline before injecting the items
-- produced by the supplier.
::class inject public subclass pipeStage

::method init
    expose doer
    use strict arg function, context=.nil
    doer = .pipeExtensions~makeFunctionDoer(function, context)
    forward class (super)

::method initOptions
    expose recursive limit
    recursive = .false
    limit = -1
    unknown = .array~new
    do a over arg(1, "a")
        parse var a first "." rest
        if "recursive"~caselessAbbrev(first, 1) then do
            recursive = .true
            if rest <> "" then do -- recursive.limit
                if rest~dataType("W") then limit = rest
                else raise syntax 93.900 array("Expected a whole number after "first". in "a) 
            end
        end
        else unknown~append(a) 
    end
    forward class (super) arguments (unknown) -- forward the initialization to super to process the unknown options

::method process
    expose doer recursive limit
    use strict arg value, index, processed=(.queue~new)
    self~write(value, index)
    doer~do(value, index)
    if \ var("result") then return -- no result returned, nothing to inject
    if \ result~hasMethod("supplier") then result = .array~of(result) -- for convenience, accept a non-supplier result
    supplier = result~supplier
    do while supplier~available & processed~items <> limit & \self~next~isEOP
      newindex = index~copy
      newindex~append(supplier~index)
      if recursive then do
          if processed~hasItem(supplier~item) then do
              self~write(supplier~item, newindex)
              return -- Stop the recursion because already processed
          end
          processed~push(supplier~item)
          self~process(supplier~item, newindex, processed)
          processed~pull
      end
      else self~write(supplier~item, newindex)
      supplier~next
    end
    self~checkEOP(self~next)

 
/******************************************************************************/
-- a do pipeStage to execute an action passed as argument.
-- CAREFULL ! There is NO automatic insertion of the "return" instruction, and
-- the commands are authorized here, so DON'T FORGET the "return" instruction
-- if you want to return a value !!!!
-- Ex : assuming value==10
-- .do[2*value] will not insert 20 in the pipeline, but will instead run the command "20".
::class do public subclass pipeStage

::method init
    expose doer
    use strict arg action, context=.nil
    doer = .pipeExtensions~makeActionDoer(action, context)
    forward class (super)

::method process
    expose doer
    use strict arg value, index
    doer~do(value, index)              
    if var("result") then self~write(result, index) -- if a result was returned by the doer then send the result
    else self~write(value, index) -- otherwise send the data item itself
    self~checkEOP(self~next)


/******************************************************************************/
-- a select pipeStage to execute a boolean filter passed as argument.
::class select public subclass pipeStage

::method init
    expose doer
    use strict arg filter, context=.nil
    doer = .pipeExtensions~makeFunctionDoer(filter, context)
    forward class (super)

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
::class CommandNotAllowed -- Security manager 

::method unknown
    return 0
    
::method command
    use strict arg info
    raise syntax 98.948 array("Command not allowed:" info~address info~command)

