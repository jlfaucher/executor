/*
This script needs a modified ooRexx interpreter which allows to extend predefined ooRexx classes.
Something similar to C# extension methods :
http://msdn.microsoft.com/en-us/library/bb383977.aspx
http://weblogs.asp.net/scottgu/archive/2007/03/13/new-orcas-language-feature-extension-methods.aspx

Here, the extensions are declared with ::extension instead of ~define (see ..\functional for ~define)
*/

call evaluate "demonstration"

--::options trace i
::routine demonstration

--- Strange... without this instruction, I don't get the first comments
nop

-- --------------------------------------------------------------
-- Message sending
-- --------------------------------------------------------------

-- A string is a message name

-- Reduce
-- The messages like "+" "-" etc. take two arguments, so you can't use the "indexed" option.
--   arg(1) : accumulated result
--   arg(2) : current item of collection
--   arg(3) : current index of collection (passed if option "indexed" is used)

-- initial value is the first item (default)
.Array~of(1,2,3,4)~reduce("+")~dump2


-- initial value is 100
.Array~of(1,2,3,4)~reduce(100, "+")~dump2


.Array~of(1,2,3,4)~reduce("*")~dump2


.List~of(1,2,3,4)~reduce("+")~dump2


.List~of(1,2,3,4)~reduce(100, "+")~dump2


.List~of(1,2,3,4)~reduce("*")~dump2


.Queue~of(1,2,3,4)~reduce("+")~dump2


.Queue~of(1,2,3,4)~reduce(100, "+")~dump2


.Queue~of(1,2,3,4)~reduce("*")~dump2


.CircularQueue~of(1,2,3,4)~reduce("+")~dump2


.CircularQueue~of(1,2,3,4)~reduce(100, "+")~dump2


.CircularQueue~of(1,2,3,4)~reduce("*")~dump2


-- initial value is the first char (default)
123~reduceChar("+")~dump2


-- initial value is 100
123~reduceChar(100, "+")~dump2


123~reduceChar("min")~dump2


123~reduceChar("max")~dump2


-- initial value is the first word (default)
"10 20 30"~reduceWord("+")~dump2


-- initial value is 100
"10 20 30"~reduceWord(100, "+")~dump2


.Array~of(1,2,3,4)~map("-")~dump2


.List~of(1,2,3,4)~map("-")~dump2


.Queue~of(1,2,3,4)~map("-")~dump2


.CircularQueue~of(1,2,3,4)~map("-")~dump2 


"abcdefghijklmnopqrstuvwxyz"~mapChar("1-")~dump2


.MutableBuffer~new("abcdefghijklmnopqrstuvwxyz")~mapChar("1+")~dump2


"The quick brown fox jumps over the lazy dog"~mapWord("length")~dump2


.MutableBuffer~new("The quick brown fox jumps over the lazy dog")~mapWord("length")~dump2


-- In place mapping
array = .Array~of(-1,2,-3,4)
array~dump2
array~map("inplace", "sign")~dump2
array~dump2


-- In place mapping (this is the default for MutableBuffer)
buffer = .MutableBuffer~new("abcdefghijklmnopqrstuvwxyz")
buffer~dump2
buffer~mapChar("1+")~dump2
buffer~dump2


-- You can explicitely request not inplace mapping
buffer = .MutableBuffer~new("abcdefghijklmnopqrstuvwxyz")
buffer~dump2
buffer~mapChar("\inplace", "1+")~dump2
buffer~dump2


-- --------------------------------------------------------------
-- Routine calling
-- --------------------------------------------------------------

-- A literal source is a routine source by default

-- Reduce :
--   arg(1) : accumulated result
--   arg(2) : current item of collection
--   arg(3) : current index of collection (passed if option "indexed" is used)

-- initial value is the first item (default), index passed as 3rd argument, returns 10 + 20+2 + 30+3 = 65
.Array~of(10, 20, 30)~reduce(, "ind"){arg(1) + arg(2) + arg(3)}~dump2


-- initial value is 0, index passed as 3rd argument, returns 0 + 10+1 + 20+2 + 30+3 = 66
.Array~of(10, 20, 30)~reduce(0, "ind"){arg(1) + arg(2) + arg(3)}~dump2


.List~of(10, 20, 30)~reduce(, "ind"){arg(1) + arg(2) + arg(3)}~dump2


.List~of(10, 20, 30)~reduce(0, "ind"){arg(1) + arg(2) + arg(3)}~dump


.Queue~of(10, 20, 30)~reduce(, "ind"){arg(1) + arg(2) + arg(3)}~dump2


.Queue~of(10, 20, 30)~reduce(0, "ind"){arg(1) + arg(2) + arg(3)}~dump2


