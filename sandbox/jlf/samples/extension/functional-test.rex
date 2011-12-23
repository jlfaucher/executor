/*
This script needs a modified ooRexx interpreter which allows to extend predefined ooRexx classes.
Something similar to C# extension methods :
http://msdn.microsoft.com/en-us/library/bb383977.aspx
http://weblogs.asp.net/scottgu/archive/2007/03/13/new-orcas-language-feature-extension-methods.aspx

Here, the extensions are declared with ::extension instead of ~define (see ..\functional for ~define)

Organization of this file :
Doer of type message
    Reducing
        Collection reduce
        String reduce
        Mutable buffer reduce
        Coactivity reduce
    Mapping
        Collection map
        String map
        Mutable buffer map
Doer of type routine
    Reducing
        Collection reduce
        String reduce
        Mutable buffer reduce
        Coactivity reduce
    Mapping
        Collection map
        String map
        Mutable buffer map
    Repeating & collecting : times, upto, downto
    Iterating & collecting
        Collection each
        Supplier each
        String each
        Mutable buffer each
        Coactivity each
Doer of type method
    Mapping
*/

call evaluate "demonstration"
say
say "Ended coactivities:" .Coactivity~endAll

--::options trace i
::routine demonstration

--- Strange... without this instruction, I don't get the first comments
nop

-- --------------------------------------------------------------
-- Reducing a collection with a message
-- --------------------------------------------------------------

-- A doer of type string is a message name

-- Reduce
--   arg(1) - accu  : accumulated result
--   arg(2) - value : current item of collection
--   arg(3) - index : current index of collection (passed if the action has the ~functionDoer method)
-- The messages like "+" "-" etc. have no ~functionDoer method, and as such are called with two arguments (no index).
-- Any doer which is created from a RexxBlock is called with three arguments (index).

-- Ordered collection, the operation can be non-commutative
.Array~of(1,2,3)~reduce("-")~dump -- initial value is the first item (default)
.Array~of(1,2,3)~reduce(100, "-")~dump -- initial value is 100


-- Non-ordered collection, the operation must be commutative
.Bag~of(1,2,3)~reduce("+")~dump
.Bag~of(1,2,3)~reduce(100, "+")~dump


-- Ordered collection, the operation can be non-commutative
.CircularQueue~of(1,2,3)~reduce("-")~dump
.CircularQueue~of(1,2,3)~reduce(100, "-")~dump


-- Non-ordered collection, the operation must be commutative
.Directory~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~reduce("+")~dump
.Directory~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~reduce(100, "+")~dump


-- Ordered collection, the operation can be non-commutative
.List~of(1,2,3)~reduce("-")~dump
.List~of(1,2,3)~reduce(100, "-")~dump


-- Non-ordered collection, the operation must be commutative
.Properties~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~reduce("+")~dump
.Properties~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~reduce(100, "+")~dump


-- Ordered collection, the operation can be non-commutative
.Queue~of(1,2,3)~reduce("-")~dump
.Queue~of(1,2,3)~reduce(100, "-")~dump


-- Non-ordered collection, the operation must be commutative
.Relation~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~reduce("+")~dump
.Relation~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~reduce(100, "+")~dump


-- A relation which has more than one item per index is supported
.Relation~new~~put(1, "v1")~~put(2, "v1")~~put(3, "v3")~reduce("+")~dump
.Relation~new~~put(1, "v1")~~put(2, "v1")~~put(3, "v3")~reduce(100, "+")~dump


-- Non-ordered collection, the operation must be commutative
.Set~of(1,2,3)~reduce("+")~dump
.Set~of(1,2,3)~reduce(100, "+")~dump


-- Non-ordered collection, the operation must be commutative
.Stem~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~reduce("+")~dump
.Stem~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~reduce(100, "+")~dump


-- Non-ordered collection, the operation must be commutative
.Table~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~reduce("+")~dump
.Table~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~reduce(100, "+")~dump


