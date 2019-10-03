--::options trace i
::requires "extension/array.cls"


/*
Remember:
In CoreClasses.orx, the class CircularQueue has a method string.
.CircularQueue~of(1,2,3)~string=     -- "1,2,3"

The method ppString defined at Object level delegates to string,
that why I see (1,2,3) when pretty printing an array which contains
this CircularQueue.

The class Queue has no method string, and is displayed (a Queue)
by the method ppRepresentation.

I would like the same display for Queue and CircularQueue.
That's why I define the method ppString on the class Collection.
All the collections will benefit from this display.
*/


::class "CollectionPrettyPrinter" mixinclass Object public

::method ppString
    -- todo ? add a parameter maxIems to ~makearray
    return self~class~id || self~makearray~ppRepresentation



