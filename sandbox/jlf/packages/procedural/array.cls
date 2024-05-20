/*
Procedural version of the Executor's extended methods.
*/

::requires "procedural/collection.cls"

-- ::options trace r

/******************************************************************************/
-- Array helper routines

::routine a public
    -- Empty array of specified shape.
    -- Remember :
    -- When called with no argument, this function returns an array
    -- which is definitively an array with no dimension : an Array (shape [] , 0 items)
    -- Any attempt to assign a value to this array using one or more index raises the error
    -- "Too many subscripts for array; 0 expected"
    -- but it's possible to assign a value by passing NO index: a()[]=value

    -- if arg() == 0 then return .array~new -- no dimension (yet), can be set later.
    -- Bug ? .array~new~dimensions returns [0], should return an array with no dimension (not [] which is an empty vector returned for arrays definitively with 0 dimension).

    -- To support that : a(myMatrix~shape)
    if arg() == 1, arg(1)~isa(.array) then return .array~new(arg(1))

    return .array~new(arg(1, "a")) -- dimension assigned, no longer possible to change it


::routine v public
    -- Vector (rank = 1)
    -- When no argument, arg(1, "a") returns an array with NO dimension. This is not what we want here, we want 1 dimension.
    if arg() == 0 then return .array~new(0) -- empty vector
    return arg(1, "a")


/******************************************************************************/
-- Object can't inherit from a mixinclass.
-- Naming convention: Object_<package name>
::class "Object_array" public

::method shape_extension class
    -- R←⍴Y (Rho)
    -- The shape of a scalar is an empty vector []
    use strict arg object
    return v()


::method shapeToString_extension class
   -- Helper to display the shape of any object
   use strict arg object
   shape = .ExtensionDispatcher~shape(object)
   if shape~dimension == 0 then return "no shape"
   return "[" || shape~toString("L", ",") || "]"


::method shapeToPrettyString_extension class
    use strict arg object, separator=""
    if .ExtensionDispatcher~isA(object, .array) then do
        shape = .ExtensionDispatcher~shapeToString(object)
        if shape <> "no shape" then shape = "shape" shape
        return shape || separator
    end
    return ""


/******************************************************************************/
::class "APLArray" public

/*
                  | value                         | dimension | dimensions                    | size | shape
------------------+-------------------------------+-----------+-------------------------------+------+-----------------------------
.array~new        | an Array (no shape, 0 items)  | 0         | [0]                           | 0    | an Array (shape [], 0 items)
.array~new(a())   | an Array (shape [], 0 items)  | 0         | an Array (no shape, 0 items)  | 1    | []
.array~new(v())   | an Array (shape [], 0 items)  | 0         | an Array (no shape, 0 items)  | 1    | []
a()               | an Array (shape [], 0 items)  | 0         | an Array (no shape, 0 items)  | 1    | []
v()               | []                            | 1         | [0]                           | 0    | [0]
*/
::method shape_extension class
    -- The shape of an array is an array which gives the size of each dimension (APL).
    use strict arg array
    dimensions = .ExtensionDispatcher~dimensions(array)
    if array~dimension == 0 then do
        -- Two cases:

        -- array definitively with no dimension : .array~new(.array~new), also returned by a()
        -- This case exist in APL : the scalars have no dimension, their shape is an empty vector
        if dimensions~items == 0 then return v() -- empty vector (1 dimension, 0 item)

        -- array with no dimension yet assigned (the first assignment will determine the dimension).
        -- This case does not exist in APL
        -- Bug ? self~dimensions returns [0]. It should return an array with no dimension.
        return a() -- really no shape yet, return an array with no dimension.
    end
    return dimensions


/******************************************************************************/
::class "ArrayPrettyPrinter" public

-- Keep it. Same signature as other ppString.
::method ppString_extension class
    use strict arg array, surroundByQuotes=.true, expandCollection = (.CollectionPrettyPrinter~expandCollection)
    return .ExtensionDispatcher~ppRepresentation(array, surroundByQuotes, expandCollection)