.CircularQueue~of(10, 20, 30)~reduce(, "ind"){arg(1) + arg(2) + arg(3)}~dump2


.CircularQueue~of(10, 20, 30)~reduce(0, "ind"){arg(1) + arg(2) + arg(3)}~dump2


-- initial value is the first word (default), index passed as 3rd argument, returns 10 + 20+2 + 30+3 = 65
"10 20 30"~reduceWord(, "ind"){arg(1) + arg(2) + arg(3)}


-- initial value is 0, index passed as 3rd argument, returns 0 + 10+1 + 20+2 + 30+3 = 66
"10 20 30"~reduceWord(0, "ind"){arg(1) + arg(2) + arg(3)}


-- Map :
--   arg(1) : current item of collection
--   arg(2) : current index of collection (passed if option "indexed" is used)

.Array~of(1,2,3,4)~map{arg(1) * 2}~dump2


.Array~of(1,2,3,4)~map{use arg n ; if n == 0 then 1 ; else n * .context~executable~call(n - 1)}~dump2


.List~of(1,2,3,4)~map{arg(1) * 2}~dump2


.List~of(1,2,3,4)~map{use arg n ; if n == 0 then 1 ; else n * .context~executable~call(n - 1)}~dump2


.Queue~of(1,2,3,4)~map{arg(1) * 2}~dump2


.Queue~of(1,2,3,4)~map{use arg n ; if n == 0 then 1 ; else n * .context~executable~call(n - 1)}~dump2


.CircularQueue~of(1,2,3,4)~map{arg(1) * 2}~dump2


.CircularQueue~of(1,2,3,4)~map{use arg n ; if n == 0 then 1 ; else n * .context~executable~call(n - 1)}~dump2


"abcdefghijklmnopqrstuvwxyz"~mapChar{arg(1)~verify('aeiouy')}~dump2


.MutableBuffer~new("abcdefghijklmnopqrstuvwxyz")~mapChar{if arg(1)~verify('aeiouy') == 1 then arg(1) ; else ''}~dump2


-- Filtering (if no result returned by the doer, then nothing appended)
"abcdefghijklmnopqrstuvwxyz"~mapChar{if arg(1)~verify('aeiouy') then arg(1)}~dump2


.MutableBuffer~new("abcdefghijklmnopqrstuvwxyz")~mapChar{if arg(1)~verify('aeiouy') == 1 then arg(1)}~dump2


"one two three"~mapWord{if arg(1)~length == 2 then arg(1)}~dump2


.array~of("one", "two", "three")~map{if arg(1)~length == 2 then arg(1)}~dump2


-- index passed as 2nd argument
"one two three"~mapWord("ind"){arg(2)":"arg(1)}~dump2


-- todo : doesn't work because the variable translation has no value when evaluating the doer : needs a closure
-- translation = .Directory~of("quick", "slow", "lazy", "nervous", "brown", "yellow", "dog", "cat")
-- translation~setMethod("UNKNOWN", "arg(1)")
-- "The quick brown fox jumps over the lazy dog"~mapWord{translation~arg(1)}~dump2
--.MutableBuffer~new("The quick brown fox jumps over the lazy dog")~mapWord({expose translation ; translation[arg(1)]}, .false)~dump2


-- A source can be tagged explicitely as a routine (but you don't need that, because it's the default)
.Array~of(1,2,3,4)~map{::routine arg(1) * 2}~dump2


.Array~of(1,2,3,4)~map{::routine use arg n ; if n == 0 then 1 ; else n * .context~executable~call(n - 1)}~dump2


-- A routine object can be used directly
.Array~of(1,2,3,4)~map(.context~package~findRoutine("factorial"))~dump2


-- ~times can act as an array generator : it collects the values returned by the doer
-- there is no default action (unlike ~upto and ~downto)
3~times{0}~dump2


3~times{arg(1)}~dump2


-- returns .nil : no resulting array because no result returned during the iteration
say 3~times{say arg(1)} 


-- ~upto can act as an array generator : it collects the values returned by the doer
-- returns .array~of(11,12,13) because the default action is {arg(1)}
11~upto(13)~dump2             


-- Note that -1 MUST be surrounded by paren or quotes
(-1)~upto(3)~dump2


11~upto(13){2*arg(1)}~dump2


-- returns .nil : no resulting array because no result returned during the iteration
say 11~upto(13){say arg(1)}


-- ~downto can act as an array generator : it collects the values returned by the doer
-- returns .array~of(13,12,11) because the default action is {arg(1)}
13~downto(11)~dump2


3~upto(-1)~dump2


13~downto(11){2*arg(1)}~dump2


-- returns .nil : no resulting array because no result returned during the iteration
say 13~downto(11){say arg(1)}


