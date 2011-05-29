::requires "pipeline/pipe.rex"
::requires "concurrency/coactivity.cls"
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
-- The processed value itself is automatically forwarded before injecting each
-- element of the collection.
::class inject public subclass pipeStage
::method init
    expose doer
    use strict arg function, context=.nil
    doer = function~doer(context)
    self~init:super

::method process
    expose doer
    use strict arg value, index
    self~write(value, index)
    supplier = doer~do(value, index)~supplier
    do while supplier~available
      self~write(supplier~item, supplier~index)
      supplier~next
    end

    
/******************************************************************************/
-- a do pipeStage to execute an action passed as argument
::class do public subclass pipeStage
::method init
    expose doer
    use strict arg action, context=.nil
    doer = action~doer(context)
    self~init:super

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
    doer = filter~doer(context)
    self~init:super

::method process
    expose doer
    use strict arg value, index
    if doer~do(value, index) then do             -- apply the filter to the data item              
        self~write(value, index)                 -- the selected items are sent
    end 
    else do
        self~writeSecondary(value, index)        -- send all not selected items down the other branch, if there
    end