::method ppRepresentation_extension class
    /*
    Return a condensed string representation of the array.
    Ex :
    .ExtensionDispatcher~ppString(.array~of(1,"two", .array~of(1, "two", 3), .array~of(1, "two"))) -- [ 1,'two',[ 1,'two', 3],[ 1,'two']]

    Recursive arrays are supported. A reference *R is inserted in the representation,
    where R is the reference of the part already displayed.
    Ex :
    a = .array~of("string1", "string2")
    b = .array~of("string2")
    b~append(a)
    a~append(b)
    a~append(a)

           +<------------------------------------+<--------+
           |                                     ^         ^
           V                                     |         |
        +---------+---------+-----+--+--+        |         |
     a1=| string1 | string2 |  .  |  .  |        |         |
        +---------+---------+--|--+--|--+        |         |
                               |     |           |         |
                               |     +---------->+         |    Reference array already displayed : *a1
                               V                           |
                           +---------+-----+               |
                           | string2 |  .  |               |
                           +---------+--|--+               |
                                        |                  |
                                        +----------------->+    Reference array already displayed : *a1

    say .ExtensionDispatcher~ppString(a)
        a1=['string1','string2',['string2',*a1],*a1]

    */
    use strict arg array, surroundByQuotes=.true, expandCollection = (.CollectionPrettyPrinter~expandCollection),,
                   maxItems=(-1), sparse="..", ellipsis="...", separator=",", val=(array), referencesTable=.nil, counter=0, trace=.false
    expandCollection = .CollectionPrettyPrinter~expandCollection
    if trace then .traceOutput~say("       >I> Method ppRepresentation_extension")
    if trace then trace i
    -- Remember : this code has been duplicated in pipe.cls, routine dataflow_representation.
    if .nil == referencesTable then referencesTable = .ExtensionDispatcher~collectReferences(val, maxItems) -- do it before pretty printing, to display the reference identifiers only when needed
    if .ExtensionDispatcher~isA(val, .array), val~dimension == 1 then do
        reference = referencesTable[val]
        if reference~selfReference, reference~displayed then return "*a" || reference~id -- pointer to the array already displayed
        reference~displayed = .true
        if reference~selfReference then do
            counter += 1
            reference~id = counter -- id assigned at first display, to have a natural progression
            valstr = "a" || reference~id || "=" || "["
        end
        else valstr = "["
        -- each item of the array is inserted.
        items = 0 -- Not global. Each item being an array will have maxItems items inserted.
                  -- Maybe a global count could be useful... Will see on usage.
        sep = ""
        if maxItems >= 0 then s = val~supplier(/*maxItems+1*/) -- +1 to let display the ellipsis
        else s = val~supplier
        i = 1 -- current index, will let detect sparse sections
        do while s~available
            item = s~item
            index = s~index
            if maxItems >= 0, items >= maxItems then do
                valstr ||= sep || ellipsis
                leave
            end
            if i <> index then do
                valstr ||= sep || sparse
                sep = separator
            end
            valstr ||= sep || .ExtensionDispatcher~ppRepresentation(val, surroundByQuotes, expandCollection, maxItems, sparse, ellipsis, separator, item, referencesTable, counter, trace)
            sep = separator
            items += 1
            i = index + 1 -- next index
            s~next -- skip sparse section, if any
        end
        if maxItems >= 0, items >= maxItems then nop -- truncated, ellipsis already added, don't add sparse
        else do -- if not truncated
            if i <= val~size then do
                valstr ||= sep || sparse
            end
        end
        valstr ||= "]"
        return valstr
    end
    else if .ExtensionDispatcher~isA(val, .array) then do
        -- for the arrays with dimension <> 1, indicate their shape and item number
        valstr = val~string
        return "("valstr .ExtensionDispatcher~shapeToPrettyString(val, ", ") || val~items "items)"
    end
    else return .ExtensionDispatcher~ppString(val)


::method collectReferences_extension class -- private (must be public)
    -- Collect all the references to array.
    -- Same code organization as ppRepresentation, to make easier joint updates.
    -- Use the same logic as ppRepresentation to limit the number of items to analyze.
    -- When a referenced array is seen more than once, then the reference is marked as selfReference, to stop the infinite recursion.
    use strict arg array, maxItems=(-1), val=(array), referencesTable=(.identityTable~new)
    if .ExtensionDispatcher~isA(val, .array), val~dimension == 1 then do
        reference = referencesTable[val]
        if .nil <> reference then do
            reference~selfReference = .true
            return referencesTable
        end
        referencesTable[val] = .ObjectSelfReference~new
        -- each item of the array is analyzed.
        items = 0 -- Not global. Each item being an array will have maxItems items inserted.
                  -- Maybe a global count could be useful... Will see on usage.
        if maxItems >= 0 then s = val~supplier(/*maxItems+1*/) -- +1 to follow the logic of ppRepresentation
        else s = val~supplier
        do while s~available
            item = s~item
            index = s~index
            if maxItems >= 0, items >= maxItems then return referencesTable
            .ExtensionDispatcher~collectReferences(val, maxItems, item, referencesTable)
            items += 1
            s~next -- skip sparse section, if any
        end
        return referencesTable
    end
    return referencesTable


/******************************************************************************/
::class ObjectSelfReference private

::attribute selfReference   -- indicator of self reference
::attribute id              -- unique identifier, used for display of references by ppRepresentation
::attribute displayed       -- will be set to .true by the pretty-printer when displaying the referenced for the first time

::method init
    self~selfReference = .false
    self~id = 0
    self~displayed = .false



