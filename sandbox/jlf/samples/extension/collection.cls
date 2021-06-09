-- Compatibility with ooRexx5
if \ .stringtable~isa(.class) then .environment["STRINGTABLE"] = .directory

--::options trace i
::requires "extension/array.cls"

/******************************************************************************/

/*
Remember:
In CoreClasses.orx, the class CircularQueue has a method string.
.CircularQueue~of(1,2,3)~string=     -- "1,2,3"

The method ppString defined at Object level delegates to string,
that's why I see (1,2,3) when pretty printing an array which contains
this CircularQueue.

The class Queue has no method string, and is displayed (a Queue)
by the method ppRepresentation.

I would like the same display for Queue and CircularQueue.
That's why I define the method ppString on the class Collection.
All the collections will benefit from this display.

See output of concurrency/generator-test.rex
*/


::class "CollectionPrettyPrinter" mixinclass Object public

::method ppString
    use named arg ppOptions. = (.Stem~new), ppOptions.expandCollection = .false

    /*
       Workaround, the method ~ppString defined in array.cls is not called
       ((1,2,3),(4,5,6))== is display with "Array" in front of each line:
            an Array (shape [2], 2 items)
             1 : Array[ 1, 2, 3]
             2 : Array[ 4, 5, 6]
    */
    if self~isa(.array) then return self~ppRepresentation

    -- This option is not applicable to arrays, hence this location of the test.
    -- For the moment, I don't activate by default the display of items for the
    -- other collections because that gives long lists when displaying .environment
    -- from ooRexxShell.
    if ppOptions.expandCollection == .false then return self~objectName

    -- todo ? add a parameter maxItems to ~allItems
    if self~isA(.OrderedCollection) then do
        return self~class~id || self~allItems~ppRepresentation(ppOptions. : ppOptions.)
    end
    else do
        return self~class~id || self~allItems~sortWith(.StringNumericComparator~new)~ppRepresentation(ppOptions. : ppOptions.)
    end


/******************************************************************************/

-- Directory initializer
--     .directory~of("key 1", "value 1", "key 2", 2, a1:1, a2:2)
-- The key-value where the key is compatible with a named  argument can be passed as named argument.
-- The key-value where the key is not compatible with a named argument can be passed as a pair of positional arguments.
::extension Directory
::method of class
    use arg key, value, ...
    directory = .context~namedArgs
    do i = 1 to arg() by 2
        directory[arg(i)] = arg(i+1)
    end
    return directory


-- helper routine d() to create a directory
--     d(a1:1, a2:2)
--     d("key 1", "value 1", "key 2", 2, a1:1, a2:2)
-- Next step : Modify the parser to support directly a directory literal (a1:1, a2:2)
-- Should support any string as key, with a notation "my key":1
-- Or maybe still more general, for a table: (expressionKey1:expressionValue1, ...)
::routine d public
    if arg() == 0 then return .context~namedArgs
    return .Directory~sendWith("of", .context~args, n:.context~namedArgs)


/******************************************************************************/

/*
Inspired by rgf_util2 NumberComparator.
Compares Rexx (string) numbers.
Numbers are compared as numbers, but if one or both arguments are not numbers,
then the normal string "compareTo" will be employed.

Comparison of numbers is carried out under NUMERIC DIGITS 40, which allows
comparing numbers in the 2**128 range
*/
::class "StringNumericComparator" public
::method compare
    use strict arg left, right

    if datatype(left, "n"), datatype(right, "n") then
    do
        numeric digits 40           -- allow to deal with numbers up to 2**128
        return (left-right)~sign    -- returns -1 (left<right), +1 (left>right), 0 (left=right)
    end
    return left~string~compareTo(right~string)


/******************************************************************************/

-- Helper to get a table representation of any collection
-- Careful: If you have a directory with a key "TABLE", and you retrieve the
-- related item with the method ~TABLE then you will NOT get this item. You
-- will get the whole directory as a table.
-- You should retrieve the item like that: directory["TABLE"].
::extension Collection
::method table
    return self~supplier~reduce(initial:.Table~new){accu[index] = item}


-- Helper to get a table representation of a supplier
-- A copy is made to not consume the supplier
::extension Supplier
::method table
    return self~copy~reduce(initial:.Table~new){accu[index] = item}
