/*
Procedural version of the Executor's extended methods.
*/

-- Compatibility with ooRexx5
if \ .stringtable~isa(.class) then .environment["STRINGTABLE"] = .directory

/******************************************************************************/

/*
Remember:
In CoreClasses.orx, the class CircularQueue has a method string.
.CircularQueue~of(1,2,3)~string=     -- "1,2,3"

The method ppString defined at Object level delegates to string,
that's why I see (1,2,3) when pretty printing an array which contains
this CircularQueue.

The class Queue has no method string, and is displayed (a Queue)
by the method ppString.

I would like the same display for Queue and CircularQueue.
That's why I define the method ppString on the class Collection.
All the collections will benefit from this display.
*/


/******************************************************************************/
::class "CollectionPrettyPrinter" public

-- expand collections (other than array) having ~items <= this constant
::constant expandCollection 10


::method ppString_extension class
    use strict arg collection, surroundByQuotes=.true, expandCollection = (.CollectionPrettyPrinter~expandCollection)

    -- This option is not applicable to arrays, hence this location of the test.
    -- For the moment, I don't activate by default the display of items for the
    -- other collections because that gives long lists when displaying .environment
    -- from ooRexxShell.
    if expandCollection == 0 then return collection~objectName
    if collection~items > expandCollection then return collection~objectName

    -- todo ? add a parameter maxItems to ~allItems
    -- same logic in Array_ppString
    if collection~isA(.OrderedCollection) then do
        return collection~class~id || .ExtensionDispatcher~ppString(collection~allItems, surroundByQuotes, expandCollection)
    end
    else do
        return collection~class~id || .ExtensionDispatcher~ppString(collection~allItems~sortWith(.StringNumericComparator~new), surroundByQuotes, expandCollection)
    end


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


