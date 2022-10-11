/*
Named arguments
Keep this file independent of the extensions (no requires).
See the file named_arguments-test_with_extensions.rex for the tests of extensions.
*/

-------------------
-- Instruction CALL
-------------------
call title "Call an internal procedure"
call interpret 'call myprocedure'
call interpret 'call myprocedure 1, 2, 3'
call interpret 'call myprocedure 1, 2, a3:3'
call interpret 'call myprocedure 1, a2:2, a3:3'
call interpret 'call myprocedure 1, a2:(2*5/4)**5, a3:.array~new(3,3)'
call interpret 'call myprocedure , , 3, ,'
call interpret 'call myprocedure , , 3, , a5:5'
---
call interpret 'call myprocedure 1, 2, 3, {}'
call interpret 'call myprocedure 1, 2, {}, a3:3'
call interpret 'call myprocedure 1, {}, a2:2, a3:3'

-------------------------------------
-- Instruction CALL with continuation
-------------------------------------
call title "Continuation of the interpreted string"
say "call interpret 'call myprocedure 1,',"
say "               'a2:2, a3:3'"
call interpret 'call myprocedure 1,',
               'a2:2, a3:3'
say "call interpret 'call myprocedure 1, a2',"
say "               ':2, a3:3'"
call interpret 'call myprocedure 1, a2',
               ':2, a3:3'
say "call interpret 'call myprocedure 1, a2:',"
say "               '2, a3:3'"
call interpret 'call myprocedure 1, a2:',
               '2, a3:3'
say "call interpret 'call myprocedure 1, a2:2,',"
say "               'a3:3'"
call interpret 'call myprocedure 1, a2:2,',
               'a3:3'

-------------------------------------
-- Instruction CALL with continuation
-------------------------------------
call title "Continuation of the CALL instruction"
say "call myprocedure 1,,"
say "     a2:2, a3:3"
call myprocedure 1,,
     a2:2, a3:3
say
say
say "call myprocedure 1, a2,"
say "     :2, a3:3"
call myprocedure 1, a2,
     :2, a3:3
say
say
say "call myprocedure 1, a2:,"
say "     2, a3:3"
call myprocedure 1, a2:,
     2, a3:3
say
say
say "call myprocedure 1, a2:2,,"
say "     a3:3"
call myprocedure 1, a2:2,,
     a3:3
say
say

----------------
-- Function call
----------------
call title "Call an internal procedure as a function"
call interpret 'r = myprocedure()'
call interpret 'r = myprocedure(1, 2, 3)'
call interpret 'r = myprocedure(1, 2, a3:3)'
call interpret 'r = myprocedure(1, a2:2, a3:3)'
call interpret 'r = myprocedure(1, a2:(2*5/4)**5, a3:.array~new(3,3))'
call interpret 'r = myprocedure( , , 3, ,)'
call interpret 'r = myprocedure( , , 3, , a5:5)'
---
call interpret 'r = myprocedure(1, 2, 3){}'
call interpret 'r = myprocedure(1, 2, a3:3){}'
call interpret 'r = myprocedure(1, a2:2, a3:3){}'

----------------------------------
-- Function call with continuation
----------------------------------
call title "Continuation of the interpreted string"
say "call interpret 'r=myprocedure(1,',"
say "               'a2:2, a3:3)'"
call interpret 'r=myprocedure(1,',
               'a2:2, a3:3)'
say "call interpret 'r = myprocedure(1, a2',"
say "               ':2, a3:3)'"
call interpret 'r = myprocedure(1, a2',
               ':2, a3:3)'
say "call interpret 'r = myprocedure(1, a2:',"
say "               '2, a3:3)'"
call interpret 'r = myprocedure(1, a2:',
               '2, a3:3)'
say "call interpret 'r = myprocedure(1, a2:2,',"
say "               'a3:3)'"
call interpret 'r = myprocedure(1, a2:2,',
               'a3:3)'

----------------------------------
-- Function call with continuation
----------------------------------
call title "Continuation of the function call"
say "r = myprocedure(1,,"
say "     a2:2, a3:3)"
r = myprocedure(1,,
     a2:2, a3:3)
say
say
say "r = myprocedure(1, a2,"
say "     :2, a3:3)"
r = myprocedure(1, a2,
     :2, a3:3)
say
say
say "r = myprocedure(1, a2:,"
say "     2, a3:3)"
r = myprocedure(1, a2:,
     2, a3:3)
say
say
say "r = myprocedure(1, a2:2,,"
say "     a3:3)"
r = myprocedure(1, a2:2,,
     a3:3)
say
say

-------------------
-- Instruction CALL
-------------------
call title "Call a routine"
call interpret 'call myroutine'
call interpret 'call myroutine 1, 2, 3'
call interpret 'call myroutine 1, 2, a3:3'
call interpret 'call myroutine 1, a2:2, a3:3'
call interpret 'call myroutine 1, a2:(2*5/4)**5, a3:.array~new(3,3)'
call interpret 'call myroutine , , 3, ,'
call interpret 'call myroutine , , 3, , a5:5'

