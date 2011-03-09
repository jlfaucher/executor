/*
This is a *PARTIAL* adaptation of functional-test.rex

This script works with a standard ooRexx, no need of ::extension here.
Depends on extended classes, but the integration is poor.
*/

say "-----------------------------------------------------------------"
say "-- Message sending"
say "-----------------------------------------------------------------"

-- When the source contains a single word, it's a message name
call Object.dump .ExtendedArray~of(1,2,3,4)~reduce(.ExtendedString~new("+")) -- sum = 10
call Object.dump .ExtendedArray~of(1,2,3,4)~reduce(.ExtendedString~new("*")) -- product = 24

call Object.dump .ExtendedList~of(1,2,3,4)~reduce(.ExtendedString~new("+")) -- sum = 10
call Object.dump .ExtendedList~of(1,2,3,4)~reduce(.ExtendedString~new("*")) -- product = 24

call Object.dump .ExtendedQueue~of(1,2,3,4)~reduce(.ExtendedString~new("+")) -- sum = 10
call Object.dump .ExtendedQueue~of(1,2,3,4)~reduce(.ExtendedString~new("*")) -- product = 24

call Object.dump .ExtendedCircularQueue~of(1,2,3,4)~reduce(.ExtendedString~new("+")) -- sum = 10
call Object.dump .ExtendedCircularQueue~of(1,2,3,4)~reduce(.ExtendedString~new("*")) -- product = 24

call Object.dump .ExtendedString~new(123)~reduce(.ExtendedString~new("min")) -- min digit = 1
call Object.dump .ExtendedString~new(123)~reduce(.ExtendedString~new("max")) -- max digit = 3

call Collection.dump .ExtendedArray~of(1,2,3,4)~map(.ExtendedString~new("-"))         -- an Array : -1, -2, -3, -4
call Collection.dump .ExtendedList~of(1,2,3,4)~map(.ExtendedString~new("-"))          -- a List : -1, -2, -3, -4
call Collection.dump .ExtendedQueue~of(1,2,3,4)~map(.ExtendedString~new("-"))         -- a Queue : -1, -2, -3, -4
call Collection.dump .ExtendedCircularQueue~of(1,2,3,4)~map(.ExtendedString~new("-")) -- -1,-2,-3,-4 : -1, -2, -3, -4 (strange : The dump of a circular queue does not show its class, it shows its contents...) 


/*========================================================================================
Note JLF : I stop adapting the script here !
The next lines become difficult to adapt : the iteration over each character/word returns
"normal" String instances, whereas I should use UserExtendedString. 
It could be possible to modify functional.cls to convert those strings into UserExtendedString
but why do that ? It's a waste of time...
========================================================================================*/

return


.String~new("abcdefghijklmnopqrstuvwxyz")~mapchar(.String~new("1-"))~dump   -- `abcdefghijklmnopqrstuvwxy
.MutableBuffer~new("abcdefghijklmnopqrstuvwxyz")~mapchar("1+", .false)~dump -- bcdefghijklmnopqrstuvwxyz{

"The quick brown fox jumps over the lazy dog"~mapword("length")~dump                                -- 3 5 5 3 5 4 3 4 3
.MutableBuffer~new("The quick brown fox jumps over the lazy dog")~mapword("length", .false)~dump    -- 3 5 5 3 5 4 3 4 3

-- In place mapping
array = .ExtendedArray~of(-1,2,-3,4)
array~dump                     -- an Array : -1, 2, -3, 4
array~map("sign", .true)~dump  -- an Array : -1, 1, -1, 1
array~dump                     -- an Array : -1, 1, -1, 1

-- In place mapping (this is the default for MutableBuffer)
buffer = .MutableBuffer~new("abcdefghijklmnopqrstuvwxyz")
buffer~dump                    -- abcdefghijklmnopqrstuvwxyz
buffer~mapChar("1+")~dump      -- bcdefghijklmnopqrstuvwxyz{
buffer~dump                    -- bcdefghijklmnopqrstuvwxyz{


say "-----------------------------------------------------------------"
say "-- Routine calling"
say "-----------------------------------------------------------------"

-- A source with more than one word is a routine source by default
.ExtendedArray~of(1,2,3,4)~map("return arg(1) * 2")~dump -- an Array : 2, 4, 6, 8
.ExtendedArray~of(1,2,3,4)~map("use arg n ; if n == 0 then return 1 ; return n * .context~executable~call(n - 1)")~dump -- an Array : 1, 2, 6, 24

.List~of(1,2,3,4)~map("return arg(1) * 2")~dump -- a List : 2, 4, 6, 8
.List~of(1,2,3,4)~map("use arg n ; if n == 0 then return 1 ; return n * .context~executable~call(n - 1)")~dump -- a List : 1, 2, 6, 24

.Queue~of(1,2,3,4)~map("return arg(1) * 2")~dump -- a Queue : 2, 4, 6, 8
.Queue~of(1,2,3,4)~map("use arg n ; if n == 0 then return 1 ; return n * .context~executable~call(n - 1)")~dump -- a Queue : 1, 2, 6, 24

.CircularQueue~of(1,2,3,4)~map("return arg(1) * 2")~dump -- 2,4,6,8 : 2, 4, 6, 8 (strange : the class is not displayed)
.CircularQueue~of(1,2,3,4)~map("use arg n ; if n == 0 then return 1 ; return n * .context~executable~call(n - 1)")~dump -- 1,2,6,24 : 1, 2, 6, 24

"abcdefghijklmnopqrstuvwxyz"~mapchar("return arg(1)~verify('aeiouy')")~dump
.MutableBuffer~new("abcdefghijklmnopqrstuvwxyz")~mapchar("if arg(1)~verify('aeiouy') == 1 then return arg(1) ; else return ''")~dump

-- A source can be tagged explicitely as a routine (but you don't need that, because it's the default)
.ExtendedArray~of(1,2,3,4)~map("::routine return arg(1) * 2")~dump -- an Array : 2, 4, 6, 8
.ExtendedArray~of(1,2,3,4)~map("::routine use arg n ; if n == 0 then return 1 ; return n * .context~executable~call(n - 1)")~dump -- an Array : 1, 2, 6, 24

-- A routine object can be used directly
.ExtendedArray~of(1,2,3,4)~map(.context~package~findRoutine("factorial"))~dump -- an Array : 1, 2, 6, 24


say "-----------------------------------------------------------------"
say "-- Method running"
say "-----------------------------------------------------------------"

colors = .ExtendedArray~of( ,
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


-- Not possible to extend Object to have the ~dump method everywhere
-- So use a routine...
::routine Object.dump
    use strict arg self, stream = .stdout
    stream~lineout(self)


::routine Collection.dump
    use strict arg self, stream = .stdout
    stream~charout(self ": ")
    previous = .false
    do e over self
        if previous then stream~charout(", ")
        stream~charout(e)
        previous = .true
    end
    stream~lineout("")


::class UserExtendedString subclass ExtendedString
::method "1-"
    c = self~subchar(1)~c2d - 1
    return c~d2c
::method "1+"
    c = self~subchar(1)~c2d + 1
    return c~d2c


::requires "extension/std/extensions-std.cls"

