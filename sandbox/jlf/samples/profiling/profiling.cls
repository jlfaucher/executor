/******************************************************************************/
-- This class is a security manager, which 
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
    use strict arg class, methodName
    method = class_method(class, methodName)
    if method == .nil then return -- nothing to do
    newMethodName = methodName"_unprotected"
    newMethod = class_method(class, newMethodName)
    if newMethod <> .nil then return -- already done
    newMethod = .Method~new("", "forward message("newMethodName")")
    newMethod~setProtected
    class~define(methodName, newMethod)
    class~define(newMethodName, method)

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
    self~charout("."current~object~class~id)
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