-----------
-- Function
-----------
call title "Call a routine as a function"
call interpret 'r = myroutine()'
call interpret 'r = myroutine(1, 2, 3)'
call interpret 'r = myroutine(1, 2, a3:3)'
call interpret 'r = myroutine(1, a2:2, a3:3)'
call interpret 'r = myroutine(1, a2:(2*5/4)**5, a3:.array~new(3,3))'
call interpret 'r = myroutine( , , 3, ,)'
call interpret 'r = myroutine( , , 3, , a5:5)'
call interpret 'r = myroutine(1, 2, 3){}'
call interpret 'r = myroutine(1, 2, a3:3){}'
call interpret 'r = myroutine(1, a2:2, a3:3){}'

---------------
-- Message term
---------------
call title "Call a method using a message term"
call interpret 'r = .myclass~mymethod'
call interpret 'r = .myclass~mymethod()'
call interpret 'r = .myclass~mymethod(1, 2, 3)'
call interpret 'r = .myclass~mymethod(1, 2, a3:3)'
call interpret 'r = .myclass~mymethod(1, a2:2, a3:3)'
call interpret 'r = .myclass~mymethod(1, a2:(2*5/4)**5, a3:.array~new(3,3))'
call interpret 'r = .myclass~mymethod( , , 3, ,)'
call interpret 'r = .myclass~mymethod( , , 3, , a5:5)'
call interpret 'r = .myclass~mymethod(1, 2, 3){}'
call interpret 'r = .myclass~mymethod(1, 2, a3:3){}'
call interpret 'r = .myclass~mymethod(1, a2:2, a3:3){}'

----------------------
-- Instruction FORWARD
----------------------
call title "Forward a message"
call interpret 'r = .myclass~forwardArray'
call interpret 'r = .myclass~forwardNamedArguments'
call interpret 'r = .myclass~forwardPositionalNamedArguments'
call interpret 'r = .myclass~forwardNamedPositionalArguments'

------------------
-- Instruction USE
------------------
call title "Instruction USE"
call interpret 'call usePositionalNamed 1, , 3, , a5:5, a6:6'
call interpret 'call useStrictPositionalNamed 1, , 3, , a5:5, a6:6'
call interpret 'call useStrictZeroNamed'
call interpret 'call useStrictOneNamed_NoDefault a1:1'
call interpret 'call useStrictOneNamed_WithDefault'
call interpret 'call useStrictOneNamed_WithDefault a1:2'
call interpret 'call useStrictOneNamed_WithDefaultExpression'
call interpret 'call useStrictOneNamed_WithDefaultExpression a1:2'
call interpret 'call useStrictAutoNamed_WithEllipse'
call interpret 'call useNamed_SimpleSymbol v1:1, v3:3, v5:5'
call interpret 'call useNamed_WithMinimumLength'

call interpret 'call useAutoNamed_SimpleSymbol v1:1, v3:3, v5:5, index:"My index", item:"My item"' -
             , 'The automatic variables are created first (here v3=3, v5=5, index="My index" and item="My item"), in the order of declaration on caller side (left to right).' -
             , 'Then the declared named arguments are assigned with the passed values, in the order of declaration on called side (left to right).' -
             , 'So it''s possible to initialize a named argument with an automatic variable (here v2 is assigned the value of index).'

call interpret 'call useNamed_Stem_CompoundSymbol_1 stem.v1:1, stem.:0, stem.v3:3, stem.v4:4, index:"My index", item:"My item"' -
             , 'The option auto is not used, so stem.v4, index and item are not created as local variables.' -
             , 'The declared named arguments are assigned with the passed values, in the order of declaration on called side (left to right):' -
             , '- The assignment stem.=0 resets the stem.' -
             , '- Then the assignments stem.v1=1, stem.v2="ITEM" (default) and stem.v3=3 are made.' -
             , 'Note that the value of the named argument item ("My item") is NOT used to initialize stem.v2 because the expression of the default value is (item) and item is an uninitialized variable'.

call interpret 'call useNamed_Stem_CompoundSymbol_2 stem.v1:1, stem.:0, stem.v3:3, stem.v4:4, index:"My index", item:"My item"' -
             , 'The option auto is not used, so stem.v4, index and item are not created as local variables.' -
             , 'The declared named arguments are assigned with the passed values, in the order of declaration on called side (left to right):' -
             , '- The assignment stem.=0 resets the stem.' -
             , '- Then the assignments stem.v1=1, stem.v2=.Context~namedArgs~index (default="My index") and stem.v3=3 are made.' -
             , 'Note that the value of the named argument item ("My item") is used to initialize stem.v2 because the expression of the default value is (Context~namedArgs~item)'.

