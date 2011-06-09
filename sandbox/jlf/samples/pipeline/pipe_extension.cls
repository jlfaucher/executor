::requires "pipeline/pipe.rex"
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
-- An inject pipeStage to inject a collection in the pipeline.
-- This collection is calculated for each processed value.
-- The history of indexes is kept : assuming that the current value has index i,
-- and the collection is (i1,v1), (i2,v2) etc... then the injected values will be 
-- (i.i1, v1), (i.i2, v2) etc..
-- The processed value itself is written in the pipeline before injecting each
-- element of the collection.
::class inject public subclass pipeStage

::method init
    expose doer
    use strict arg function, context=.nil
    -- I want to avoid to type "return" to make the filter simpler...
    if function~caselessPos("return ") == 0 then function = "return" function
    doer = function~doer(context)
    doer~setSecurityManager(.CommandNotAllowed~new)
    forward class (super)

::method initOptions
    expose recursive
    recursive = .false
    unknown = .array~new
    do a over arg(1, "a")
        if "recursive"~caselessAbbrev(a, 1) then recursive = .true 
        else unknown~append(a) 
    end
    forward class (super) arguments (unknown)    -- forward the initialization to super to process the unknown options

::method process
    expose doer recursive
    use strict arg value, index, processed=(.queue~new)
    self~write(value, index)
    supplier = doer~do(value, index)~supplier
    do while supplier~available
      if index~isA(.array) then newindex = index~copy
                           else newindex = .array~of(index)
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

    
/******************************************************************************/
-- a do pipeStage to execute an action passed as argument
::class do public subclass pipeStage

::method init
    expose doer
    use strict arg action, context=.nil
    doer = action~doer(context)
    forward class (super)

::method process
    expose doer
    use strict arg value, index
    doer~do(value, index)              
    if var("result") then self~write(result, index) -- if a result was returned by the doer then send the result
    self~write(value, index)                     -- otherwise send the data item itself


/******************************************************************************/
-- a select pipeStage to execute a boolean filter passed as argument
::class select public subclass pipeStage

::method init
    expose doer
    use strict arg filter, context=.nil
    -- I want to avoid to type "return" to make the filter simpler...
    if filter~caselessPos("return ") == 0 then filter = "return" filter
    doer = filter~doer(context)
    doer~setSecurityManager(.CommandNotAllowed~new)
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


/******************************************************************************/
::class CommandNotAllowed -- Security manager 

::method unknown
    return 0
    
::method command
    use strict arg info
    raise syntax 98.948 array("Command not allowed:" info~address info~command)

