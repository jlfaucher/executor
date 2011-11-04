/*
Coactivity is an emulation of coroutines in ooRexx.

This script works with a standard ooRexx, but there is a dependency on doers.
It's up to the package which requires the current script to requires also :
either extension.cls (if supporting ::extension)
or extension-std.cls (if standard ooRexx)

This is not a "real" coroutine implementation, because it's based on ooRexx activities
and synchronization. But at least you have all the functionalities of stackful
asymmetric coroutines (resume + yield). All is in place to support symmetric coroutines
(yield only), but the scheduler remains to implement.

Coroutines are a programming language concept that allows for explicit, cooperative
and stateful switching between subroutines. The advantage of real coroutine over
threads is that they do not have to be synchronized because they pass control to
each other explicitly and deterministically.
*/


--::options trace i
::options NOMACROSPACE
::requires "concurrency/activity.cls"


-- .yield[value] is more compact than .Coactivity~yield(value)
::class "yield" public
::method "[]" class unguarded
    forward message ("yield") to (.Coactivity)


--------------------------------------------------------------------------------
::class "Coactivity" mixinclass Object public

/*
Status transitions :
    notStarted --> running | ended | killed
    running --> suspended | ended | killed
    suspended --> running | ended | killed
*/
::constant notStarted 0
::constant suspended 1
::constant running 2
::constant ended 3
::constant killed 4

-- Class attributes
::attribute table class private -- contains all the active coactivities
::attribute makeArrayLimit class -- Coactivities can generate an infinite number of values, so must put a limit...

-- Instance attributes for entry point
-- ::attribute doer private
-- ::attribute object private

-- Instance attributes for execution
-- ::attribute status private
-- ::attribute arguments private
-- ::attribute yieldValue private


::method init class
    self~table = .IdentityTable~new
    self~makeArrayLimit = 10000 -- not a constant, I think it's useful to let the end user change this value


::method count class
    return self~table~items


::method all class
    return self~table~makeArray


::method endAll class
    count = 0
    do coactivity over self~table~allIndexes
        if coactivity~end then count += 1
    end
    return count


::method killAll class
    count = 0
    do coactivity over self~table~allIndexes
        if coactivity~kill then count += 1
    end
    return count


::method init unguarded
    /*
    The coactivity entry can be a routine, a couple (message, object) or a couple (method, object).
    The default entry is the couple ("main", self).
    By default, the coactivity is started (the 'start' method is called)
    */
    expose doer object status
    use strict arg action="main", start=.true, object=(self)

    doer = action~doer
    status = .Coactivity~notStarted
    if start then self~start


::method executable
    expose doer
    return doer


::method start
    /*
    Create the activity that will control the coactivity and make it suspended.
    Use 'resume' to start the coactivity effectively.
    The arguments passed to the first 'resume' will be made available to the coactivity through the traditional 'use arg'.
    The arguments passed to the next 'resume's will be made available as an array returned by 'yield'.
    */
    expose arguments doer object status
    use strict arg -- no arg
    if status <> .Coactivity~notStarted then raise syntax 93.900 array ("Only 'not started' coactivities can be started (current status is '"self~statusText"')")
    status = .Coactivity~suspended
    reply self
    .Activity~local~empty
    .Activity~local~coactivity = self
    .Coactivity~table[self] = self
    signal on any name trapCondition -- catch all
    signal on syntax name trapCondition -- gives better messages
    guard off
    guard on when status <> .Coactivity~suspended
    if status == .Coactivity~running then do
        guard off
        -- arguments are coming from 'resume' (the first resume activates the coactivity)
        if doer~needsObject then doer~doWith(object, arguments) -- object needed (message, method)
        else doer~doWith(arguments) -- no object needed (routine)
        guard on
        if var("result") then self~yieldLast(result)
        else self~yieldLast
        status = .Coactivity~ended
    end
    trapCondition:
    self~kill -- maybe already killed or ended
    if self~hasMethod("onTerminate") then self~onTerminate
    .Coactivity~table~remove(self)
    .Activity~local~empty
    if self~isKilled & condition("o") <> .nil then raise propagate


::method main abstract
    -- Default entry point of the coactivity, to be implemented in a subclass
    -- (The subclassing is optional. You can use any doer as entry point).


::method yield class unguarded
    /*
    Helper method to let yield from any nested invocation
    (i.e. directly or indirectly called by the coactivity 'start' method).
    The goal is to retrieve the coactivity instance and send it the message yield.
    myCoactivity~start  <--------------+
        invocation                     |
            invocation                 |
                ...                    |
                    invocation : .Coactivity~yield()
    */
    coactivity = .Activity~local~coactivity
    if coactivity == .nil then raise syntax 93.900 array ("yield can be used only from a coactivity")
    forward to (coactivity)


::method yield private
    -- Can be called only from a coactivity.
    -- Returns an array which contains the arguments passed to 'resume' by the client of the coactivity.
    expose arguments status yieldValue
    drop yieldValue
    if status == .Coactivity~killed then raise syntax 93.900 array ("Coactivity is killed") -- this is to unwind any nested invocation and return to 'start'
    if status == .Coactivity~ended then raise syntax 93.900 array ("Coactivity is ended") -- this is to unwind any nested invocation and return to 'start'
    if arg() <> 0 then use strict arg yieldValue -- yieldValue will be returned to the Coactivity's client by 'resume'
    status = .Coactivity~suspended
    guard off
    guard on when status <> .Coactivity~suspended
    if status == .Coactivity~killed then raise syntax 93.900 array ("Coactivity is killed") -- this is to unwind any nested invocation and return to 'start'
    if status == .Coactivity~ended then raise syntax 93.900 array ("Coactivity is ended") -- this is to unwind any nested invocation and return to 'start'
    if arguments~items <> 0 then return arguments -- returns the arguments that the coactivity's client passed to 'resume'