call interpret 'call useAutoNamed_Stem_CompoundSymbol stem.v1:1, stem.:0, stem.v3:3, stem.v4:4, index:"My index", item:"My item"' -
             , 'Same test case as previous, except the option auto which is used.' -
             , 'The automatic variables are created first (here stem.v4=4, index="My index" and item="My item"), in the order of declaration on caller side (left to right).' -
             , 'Then the declared named arguments are assigned with the passed values, in the order of declaration on called side (left to right).' -
             , 'The assignment stem.=0 resets the stem, and erase the automatic variables stem.v4.' -
             , 'Then the assignments stem.v1=1, stem.v2="My index" (default) and stem.v3=3 are made.'

call interpret 'call useAutoNamed_Stem_CompoundSymbol stem.v1:1, stem.v3:3, stem.v4:4, index:"My index", item:"My item"' -
             , 'Same test case as previous, except that stem.:0 is no longer passed by the caller.' -
             , 'The automatic variables are created first (here stem.v4=4, index="My index" and item="My item"), in the order of declaration on caller side (left to right).' -
             , 'Then the declared named arguments are assigned with the passed values, in the order of declaration on called side (left to right).' -
             , 'The stem is dropped, which drops the automatic variables stem.v4.' -
             , 'Then the assignments stem.v1=1, stem.v2="My index" (default) and stem.v3=3 are made.'

call interpret 'call useAutoNamed_CompoundSymbol stem.v1:1, stem.v3:3, stem.v4:4, index:"My index", item:"My item"' -
             , 'Same test case as previous, except that the named argument ''stem.'' is no longer declared by the callee, so no longer reset.' -
             , 'The automatic variables are created first (here stem.v4=4, index="My index" and item="My item"), in the order of declaration on caller side (left to right).' -
             , 'Then the declared named arguments are assigned with the passed values, in the order of declaration on called side (left to right).' -
             , 'Then the assignments stem.v1=1, stem.v2="My index" (default) and stem.v3=3 are made.' -
             , 'Note that the automatic variable stem.v4 is available, since the stem is not reset.'


say "Testing the display of trace"
say '{...<source>..}~(a:1,b:"letter b",stem.:"default", stem.a:100, stem.b:200, stem.c:300)'
a = 10
b = 11
c = 12
{
    call sayCollection "source", .context~executable~source, displayHeader:.false, displayIndex:.false, displayIndent:.false
    say "-----------------------------------------"
    trace i
    -- the names of the compound symbols are used for matching, independently of the values of their components.
    -- Even if a==50, stem.a will be matched as "STEM.A", not "STEM.50"
    a = 50
    b = 51
    c = 52
    use strict /*auto*/ named arg a, b, stem., stem.a, stem.b, stem.c
    trace o
    say "-----------------------------------------"
    call sayArg .context
    call sayCollection "variables", .context~variables
    call sayCollection "stem", stem.
    say; say
}~rawexecutable~call(a:1,b:"letter b",stem.:"default", stem.a:100, stem.b:200, stem.c:300)


-----------------
-- UNKNOWN method
-----------------
call title "Unknown method"
call interpret 'r = .myclass~foo'
call interpret 'r = .myclass~foo()'
call interpret 'r = .myclass~foo(1, 2, 3)'
call interpret 'r = .myclass~foo(1, 2, a3:3)'
call interpret 'r = .myclass~foo(1, a2:2, a3:3)'
call interpret 'r = .myclass~foo(1, a2:(2*5/4)**5, a3:.array~new(3,3))'
call interpret 'r = .myclass~foo( , , 3, ,)'
call interpret 'r = .myclass~foo( , , 3, , a5:5)'
call interpret 'r = .myclass~foo(1, 2, 3){}'
call interpret 'r = .myclass~foo(1, 2, a3:3){}'
call interpret 'r = .myclass~foo(1, a2:2, a3:3){}'

--------------
-- Message~new
--------------
-- todo...

-------------------------
-- Message~namedArguments
-------------------------
-- todo...

-----------------------------
-- Object~run floating method
-----------------------------
call title "Run a floating method"
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"])'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "I")'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "I", 1, 2, 3)'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "I", 1, 2, a3:3)'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "I", 1, a2:2, a3:3)'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "I", 1, a2:(2*5/4)**5, a3:.array~new(3,3))'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "I", , , 3, ,)'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "I", , , 3, , a5:5)'
-- Here, namedArguments is just an ordinary argument, unlike when used with the 'A' option
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "I", 1, 2, a3:3, namedArguments:.directory~of(a2:2, a3:3))'
---
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "I", 1, 2, 3){}'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "I", 1, 2, a3:3){}'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "I", 1, a2:2, a3:3){}'
---
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "A", .array~new)'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "A", (1, 2, 3))'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "A", (1, 2), namedArguments:.directory~of(a3:3))'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "A", .array~of(1), namedArguments:.directory~of(a2:2, a3:3))'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "A", .array~of(1), namedArguments:.directory~of(a2:(2*5/4)**5, a3:.array~new(3,3)))'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "A", ( , , 3, ,))'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "A", ( , , 3, ,), namedArguments:.directory~of(a5:5))'