-- Non-ordered collection, the operation must be commutative
.IdentityTable~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~reduce("+")~dump
.IdentityTable~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~reduce(100, "+")~dump


-- --------------------------------------------------------------
-- Reducing a string with a message
-- --------------------------------------------------------------

-- initial value is the first char (default)
123~reduceC("-")~dump


-- initial value is 100
123~reduceC(100, "-")~dump


123~reduceC("min")~dump


123~reduceC("max")~dump


-- initial value is the first word (default)
"10 20 30"~reduceW("-")~dump


-- initial value is 100
"10 20 30"~reduceW(100, "-")~dump


-- --------------------------------------------------------------
-- Reducing a mutable buffer with a message
-- --------------------------------------------------------------

-- initial value is the first char (default)
.MutableBuffer~new(123)~reduceC("-")~dump


-- initial value is 100
.MutableBuffer~new(123)~reduceC(100, "-")~dump


.MutableBuffer~new(123)~reduceC("min")~dump


.MutableBuffer~new(123)~reduceC("max")~dump


-- initial value is the first word (default)
.MutableBuffer~new("10 20 30")~reduceW("-")~dump


-- initial value is 100
.MutableBuffer~new("10 20 30")~reduceW(100, "-")~dump


-- --------------------------------------------------------------
-- Reducing a coactivity with a message
-- --------------------------------------------------------------

-- The full tag is "::coactivity".
-- The shortest abbreviation is "::c".
-- initial value is the first yielded item (default)
{::c .yield[10]; .yield[20]; .yield[30]}~doer~reduce("-")~dump


-- initial value is 100
{::c .yield[10]; .yield[20]; .yield[30]}~doer~reduce(100, "-")~dump


-- --------------------------------------------------------------
-- Mapping a collection with a message, not-in-place
-- --------------------------------------------------------------

array = .Array~of(-1,2,-3)
array~dump -- collection before mapping
array~map("sign")~dump
array~dump -- collection after mapping (unchanged)


bag = .Bag~of(-1,2,-3)
bag~dump -- collection before mapping
bag~map("sign")~dump
bag~dump -- collection after mapping (unchanged)


circularQueue = .CircularQueue~of(-1,2,-3)
circularQueue~dump -- collection before mapping
circularQueue~map("sign")~dump
circularQueue~dump -- collection after mapping (unchanged)


directory = .Directory~new~~put(-1, "v1")~~put(2, "v2")~~put(-3, "v3")
directory~dump -- collection before mapping
directory~map("sign")~dump
directory~dump -- collection after mapping (unchanged)


list = .List~of(-1,2,-3)
list~dump -- collection before mapping
list~map("sign")~dump
list~dump -- collection after mapping (unchanged)


properties = .Properties~new~~put(-1, "v1")~~put(2, "v2")~~put(-3, "v3")
properties~dump -- collection before mapping
properties~map("sign")~dump
properties~dump -- collection after mapping (unchanged)


queue = .Queue~of(-1,2,-3)
queue~dump -- collection before mapping
queue~map("sign")~dump
queue~dump -- collection after mapping (unchanged)


relation = .Relation~new~~put(-1, "v1")~~put(2, "v2")~~put(-3, "v3")
relation~dump -- collection before mapping
relation~map("sign")~dump
relation~dump -- collection after mapping (unchanged)


-- A relation which has more than one item per index is supported
relation = .Relation~new~~put(-1, "v1")~~put(1, "v1")~~put(-3, "v3")
relation~dump -- collection before mapping
relation~map("sign")~dump
relation~dump -- collection after mapping (unchanged)