::method yieldLast private
    /*
    Internal method called when the coactivity action has returned.
    */
    expose yieldValue
    drop yieldValue
    if arg() <> 0 then use strict arg yieldValue -- yieldValue will be returned to the coactivity's client by 'resume'


::method resume
    -- You can pass arguments to this method.
    -- They will be passed to the coactivity, either as traditional 'use arg' if first call, or as an array returned by 'yield'.
    expose arguments status yieldValue
    if status == .Coactivity~notStarted then raise syntax 93.900 array ("Coactivity is not started")
    if status == .Coactivity~killed then raise syntax 93.900 array ("Coactivity is killed")
    if status == .Coactivity~ended then return -- raise syntax 93.900 array ("Coactivity is ended")
    arguments = arg(1, "a")
    status = .Coactivity~running
    guard off
    guard on when status <> .Coactivity~running
    if status == .Coactivity~killed then raise syntax 93.900 array ("Coactivity is killed")
    if var("yieldValue") then return yieldValue


::method end
    expose status
    if status == .Coactivity~ended then return .false
    if status == .Coactivity~killed then return .false
    -- A not started coactivity can be ended, to forbid its starting.
    status = .Coactivity~ended
    return .true


::method kill
    expose status
    if status == .Coactivity~ended then return .false
    if status == .Coactivity~killed then return .false
    -- A not started coactivity can be killed, to forbid its starting.
    status = .Coactivity~killed
    return .true


::method isStarted
    expose status
    return status <> .Coactivity~notStarted


::method isAlive
    expose status
    return status == .Coactivity~suspended | status == .Coactivity~running


::method isEnded
    expose status
    return status == .Coactivity~ended


::method isKilled
    expose status
    return status == .Coactivity~killed


::method statusText
    expose status
    select
        when status == .Coactivity~notStarted then return "not started"
        when status == .Coactivity~suspended then return "suspended"
        when status == .Coactivity~running then return "running"
        when status == .Coactivity~ended then return "ended"
        when status == .Coactivity~killed then return "killed"
        otherwise return "unknown"
    end


/*
BAD IDEA ! The method defaultName is called by the interpreter when tracing and you enter in
a recursive loop because defaultName itself is traced. Should use "objectName=" instead, but
will have to call it each time the status is changed. Maybe later...

::method defaultName
    defaultName = self~statusText self~class~id
    if defaultName~caselessMatchChar(1, "aeiou") then article = "An" ; else article = "A"
    return article defaultName
*/


::method supplier unguarded
    return .LazyCoactivitySupplier~new(self)


::method makeArray unguarded
    -- This is really NOT adapted to coactivities which can generate an infinite set of values  !
    -- But this is the only way to write : do over myCoactivity ...
    -- A better approach would be to modify the interpreter to support : do over anySupplier ...
    use strict arg limit=(.Coactivity~makeArrayLimit)
    array = .Array~new
    do forever
        if array~dimension(1) >= limit then do
            -- Better to not end the coactivity : makeArray is like clojure's take or like the pipestage .take
            -- self~end
            leave
        end
        self~resume
        if \var("result") then leave
        array~append(result)
    end
    return array


--------------------------------------------------------------------------------
/*
Lazy Coactivity supplier :
This supplier does not take a snapshot of the items remaining to generate by the coactivity.
Instead, it calculates the next item only when the 'next' method is called.
*/
::class "LazyCoactivitySupplier" subclass Supplier

::attribute coactivity
::attribute startedByMe
::attribute currentIndex
::attribute currentItem
::attribute isAvailable


::method init
    use strict arg coactivity
    empty = .array~new(0) -- Lazy supplier
    self~init:super(empty, empty)
    self~coactivity = coactivity
    self~startedByMe = .false
    if \self~coactivity~isStarted then do ; self~coactivity~start ; self~startedByMe = .true; end
    self~currentIndex = 0
    self~next


::method uninit
    /*
    I think I need the uninit method to support properly this use case :
    .coactivity~new{i=0; do forever; i+=1; .yield[i]; end}~pipe(.take 5 | .displayer)
    While the pipeline is running, the coactivity supplier is referenced by the 'source' property of the first pipe stage, and can't be GC'ed.
    The pipeline itself can't be GC'ed because the first pipe stage is referenced from the call stack, as an argument of 'pipe'.
    When 5 values have been taken (.take 5), the pipeline is stopped and the method 'pipe' returns.
    From now, the pipeline can be GC'ed, because it's no longer referenced from the call stack.
    And once the pipeline is GC'ed, there is no more reference to the coactivity supplier, which can be GC'ed.
    */
    if self~startedByMe then self~coactivity~end


::method available
    return self~isAvailable


::method index
    if self~isAvailable then return self~currentIndex


::method item
    if self~isAvailable then return self~currentItem


::method next
    expose currentItem
    self~coactivity~resume
    drop currentItem
    if var("result") then do
        self~currentItem = result
        self~currentIndex += 1
        self~isAvailable = .true
    end
    else self~isAvailable = .false