------------------
-- Object~SendWith
------------------
call title "Call a method using sendWith"
call interpret 'r = .myclass~sendWith("mymethod", .array~new)'
call interpret 'r = .myclass~sendWith("mymethod", (1, 2, 3))'
call interpret 'r = .myclass~sendWith("mymethod", (1, 2), namedArguments:.directory~of(a3:3))'
call interpret 'r = .myclass~sendWith("mymethod", .array~of(1), namedArguments:.directory~of(a2:2, a3:3))'
call interpret 'r = .myclass~sendWith("mymethod", .array~of(1), namedArguments:.directory~of(a2:(2*5/4)**5, a3:.array~new(3,3)))'
call interpret 'r = .myclass~sendWith("mymethod", ( , , 3, ,))'
call interpret 'r = .myclass~sendWith("mymethod", ( , , 3, ,), namedArguments:.directory~of(a5:5))'
---
call interpret 'r = .myclass~sendWith("mymethod", (1, 2, 3, {}))'
call interpret 'r = .myclass~sendWith("mymethod", (1, 2, {}), namedArguments:.directory~of(a3:3))'
call interpret 'r = .myclass~sendWith("mymethod", (1, {}), namedArguments:.directory~of(a2:2, a3:3))'

-------------------
-- Object~startWith
-------------------
-- todo...

-------------------
-- Routine~callWith
-------------------
-- todo...

---------------------
-- Context~setArgs
---------------------
call title "Change the arguments"
say "Initial arguments"
call sayArg .context
say interpret 'call sayArg .context'
interpret 'call sayArg .context'

say
say '.context~setArgs(.array~of(1,2))'
.context~setArgs(.array~of(1,2))
call sayArg .context
say interpret 'call sayArg .context'
interpret 'call sayArg .context'
say 'use arg a1, a2; say "a1="a1 "a2="a2'
use arg a1, a2; say "a1="a1 "a2="a2
say interpret 'say "a1="arg(1) "a2="arg(2)'
interpret 'say "a1="arg(1) "a2="arg(2)'

say
say '.context~setArgs(.array~of(1,2), namedArguments:.directory~of(n1:1, n2:2))'
.context~setArgs(.array~of(1,2), namedArguments:.directory~of(n1:1, n2:2))
call sayArg .context
say interpret 'call sayArg .context'
interpret 'call sayArg .context'
say 'use arg a1, a2; say "a1="a1 "a2="a2'
use arg a1, a2; say "a1="a1 "a2="a2
say interpret 'say "a1="arg(1) "a2="arg(2)'
interpret 'say "a1="arg(1) "a2="arg(2)'
say 'use named arg n1, n2; say "n1="n1 "n2="n2'
use arg n1, n2; say "n1="n1 "n2="n2
say
say

-- When creating a thread, the arguments are migrated to the thread. Check that it works as expected after using setArgs
call interpret '.myclass~reply(.array~of(1, 2), namedArguments:.directory~of(n1:1, n2:2))'
call SysSleep 1 -- wait one second to be sure that the messages after reply are displayed before continuing

---------------------------
-- StackFrame~nameArguments
---------------------------
-- todo...

------------------------
-- Security manager CALL
------------------------
-- todo...

--------------------------
-- Security manager METHOD
--------------------------
-- todo...

--------
-- Block
--------
call title "Call a block"
call interpret '{call sayArg .context}~rawExecutable~call'
call interpret '{call sayArg .context}~rawExecutable~call()'
call interpret '{call sayArg .context}~rawExecutable~call(1, 2, 3)'
call interpret '{call sayArg .context}~rawExecutable~call(1, 2, a3:3)'
call interpret '{call sayArg .context}~rawExecutable~call(1, a2:2, a3:3)'
call interpret '{call sayArg .context}~rawExecutable~call(1, a2:(2*5/4)**5, a3:.array~new(3,3))'
call interpret '{call sayArg .context}~rawExecutable~call( , , 3, ,)'
call interpret '{call sayArg .context}~rawExecutable~call( , , 3, , a5:5)'
---
call interpret '{call sayArg .context}~rawExecutable~call(1, 2, 3){}'
call interpret '{call sayArg .context}~rawExecutable~call(1, 2, a3:3){}'
call interpret '{call sayArg .context}~rawExecutable~call(1, a2:2, a3:3){}'

--------------------------
-- Trapped expected errors
--------------------------
call title "Trapped expected errors"

-- no error, should raise an error
-- [later] why do you expect an error here ? The trailing comma is a continuation character followed by nothing
call interpret 'call myprocedure , , 3, , a5:5,' -
             , 'Ok, no error because the trailing comma is a continuation character followed by nothing'
call interpret 'call myroutine , , 3, , a5:5,' -
             , 'Ok, no error because the trailing comma is a continuation character followed by nothing'

-- here the trailing comma is not a continuation character
call interpret 'call myprocedure , , 3, , a5:5,;' -
             , 'Should raise an error because of the trailing comma (TODO)'
