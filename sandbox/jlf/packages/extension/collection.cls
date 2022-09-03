-- Compatibility with ooRexx5
if \ .stringtable~isa(.class) then .environment["STRINGTABLE"] = .directory

::extension MapCollection inherit MapCollectionInitializer
::extension Collection    inherit CollectionPrettyPrinter

--::options trace i

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

::constant expandCollection 10 -- expand collections (other than array) having ~items <= this constant

::method ppString
    use named arg ppOptions. = (.Stem~new), ppOptions.expandCollection = (.CollectionPrettyPrinter~expandCollection)

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
    if ppOptions.expandCollection == 0 then return self~objectName
    if self~items > ppOptions.expandCollection then return self~objectName

    -- todo ? add a parameter maxItems to ~allItems
    -- same logic in array~ppRepresentation
    if self~isA(.OrderedCollection) then do
        return self~class~id || self~allItems~ppRepresentation(ppOptions. : ppOptions.)
    end
    else do
        return self~class~id || self~allItems~sortWith(.StringNumericComparator~new)~ppRepresentation(ppOptions. : ppOptions.)
    end


/******************************************************************************/

-- MapCollection initializer
--     aMapCollection~of(key1, value1, key2, value2, ..., n1:v1, n2:v2, ...)
--     aMapCollection~of( (key1, value1), (key2, value2), ..., n1:v1, n2:v2, ...)
-- The key-value where the key is compatible with a named  argument can be passed as named argument.
-- The key-value where the key is not compatible with a named argument can be passed as a pair of positional arguments.
-- Careful: ooRexx5 added .MapCollection~of where each key-value must be an array (key, value).
-- I make this implementation compatible with ooRexx5.
-- If the first argument is an array then assume it's the ooRexx5 way.

::class "MapCollectionInitializer" mixinclass Object public

::method of class
    collection = .context~namedArgs -- a directory
    if collection <> self then collection = self~new~putall(collection) -- convert the directory of named arguments to the target collection
    if arg(1)~isA(.array) then do
        -- Assume it's the ooRexx5 way...
          args = arg(1, 'a')
          -- get the arguments as an array

          -- create an instance of this class
          collection = self~new

          -- process each of the arguments.  Omitted arguments
          -- are not permitted and each argument must be an
          -- array of exactly two items
          loop i = 1 to args~last
             -- no omitted
             if \args~hasIndex(i) then
                raise syntax 93.903 array(i)
             arg = args[i]
             -- get the argument value.
             if \arg~isA(.array) then
                raise syntax 88.923 array(.context~name, i, arg)
             if \arg~dimension == 1 then
                raise syntax 88.923 array(.context~name, i, arg)
             -- this must have just two items
             if arg~items \= 2 | arg~last \= 2 then
                raise syntax 88.924 array(.context~name, i, 2)

             -- the index is first, the value is second, the reverse of PUT
             collection~put(arg[2], arg[1])
          end
    end
    else do
        loop i = 1 to arg() by 2
            collection~put(arg(i+1), arg(i))
        end
    end
    return collection


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
    use strict arg itemPlusIndex=.false
    if itemPlusIndex then return self~supplier~table(itemPlusIndex)
    return .table~new~putAll(self)


-- Helper to get a table representation of a supplier
-- Note: the supplier is consumed, so pass a copy of the supplier if needed
::extension Supplier
::method table
    use strict arg itemPlusIndex=.false
    if itemPlusIndex then do
        -- This supplier has been typically generated by eachI, selectI, takeI, generateI, etc...
        -- Rebuild a table with the right indexes
        table = .table~new
        do while self~available
            table[self~item[2]] = self~item[1]
            self~next
        end
        return table
    end
    return .table~new~putAll(self)
