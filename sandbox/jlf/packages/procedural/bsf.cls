/*
Procedural version of the Executor's extended methods.
*/

/******************************************************************************/
::class "BSFObject" public

::method isA_extension class
    use strict arg object, class

    if object~hasMethod("bsf.isArray") then do
        -- From BSF version 850.20240524, it's possible to test if a java object is an array:
        objectIsArray = object~bsf.isArray
    end
    else do
        -- To remain compatible with ooRexx 4.2 which can't use BSF version 850.20240524
        objectIsArray = object~class~id == "BSF_ARRAY_REFERENCE"
    end

    select
        when object~bsf.isA(.java.lang.String),     class == .String then return .true
        when object~bsf.isA(.java.lang.Boolean),    class == .String then return .true
        when object~bsf.isA(.java.lang.Byte),       class == .String then return .true
        when object~bsf.isA(.java.lang.Character),  class == .String then return .true
        when object~bsf.isA(.java.lang.Double),     class == .String then return .true
        when object~bsf.isA(.java.lang.Float),      class == .String then return .true
        when object~bsf.isA(.java.lang.Integer),    class == .String then return .true
        when object~bsf.isA(.java.lang.Long),       class == .String then return .true
        when object~bsf.isA(.java.lang.Short),      class == .String then return .true

        /*
        arr = bsf.createArray(.bsf4rexx~int, 3, 4)
        arr[1,1] = 11
        arr[3,4] = 34
        arr~class= -- (The BSF_ARRAY_REFERENCE class)

        .bsf4rexx~bsf.dir= -- a Directory of pre-registered classes
        .bsf4rexx~array.class= -- (class java.lang.reflect.Array)

        jsystem = bsf.loadClass('java.lang.System')
        properties = jsystem~getProperties
        properties~class= -- (The BSF_REFERENCE class)

        2016-11-06, ---rgf
        On ooRexx 5.0.0 beta the DO...OVER only works if the receiving object has a MAKEARRAY method and does
        not rely on the UNKNOWN method at all. For this reason we need to have a MAKEARRAY method present in
        the BSF class: starting with basing BSF4ooRexx on Java 1.6/6.0 in November 2016, all Java objects
        implementing java.lang.Iterable, java.util.Enumeration, java.util.Collection, java.util.Iterator or java.util.Map
        will get a "virtual ooRexx" MAKEARRAY and SUPPLIER method, returning an ooRexx array or an ooRexx supplier.

        The new Java code will create a Rexx array in Java and populate it, returning the RexxProxy object. The contained
        Rexx object can be extracted with the external Rexx function BsfRexxProxy(proxy,"object")

        It is expected that this particular message gets only invoked by DO...OVER, which expects (as of ooRexx 5.0.0beta)
        a genuine Rexx array object to be returned
        */
        when objectIsArray, class == .Array then return .true
        when objectIsArray, class == .OrderedCollection then return .true
        when objectIsArray, class == .Collection then return .true

        otherwise return object~isA(class)
    end
    return .false


/******************************************************************************/
::class "BSF_ARRAY_REFERENCE_EXTENSION" public

::method dimensions_extension class
    /*
    arr = bsf.createArray(.bsf4rexx~int, 0)
    .extensiondispatcher~dimensions(arr)=       -- [ 0]

    arr = bsf.createArray(.bsf4rexx~int, 10)
    .extensiondispatcher~dimensions(arr)=       -- [ 10]

    arr = bsf.createArray(.bsf4rexx~int, 10,10,10)
    .extensiondispatcher~dimensions(arr)=       -- [ 10, 10, 10]

    arr = bsf.createArray(.bsf4rexx~int, 10,0,10)
    .extensiondispatcher~dimensions(arr)=       -- [ 10, 0, 0]      Different from ooRexx
    .array~new(10,0,10)~dimensions=             -- [ 10, 0, 10]
    */
    use strict arg object
    dimension = object~dimension
    dimensions = .array~new(dimension)
    do i=1 to dimension
        dimensions[i] = object~dimension(i)
    end
    return dimensions


/******************************************************************************/
::class "BSFPrettyPrinter" public

::method ppString_extension class
    use strict arg object, surroundByQuotes=.true

    -- Don't use makeArray: A multi-dimensional Array is converted into a non-sparse single-dimensional Array.
    -- ppRepresentation is better.
    if .ExtensionDispatcher~isA(object, .Array) then return .ExtensionDispatcher~ppRepresentation(object, surroundByQuotes)

    -- Collection not supported bevause BSF doesn't support ~allItems.

    -- strings are surrounded by quotes, except string numbers.
    if .ExtensionDispatcher~isA(object, .String) then return .ExtensionDispatcher~ppString(object~toString, surroundByQuotes)

    -- To make a distinction between a real string and other objects, surround by (...)
    return "("object~toString")"