call interpret 'call myroutine , , 3, , a5:5,;' -
             , 'Should raise an error because of the trailing comma (TODO)'

-- only assignable variable symbols are allowed
call interpret 'call myprocedure .envSymbol:1' -
             , 'Error 31.003 Variable symbol must not start with a ''.''; found ''.envSymbol'''
call interpret 'call myprocedure 3:1' -
             , 'Error 35.1:  Incorrect expression detected at ":"'
call interpret 'call myprocedure 1, a2:2, 3' -
             , 'Error 31.2:  Variable symbol must not start with a number; found "3'
call interpret 'call myprocedure 1.2:1' -
             , 'Error 35.1: Incorrect expression detected at ":"'
call interpret 'call myprocedure 1.2.3:1' -
             , 'Error 35.1: Incorrect expression detected at ":"'

-- call with named arguments
call interpret 'call myprocedure 1, a2:2, a3:' -
             , 'Error 99.900:  Named argument: expected expression after colon'
call interpret 'call myprocedure a1:1, a1:2' -
               'Error 99.900:  Named argument: ''A1:'' is passed more than once'
call interpret 'call myprocedure a1:1, , a3:3' -
             , 'Error 99.900: Named argument: expected symbol followed by colon'
call interpret 'call myprocedure instance~method:1' -
             , 'Error 20.917: Symbol expected after superclass colon (:)'

-- Method 'sendWith'
call interpret 'r = .myclass~sendWith("mymethod")' -
             , 'Error 93.903: Missing argument in method; argument 2 is required'
call interpret 'r = .myclass~sendWith("mymethod", .object /* not an array */, namedArguments:.directory~of(a3:3))' -
             , 'Error 88.913: positional argument 2 must have a single-dimensional array value; found "The Object class"'
call interpret 'r = .myclass~sendWith("mymethod", (1, 2), namedArguments: "not a directory")' -
             , 'Error 98.900: sendWith: The value of NAMEDARGUMENTS must be a directory or NIL'


-- Method 'callWith'
call interpret '{}~rawExecutable~callwith(.array~of(), n:.directory~of(""))' -
             , 'Error 20.900: Expected a symbol for the named argument name; found ""'
call interpret '{}~rawExecutable~callwith(.array~of(), n:.directory~of("1"))' -
             , 'Error 20.900: Expected a symbol for the named argument name; found "1"'
call interpret '{}~rawExecutable~callwith(.array~of(), n:.directory~of("a 1"))' -
             , 'Error 20.900: Expected a symbol for the named argument name; found "a 1"'
call interpret '{}~rawExecutable~callwith(.array~of(), n:.directory~of(".a"))' -
             , 'Error 20.900: Expected a symbol for the named argument name; found ".a"'

-- Instruction 'forward'
source = 'forward message "mymethod" namedArguments continue'
call interpret 'm = .method~new("",' quoted(source)')' -
             , 'Error 35.1:    Incorrect expression detected at "CONTINUE"'
source = 'forward message "mymethod" namedArguments'
call interpret 'm = .method~new("",' quoted(source)')' -
             , 'Error 35.900:  Missing expression following NAMEDARGUMENTS keyword of a FORWARD instruction'
source = 'forward message "mymethod" array ( 10, 20, 30, a1:40, a2:50 ) namedArguments (.directory~of(a1:1, a2:2) continue'
call interpret 'm = .method~new("",' quoted(source)')' -
             , 'Error 25.918: Duplicate [NAMED]ARGUMENTS or ARRAY keyword found'
call interpret 'r = .myclass~forwardNamedArgumentsNotDirectory' -
             , "Error 98.900: FORWARD: The value of 'NAMEDARGUMENTS' must be a directory or NIL"

-- Method 'run'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "A", (1, 2, 3)){}' -
             , 'Error 93.902: Too many positional arguments in invocation of method; 3 expected'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "A", (1, 2), namedArguments:.directory~of(a3:3)){}' -
             , 'Error 93.902: Too many positional arguments in invocation of method; 3 expected'
call interpret 'r = .myclass~myrun(.methods["MYFLOATINGMETHOD"], "A", .array~of(1), namedArguments:.directory~of(a2:2, a3:3)){}' -
             , 'Error 93.902: Too many positional arguments in invocation of method; 3 expected'

-- Instruction 'use named'
call interpret 'call useNamed_EnvironmentSymbolNotAllowed' -
             , 'Error 31.3: Variable symbol must not start with a "."; found ".ENVSYMBOL"'
call interpret 'call useNamed_MessageTermNotAllowed' -
             , 'Error 87.2: The USE NAMED instruction requires a comma-separated list of variable symbols'
call interpret 'call useNamed_SkippedArgumentNotAllowed' -
             , 'Error 87.1: Skipped variables are not allowed by the USE NAMED instruction'

