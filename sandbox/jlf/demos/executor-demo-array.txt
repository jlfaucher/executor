prompt directory off
demo on

--------------------
-- Array programming
--------------------

/*
rank

APL R←⍴⍴Y
An array may have 0 or more axes or dimensions.
The number of axes of an array is known as its rank.
An array with 0 axes (rank 0) is called a scalar
An array with 1 axis (rank 1) is called a vector.
An array with 2 axes (rank 2) is called a matrix or table.
An array with 3 axes (rank 3) is called a cube.
An array with more than 2 axes is called a multi-dimensional array
*/
sleep no prompt

/*
shape

APL R←⍴Y (Rho)
The shape of a scalar is an empty vector []
The shape of an array is an array which gives the size of each dimension.
*/
sleep no prompt

/*
ooRexx:
Any object other than an array is a scalar.
In particular, a string is a scalar, not an array as in APL.
Special case which does not exist in APL : The rank of an array with no dimension yet assigned is -1.
*/
sleep no prompt

-- scalar
"string"~shape=
sleep
"string"~rank=
sleep no prompt

-- array with no dimension
.array~new~shape=
sleep
.array~new~rank=
sleep no prompt

/*
The helper v(...) creates a vector.
*/
sleep no prompt

-- empty vector
v()=
sleep
v()~rank=
sleep no prompt

-- vector of 3 items
v(0,1,2)~shape=
sleep
v(0,1,2)~rank=
sleep no prompt

/*
The helper a(...) creates an empty array of specified dimensions.
It's almost similar to .array~new(...), except for a() which returns an array with 0 dimension (a scalar).
Once the number of dimension(s) is fixed, it's no longer possible to change it.
This is different from .array~new which returns an array without dimension.
The number of dimension(s) will be determined by the first access to the array:
a = .array~new; say a[]        -- Not enough positional arguments for method; 1 expected
a = .array~new; say a[1]       -- 1 dimension
a = .array~new; say a[1,1]     -- 2 dimensions
*/
sleep no prompt

-- array with 0 dimension (scalar)
nodim = a()
sleep
nodim=
sleep
nodim~rank=
sleep no prompt

-- you can't use any index with such array
nodim[1]=
sleep no prompt

-- but no index is ok
nodim[]=
sleep
nodim[] = "hello!"
sleep
nodim[]=
sleep no prompt

-- empty vector of shape 5
a(5)~shape=
sleep
a(5)~rank=
sleep no prompt

-- empty matrix of shape 2,2
a(2,2)~shape=
sleep
a(2,2)~rank=
sleep no prompt

-- empty cube of shape 3,3,3
a(3,3,3)~shape=
sleep
a(3,3,3)~rank=
sleep no prompt

/*
The instance method array~of is an initializer which takes into account the dimensions (shape) of the array.

Rules inspired by APL :
If there are too many items, the extra items are ignored.
If there are fewer items than implied by the dimensions, the list of items is reused as many times as necessary to fill the array.
*/
sleep
a(6)~of(1,2,3)=
sleep
a(2,3)~of(1,2,3)=
sleep
a(6)~of(1,2,3,4,5,6,7,8,9)=
sleep
a(2,3)~of(1,2,3,4,5,6,7,8,9)=
sleep no prompt

/*
If there is only one argument, and this argument has the method ~supplier then each item returned by the argument's supplier is an item.
*/
sleep
a(2,3)~of(.environment)=
sleep no prompt

/*
If there is only one argument, and this argument is a doer, then the doer is called for each cell to initialize.
The value returned by the doer is the item for the current cell.
If no value returned then the cell remains unassigned.
*/
sleep
a(2,3)~of{ if item//4 <> 0 then 10*item }=
sleep no prompt

/*
If there is more than one argument then each argument is an item as-is.
If some arguments are omitted, then the corresponding item in the initialized array remains non-assigned.
*/
sleep
a(2,3)~of(1,,3,,5,)=
sleep no prompt

/*
reshape

APL R←X⍴Y (Rho)
args : new dimension(s)
*/
sleep
a(5)~of{ 2*item }=
sleep
a(5)~of{ 2*item }~reshape(3,3)=
sleep no prompt

/*
each

APL R←,Y (Ravel)
Y may be any array. R is a vector of the elements of Y taken in row-major order.
inverse of reshape, which turns any data into a vector whose length is the product
of the shape vector (the dimensions) of the operand array
*/
sleep
a(1,2,3)~of{index}=
sleep
a(1,2,3)~of{index}~each=
sleep no prompt

/*
depth

APL R←≡Y (Equal Underbar)
Depth (≡) indicates the degree of nesting within an array.
It returns a non-negative integer which defines the maximum number of levels
of structure to be penetrated in order to get to a simple scalar where simple means non-nested.
The depth of an array is 1 greater than that of its most deeply nested item.

ooRexx:
Returns "infinity" when the array is self-referencing.
*/
sleep
1~depth=
sleep
v(1)~depth=
sleep
v(v(1))~depth=
sleep
v=v(1); v~append(v); v~depth=;
sleep no prompt

/*
enclose

APL R←⊂Y (Left Shoe)
If Y is a simple scalar, R is the simple scalar unchanged.
Otherwise, R has a depth whose magnitude is one greater than the magnitude of the depth of Y.
*/
sleep
e=1~enclose
e=
sleep
e~depth=
sleep
e=v(1)~enclose~enclose
e=
sleep
e~depth=
sleep no prompt

/*
disclose

APL R←⊃Y (Right Shoe)
Disclose is the inverse of Enclose.
*/
sleep
e=v(1)~enclose~enclose
e=
e=e~disclose
e=
sleep
e~depth=
sleep
e=e~disclose
e=
sleep
e~depth=
sleep no prompt

/*
Indexing a vector
It is possible to extract several items in a single operation, and in any order.
An item can be selected more than once.
*/
sleep
vector = (10,20,30,40,50)
sleep
vector~indexer(3)=
sleep
vector~indexer(3,3)=
sleep
'LE CHAT'~eachc~indexer(7,5,2,3,4,6,7)~tostring("c")=
sleep no prompt

/*
The index may be an array of any shape: scalar, vector, matrix, or an array of higher rank.
When a vector is indexed by an array, the result has exactly the same shape as the index
array, as if each item of the index had been replaced by the item it designates:
*/
sleep
index = a(3,5)~of(5,5,4,4,3,3,2,2,1,1)
index=
sleep
vector = (10,20,30,40,50)
sleep
vector~indexer(index)=
sleep no prompt

/*
End of demonstration.
*/
prompt directory on
demo off
