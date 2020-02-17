call evaluate "demonstration"
say
say "Ended coactivities:" .Coactivity~endAll


--::options trace i
::routine demonstration

delay = 0.5 -- this delay is passed to SysSleep to avoid messing the output because of the concurrent execution

-- -----------------------------------------------------------------------------
-- .Directory~of
-- -----------------------------------------------------------------------------

-- The class .Directory now supports the method ~of.
-- The key-value where the key is compatible with a named  argument can be passed as named argument.
-- The key-value where the key is not compatible with a named argument can be passed as a pair of positional arguments.
call dump2 .directory~of("key 1", "value 1","key 2", 2, key3:"value 3", key4:4)
/*
    a Directory (4 items)
    'KEY3'  : 'value 3'
    'KEY4'  : 4
    'key 1' : 'value 1'
    'key 2' : 2
*/

-- Helper routine d() to create a directory
call dump2 d(a1:1, a2:2)
/*
    a Directory (2 items)
    'A1' : 1
    'A2' : 2
*/

-- Helper routine d() to create a directory
call dump2 d("key 1", "value 1","key 2", 2, key3:"value 3", key4:4)
/*
    a Directory (4 items)
    'KEY3'  : 'value 3'
    'KEY4'  : 4
    'key 1' : 'value 1'
    'key 2' : 2
*/


-- -----------------------------------------------------------------------------
-- Method ~do
-- -----------------------------------------------------------------------------

-- The ~do method now supports named arguments
-- Illustration with a doer of type routine
{call dump2 .context~args; call dump2 .context~namedargs}~do(1, , 3, a1:1, a2:2)
/*
    an Array (shape [3], 2 items)
    1 : 1
    3 : 3
    a Directory (2 items)
    'A1' : 1
    'A2' : 2
*/

-- The ~do method now supports named arguments
-- Illustration with a doer of type method
method = .MyClass~instancemethod("myMethod")
method~do(.MyClass, 1, , 3, a1:1, a2:2)
/*
    an Array (shape [3], 2 items)
     1 :  1
     3 :  3
    a Directory (2 items)
    'A1' :  1
    'A2' :  2
*/


-- The ~do method now supports named arguments
-- Illustration with a doer of type message
"myMethod"~do(.MyClass, 1, , 3, a1:1, a2:2)
/*
    an Array (shape [3], 2 items)
     1 :  1
     3 :  3
    a Directory (2 items)
    'A1' :  1
    'A2' :  2
*/


-- The ~do method now supports named arguments
-- Illustration with a doer of type closure
{expose dummy; call dump2 .context~args; call dump2 .context~namedargs}~do(1, , 3, a1:1, a2:2)
/*
    an Array (shape [3], 2 items)
    1 : 1
    3 : 3
    a Directory (2 items)
    'A1' : 1
    'A2' : 2
*/


-- The ~do method now supports named arguments
-- Illustration with a doer of type coactivity
{::co call dump2 .context~args; call dump2 .context~namedargs}~do(1, , 3, a1:1, a2:2)
/*
    an Array (shape [3], 2 items)
    1 : 1
    3 : 3
    a Directory (2 items)
    'A1' : 1
    'A2' : 2
*/


-- -----------------------------------------------------------------------------
-- Method ~doWith
-- -----------------------------------------------------------------------------

-- The ~doWith method now supports named arguments
-- Illustration with a doer of type routine
-- Here the abbreviation 'n' is supported because doWith forwards directly to callWith
{call dump2 .context~args; call dump2 .context~namedargs}~doWith(v(1, , 3), n:d(a1:1, a2:2))
/*
    an Array (shape [3], 2 items)
    1 : 1
    3 : 3
    a Directory (2 items)
    'A1' : 1
    'A2' : 2
*/


-- The ~doWith method now supports named arguments
-- Illustration with a doer of type method
method = .MyClass~instancemethod("myMethod")
method~doWith(.MyClass, v(1, , 3), n:d(a1:1, a2:2))
/*
    an Array (shape [3], 2 items)
     1 :  1
     3 :  3
    a Directory (2 items)
    'A1' :  1
    'A2' :  2
*/


-- The ~doWith method now supports named arguments
-- Illustration with a doer of type message
"myMethod"~doWith(.MyClass, v(1, , 3), n:d(a1:1, a2:2))
/*
    an Array (shape [3], 2 items)
     1 :  1
     3 :  3
    a Directory (2 items)
    'A1' :  1
    'A2' :  2
*/