-- Instruction 'use'
call interpret 'call useStrictZeroNamed a1:1' -
             , 'Error 40.4: Too many named arguments in invocation of USESTRICTZERONAMED; maximum expected is 0'
call interpret 'call useStrictOneNamed_NoDefault' -
             , 'Error 40.3: Not enough named arguments in invocation of USESTRICTONENAMED_NODEFAULT; minimum expected is 1'
call interpret 'call useStrictOneNamed_NoDefault b1:1' -
             , 'Error 88.917: named argument B1 is not an expected argument name'
call interpret '{use strict named arg n1,n2,n3}~rawExecutable~call()' -
             , 'Error 40.3: Not enough named arguments in invocation of ; minimum expected is 3'
call interpret '{use strict named arg n1=1,n2,n3}~rawExecutable~call()' -
             , 'Error 40.3: Not enough named arguments in invocation of ; minimum expected is 2'
call interpret '{use strict named arg n1=1,n2,n3=3}~rawExecutable~call()' -
             , 'Error 40.3: Not enough named arguments in invocation of ; minimum expected is 1'
call interpret 'call useStrictOneNamed_NoDefault b1:1, b2:2' -
             , 'Error 40.4: Too many named arguments in invocation of USESTRICTONENAMED_NODEFAULT; maximum expected is 1'
call interpret 'call useStrictOneNamed_WithDefault b2:2' -
             , 'Error 88.917: named argument B2 is not an expected argument name'
call interpret 'call useStrictOneNamed_WithDefaultExpression b2:2' -
             , 'Error 88.917: named argument B2 is not an expected argument name'
call interpret 'call useStrictAutoNamed_WithoutEllipse' -
             , 'Error 99.900: STRICT AUTO requires the "..." argument marker at the end of the argument list'

-- Abbreviation
call interpret '{use named arg n()}' -
             , 'Error 26.900: Named argument minimum length must be a positive whole number'
call interpret '{use named arg n(0)}' -
             , 'Error 26.900: Named argument minimum length must be a positive whole number'
call interpret '{use named arg command, commands(7)}' -
             , 'Error 99.900: Use named arg: The name ''COMMAND'' collides with ''COMMANDS(7)'''
call interpret '{use named arg command(1), commands(7)}' -
             , 'Error 99.900: Use named arg: The name ''COMMAND(1)'' collides with ''COMMANDS(7)'''
call interpret '{use named arg n, n}' -
             , 'Error 99.900: Use named arg: The name ''N'' collides with ''N'''
call interpret '{use named arg item(1), index(1)}' -
             , 'Error 99.900: Use named arg: The name ''ITEM(1)'' collides with ''INDEX(1)'''

-- Change arguments
call interpret '.context~setArgs' -
             , 'Error 93.903: Missing positional argument in method; argument 1 is required'
call interpret '.context~setArgs(.nil)' -
             , 'Error 88.913: positional argument 1 must have a single-dimensional array value; found "The NIL object"'
call interpret '.context~setArgs(,)' -
             , 'Error 93.902: Too many positional arguments in invocation of method; 1 expected'
call interpret '.context~setArgs(,,)' -
             , 'Error 93.902: Too many positional arguments in invocation of method; 1 expected'
call interpret '.context~setArgs(.array~of(1), .directory~of(n1:1))' -
             , 'Error 93.902: Too many positional arguments in invocation of method; 1 expected'
call interpret '.context~setArgs(.array~of(1), namedArguments:"not a directory")' -
             , 'Error 98.900: SETARGS namedArguments must be a directory or NIL'
call interpret '.context~setArgs(.array~of(1), NOT_namedArguments:.directory~of(n1:1))' -
             , 'Error 88.917: named argument NOT_NAMEDARGUMENTS is not an expected argument name'

return

--------------------------------------------------------------------------------

myprocedure:
    call sayArg .context
    return ""

--------------------------------------------------------------------------------

interpret: procedure
    signal on syntax name error
    source = arg(1)
    say source
    interpret source
    expected:
    if arg() == 2 then say "Expected:" arg(2)
    if arg() > 2 then do
        say "Expected:"
        do i=2 to arg()
            say arg(i)
        end
    end
    say; say
    return
    error:
    call sayCondition condition("O")
    signal expected

--------------------------------------------------------------------------------

::routine myroutine
    call sayArg .context
    return ""

--------------------------------------------------------------------------------
:: routine usePositionalNamed
    call sayArg .context
    call indent
    say 'use arg p1, p2, p3, p4'
         use arg p1, p2, p3, p4
    call indent
    say 'use named arg a5, a6'
         use named arg a5, a6
    call sayCollection "variables", .context~variables
    return ""

--------------------------------------------------------------------------------
:: routine useStrictPositionalNamed
    call sayArg .context
    call indent
    say 'use strict arg p1, p2=2, p3, p4=4'
         use strict arg p1, p2=2, p3, p4=4
    call indent
    say 'use strict named arg a5, a6'
         use strict named arg a5, a6
    call sayCollection "variables", .context~variables
    return ""

