call evaluate "demonstration"
say
say "Ended coactivities:" .Coactivity~endAll

--::options trace i
::routine demonstration

--- Strange... without this instruction, I don't get the first comments
nop

-- --------------------------------------------------------------
-- Array initializers
-- --------------------------------------------------------------

-- If there is only one argument, and this argument has the method ~supplier then each item returned by the argument's supplier is an item.
call dump2      .array~new(2,3)~of(1~upto(6))
-- 1 2 3
-- 4 5 6

-- If there is only one argument, and this argument is a doer, then the doer is called for each cell to initialize.
call dump2      .array~new(2,3)~of{10*item}
-- 10 20 30
-- 40 50 60

-- Otherwise, when more than one argument, each argument is an item as-is.
call dump2      .array~new(2,3)~of(1,2,3,4,5,6)
-- 1 2 3
-- 4 5 6

-- If some arguments are omitted, then the corresponding item in the initialized arrat remains non-assigned.
call dump2      .array~new(2,3)~of(1,,3,,5,6)
-- 1 . 3
-- . 5 6

-- For me, there is a problem (bug ?) when the last arguments are explicitely omitted : they are not counted by the interpreter !
-- I passed explicitely 6 arguments, 3 of them being omitted.
-- 19/09/2017 Fixed in Executor
call dump2      .array~new(2,3)~of(1,,3,,5,)
-- 1 . 3
-- . 5 .
-- Before the fix, the last omitted argument was ignored and the result was :
-- 1 . 3
-- . 5 1

-- Rules inspired by APL :
-- If there are too many items, the extra items are ignored.
-- If there are fewer items than implied by the dimensions, the list of items is reused as many times as necessary to fill the array.
call dump2      .array~new(2,3)~of(1,2)
-- 1 2 1
-- 2 1 2

