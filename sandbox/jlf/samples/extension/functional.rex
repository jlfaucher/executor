/*
This script needs a modified ooRexx interpreter which allows to extend predefined ooRexx classes.
Something similar to C# extension methods :
http://msdn.microsoft.com/en-us/library/bb383977.aspx
http://weblogs.asp.net/scottgu/archive/2007/03/13/new-orcas-language-feature-extension-methods.aspx

Here, the extensions are declared with ::extension instead of ~define (see ..\functional for ~define)
*/


-----------------------------------------------------------------------------
-- A Doer is an object who knows how to execute itself (understands "do")
-- A Message can't be a Doer directly, must use an intermediate class MessageNameSender

::extension Routine
::method doer
    use strict arg context=.nil
    if context <> .nil then raise syntax 93.963 -- Context not supported
    return self
::method do
    self~callWith(arg(1,"a"))
    if var("result") then return result

    
::extension Method
::method doer
    use strict arg context=.nil
    if context <> .nil then raise syntax 93.963 -- Context not supported 
    return self
::method do
    use strict arg object, ...
    object~run(self, "a", arg(2,"a"))
    if var("result") then return result

    
::extension String -- first part
::method doer
    use strict arg context=.nil
    parse var self word1 rest
    -- When the source string contains a single word without '(', it's a message name
    if rest == "" & word1~pos("(") == 0 then do
        if context <> .nil then raise syntax 93.963 -- Context not supported 
        return .MessageNameSender~new(self)
    end
    if word1~caselessEquals("::method") then do
        if context == .nil then return .Method~new("", rest)
        return .Method~new("", rest, context)
    end
    if word1~caselessEquals("::routine") then do
        if context == .nil then return .Routine~new("", rest)
        return .Routine~new("", rest, context)
    end
    -- Routine by default
    if context == .nil then return .Routine~new("", self)
    return .Routine~new("", self, context)
    

-- Doer for sending a message name
::class MessageNameSender
::attribute messageName
::method init
    use strict arg messageName
    self~messageName = messageName
::method do
    use strict arg object, ...
    object~sendWith(self~messageName, arg(2,"a"))
    if var("result") then return result


-----------------------------------------------------------------------------
-- Higher-order actions

::extension String  -- second part
::method reduce
    use strict arg action, context=.nil
    return self~makearray("")~reduce(action, context)
    
    
::extension Collection
::method reduce
    use strict arg action, context=.nil
    doer = action~doer(context) -- parse only once, before iteration
    supplier = self~supplier
    if \ supplier~available then return .nil
    r = supplier~item
    supplier~next
    do while supplier~available
        r = doer~do(r, supplier~item)
        supplier~next
    end
    return r


::extension String -- third part
::method mapchar
    use strict arg action, inplace=.false, context=.nil
    if inplace == .true then raise syntax 93.963 -- in place not applicable to string
    return .MutableBuffer~new(self)~mapchar(action, .true, context)~string
::method mapword
    use strict arg action, inplace=.false, context=.nil
    if inplace == .true then raise syntax 93.963 -- in place not applicable to string
    return .MutableBuffer~new(self)~mapword(action, .true, context)~string


::extension MutableBuffer -- third part
::method mapchar
    use strict arg action, inplace=.true, context=.nil
    doer = action~doer(context) -- parse only once, before iteration
    r = self
    if \inplace then r = self~copy
    string = r~string
    r~delete(1)
    do char over string~makearray("")
        r~append(doer~do(char))
    end
    return r
::method mapword
    use strict arg action, inplace=.true, context=.nil
    doer = action~doer(context) -- parse only once, before iteration
    r = self
    if \inplace then r = self~copy
    string = r~string
    r~delete(1)
    first = .true
    do word over string~space~makearray(" ")
        if \first then self~append(" ")
        r~append(doer~do(word))
        first = .false
    end
    return r


-- Will work with Array, List, Queue, CircularQueue (any collection which supports "first" and "next")
-- These 4 classes are subclasses of  OrderedCollection, so I could extend OrderedCollection to add the method "Map".
-- For test purpose, I create a mixin and extend the 4 classes individually.
-- I don't use a supplier because it works on a snapshot of the collection and is not done for updating the collection
-- (when inplace == .true the collection is updated in place)
::class MappableCollection mixinclass OrderedCollection
::method map
    use strict arg action, inplace=.false, context=.nil
    doer = action~doer(context) -- parse only once, before iteration
    r = self
    if \inplace then r = self~copy
    current = self~first
    do while current <> .nil
        r[current] = doer~do(self[current])
        current = self~next(current)
    end
    return r


::extension Array inherit MappableCollection
::extension List inherit MappableCollection
::extension Queue inherit MappableCollection
--::extension CircularQueue inherit MappableCollection -- mixin already inherited from Queue 


::extension String
::method times
    use strict arg action, context=.nil
    doer = action~doer(context) -- parse only once, before iteration
    do i = 1 to self
        doer~do(i)
    end
    return self

