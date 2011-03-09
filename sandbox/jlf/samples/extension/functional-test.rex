/*
This script needs a modified ooRexx interpreter which allows to extend predefined ooRexx classes.
Something similar to C# extension methods :
http://msdn.microsoft.com/en-us/library/bb383977.aspx
http://weblogs.asp.net/scottgu/archive/2007/03/13/new-orcas-language-feature-extension-methods.aspx

Here, the extensions are declared with ::extension instead of ~define (see ..\functional for ~define)
*/

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

"abcdefghijklmnopqrstuvwxyz"~mapchar("1-")~dump                             -- `abcdefghijklmnopqrstuvwxy
.MutableBuffer~new("abcdefghijklmnopqrstuvwxyz")~mapchar("1+", .false)~dump -- bcdefghijklmnopqrstuvwxyz{

"The quick brown fox jumps over the lazy dog"~mapword("length")~dump                                -- 3 5 5 3 5 4 3 4 3
.MutableBuffer~new("The quick brown fox jumps over the lazy dog")~mapword("length", .false)~dump    -- 3 5 5 3 5 4 3 4 3

-- In place mapping
array = .Array~of(-1,2,-3,4)
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
.Array~of(1,2,3,4)~map("return arg(1) * 2")~dump -- an Array : 2, 4, 6, 8
.Array~of(1,2,3,4)~map("use arg n ; if n == 0 then return 1 ; return n * .context~executable~call(n - 1)")~dump -- an Array : 1, 2, 6, 24

.List~of(1,2,3,4)~map("return arg(1) * 2")~dump -- a List : 2, 4, 6, 8
.List~of(1,2,3,4)~map("use arg n ; if n == 0 then return 1 ; return n * .context~executable~call(n - 1)")~dump -- a List : 1, 2, 6, 24

.Queue~of(1,2,3,4)~map("return arg(1) * 2")~dump -- a Queue : 2, 4, 6, 8
.Queue~of(1,2,3,4)~map("use arg n ; if n == 0 then return 1 ; return n * .context~executable~call(n - 1)")~dump -- a Queue : 1, 2, 6, 24

.CircularQueue~of(1,2,3,4)~map("return arg(1) * 2")~dump -- 2,4,6,8 : 2, 4, 6, 8 (strange : the class is not displayed)
.CircularQueue~of(1,2,3,4)~map("use arg n ; if n == 0 then return 1 ; return n * .context~executable~call(n - 1)")~dump -- 1,2,6,24 : 1, 2, 6, 24

"abcdefghijklmnopqrstuvwxyz"~mapchar("return arg(1)~verify('aeiouy')")~dump
.MutableBuffer~new("abcdefghijklmnopqrstuvwxyz")~mapchar("if arg(1)~verify('aeiouy') == 1 then return arg(1) ; else return ''")~dump

/* todo : doesn't work because the variable translation has no value when evaluating the doer
translation = .Directory~of("quick", "slow", "lazy", "nervous", "brown", "yellow", "dog", "cat")
translation~setMethod("UNKNOWN", "return arg(1)")
"The quick brown fox jumps over the lazy dog"~mapword("return translation~arg(1)",,.context~package)~dump
.MutableBuffer~new("The quick brown fox jumps over the lazy dog")~mapword("return translation[arg(1)]", .false, .context~package)~dump
*/

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


::extension Object
::method dump
    use strict arg stream = .stdout
    stream~lineout(self)

    
::extension Collection
::method dump
    use strict arg stream = .stdout
    stream~charout(self ": ")
    previous = .false
    do e over self
        if previous then stream~charout(", ")
        stream~charout(e)
        previous = .true
    end
    stream~lineout("")
    

::extension String
::method "1-"
    c = self~subchar(1)~c2d - 1
    return c~d2c
::method "1+"
    c = self~subchar(1)~c2d + 1
    return c~d2c

    
::extension Directory
::method of class
    use strict arg key, value, ...
    directory = .Directory~new
    do i = 1 to arg() by 2
        directory[arg(i)] = arg(i+1)
    end
    return directory
    
    
::requires "extension/extensions.cls"