--------------------------------------------------------------------------------
::routine useStrictZeroNamed
    call sayArg .context
    call indent
    say 'use strict named arg'
         use strict named arg
    call sayCollection "variables", .context~variables
    return ""

--------------------------------------------------------------------------------
::routine useStrictOneNamed_NoDefault
    call sayArg .context
    call indent
    say 'use strict named arg a1'
         use strict named arg a1
    call sayCollection "variables", .context~variables
    return ""

--------------------------------------------------------------------------------
::routine useStrictOneNamed_WithDefault
    call sayArg .context
    call indent
    say 'use strict named arg a1=1'
         use strict named arg a1=1
    call sayCollection "variables", .context~variables
    return ""

--------------------------------------------------------------------------------
::routine useStrictOneNamed_WithDefaultExpression
    call sayArg .context
    call indent
    say 'use strict named arg a1=(1+0)'
         use strict named arg a1=(1+0)
    call sayCollection "variables", .context~variables
    return ""

--------------------------------------------------------------------------------
:: routine useNamed_SimpleSymbol
    call sayArg .context
    call indent
    say 'use named arg v1, v2=2'
         use named arg v1, v2=2
    call sayCollection "variables", .context~variables
    return ""

--------------------------------------------------------------------------------
::routine useNamed_WithMinimumLength
    -- Specifying a minimum length

    call indent
    say 'use named arg n(1)'
         use named arg n(1)

    call indent
    say 'use named arg n(10)'
         use named arg n(10)

    call indent
    say 'use named arg n(100)'
         use named arg n(100)

    call indent
    say 'use named arg n(+1)'
         use named arg n(+1)

    call indent
    say 'use named arg n(1) = 10'
         use named arg n(1) = 10

    return ""

--------------------------------------------------------------------------------
::routine useStrictAutoNamed_WithoutEllipse
    source = ( -
    'call sayArg .context'              ,-
    'call indent'                       ,-
    'say "use strict auto named arg"'   ,-
    '     use strict auto named arg'    ,-
    )
    -- raise an error at parse time'
    -- Error 99.900:  STRICT AUTO requires the "..." argument marker at the end of the argument list'
    routine = .routine~new("useStrictAutoNamed_WithoutEllipse", source)

--------------------------------------------------------------------------------
::routine useStrictAutoNamed_WithEllipse
    call sayArg .context
    call indent
    say 'use strict auto named arg ...'
         use strict auto named arg ...
    call sayCollection "variables", .context~variables
    return ""

--------------------------------------------------------------------------------
:: routine useAutoNamed_SimpleSymbol
    call sayArg .context
    call indent
    say 'use auto named arg v1=(item), v2=(index)'
         use auto named arg v1=(item), v2=(index)
    call sayCollection "variables", .context~variables
    return ""

--------------------------------------------------------------------------------
:: routine useNamed_Stem_CompoundSymbol_1
    call sayArg .context
    call indent
    say 'use named arg stem., stem.v1, stem.v2=(item), stem.v3=(index)'
         use named arg stem., stem.v1, stem.v2=(item), stem.v3=(index)
    call sayCollection "variables", .context~variables
    call sayCollection "stem", stem.
    return ""

--------------------------------------------------------------------------------
:: routine useNamed_Stem_CompoundSymbol_2
    call sayArg .context
    call indent
    say 'use named arg stem., stem.v1, stem.v2=(.Context~namedArgs~item), stem.v3=(.Context~namedArgs~index)'
         use named arg stem., stem.v1, stem.v2=(.Context~namedArgs~item), stem.v3=(.Context~namedArgs~index)
    call sayCollection "variables", .context~variables
    call sayCollection "stem", stem.
    return ""

--------------------------------------------------------------------------------
:: routine useAutoNamed_Stem_CompoundSymbol
    call sayArg .context
    call indent
    say 'use auto named arg stem., stem.v1, stem.v2=(item), stem.v3=(index)'
         use auto named arg stem., stem.v1, stem.v2=(item), stem.v3=(index)
    call sayCollection "variables", .context~variables
    call sayCollection "stem", stem.
    return ""

--------------------------------------------------------------------------------
:: routine useAutoNamed_CompoundSymbol
    call sayArg .context
    call indent
    say 'use auto named arg stem.v1, stem.v2=(item), stem.v3=(index)'
         use auto named arg stem.v1, stem.v2=(item), stem.v3=(index)
    call sayCollection "variables", .context~variables
    call sayCollection "stem", stem.
    return ""

--------------------------------------------------------------------------------
:: routine useNamed_EnvironmentSymbolNotAllowed
    call indent
    say                 'use named arg .envSymbol'
    m = .method~new("", 'use named arg .envSymbol')

--------------------------------------------------------------------------------
:: routine useNamed_MessageTermNotAllowed
    call indent
    say                 'use named arg instance~method'
    m = .method~new("", 'use named arg instance~method')

