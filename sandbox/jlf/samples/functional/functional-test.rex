/*
This script needs a modified ooRexx interpreter which allows to extend predefined ooRexx classes.
Something similar to C# extension methods :
http://msdn.microsoft.com/en-us/library/bb383977.aspx
http://weblogs.asp.net/scottgu/archive/2007/03/13/new-orcas-language-feature-extension-methods.aspx
*/

.Object~define("dump", .methods~ObjectDump)
.Collection~define("dump", .methods~CollectionDump)

say "-----------------------------------------------------------------"
say "-- Message sending"
say "-----------------------------------------------------------------"

-- When the source contains a single word, it's a message name
.Array~of(1,2,3,4)~reduce("+")~dump -- sum = 10
.Array~of(1,2,3,4)~reduce("*")~dump -- product = 24

.List~of(1,2,3,4)~reduce("+")~dump -- sum = 10
.List~of(1,2,3,4)~reduce("*")~dump -- product = 24

.Queue~of(1,2,3,4)~reduce("+")~dump -- sum = 10
.Queue~of(1,2,3,4)~reduce("*")~dump -- product = 24

.CircularQueue~of(1,2,3,4)~reduce("+")~dump -- sum = 10
.CircularQueue~of(1,2,3,4)~reduce("*")~dump -- product = 24

123~reduce("min")~dump -- min digit = 1
123~reduce("max")~dump -- max digit = 3

.Array~of(1,2,3,4)~map("-")~dump         -- an Array : -1, -2, -3, -4
.List~of(1,2,3,4)~map("-")~dump          -- a List : -1, -2, -3, -4
.Queue~of(1,2,3,4)~map("-")~dump         -- a Queue : -1, -2, -3, -4
.CircularQueue~of(1,2,3,4)~map("-")~dump -- -1,-2,-3,-4 : -1, -2, -3, -4 (strange : The dump of a circular queue does not show its class, it shows its contents...) 

-- In place mapping
numbers = .Array~of(-1,2,-3,4)
numbers~dump                     -- an Array : -1, 2, -3, 4
numbers~map("sign", .true)~dump  -- an Array : -1, 1, -1, 1
numbers~dump                     -- an Array : -1, 1, -1, 1


say "-----------------------------------------------------------------"
say "-- Routine calling"
say "-----------------------------------------------------------------"

-- A source with more than one word is a routine source by default
.Array~of(1,2,3,4)~map("return arg(1) * 2")~dump -- an Array : 2, 4, 6, 8
.Array~of(1,2,3,4)~map("use arg n ; if n == 0 then return 1 ; return n * .context~executable~call(n - 1)")~dump -- an Array : 1, 2, 6, 24

.List~of(1,2,3,4)~map("return arg(1) * 2")~dump -- a List : 2, 4, 6, 8
.List~of(1,2,3,4)~map("use arg n ; if n == 0 then return 1 ; return n * .context~executable~call(n - 1)")~dump -- a List : 1, 2, 6, 24

.Queue~of(1,2,3,4)~map("return arg(1) * 2")~dump -- a Queue : 2, 4, 6, 8
.Queue~of(1,2,3,4)~map("use arg n ; if n == 0 then return 1 ; return n * .context~executable~call(n - 1)")~dump -- a Queue : 1, 2, 6, 24

.CircularQueue~of(1,2,3,4)~map("return arg(1) * 2")~dump -- 2,4,6,8 : 2, 4, 6, 8 (strange : the class is not displayed)
.CircularQueue~of(1,2,3,4)~map("use arg n ; if n == 0 then return 1 ; return n * .context~executable~call(n - 1)")~dump -- 1,2,6,24 : 1, 2, 6, 24

-- A source can be tagged explicitely as a routine (but you don't need that, because it's the default)
.Array~of(1,2,3,4)~map("::routine return arg(1) * 2")~dump -- an Array : 2, 4, 6, 8
.Array~of(1,2,3,4)~map("::routine use arg n ; if n == 0 then return 1 ; return n * .context~executable~call(n - 1)")~dump -- an Array : 1, 2, 6, 24

-- A routine object can be used directly
.Array~of(1,2,3,4)~map(.context~package~findRoutine("factorial"))~dump -- an Array : 1, 2, 6, 24


say "-----------------------------------------------------------------"
say "-- Method running"
say "-----------------------------------------------------------------"

colors = .Array~of( ,
    .Color~new("black", "000000") ,,
    .Color~new("blue",  "0000FF") ,,
    .Color~new("green", "008000") ,,
    .Color~new("grey",  "BEBEBE") ,
    )
    
-- A source can be tagged explicitely as a method (you need that, because it's a routine by default)
colors~map('::method return self~rgbInteger "("self~redIntensity", "self~greenIntensity", "self~blueIntensity")"')~dump -- an Array : 0 (0, 0, 0), 255 (0, 0, 255), 32768 (0, 128, 0), 12500670 (190, 190, 190)

-- A method object can be used directly
-- No need to define the method on the receiver class
colors~map(.methods~entry("decimalColor"))~dump -- an Array : 0 (0, 0, 0), 255 (0, 0, 255), 32768 (0, 128, 0), 12500670 (190, 190, 190)


-----------------------------------------------------------------
-- Definitions
-----------------------------------------------------------------

::method ObjectDump
    use strict arg stream = .stdout
    stream~lineout(self)
    
::method CollectionDump
    use strict arg stream = .stdout
    stream~charout(self ": ")
    previous = .false
    do e over self
        if previous then stream~charout(", ")
        stream~charout(e)
        previous = .true
    end
    stream~lineout("")
    

::routine factorial
    use strict arg n
    if n == 0 then return 1
    return n * factorial(n - 1)

    
::method factorial
    if self == 0 then return 1
    return self * (self - 1)~factorial


::method decimalColor
   return self~rgbInteger "("self~redIntensity", "self~greenIntensity", "self~blueIntensity")"


::class Color
::attribute name
::attribute rgb
::attribute rgbInteger private
::method init
    use strict arg name, rgb
    self~name = name
    self~rgb = rgb
    self~rgbInteger = rgb~x2d
::method redIntensity
    return self~rgb~substr(1,2)~x2d 
::method greenIntensity
    return self~rgb~substr(3,2)~x2d 
::method blueIntensity
    return self~rgb~substr(5,2)~x2d 


--::requires "functional-v1.rex"
::requires "functional-v2.rex"

