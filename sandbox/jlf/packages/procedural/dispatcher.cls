/*
Procedural version of the Executor's extended methods.

Design notes:
Use the same classes as Executor.
Since this file is not loaded by Executor, there is no risk of collision.

Illustration with the ppstring method which is added by extension on several classes.
Query from ooRexxShell:
ooRexx[sh]> ?method ppstring
PM P.G.    'PPSTRING' : 'ArrayPrettyPrinter' (array.cls)
PM P.G.    'PPSTRING' : 'CollectionPrettyPrinter' (collection.cls)
PM P.G.    'PPSTRING' : 'MutableBufferPrettyPrinter' (string.cls)
PM P.G.    'PPSTRING' : 'StringPrettyPrinter' (string.cls)
P. P.G.    'PPSTRING' : 'Object' (object.cls)
P. PCG.    'PPSTRING' : 'Object' (object.cls)

object.cls
    -- Object can't inherit from a mixinclass (would raise "cannot inherit from itself")
    ::extension Object
    ::method ppString
        <implementation>

string.cls
    ::extension String inherit StringPrettyPrinter
    ::class "StringPrettyPrinter" mixinclass Object public
    ::method ppString
        <implementation>

We retrieve the same classes in the procedural packages.
The method names are suffixed with "_extension". See hasMethod for the reason.

The Object class can't be extended by a mixin class, it's a direct extension.
The Object class can be extended in several packages.
The naming convention for the Object's implementation classes is Object_<package>.
Example:
    Object_object   defined in the package object.cls
    Object_array    defined in the package object.cls

The ExtensionDispatcher class is a facade forwarding to the right implementation
class. The search order is the same as the ooRexx interpreter search order for
method selection. This search order is hardcoded in each facade's method.

When calling the ppstring method, it's not possible to use myObject~ppstring.
Must use .ExtensionDispatcher~ppstring(myObject).

Integration with rgf_util2:
dump2(collection, ...)
    for each item of the collection's supplier
    call
        pp2(s~item)
        call
            either s~item~ppString                          if Executor
            or     .ExtensionDispatcher~ppstring(s~item)    if ooRexx 4.2 / 5 when dispatcher.cls loaded
            or     the rgf_util2 implementation
*/

.environment~setentry("ExtensionDispatcher", .ExtensionDispatcher)

::requires "procedural/array.cls"
::requires "procedural/collection.cls"
::requires "procedural/object.cls"
::requires "procedural/string.cls"


/******************************************************************************/
::class "ExtensionDispatcher" public

::method hasMethod class
    if arg() == 1 then do
        -- Querying itself, not querying an extended object
        use strict arg methodname
        /*
        Got an error with
            ooRexx[sh]> .ArrayPrettyPrinter=
            error Object "1" does not understand message "ppRepresentation"
        because .ArrayPrettyPrinter~hasMethod("ppString") returns .true,
        making believe that it supports ~ppString for itself.

        The 1 comes from this call in rgf_util2.rex
            ::routine pp2
              if a1~hasMethod("ppString") then return a1~ppString(surroundByQuotes)
        where a1 == .ArrayPrettyPrinter
              surroundByQuotes == .true
        surroundByQuotes is taken as the object on which the procedural method
        must be applied:
            array.cls
            ::class "ArrayPrettyPrinter"
            ::method ppString class
                use strict arg array, ...

        Workaround:
        The methods of the implementation classes are named xxx_extension.
        The facade methods of ExtensionDispatcher are hidden by ~hasMethod.
        */
        methodname_implementationClass = methodname"_implementationClass"
        if self~hasMethod:super(methodname_implementationClass) then return .false -- it's a facade method
        return self~hasMethod:super(methodName)
    end
    else do
        -- Querying an extended object
        use strict arg object, methodname
        methodname_implementationClass = methodname"_implementationClass"
        if \ self~hasMethod:super(methodname_implementationClass) then return .false
        implementationClass = self~send(methodname_implementationClass, object, /*raiseError*/ .false)
        if .nil == implementationClass then return .false
        return implementationClass~hasMethod(methodname"_extension") -- by design, should always be .true, unless the implementation is not yet finalized
    end


/*********************/
/* Extension methods */
/*********************/

--------------------------------------------------------------------------------
-- collectReferences
--------------------------------------------------------------------------------
::method collectReferences_implementationClass class private
    use strict arg object, raiseError = .true
    select
        when object~isA(.Array) then return .ArrayPrettyPrinter
        otherwise if raiseError then raise syntax 97.001 array (object, "collectReferences") -- Object method not found
    end
    return .nil


::method collectReferences class
    use strict arg object, ...
    implementationClass = self~collectReferences_implementationClass(object)
    forward to (implementationClass) message "collectReferences_extension"


--------------------------------------------------------------------------------
-- ppRepresentation
--------------------------------------------------------------------------------
::method ppRepresentation_implementationClass class private
    use strict arg object, raiseError = .true
    select
        when object~isA(.Array) then return .ArrayPrettyPrinter
        otherwise if raiseError then raise syntax 97.001 array (object, "ppRepresentation") -- Object method not found
    end
    return .nil


::method ppRepresentation class
    use strict arg object, ...
    implementationClass = self~ppRepresentation_implementationClass(object)
    forward to (implementationClass) message "ppRepresentation_extension"


--------------------------------------------------------------------------------
-- ppString
--------------------------------------------------------------------------------
::method ppString_implementationClass class private
    use strict arg object, raiseError = .true
    select
        when object~isA(.Array)          then return .ArrayPrettyPrinter
        when object~isA(.Collection)     then return .CollectionPrettyPrinter
        when object~isA(.MutableBuffer)  then return .MutableBufferPrettyPrinter
        when object~isA(.String)         then return .StringPrettyPrinter
        otherwise                             return .Object_object
    end
    return .nil


::method ppString class
    use strict arg object, ...
    implementationClass = self~ppString_implementationClass(object)
    forward to (implementationClass) message "ppString_extension"


--------------------------------------------------------------------------------
-- quoted
--------------------------------------------------------------------------------
::method quoted_implementationClass class private
    use strict arg object, raiseError = .true
    select
        when object~isA(.String) then return .StringHelpers
        otherwise if raiseError  then raise syntax 97.001 array (object, "quoted") -- Object method not found
    end
    return .nil


::method quoted class
    use strict arg object, ...
    implementationClass = self~quoted_implementationClass(object)
    forward to (implementationClass) message "quoted_extension"


--------------------------------------------------------------------------------
-- shape
--------------------------------------------------------------------------------
::method shape_implementationClass class private
    use strict arg object, raiseError = .true
    select
        when object~isA(.Array) then return .ArrayPrettyPrinter
        otherwise                    return .Object_array
    end
    return .nil


::method shape class
    use strict arg object, ...
    implementationClass = self~shape_implementationClass(object)
    forward to (implementationClass) message "shape_extension"


--------------------------------------------------------------------------------
-- shapeToPrettyString
--------------------------------------------------------------------------------
::method shapeToPrettyString_implementationClass class private
    use strict arg object, raiseError = .true
    return .Object_array


::method shapeToPrettyString class
    use strict arg object, ...
    implementationClass = self~shapeToPrettyString_implementationClass(object)
    forward to (implementationClass) message "shapeToPrettyString_extension"


--------------------------------------------------------------------------------
-- shapeToString
--------------------------------------------------------------------------------
::method shapeToString_implementationClass class private
    use strict arg object, raiseError = .true
    return .Object_array


::method shapeToString class
    use strict arg object, ...
    implementationClass = self~shapeToString_implementationClass(object)
    forward to (implementationClass) message "shapeToString_extension"