--------------------------------------------------------------------------------
:: routine useNamed_SkippedArgumentNotAllowed
    call indent
    say                 'use named arg n1,,n3'
    m = .method~new("", 'use named arg n1,,n3')

--------------------------------------------------------------------------------

::method myFloatingMethod
    call sayArg .context
    return ""

--------------------------------------------------------------------------------

::class myclass
::method mymethod class
    call sayArg .context
    return ""

::method forwardArray class
    call indent
    say 'forward message "mymethod" array ( 10, 20, 30, a1:40, a2:50 ) continue'
         forward message "mymethod" array ( 10, 20, 30, a1:40, a2:50 ) continue
    return ""

::method forwardNamedArguments class
    call indent
    say 'forward message "mymethod" namedArguments (.directory~of(a1:1, a2:2)) continue'
         forward message "mymethod" namedArguments (.directory~of(a1:1, a2:2)) continue
    return ""

::method forwardNamedArgumentsNotDirectory class
    call indent
    say 'forward message "mymethod" namedArguments ("not a directory") continue'
         forward message "mymethod" namedArguments ("not a directory") continue
    return ""

::method forwardPositionalNamedArguments class
    call indent
    say 'forward message "mymethod" arguments ((1,2)) namedArguments (.directory~of(a1:1, a2:2)) continue'
         forward message "mymethod" arguments ((1,2)) namedArguments (.directory~of(a1:1, a2:2)) continue
    return ""

::method forwardNamedPositionalArguments class
    call indent
    say 'forward message "mymethod" namedArguments (.directory~of(a1:1, a2:2)) arguments ((1,2)) continue'
         forward message "mymethod" namedArguments (.directory~of(a1:1, a2:2)) arguments ((1,2)) continue
    return ""

::method myrun class
    -- 'run' is a private method, must be called from another method of myclass, hence 'myrun'
    forward message ("run")

::method unknown class
    use arg name, arguments
    -- use named arg namedArguments
    namedArguments = .context~namedArgs["NAMEDARGUMENTS"]

    call indent 1
    say "method 'unknown'"
    call sayArg .context, indentLevel:1

    -- call sayCollection "initial positional", arguments, 1
    -- call sayCollection "initial named", namedArguments, 1

    call indent 1
    say "method 'unknown' forward to (.myfooclass) message (name) arguments (arguments) namedArguments (namedArguments)"
    forward to(.myfooclass) message (name) arguments (arguments) namedArguments (namedArguments)

::method reply class
    call indent 1
    say "On entry in the method"
    call sayArg .context
    say

    use arg positionalArguments
    use named arg namedArguments
    .context~setArgs(positionalArguments, n:namedArguments)
    call indent 1
    say "After setArgs"
    call sayArg .context

    reply
    call indent 1
    say "On entry in the thread (migrated arguments)"
    call sayArg .context

    .context~setArgs(.array~of(1, 2, 3), n:.directory~of(n1:1, n2:2, n3:3))
    call indent 1
    say "After setArgs in thread"
    call sayArg .context

    say
    say

--------------------------------------------------------------------------------

::class myfooclass
::method foo class
    call sayArg .context, indentLevel:1
    return ""

--------------------------------------------------------------------------------

::routine quoted
    return "'"arg(1)"'"

::routine indent
    use strict arg level=1
    do level
        call charout , "    "
    end

::routine sayArg
    use strict arg context
    use strict named arg indentLevel=0
    positionalArgs = context~args
    namedArgs = context~namedArgs
    call sayCollection "positional", positionalArgs, indentLevel:indentLevel
    call sayCollection "named", namedArgs, indentLevel:indentLevel

::routine sayCollection
    use strict arg kind, collection
    use strict named arg displayHeader=.true, displayIndex=.true, displayIndent=.true, indentLevel=0

    if displayHeader then do
        if displayIndent then call indent indentLevel+1
        if collection~isa(.array) then say kind "count="collection~items "size="collection~size
        else if collection <> .nil then say kind "count="collection~items
        else say kind "count=0"
    end

    if collection == .nil then return

    indexes = collection~allIndexes
    if \collection~isa(.orderedCollection) then indexes = indexes~sort
    do i over indexes
        if displayIndent then call indent indentLevel+2
        if displayIndex then call charout , i ": "
        say collection[i]
    end

::routine sayCondition
    use strict arg condition
    if condition~condition <> "SYNTAX" then call sayTrapped condition~condition
    if condition~description <> .nil, condition~description <> "" then call sayTrapped condition~description
    -- For SYNTAX conditions
    if condition~message <> .nil then call sayTrapped condition~message
    else if condition~errortext <> .nil then call sayTrapped condition~errortext
    if condition~code <> .nil then call sayTrapped "Code=" condition~code

::routine sayTrapped
    use strict arg value
    call indent
    say "[trapped]" value

::routine title
    use arg text, width=80
    say copies("*", width)
    say "*"center(text, width-2)"*"
    say copies("*", width)
    say

--------------------------------------------------------------------------------

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