-- The ~doWith method now supports named arguments
-- Illustration with a doer of type closure
{expose dummy; call dump2 .context~args; call dump2 .context~namedargs}~doWith(v(1, , 3), n:d(a1:1, a2:2))
/*
    an Array (shape [3], 2 items)
    1 : 1
    3 : 3
    a Directory (2 items)
    'A1' : 1
    'A2' : 2
*/


-- The ~doWith method now supports named arguments
-- Illustration with a doer of type coactivity
{::co call dump2 .context~args; call dump2 .context~namedargs}~doWith(v(1, , 3), n:d(a1:1, a2:2))
/*
    an Array (shape [3], 2 items)
    1 : 1
    3 : 3
    a Directory (2 items)
    'A1' : 1
    'A2' : 2
*/


-- -----------------------------------------------------------------------------
-- Method ~go
-- -----------------------------------------------------------------------------

-- The ~go method now supports named arguments
-- Illustration with a doer of type routine
{call dump2 .context~args; call dump2 .context~namedargs}~go(1, , 3, a1:1, a2:2)
/*
    an Array (shape [3], 2 items)
    1 : 1
    3 : 3
    a Directory (2 items)
    'A1' : 1
    'A2' : 2
*/
call syssleep delay -- to avoid messing the output because of the concurrent execution

-- The ~go method now supports named arguments
-- Illustration with a doer of type method
method = .MyClass~instancemethod("myMethod")
message = method~go(.MyClass, 1, , 3, a1:1, a2:2)
/*
    an Array (shape [3], 2 items)
     1 :  1
     3 :  3
    a Directory (2 items)
    'A1' :  1
    'A2' :  2
*/
call syssleep delay -- to avoid messing the output because of the concurrent execution


-- The ~go method now supports named arguments
-- Illustration with a doer of type message
message = "myMethod"~go(.MyClass, 1, , 3, a1:1, a2:2)
/*
    an Array (shape [3], 2 items)
     1 :  1
     3 :  3
    a Directory (2 items)
    'A1' :  1
    'A2' :  2
*/
call syssleep delay -- to avoid messing the output because of the concurrent execution


-- The ~go method now supports named arguments
-- Illustration with a doer of type closure
{expose dummy; call dump2 .context~args; call dump2 .context~namedargs}~go(1, , 3, a1:1, a2:2)
/*
    an Array (shape [3], 2 items)
    1 : 1
    3 : 3
    a Directory (2 items)
    'A1' : 1
    'A2' : 2
*/
call syssleep delay -- to avoid messing the output because of the concurrent execution


-- The ~go method now supports named arguments
-- Illustration with a doer of type coactivity
{::co call dump2 .context~args; call dump2 .context~namedargs}~go(1, , 3, a1:1, a2:2)
/*
    an Array (shape [3], 2 items)
    1 : 1
    3 : 3
    a Directory (2 items)
    'A1' : 1
    'A2' : 2
*/
call syssleep delay -- to avoid messing the output because of the concurrent execution


-- -----------------------------------------------------------------------------
-- Method ~goWith
-- -----------------------------------------------------------------------------

-- The ~goWith method now supports named arguments
-- Illustration with a doer of type routine
{call dump2 .context~args; call dump2 .context~namedargs}~goWith(v(1, , 3), n:d(a1:1, a2:2))
/*
    an Array (shape [3], 2 items)
    1 : 1
    3 : 3
    a Directory (2 items)
    'A1' : 1
    'A2' : 2
*/
call syssleep delay -- to avoid messing the output because of the concurrent execution


-- The ~goWith method now supports named arguments
-- Illustration with a doer of type method
method = .MyClass~instancemethod("myMethod")
message = method~goWith(.MyClass, v(1, , 3), n:d(a1:1, a2:2))
/*
    an Array (shape [3], 2 items)
     1 :  1
     3 :  3
    a Directory (2 items)
    'A1' :  1
    'A2' :  2
*/
call syssleep delay -- to avoid messing the output because of the concurrent execution


