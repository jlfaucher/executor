/******************************************************************************/
/*
This class is a security manager, which intercepts the messages sent for
protected methods. A call stack, call count and duration is managed for each
method.

To let intercept the messages, the methods to profile must be instrumented 
by calling one of those methods :
.Profiler~instrumentMethods(myclass, arrayOfMessagesToIntercept)
.Profiler~instrumentMethod(myclass, message)
.Profiler~instrumentClassMethods(myclass, arrayOfMessagesToIntercept) -- Not supported by standard ooRexx
.Profiler~instrumentClassMethod(myclass, message)                     -- Not supported by standard ooRexx

Changes made by the instrumentation :
    ::method myMethod
    <my code here...>
    
    is instrumented to become :
    
    ::method myMethod protected        <-- will be intercepted
    forward message("myMethod_unprotected")
    
    ::method myMethod_unprotected      <-- the security manager will forward this message
    <my code here...>

Typical usage of the profiler :
    profiler = .Profiler~new                      -- create a fresh profiler, all counters at zero, empty call stack
    profiler~push(rootObject, rootMessage)        -- will be the first entry displayed in the call stack
    .context~package~setSecurityManager(profiler) -- put in place the profiler
    <run your code>
    profiler~reportResults(profiler~pull)         -- display the results

Exemple of output :
.pipeProfiler~instrument("start", "process", "eof", "isEOP")
.pipeProfiler~instrumentClassMethods(.pipeIndex, .array~of("create")) -- no effect with standard ooRexx
(.sort byValue | .console)~go(.array~of(b, a, c), .true) -- standard ooRexx
.array~of(b, a, c)~pipeProfile(.sort byValue | .console) -- extended ooRexx
(an Array),2 : A
(an Array),1 : B
(an Array),3 : C
----------------------------------------
.sort~go
  .sort~EOF count=1 duration=0.015000
    .console~EOF count=1 duration=0
    .console~ISEOP count=6 duration=0
    .console~PROCESS count=3 duration=0.015000
  .sort~ISEOP count=6 duration=0
  .sort~PROCESS count=3 duration=0
  .sort~START count=1 duration=0
    .console~START count=1 duration=0
  .pipeIndex~CREATE count=3 duration=0
duration=0.015000
----------------------------------------
*/

-- To profile class methods, I need to redefine instances methods of classes.
-- For that, must use setMethod, but setMethod is a private method.
-- Don't know how to redefine an instance method on any class, unless doing that...
.Object~define("setMethod1", "forward message('setMethod')") -- No effect with standard ooRexx

::class Profiler public

::attribute output
::attribute header
::attribute footer
::attribute indent
::attribute messageStack

::method init
    use strict arg output = .traceOutput
    self~output = output
    self~header = "-"~copies(40)
    self~footer = "-"~copies(40)
    self~indent = "  "
    self~messageStack = .Queue~new

---------- Instrumentation ------------

::method instrumentMethods class
    use strict arg class, messages
    do message over messages
        self~instrumentMethod(class, message)
    end

::method instrumentMethod class
    use strict arg class, message
    method = class_method(class, message)
    if method == .nil then return -- nothing to do
    newMessage = message"_unprotected"
    newMethod = class_method(class, newMessage)
    if newMethod <> .nil then return -- already done
    newMethod = .Method~new("", "forward message("newMessage")")
    newMethod~setProtected
    class~define(message, newMethod)
    class~define(newMessage, method)

::method instrumentClassMethods class
    use strict arg class, messages
    do message over messages
        self~instrumentClassMethod(class, message)
    end

::method instrumentClassMethod class
    use strict arg class, message
    method = object_instanceMethod(class, message)
    if method == .nil then return -- nothing to do
    newMessage = message"_unprotected"
    newMethod = object_instanceMethod(class, newMessage)
    if newMethod <> .nil then return -- already done
    newMethod = .Method~new("", "forward message("newMessage")")
    newMethod~setProtected
    class~setMethod1(message, newMethod)
    class~setMethod1(newMessage, method)

---------- Profiling ------------------

::method push
    use strict arg object, message
    key = object~identityHash || message
    current = self~messageStack~peek
    profileData = .nil
    if current <> .nil then profileData = current~followers[key]
    if profileData == .nil then do
        profileData = .MessageProfileData~new(object, message)
        if current <> .nil then current~followers[key] = profileData
    end
    self~messageStack~push(profileData)

::method pull
    return self~messageStack~pull

::method unknown
    return 0

::method method -- called for each intercepted method
    use strict arg info
    object = info~object
    message = info~name
    arguments = info~arguments
    self~push(object, message)
    call time "r"
    forward to (object) message (message || "_unprotected") arguments (arguments) continue
    elapsedTime = time("e")
    if var("result") then info~setentry("RESULT", result)
    profileData = self~pull
    profileData~count += 1
    profileData~duration += elapsedTime
    return 1

---------- Reporting ------------------

::method reportResults
    use strict arg current, level=0
    if current == .nil then return
    if level == 0 then self~lineout(self~header)
    self~charout(self~indent~copies(level))
    if current~object~isA(.Class) then self~charout("."current~object~id) -- to rework
    else self~charout("."current~object~class~id)
    self~charout("~"current~message)
    if current~count <> 0 then do
        self~charout(" count="current~count)
        self~charout(" duration="current~duration)
    end
    self~lineout("")
    totalDuration = current~duration
    do key over current~followers~allIndexes~sort
        profileData = current~followers[key]
        self~reportResults(profileData, level+1)
        totalDuration += profileData~duration
    end
    if level == 0 then do
        self~lineout("duration="totalDuration)
        self~lineout(self~footer)
    end

::method charout
    forward to (self~output)

::method lineout
    forward to (self~output)


/******************************************************************************/
::class MessageProfileData

::attribute object
::attribute message
::attribute count
::attribute duration
::attribute followers

::method init
    use strict arg object=.nil, message=.nil
    self~object = object
    self~message = message
    self~count = 0
    self~duration = 0
    self~followers = .Directory~new


/******************************************************************************/
::routine class_method -- helper, different from .Class~method, because limited to the methods of the class itself
    use strict arg class, methodName
    supplier = class~methods(.nil)
    do while supplier~available
        if supplier~index~caselessEquals(methodName) then return supplier~item
        supplier~next
    end
    return .nil

/******************************************************************************/
::routine object_instanceMethod -- helper, different from .Object~instanceMethod, because limited to the methods of the object itself
    use strict arg object, methodName
    supplier = object~instanceMethods(object)
    do while supplier~available
        if supplier~index~caselessEquals(methodName) then return supplier~item
        supplier~next
    end
    return .nil

