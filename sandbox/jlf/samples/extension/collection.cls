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
*/


::class "CollectionPrettyPrinter" mixinclass Object public

::method ppString
    -- Workaround, the method ~ppString defined in array.cls is not called
    if self~isa(.array) then return self~ppRepresentation

    -- todo ? add a parameter maxItems to ~makearray
    return self~class~id || self~makearray~ppRepresentation



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