-- The ~goWith method now supports named arguments
-- Illustration with a doer of type message
message = "myMethod"~goWith(.MyClass, v(1, , 3), n:d(a1:1, a2:2))
/*
    an Array (shape [3], 2 items)
     1 :  1
     3 :  3
    a Directory (2 items)
    'A1' :  1
    'A2' :  2
*/
call syssleep delay -- to avoid messing the output because of the concurrent execution


-- The ~goWith method now supports named arguments
-- Illustration with a doer of type closure
{expose dummy; call dump2 .context~args; call dump2 .context~namedargs}~goWith(v(1, , 3), n:d(a1:1, a2:2))
/*
    an Array (shape [3], 2 items)
    1 : 1
    3 : 3
    a Directory (2 items)
    'A1' : 1
    'A2' : 2
*/
call syssleep delay -- to avoid messing the output because of the concurrent execution


-- The ~goWith method now supports named arguments
-- Illustration with a doer of type coactivity
{::co call dump2 .context~args; call dump2 .context~namedargs}~goWith(v(1, , 3), n:d(a1:1, a2:2))
/*
    an Array (shape [3], 2 items)
    1 : 1
    3 : 3
    a Directory (2 items)
    'A1' : 1
    'A2' : 2
*/
call syssleep delay -- to avoid messing the output because of the concurrent execution


-- -----------------------------------------------------------------------------
-- Method ~partial
-- -----------------------------------------------------------------------------

-- The ~partial method now supports named arguments
-- Illustration, part 1 : the partial arguments
{call dump2 .context~args; call dump2 .context~namedargs}~partial(1, , 3, , a1:1, a2:2)~()
/*
    an Array (shape [4], 2 items)
    1 : 1
    3 : 3
    a Directory (2 items)
    'A1' : 1
    'A2' : 2
*/

-- The ~partial method now supports named arguments
-- Illustration, part 2: the final arguments
{call dump2 .context~args; call dump2 .context~namedargs}~partial(1, , 3, , a1:1, a2:2)~(2, ,5 , a1:10, a3:3)
/*
    an Array (shape [4], 4 items)
    1 : 1                   -- Set with ~partial
    2 : 2                   -- Passed in final call (fill the first "hole")
    3 : 3                   -- Set with ~partial
    5 : 5                   -- Passed in final call (skip the second "hole" because of the omitted argument between 2 and 5)
    a Directory (3 items)
    'A1' : 10               -- The value set with ~partial has been overriden
    'A2' : 2                -- Set with ~partial
    'A3' : 3                -- Added in final call
*/


--------------------------------------------------------------------------------
-- Definitions
--------------------------------------------------------------------------------

::class MyClass

::method myMethod class
    call dump2 .context~args
    call dump2 .context~namedargs


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

::routine evaluate
    use strict arg evaluate_routineName
    evaluate_routine = .context~package~findRoutine(evaluate_routineName)
    evaluate_routineSource = evaluate_routine~source
    evaluate_curly_bracket_count = 0
    evaluate_string = ""
    evaluate_clause_separator = ""
    evaluate_multiline_comment = 0
    evaluate_supplier = evaluate_routineSource~supplier
    loop:
        if \ evaluate_supplier~available then return
        evaluate_sourceline = evaluate_supplier~item
        if evaluate_sourceline~strip~left(3) == "---" then nop -- Comments starting with 3 '-' are removed
        else if evaluate_sourceline~strip == "/*" then evaluate_multiline_comment += 1
        else if evaluate_sourceline~strip == "*/" then evaluate_multiline_comment -= 1
        else if evaluate_multiline_comment <> 0 then nop -- Skip the multiline comments
        else if evaluate_sourceline~strip == "nop" then nop -- nop is a workaround to get the first comments
        else if evaluate_sourceline~strip~left(2) == "--" then say evaluate_sourceline -- Comments starting with 2 '-' are kept
        else if evaluate_sourceline~strip == "" then say
        else do
            -- To avoid messing the output, don't display the source line if it contains syssleep,
            -- because it may be intermixed with concurrent output (that happened to me).
            if \ evaluate_sourceline~contains("syssleep") then say "   "evaluate_sourceline
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
    say condition("O")~traceback~makearray~tostring
    evaluate_string = ""
    signal iterate


--------------------------------------------------------------------------------
::requires "extension/extensions.cls"
::requires "rgf_util2/rgf_util2_wrappers.rex" -- for the dump2 methods
