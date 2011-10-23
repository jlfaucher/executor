/*
This script needs a modified ooRexx interpreter which support extension of predefined ooRexx classes.
Don't requires this script directly. Instead, requires "extension/extensions.cls"
*/

--::options trace i

::class "ArrayInitializer" mixinclass Object public

/*
Initializer (instance method) which takes into account the dimensions of the array.

If there is only one argument, and this argument is a string, then each word of the string is an item (APL-like).
    .array~new(2,3)~of(1 2 3 4 5 6)
    1 2 3
    4 5 6

If there is only one argument, and this argument has the method ~supplier then each item returned by the argument's supplier is an item.
    .array~new(2,3)~of(1~upto(6))
    1 2 3
    4 5 6

If there is only one argument, and this argument is a doer, then the doer is called for each cell to initialize.
The index of the current cell is passed as argument to the doer.
The value returned by the doer is the item for the current cell.
    .array~new(2,3)~of{10*arg(1)}
    10 20 30
    40 50 60

Otherwise each argument is an item as-is.
    .array~new(2,3)~of(1,2,3,4,5,6)
    1 2 3
    4 5 6

The items are a list of values that must be assigned to the cells of the array.
Rules inspired by APL :
If there are too many items, the extra items are ignored.
If there are fewer items than implied by the dimensions, the list of items is reused as 
many times as necessary to fill the array.
    .array~new(2,3)~of(1)
    1 1 1
    1 1 1
*/

::method of
    if arg() == 0 then args = .array~of(.nil)
    else if arg() == 1, arg(1)~isA(.String) then args = arg(1)~subwords
    else args = arg(1, "a")
    argsCount = args~items
    
    dim = self~dimension
    if dim == 0 then dim = 1 -- assumes it's a vector
    index = dim~times{1} -- Initializes all indexes at 1

    -- to continue...


-- The shape of an array is an array which gives the size of each dimension.
::method shape
    shape = .array~new(self~dimension)
    do i=1 to self~dimension
        shape[i] = self~dimension(i)
    end
    return shape