-- each : 
-- The type of generated collection depends on the type of itererated source.
-- collection --> same type of collection
-- supplier --> array
-- coactivity --> array

.Array~of(1,2,3)~each{2*arg(1)}~dump2


.Bag~of(1,2,3)~each{2*arg(1)}~dump2


.CircularQueue~of(1,2,3)~each{2*arg(1)}~dump2


.Directory~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~each{2*arg(1)}~dump2


.List~of(1,2,3)~each{2*arg(1)}~dump2


.Properties~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~each{2*arg(1)}~dump2


.Queue~of(1,2,3)~each{2*arg(1)}~dump2


.Relation~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~each{2*arg(1)}~dump2


.Set~of(1,2,3)~each{2*arg(1)}~dump2


.Stem~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~each{2*arg(1)}~dump2


.Table~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~each{2*arg(1)}~dump2


.IdentityTable~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~each{2*arg(1)}~dump2


-- supplier : the collection generated by ~each is always an array
.set~of(1,2,3)~supplier~each{2*arg(1)}


-- coactivity : the collection generated by ~each is always an array
{::c do i=1 to 3; .yield[i]; end}~doer~each{2*arg(1)}


-- --------------------------------------------------------------
-- Method running
-- --------------------------------------------------------------

colors = .Array~of( ,
    .Color~new("black", "000000") ,,
    .Color~new("blue",  "0000FF") ,,
    .Color~new("green", "008000") ,,
    .Color~new("grey",  "BEBEBE") ,
    )

    
-- A source can be tagged explicitely as a method (you need that, because it's a routine by default)
colors~map{::method self~rgbInteger "("self~redIntensity", "self~greenIntensity", "self~blueIntensity")"}~dump2


-- A method object can be used directly
-- No need to define the method on the receiver class...
colors~map(.methods~entry("decimalColor"))~dump2


-- ... except when the method is recursive and recalls itself by name
.String~define("factorial", .methods~entry("factorial"))
.Array~of(1,2,3,4)~map(.methods~entry("factorial"))~dump2


-- Here, the method is recursive, but does not recall itself by name
.Array~of(1,2,3,4)~map(.methods~entry("factorialExecutable"))~dump2


-----------------------------------------------------------------
-- Definitions
-----------------------------------------------------------------

::routine factorial
    use strict arg n
    if n == 0 then return 1
    return n * factorial(n - 1) -- here, the routine 'factorial' has a global name, and can be called

    
::method factorial
    if self == 0 then return 1
    return self * (self - 1)~factorial -- this code will work only if self understands 'factorial'


::method factorialExecutable
    if self == 0 then return 1
    return self * (self - 1)~run(.context~executable) -- recursive call, but not by name


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
    
    
-------------------------------------------------------------------------------
::routine evaluate
    use strict arg evaluate_routineName
    evaluate_routine = .context~package~findRoutine(evaluate_routineName)
    evaluate_routineSource = evaluate_routine~source
    evaluate_curly_bracket_count = 0
    evaluate_string = ""
    evaluate_clause_separator = ""
    evaluate_supplier = evaluate_routineSource~supplier
    loop:
        if \ evaluate_supplier~available then return
        evaluate_sourceline = evaluate_supplier~item
        if evaluate_sourceline~strip~left(3) == "---" then nop -- Comments starting with 3 '-' are removed
        else if evaluate_sourceline~strip == "nop" then nop -- nop is a workaround to get the first comments
        else if evaluate_sourceline~strip~left(2) == "--" then say evaluate_sourceline -- Comments starting with 2 '-' are kept
        else if evaluate_sourceline~strip == "" then say
        else do
            say "   "evaluate_sourceline
            evaluate_curly_bracket_count += evaluate_sourceline~countStr("{") - evaluate_sourceline~countStr("}")
            if ",-"~pos(evaluate_sourceline~right(1)) <> 0 then do
                evaluate_string ||= evaluate_clause_separator || evaluate_sourceline~left(evaluate_sourceline~length - 1)
                evaluate_clause_separator = ""
            end
            else if evaluate_curly_bracket_count > 0 then do
                evaluate_string ||= evaluate_clause_separator || evaluate_sourceline
                evaluate_clause_separator = "; "
            end
            else if evaluate_curly_bracket_count == 0 then do
                evaluate_string ||= evaluate_clause_separator || evaluate_sourceline
                evaluate_clause_separator = ""
                signal on syntax
                interpret evaluate_string
                evaluate_string = ""
            end
        end
    iterate:
        evaluate_supplier~next
    signal loop
syntax:
    say "*** got an error :" condition("O")~message
    evaluate_string = ""
    signal iterate


-------------------------------------------------------------------------------
::requires "extension/extensions.cls"
::requires "rgf_util2/rgf_util2_wrappers.rex"


