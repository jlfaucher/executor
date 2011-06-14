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
-- This class is defined in pipe.rex, but I don't want to make pipe.rex dependent
-- on extensions. That's why this method is added here.
-- There is a test at runtime to see if compareExpression is present on the class.
-- If not present (case of standard ooRexx), an error "Unknown option" is raised if
-- the user specifies an expression in the sort pipestage.
::extension indexedValueComparator

::method compareExpressions
    expose doer
    use strict arg first, second
    result1 = doer~do(first~value, first~index)
    result2 = doer~do(second~value, second~index)
    return self~compareStrings(result1~string, result2~string)

-- The routine makeFunctionDoer is not visible from pipe.rex
::method makeFunctionDoer
    use strict arg oneLinerFunction, context=.nil
    return makeFunctionDoer(oneLinerFunction, context)


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
    doer = makeFunctionDoer(function, context)
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
    forward class (super) arguments (unknown)    -- forward the initialization to super to process the unknown options

::method process
    expose doer recursive limit
    use strict arg value, index, processed=(.queue~new)
    self~write(value, index)
    doer~do(value, index)
    if \ var("result") then return -- no result returned, nothing to inject
    if \ result~hasMethod("supplier") then result = .array~of(result) -- for convenience, accept a non-collection result
    supplier = result~supplier
    do while supplier~available & processed~items <> limit
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

    
/******************************************************************************/
-- a do pipeStage to execute an action passed as argument
::class do public subclass pipeStage

::method init
    expose doer
    use strict arg action, context=.nil
    doer = makeActionDoer(action, context)
    forward class (super)

::method process
    expose doer
    use strict arg value, index
    doer~do(value, index)              
    if var("result") then self~write(result, index) -- if a result was returned by the doer then send the result
    else self~write(value, index)                     -- otherwise send the data item itself


/******************************************************************************/
-- a select pipeStage to execute a boolean filter passed as argument
::class select public subclass pipeStage

::method init
    expose doer
    use strict arg filter, context=.nil
    doer = makeFunctionDoer(filter, context)
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


/******************************************************************************/
-- A function always takes two parameters : value and index. They are automatically declared.
-- A function always return a result. The "return" instruction is automatically inserted, if missing.
-- A function is not allowed to run a command.
::routine makeFunctionDoer public
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
::routine makeActionDoer public
    use strict arg oneLinerAction, context=.nil
    if oneLinerAction~strip <> "" then do
        oneLinerAction = "use arg value, index;" oneLinerAction
    end
    doer = oneLinerAction~doer(context)
    return doer

