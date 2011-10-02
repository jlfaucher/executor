/*
This script needs a modified ooRexx interpreter which support extension of predefined ooRexx classes.
Don't requires this script directly. Instead, requires "extension/extensions.cls"
*/

--::options trace i

::class "ArrayInitializer" mixinclass Object public

-- Instance methods, which takes into account the dimensions of the array
-- If there is only one argument, and this argument is a string, then each word of the string is an item.
--     .array~new(2,3)~of(1 2 3 4 5 6)
--     1 2 3
--     4 5 6
-- Otherwise each argument is an item.
--     .array~new(2,2)~of(1,2,3,4,5,6)
--     1 2 3
--     4 5 6
-- The items are a list of values that must be assigned to the cells of the array.
-- If there are too many items, the extra items are ignored.
-- If there are fewer items than implied by the dimensions, the list of items is reused as 
-- many times as necessary to fill the array.
::method of
    if arg() == 0 then args = .array~of(.nil)
    if arg() == 1, arg(1)~isA(.String) then args = arg(1)~subwords
    else args = arg(1, "a")
    argsCount = args~items
    
    dim = self~dimension
    if dim == 0 then dim = 1
    index = dim~times{1} -- Initializes all indexes at 1

    -- to continue...