-- Test case that demonstrated a bug (a new generator was created when initializing the second array)
g={::coactivity loop i=0; if i//2 == 0 then .yield[i]; else .yield[]; end}
call dump2      .array~new(2,3)~of(g)
-- 0 . 2
-- . 4 .
call dump2      .array~new(2,3)~of(g)
-- 6  . 8
-- . 10 .


-- --------------------------------------------------------------
-- Recursive arrays
-- --------------------------------------------------------------

a = .array~of("string1","string2")
b = .array~of("string2")
b~append(a)
a~append(b)
a~append(a)
-- display the first three levels
call dump2      a, 3

say a~ppRepresentation

a~pipe(.console dataflow)

a~pipe(.inject iterateBefore {item} recursive.0.memorize | .console dataflow)

d = .array~of("d")
c = .array~of("c", d)
b = .array~of("b", c)
a = .array~of("a", b)
d~append(a)
-- display the first five levels
call dump2      a, 5

say a~ppRepresentation

-- --------------------------------------------------------------
-- Array operators
-- --------------------------------------------------------------

a = .array~of(10, 20, 30)
b = .array~of(5, a, 5+6i)
c = .array~of(15+16i, b, 15)

call dump2      -a
call dump2      -b
call dump2      -c

call dump2      100 + a
call dump2      100 + b
call dump2      100 + c
call dump2      a + 100
call dump2      b + 100
call dump2      c + 100
call dump2      (100+200i) + a
call dump2      (100+200i) + b
call dump2      (100+200i) + c
call dump2      a + (100+200i)
call dump2      b + (100+200i)
call dump2      c + (100+200i)
call dump2      a + a
call dump2      b + b
call dump2      c + c
call dump2      a + b + c

call dump2      100 - a
call dump2      100 - b
call dump2      100 - c
call dump2      a - 100
call dump2      b - 100
call dump2      c - 100
call dump2      (100+200i) - a
call dump2      (100+200i) - b
call dump2      (100+200i) - c
call dump2      a - (100+200i)
call dump2      b - (100+200i)
call dump2      c - (100+200i)
call dump2      a - a
call dump2      b - b
call dump2      c - c
call dump2      a - b - c

call dump2      100 * a
call dump2      100 * b
call dump2      100 * c
call dump2      a * 100
call dump2      b * 100
call dump2      c * 100
call dump2      (100+200i) * a
call dump2      (100+200i) * b
call dump2      (100+200i) * c
call dump2      a * (100+200i)
call dump2      b * (100+200i)
call dump2      c * (100+200i)
call dump2      a * a
call dump2      b * b
call dump2      c * c
call dump2      a * b * c

call dump2      100 / a
call dump2      100 / b
call dump2      100 / c
call dump2      a / 100
call dump2      b / 100
call dump2      c / 100
call dump2      (100+200i) / a
call dump2      (100+200i) / b
call dump2      (100+200i) / c
call dump2      a / (100+200i)
call dump2      b / (100+200i)
call dump2      c / (100+200i)
call dump2      a / a
call dump2      b / b
call dump2      c / c
call dump2      a / b / c

call dump2      100 % a
call dump2      100 % b
call dump2      100 % c
call dump2      a % 100
call dump2      b % 100
call dump2      c % 100
call dump2      (100+200i) % a
call dump2      (100+200i) % b
call dump2      (100+200i) % c
call dump2      a % (100+200i)
call dump2      b % (100+200i)
call dump2      c % (100+200i)
call dump2      a % a
call dump2      b % b
call dump2      c % c
call dump2      a % b % c

call dump2      100 // a
call dump2      100 // b
call dump2      100 // c
call dump2      a // 100
call dump2      b // 100
call dump2      c // 100
call dump2      (100+200i) // a
call dump2      (100+200i) // b
call dump2      (100+200i) // c
call dump2      a // (100+200i)
call dump2      b // (100+200i)
call dump2      c // (100+200i)
call dump2      a // a
call dump2      b // b
call dump2      c // c
call dump2      a // b // c

call dump2      100 ** a
--call dump2      100 ** b                  -- Operand to the right of the power operator (**) must be a whole number; found "a COMPLEX"
--call dump2      100 ** c                  -- Operand to the right of the power operator (**) must be a whole number; found "a COMPLEX"
call dump2      a ** 100
--call dump2      b ** 100                  -- Object "a COMPLEX" does not understand message "**"
--call dump2      c ** 100                  -- Object "a COMPLEX" does not understand message "**"
--call dump2      (100+200i) ** a    -- Object "a COMPLEX" does not understand message "**"
--call dump2      (100+200i) ** b    -- Object "a COMPLEX" does not understand message "**"
--call dump2      (100+200i) ** c    -- Object "a COMPLEX" does not understand message "**"
--call dump2      a ** (100+200i)    -- Operand to the right of the power operator (**) must be a whole number; found "a COMPLEX"
--call dump2      b ** (100+200i)    -- Operand to the right of the power operator (**) must be a whole number; found "a COMPLEX"
--call dump2      c ** (100+200i)    -- Object "a COMPLEX" does not understand message "**"
call dump2      a ** a
--call dump2      b ** b                    -- Object "a COMPLEX" does not understand message "**"
--call dump2      c ** c                    -- Object "a COMPLEX" does not understand message "**"
--call dump2      a ** b ** c               -- Operand to the right of the power operator (**) must be a whole number; found "a COMPLEX"

call dump2      100 a
call dump2      100 b
call dump2      100 c
call dump2      a 100
call dump2      b 100
call dump2      c 100
call dump2      (100+200i) a
call dump2      (100+200i) b
call dump2      (100+200i) c
call dump2      a (100+200i)
call dump2      b (100+200i)
call dump2      c (100+200i)
call dump2      a a
call dump2      b b
call dump2      c c
call dump2      a b c

call dump2      100 || a
call dump2      100 || b
call dump2      100 || c
call dump2      a || 100
call dump2      b || 100
call dump2      c || 100
call dump2      (100+200i) || a
call dump2      (100+200i) || b
call dump2      (100+200i) || c
call dump2      a || (100+200i)
call dump2      b || (100+200i)
call dump2      c || (100+200i)
call dump2      a || a
call dump2      b || b
call dump2      c || c
call dump2      a || b || c

call dump2      (100)(a)
call dump2      (100)(b)
call dump2      (100)(c)
call dump2      (a)(100)
call dump2      (b)(100)
call dump2      (c)(100)
call dump2      ((100+200i))(a)
call dump2      ((100+200i))(b)
call dump2      ((100+200i))(c)
call dump2      (a)((100+200i))
call dump2      (b)((100+200i))
call dump2      (c)((100+200i))
call dump2      (a)(a)
call dump2      (b)(b)
call dump2      (c)(c)
call dump2      (a)(b)(c)

call dump2      1~upto(10) >= 5
call dump2      \ (1~upto(10) >= 5)


ts1day = .TimeSpan~fromDays(1)
ts1hour = .TimeSpan~fromHours(1)
ts1minute = .TimeSpan~fromMinutes(1)
ts1second = .TimeSpan~fromSeconds(1)
ts1microsecond = .TimeSpan~fromMicroseconds(1)
date = .datetime~new(2013,1,10, 12, 30, 10)

call dump2      .array~of(ts1microsecond, ts1second, ts1minute, ts1hour, ts1day) + date
call dump2      date + .array~of(ts1microsecond, ts1second, ts1minute, ts1hour, ts1day)


-----------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------

::routine dump2
    use arg coll, maxlevel, level=1, indent=""

    say indent"["coll~class~id":"
    s=coll~supplier
    do while s~available
        .output~charout(indent layout(s~index)~right(7)" : ")
        if s~item~isA(.Collection) then do
            if level >= maxlevel then say "..."
            else do
                say
                call dump2 s~item, maxlevel, level+1, "           "indent
            end
        end
        else say layout(s~item)
        s~next
    end
    say indent"]"


::routine layout
    use strict arg obj
    if obj~isA(.array), obj~dimension <= 1, obj~hasMethod("ppRepresentation") then return obj~ppRepresentation(100)
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
    say condition("O")~traceback~makearray~tostring
    evaluate_string = ""
    signal iterate


-----------------------------------------------------------------
::requires "extension/extensions.cls"
::requires "pipeline/pipe_extension.cls"
::requires "rgf_util2/rgf_util2_wrappers.rex"


/*

Examples of new display when self reference
old     (*n is the number of levels to cross to reach the self reference, only vertical)
---
new     (*v is the variable giving the self reference, can be vertical or horizontal)



// ok
['string1','string2',['string2',*1],*0]
---
a1=['string1','string2',['string2',*a1],*a1]


// ok
source:3,[v1='string2',['string1',v1,*1,*0]]
---
source:3,a1=[v1='string2',a2=['string1',*v1,*a1,*a2]]


// ok
source:4,['string1',v1='string2',[v1,*1],*0]
---
source:4,a1=['string1',v1='string2',[*v1,*a1],*a1]


// ok
source:1,v1='string1' | inject:1,v1
---
source:1,v1='string1' | inject:1,*v1


// ok
source:2,v1='string2' | inject:2,v1
---
source:2,v1='string2' | inject:2,*v1


// ok
source:3,[v1='string2',['string1',v1,*1,*0]] | inject:1,v1
---
source:3,a1=[v1='string2',a2=['string1',*v1,*a1,*a2]] | inject:1,*v1


// ok
// The structure of the list after inject looks different, but that's ok.
// It's because in new, we have directly a reference to the list *a2 which has a reference to *a1 which is a list with 2 elements, so similar to old [v1,*1]
source:3,[v1='string2',[v2='string1',v1,*1,*0]] | inject:2,[v2,v1,[v1,*1],*0]
---
source:3,a1=[v1='string2',a2=['string1',*v1,*a1,*a2]] | inject:2,*a2


// ok
source:4,[v1='string1',v2='string2',[v2,*1],*0] | inject:1,v1
---
source:4,a1=[v1='string1',v2='string2',[*v2,*a1],*a1] | inject:1,*v1


// ok
source:4,['string1',v1='string2',[v1,*1],*0] | inject:2,v1
---
source:4,a1=['string1',v1='string2',[*v1,*a1],*a1] | inject:2,*v1


// ok
source:4,[v1='string1',v2='string2',[v2,*1],*0] | inject:3,[v2,[v1,v2,*1,*0]]
---
source:4,a1=['string1',v1='string2',a2=[*v1,*a1],*a1] | inject:3,*a2


// ok
source:4,[v1='string1',v2='string2',[v2,*1],*0] | inject:4,[v1,v2,[v2,*1],*0]
---
source:4,a1=['string1',v1='string2',[*v1,*a1],*a1] | inject:4,*a1


// ok
['a',['b',['c',['d',*3]]]]
---
a1=['a',['b',['c',['d',*a1]]]]

*/