-- The resulting set has less items (normal... it's a set)
set = .Set~of(-1,2,-3)
set~dump -- collection before mapping
set~map("sign")~dump
set~dump -- collection after mapping (unchanged)


stem = .Stem~new~~put(-1, "v1")~~put(2, "v2")~~put(-3, "v3")
stem~dump -- collection before mapping
stem~map("sign")~dump
stem~dump -- collection after mapping (unchanged)


table = .Table~new~~put(-1, "v1")~~put(2, "v2")~~put(-3, "v3")
table~dump -- collection before mapping
table~map("sign")~dump
table~dump -- collection after mapping (unchanged)


identityTable = .IdentityTable~new~~put(-1, "v1")~~put(2, "v2")~~put(-3, "v3")
identityTable~dump -- collection before mapping
identityTable~map("sign")~dump
identityTable~dump -- collection after mapping (unchanged)


-- --------------------------------------------------------------
-- Mapping a collection with a message, in-place (replace the items)
-- --------------------------------------------------------------

array = .Array~of(-1,2,-3)
array~dump -- collection before mapping
array~mapR("sign")~dump
array~dump -- collection after mapping (impacted by mapping)


bag = .Bag~of(-1,2,-3)
bag~dump -- collection before mapping
bag~mapR("sign")~dump
bag~dump -- collection after mapping (impacted by mapping


circularQueue = .CircularQueue~of(-1,2,-3)
circularQueue~dump -- collection before mapping
circularQueue~mapR("sign")~dump
circularQueue~dump -- collection after mapping (impacted by mapping


directory = .Directory~new~~put(-1, "v1")~~put(2, "v2")~~put(-3, "v3")
directory~dump -- collection before mapping
directory~mapR("sign")~dump
directory~dump -- collection after mapping (impacted by mapping


list = .List~of(-1,2,-3)
list~dump -- collection before mapping
list~mapR("sign")~dump
list~dump -- collection after mapping (impacted by mapping


properties = .Properties~new~~put(-1, "v1")~~put(2, "v2")~~put(-3, "v3")
properties~dump -- collection before mapping
properties~mapR("sign")~dump
properties~dump -- collection after mapping (impacted by mapping


queue = .Queue~of(-1,2,-3)
queue~dump -- collection before mapping
queue~mapR("sign")~dump
queue~dump -- collection after mapping (impacted by mapping


relation = .Relation~new~~put(-1, "v1")~~put(2, "v2")~~put(-3, "v3")
relation~dump -- collection before mapping
relation~mapR("sign")~dump
relation~dump -- collection after mapping (impacted by mapping


-- A relation which has more than one item per index is supported
relation = .Relation~new~~put(-1, "v1")~~put(1, "v1")~~put(-3, "v3")
relation~dump -- collection before mapping
relation~mapR("sign")~dump
relation~dump -- collection after mapping (impacted by mapping


-- The resulting set has less items (normal... it's a set)
set = .Set~of(-1,2,-3)
set~dump -- collection before mapping
set~mapR("sign")~dump
set~dump -- collection after mapping (impacted by mapping


stem = .Stem~new~~put(-1, "v1")~~put(2, "v2")~~put(-3, "v3")
stem~dump -- collection before mapping
stem~mapR("sign")~dump
stem~dump -- collection after mapping (impacted by mapping


table = .Table~new~~put(-1, "v1")~~put(2, "v2")~~put(-3, "v3")
table~dump -- collection before mapping
table~mapR("sign")~dump
table~dump -- collection after mapping (impacted by mapping


identityTable = .IdentityTable~new~~put(-1, "v1")~~put(2, "v2")~~put(-3, "v3")
identityTable~dump -- collection before mapping
identityTable~mapR("sign")~dump
identityTable~dump -- collection after mapping (impacted by mapping


-- --------------------------------------------------------------
-- Mapping a string with a message
-- --------------------------------------------------------------

"abcdefghijklmnopqrstuvwxyz"~mapC("c2x")~dump


"The quick brown fox jumps over the lazy dog"~mapW("length")~dump


-- --------------------------------------------------------------
-- Mapping a mutable buffer with a message
-- --------------------------------------------------------------

--  Not-in-place mapping (map the characters)
buffer = .MutableBuffer~new("abcdefghijklmnopqrstuvwxyz")
buffer~dump -- mutable buffer before mapping
buffer~mapC("c2x")~dump
buffer~dump -- mutable buffer after mapping


--  Not-in-place mapping (map the words)
buffer = .MutableBuffer~new("The quick brown fox jumps over the lazy dog")
buffer~dump -- mutable buffer before mapping
buffer~mapW("length")~dump
buffer~dump -- mutable buffer after mapping


-- In place mapping (Replace the characters)
buffer = .MutableBuffer~new("abcdefghijklmnopqrstuvwxyz")
buffer~dump -- mutable buffer before mapping
buffer~mapCR("c2x")~dump
buffer~dump -- mutable buffer after mapping


-- In place mapping (Replace the words)
buffer = .MutableBuffer~new("The quick brown fox jumps over the lazy dog")
buffer~dump -- mutable buffer before mapping
buffer~mapWR("length")~dump
buffer~dump -- mutable buffer after mapping


-- --------------------------------------------------------------
-- Reducing a collection with a routine
-- --------------------------------------------------------------

-- A literal source is a routine source by default

-- Reduce :
--   arg(1) - accu  : accumulated result
--   arg(2) - value : current item of collection
--   arg(3) - index : current index of collection (passed if the doer has the ~functionDoer method)

-- The source literal is transformed by ~reduce before creating an executable,
-- which lets use an implicit return.
-- See method ~functionDoer in doers.cls for more details.
-- You can see the transformed source by running that from ooRexxShell :
--    {accu + value + index}~functionDoer("use arg accu, value, index")~source=
-- The output is :
--    # 1: index=[1] -> item=[use arg accu, value, index ; options "NOCOMMANDS" ; accu + value + index]
--    # 2: index=[2] -> item=[ ; if var("result") then return result]

.Array~of(10, 20, 30)~reduce{accu + value + index}~dump -- returns 10 + 20+2 + 30+3 = 65
.Array~of(10, 20, 30)~reduce(0){accu + value + index}~dump -- returns 0 + 10+1 + 20+2 + 30+3 = 66


-- Remember ! In a bag, the index and the item have the same value
.Bag~of(10 ,20 ,30)~reduce{accu + value + index}~dump
.Bag~of(10 ,20 ,30)~reduce(0){accu + value + index}~dump


.CircularQueue~of(10, 20, 30)~reduce{accu + value + index}~dump
.CircularQueue~of(10, 20, 30)~reduce(0){accu + value + index}~dump


-- Here the index is not a number, hence the (arbitrary) use of ~c2d to derive a number from the index
.Directory~new~~put(10, "v1")~~put(20, "v2")~~put(30, "v3")~reduce{accu + value + index~c2d}~dump
.Directory~new~~put(10, "v1")~~put(20, "v2")~~put(30, "v3")~reduce(0){accu + value + index~c2d}~dump


-- Special case ! The index of a list starts at 0...
.List~of(10, 20, 30)~reduce{accu + value + index}~dump
.List~of(10, 20, 30)~reduce(0){accu + value + index}~dump


-- Here the index is not a number, hence the (arbitrary) use of ~c2d to derive a number from the index
.Properties~new~~put(10, "v1")~~put(20, "v2")~~put(30, "v3")~reduce{accu + value + index~c2d}~dump
.Properties~new~~put(10, "v1")~~put(20, "v2")~~put(30, "v3")~reduce(0){accu + value + index~c2d}~dump


.Queue~of(10, 20, 30)~reduce{accu + value + index}~dump
.Queue~of(10, 20, 30)~reduce(0){accu + value + index}~dump


-- Here the index is not a number, hence the (arbitrary) use of ~c2d to derive a number from the index
.Relation~new~~put(10, "v1")~~put(20, "v2")~~put(30, "v3")~reduce{accu + value + index~c2d}~dump
.Relation~new~~put(10, "v1")~~put(20, "v2")~~put(30, "v3")~reduce(0){accu + value + index~c2d}~dump


-- A relation which has more than one item per index is supported
-- Here the index is not a number, hence the (arbitrary) use of ~c2d to derive a number from the index
.Relation~new~~put(10, "v1")~~put(20, "v1")~~put(30, "v3")~reduce{accu + value + index~c2d}~dump
.Relation~new~~put(10, "v1")~~put(20, "v1")~~put(30, "v3")~reduce(0){accu + value + index~c2d}~dump


-- Remember ! In a set, the index and the item have the same value
.Set~of(10 ,20 ,30)~reduce{accu + value + index}~dump
.Set~of(10 ,20 ,30)~reduce(0){accu + value + index}~dump


-- Here the index is not a number, hence the (arbitrary) use of ~c2d to derive a number from the index
.Stem~new~~put(10, "v1")~~put(20, "v2")~~put(30, "v3")~reduce{accu + value + index~c2d}~dump
.Stem~new~~put(10, "v1")~~put(20, "v2")~~put(30, "v3")~reduce(0){accu + value + index~c2d}~dump


-- Here the index is not a number, hence the (arbitrary) use of ~c2d to derive a number from the index
.Table~new~~put(10, "v1")~~put(20, "v2")~~put(30, "v3")~reduce{accu + value + index~c2d}~dump
.Table~new~~put(10, "v1")~~put(20, "v2")~~put(30, "v3")~reduce(0){accu + value + index~c2d}~dump


-- Here the index is not a number, hence the (arbitrary) use of ~c2d to derive a number from the index
.IdentityTable~new~~put(10, "v1")~~put(20, "v2")~~put(30, "v3")~reduce{accu + value + index~c2d}~dump
.IdentityTable~new~~put(10, "v1")~~put(20, "v2")~~put(30, "v3")~reduce(0){accu + value + index~c2d}~dump


-- --------------------------------------------------------------
-- Reducing a string with a routine
-- --------------------------------------------------------------

-- initial value is the first char (default), index passed as 3rd argument, returns 1 + 2+2 + 3+3 = 11
123~reduceC{accu + value + index}~dump


-- initial value is 0, index passed as 3rd argument, returns 0 + 1+1 + 2+2 + 3+3 = 12
123~reduceC(0){accu + value + index}~dump


-- initial value is the first word (default), index passed as 3rd argument, returns 10 + 20+2 + 30+3 = 65
"10 20 30"~reduceW{accu + value + index}~dump


-- initial value is 0, index passed as 3rd argument, returns 0 + 10+1 + 20+2 + 30+3 = 66
"10 20 30"~reduceW(0){accu + value + index}~dump


-- --------------------------------------------------------------
-- Reducing a mutable buffer with a routine
-- --------------------------------------------------------------

-- initial value is the first char (default), index passed as 3rd argument, returns 1 + 2+2 + 3+3 = 11
.MutableBuffer~new(123)~reduceC{accu + value + index}~dump


-- initial value is 0, index passed as 3rd argument, returns 0 + 1+1 + 2+2 + 3+3 = 12
.MutableBuffer~new(123)~reduceC(0){accu + value + index}~dump


-- initial value is the first word (default), index passed as 3rd argument, returns 10 + 20+2 + 30+3 = 65
.MutableBuffer~new("10 20 30")~reduceW{accu + value + index}~dump


-- initial value is 0, index passed as 3rd argument, returns 0 + 10+1 + 20+2 + 30+3 = 66
.MutableBuffer~new("10 20 30")~reduceW(0){accu + value + index}~dump


-- --------------------------------------------------------------
-- Reducing a coactivity with a routine
-- --------------------------------------------------------------

-- initial value is the first yielded item (default)
{::c .yield[10]; .yield[20]; .yield[30]}~doer~reduce{accu + value + index}~dump


-- initial value is 0
{::c .yield[10]; .yield[20]; .yield[30]}~doer~reduce(0){accu + value + index}~dump


-- --------------------------------------------------------------
-- Mapping a collection with a routine
-- --------------------------------------------------------------

-- Map :
--   arg(1) - value : current item of collection
--   arg(2) - index : current index of collection (passed if the action has the ~functionDoer method)

.Array~of(1,2,3,4)~map{value * 2}~dump


.Array~of(1,2,3,4)~map{use arg n ; if n == 0 then 1 ; else n * .context~executable~call(n - 1)}~dump


.List~of(1,2,3,4)~map{value * 2}~dump


.List~of(1,2,3,4)~map{use arg n ; if n == 0 then 1 ; else n * .context~executable~call(n - 1)}~dump


.Queue~of(1,2,3,4)~map{value * 2}~dump


.Queue~of(1,2,3,4)~map{use arg n ; if n == 0 then 1 ; else n * .context~executable~call(n - 1)}~dump


.CircularQueue~of(1,2,3,4)~map{value * 2}~dump


.CircularQueue~of(1,2,3,4)~map{use arg n ; if n == 0 then 1 ; else n * .context~executable~call(n - 1)}~dump


-- Filtering is not possible on collections using map (to keep the indexes unchanged).
-- When no value is returned by ~map, then the current item is kept unchanged in the collection.
.array~of("one", "two", "three")~map{if value~length == 3 then value}~dump


-- A source can be tagged explicitely as a routine (but you don't need that, because it's the default)
.Array~of(1,2,3,4)~map{::routine value * 2}~dump


-- The shortest abbreviation is of "::routine" is ":"
-- When the interpreter sees a ":" as first character of a source literal, then no executable is created by it (delayed parsing).
-- That can be useful when the source literal is not parsable by the interpreter as-is, but becomes interpretable after transformation
-- (this is not the case here, the source literal can be parsed without error by the interpreter).
.Array~of(1,2,3,4)~map{: use arg n ; if n == 0 then 1 ; else n * .context~executable~call(n - 1)}~dump


-- A routine object can be used directly.
-- In this case, there is no source transformation.
.Array~of(1,2,3,4)~map(.context~package~findRoutine("factorial"))~dump


-- --------------------------------------------------------------
-- Mapping a string with a routine
-- --------------------------------------------------------------

"abcdefghijklmnopqrstuvwxyz"~mapC{value~verify('aeiouy')}~dump


-- Filtering (if no result returned by the doer, then nothing appended)
"abcdefghijklmnopqrstuvwxyz"~mapC{if value~verify('aeiouy') then value}~dump


"one two three"~mapW{if value~length == 3 then value}~dump


-- Reminder : index passed as 2nd argument
"one two three"~mapW{index":"value}~dump


-- --------------------------------------------------------------
-- Mapping a mutable buffer with a routine
-- --------------------------------------------------------------

-- Looks like a filtering, but it's not : a value is returned for each character (can be empty string)
.MutableBuffer~new("abcdefghijklmnopqrstuvwxyz")~mapC{if value~verify('aeiouy') == 1 then value ; else ''}~dump


.MutableBuffer~new("abcdefghijklmnopqrstuvwxyz")~mapC{if value~verify('aeiouy') == 1 then value}~dump


translation = .Directory~of("quick", "slow", "lazy", "nervous", "brown", "yellow", "dog", "cat")
translation~setMethod("UNKNOWN", "return arg(1)")
"The quick brown fox jumps over the lazy dog"~mapW{::cl expose translation ; translation[arg(1)]}~dump
.MutableBuffer~new("The quick brown fox jumps over the lazy dog")~mapW{::cl expose translation ; translation[arg(1)]}~dump


-- --------------------------------------------------------------
-- Repeating & collecting with a routine
-- --------------------------------------------------------------

-- No resulting array because no result returned during the iteration.
3~times{say 2*value}


-- ~times can act as an array generator : it collects the values returned by the doer.
3~times{2*value}~dump


3~times{0}~dump


-- returns .array~of(1,2,3) because the default action is {value}
3~times~dump


-- No resulting array because no result returned during the iteration.
11~upto(13){say 2*value}


-- ~upto can act as an array generator : it collects the values returned by the doer.
11~upto(13){2*value}~dump


11~upto(13){0}~dump


-- returns .array~of(11,12,13) because the default action is {value}
11~upto(13)~dump


-- Note that -1 MUST be surrounded by paren or quotes
(-1)~upto(3)~dump


-- No resulting array because no result returned during the iteration
13~downto(11){say 2*value}


-- ~downto can act as an array generator : it collects the values returned by the doer.
13~downto(11){2*value}~dump


-- returns .array~of(13,12,11) because the default action is {value}
13~downto(11)~dump


3~downto(-1)~dump


-- --------------------------------------------------------------
-- Iterating over a collection & collecting with a routine
-- --------------------------------------------------------------

-- each :
-- The values returned by the action are collected in an array

.Array~of(1,2,3)~each{2*value}~dump
.Array~of(1,2,3)~each{2*value + index}~dump
.Array~of(1,2,3)~eachI{2*value + index}~dump


.Bag~of(1,2,3)~each{2*value}~dump
.Bag~of(1,2,3)~each{2*value + index}~dump
.Bag~of(1,2,3)~eachI{2*value + index}~dump


.CircularQueue~of(1,2,3)~each{2*value}~dump
.CircularQueue~of(1,2,3)~each{2*value + index}~dump
.CircularQueue~of(1,2,3)~eachI{2*value + index}~dump


.Directory~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~each{2*value}~dump
-- Here the index is not a number, hence the (arbitrary) use of ~c2d to derive a number from the index
.Directory~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~each{2*value + index~c2d}~dump
.Directory~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~eachI{2*value + index~c2d}~dump


.List~of(1,2,3)~each{2*value}~dump
.List~of(1,2,3)~each{2*value + index}~dump
.List~of(1,2,3)~eachI{2*value + index}~dump


.Properties~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~each{2*value}~dump
-- Here the index is not a number, hence the (arbitrary) use of ~c2d to derive a number from the index
.Properties~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~each{2*value + index~c2d}~dump
.Properties~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~eachI{2*value + index~c2d}~dump


.Queue~of(1,2,3)~each{2*value}~dump
.Queue~of(1,2,3)~each{2*value + index}~dump
.Queue~of(1,2,3)~eachI{2*value + index}~dump


.Relation~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~each{2*value}~dump
-- Here the index is not a number, hence the (arbitrary) use of ~c2d to derive a number from the index
.Relation~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~each{2*value + index~c2d}~dump
.Relation~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~eachI{2*value + index~c2d}~dump


.Set~of(1,2,3)~each{2*value}~dump
.Set~of(1,2,3)~each{2*value + index}~dump
.Set~of(1,2,3)~eachI{2*value + index}~dump


.Stem~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~each{2*value}~dump
-- Here the index is not a number, hence the (arbitrary) use of ~c2d to derive a number from the index
.Stem~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~each{2*value + index~c2d}~dump
.Stem~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~eachI{2*value + index~c2d}~dump


.Table~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~each{2*value}~dump
-- Here the index is not a number, hence the (arbitrary) use of ~c2d to derive a number from the index
.Table~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~each{2*value + index~c2d}~dump
.Table~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~eachI{2*value + index~c2d}~dump


.IdentityTable~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~each{2*value}~dump
-- Here the index is not a number, hence the (arbitrary) use of ~c2d to derive a number from the index
.IdentityTable~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~each{2*value + index~c2d}~dump
.IdentityTable~new~~put(1, "v1")~~put(2, "v2")~~put(3, "v3")~eachI{2*value + index~c2d}~dump


-- --------------------------------------------------------------
-- Iterating over a supplier & collecting with a routine
-- --------------------------------------------------------------

-- supplier : the collection generated by ~each is always an array
.set~of(1,2,3)~supplier~each{2*value}~dump


-- --------------------------------------------------------------
-- Iterating over a string & collecting with a routine
-- --------------------------------------------------------------

-- string : the collection generated by ~each is always an array

"abcdef"~eachC{value}~dump
"abcdef"~eachC{".."~copies(index)value}~dump
"abcdef"~eachCI{".."~copies(index)value}~dump


"The quick brown fox"~eachW{value}~dump
"The quick brown fox"~eachW{".."~copies(index)value}~dump
"The quick brown fox"~eachWI{".."~copies(index)value}~dump


-- --------------------------------------------------------------
-- Iterating over a mutable buffer & collecting with a routine
-- --------------------------------------------------------------

-- mutable buffer : the collection generated by ~each is always an array

.MutableBuffer~new("abcdef")~eachC{value}~dump
.MutableBuffer~new("abcdef")~eachC{".."~copies(index)value}~dump
.MutableBuffer~new("abcdef")~eachCI{".."~copies(index)value}~dump


.MutableBuffer~new("The quick brown fox")~eachW{value}~dump
.MutableBuffer~new("The quick brown fox")~eachW{".."~copies(index)value}~dump
.MutableBuffer~new("The quick brown fox")~eachWI{".."~copies(index)value}~dump


-- --------------------------------------------------------------
-- Iterating over a coactivity & collecting with a routine
-- --------------------------------------------------------------

-- coactivity : the collection generated by ~each is always an array

{::c do i=1 to 3; .yield[i]; end}~doer~each{2*value}~dump
{::c do i=1 to 3; .yield[i]; end}~doer~each{2*value + index}~dump
{::c do i=1 to 3; .yield[i]; end}~doer~eachI{2*value + index}~dump


-- --------------------------------------------------------------
-- Mapping with a method
-- --------------------------------------------------------------

colors = .Array~of( ,
    .Color~new("black", "000000") ,,
    .Color~new("blue",  "0000FF") ,,
    .Color~new("green", "008000") ,,
    .Color~new("grey",  "BEBEBE") ,
    )


-- A source can be tagged explicitely as a method (you need that, because it's a routine by default)
colors~map{::method self~rgbInteger "("self~redIntensity", "self~greenIntensity", "self~blueIntensity")"}~dump


-- A method object can be used directly
-- No need to define the method on the receiver class...
colors~map(.methods~entry("decimalColor"))~dump


-- ... except when the method is recursive and recalls itself by name
.String~define("factorial", .methods~entry("factorial"))
.Array~of(1,2,3,4)~map(.methods~entry("factorial"))~dump


-- Here, the method is recursive, but does not recall itself by name
.Array~of(1,2,3,4)~map(.methods~entry("factorialExecutable"))~dump


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


-----------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------

::extension Directory
::method of class
    use strict arg key, value, ...
    directory = .Directory~new
    do i = 1 to arg() by 2
        directory[arg(i)] = arg(i+1)
    end
    return directory


::extension Object
::method dump
    say '['self~string']'


::extension String
::method dump
    valstr = self~string
    isnum = self~dataType("N")
    if \isnum then valstr = '"'valstr'"' -- strings are surrounded by quotes, except string numbers
    say '['valstr']'


::extension MutableBuffer
-- Unlike the routine pp2, this method does not display the identityHash
-- (to avoid false differences when comparing with previous output)
::method dump
    self~string~dump


::extension Collection
::method dump
    call dump self


::extension Supplier
::method dump
    call dump self


-----------------------------------------------------------------
::routine dump
    use arg coll, indent=""

    say indent"["coll~class~id":"
    s=coll~supplier
    do while s~available
        .output~charout(indent layout(s~index)~left(3)" : ")
        if s~item~isA(.Collection) then do
            say
            call dump s~item, "    "indent 
        end
        else say layout(s~item)
        s~next
    end
    say indent"]"


::routine layout
    use strict arg obj
    if \obj~isA(.String) then return obj~string
    if \obj~dataType("N") then return obj
    if obj < 0 then return obj
    return " "obj


-----------------------------------------------------------------
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


-----------------------------------------------------------------
::requires "extension/extensions.cls"


