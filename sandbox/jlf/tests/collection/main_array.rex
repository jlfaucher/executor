prompt off address directory
demo on

.context~package~loadPackage("collection_helpers.cls")


-- --------------------------------------------------------------
-- Array initializers
-- --------------------------------------------------------------

-- If there is only one argument, and this argument has the method ~supplier then each item returned by the argument's supplier is an item.
call dump_collection      .array~new(2,3)~of(1~upto(6))
-- 1 2 3
-- 4 5 6

-- If there is only one argument, and this argument is a doer, then the doer is called for each cell to initialize.
call dump_collection      .array~new(2,3)~of{10*item}
-- 10 20 30
-- 40 50 60

-- Otherwise, when more than one argument, each argument is an item as-is.
call dump_collection      .array~new(2,3)~of(1,2,3,4,5,6)
-- 1 2 3
-- 4 5 6

-- If some arguments are omitted, then the corresponding item in the initialized arrat remains non-assigned.
call dump_collection      .array~new(2,3)~of(1,,3,,5,6)
-- 1 . 3
-- . 5 6

-- For me, there is a problem (bug ?) when the last arguments are explicitely omitted : they are not counted by the interpreter !
-- I passed explicitely 6 arguments, 3 of them being omitted.
-- 19/09/2017 Fixed in Executor
call dump_collection      .array~new(2,3)~of(1,,3,,5,)
-- 1 . 3
-- . 5 .
-- Before the fix, the last omitted argument was ignored and the result was :
-- 1 . 3
-- . 5 1

-- Rules inspired by APL :
-- If there are too many items, the extra items are ignored.
-- If there are fewer items than implied by the dimensions, the list of items is reused as many times as necessary to fill the array.
call dump_collection      .array~new(2,3)~of(1,2)
-- 1 2 1
-- 2 1 2

-- Test case that demonstrated a bug (a new generator was created when initializing the second array)
g={::coactivity loop i=0; if i//2 == 0 then .yield[i]; else .yield[]; end}
call dump_collection      .array~new(2,3)~of(g)
-- 0 . 2
-- . 4 .
call dump_collection      .array~new(2,3)~of(g)
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
call dump_collection      a, 3

say a~ppRepresentation

a~pipe(.console "dataflow")

a~pipe(.inject "iterateBefore" {item} "recursive.0.memorize" | .console "dataflow")

d = .array~of("d")
c = .array~of("c", d)
b = .array~of("b", c)
a = .array~of("a", b)
d~append(a)
-- display the first five levels
call dump_collection      a, 5

say a~ppRepresentation

-- --------------------------------------------------------------
-- Array operators
-- --------------------------------------------------------------

a = .array~of(10, 20, 30)
b = .array~of(5, a, 5+6i)
c = .array~of(15+16i, b, 15)

call dump_collection      -a
call dump_collection      -b
call dump_collection      -c

call dump_collection      100 + a
call dump_collection      100 + b
call dump_collection      100 + c
call dump_collection      a + 100
call dump_collection      b + 100
call dump_collection      c + 100
call dump_collection      (100+200i) + a
call dump_collection      (100+200i) + b
call dump_collection      (100+200i) + c
call dump_collection      a + (100+200i)
call dump_collection      b + (100+200i)
call dump_collection      c + (100+200i)
call dump_collection      a + a
call dump_collection      b + b
call dump_collection      c + c
call dump_collection      a + b + c

call dump_collection      100 - a
call dump_collection      100 - b
call dump_collection      100 - c
call dump_collection      a - 100
call dump_collection      b - 100
call dump_collection      c - 100
call dump_collection      (100+200i) - a
call dump_collection      (100+200i) - b
call dump_collection      (100+200i) - c
call dump_collection      a - (100+200i)
call dump_collection      b - (100+200i)
call dump_collection      c - (100+200i)
call dump_collection      a - a
call dump_collection      b - b
call dump_collection      c - c
call dump_collection      a - b - c

call dump_collection      100 * a
call dump_collection      100 * b
call dump_collection      100 * c
call dump_collection      a * 100
call dump_collection      b * 100
call dump_collection      c * 100
call dump_collection      (100+200i) * a
call dump_collection      (100+200i) * b
call dump_collection      (100+200i) * c
call dump_collection      a * (100+200i)
call dump_collection      b * (100+200i)
call dump_collection      c * (100+200i)
call dump_collection      a * a
call dump_collection      b * b
call dump_collection      c * c
call dump_collection      a * b * c

call dump_collection      100 / a
call dump_collection      100 / b
call dump_collection      100 / c
call dump_collection      a / 100
call dump_collection      b / 100
call dump_collection      c / 100
call dump_collection      (100+200i) / a
call dump_collection      (100+200i) / b
call dump_collection      (100+200i) / c
call dump_collection      a / (100+200i)
call dump_collection      b / (100+200i)
call dump_collection      c / (100+200i)
call dump_collection      a / a
call dump_collection      b / b
call dump_collection      c / c
call dump_collection      a / b / c

call dump_collection      100 % a
call dump_collection      100 % b
call dump_collection      100 % c
call dump_collection      a % 100
call dump_collection      b % 100
call dump_collection      c % 100
call dump_collection      (100+200i) % a
call dump_collection      (100+200i) % b
call dump_collection      (100+200i) % c
call dump_collection      a % (100+200i)
call dump_collection      b % (100+200i)
call dump_collection      c % (100+200i)
call dump_collection      a % a
call dump_collection      b % b
call dump_collection      c % c
call dump_collection      a % b % c

call dump_collection      100 // a
call dump_collection      100 // b
call dump_collection      100 // c
call dump_collection      a // 100
call dump_collection      b // 100
call dump_collection      c // 100
call dump_collection      (100+200i) // a
call dump_collection      (100+200i) // b
call dump_collection      (100+200i) // c
call dump_collection      a // (100+200i)
call dump_collection      b // (100+200i)
call dump_collection      c // (100+200i)
call dump_collection      a // a
call dump_collection      b // b
call dump_collection      c // c
call dump_collection      a // b // c

call dump_collection      100 ** a
--call dump_collection      100 ** b                  -- Operand to the right of the power operator (**) must be a whole number; found "a COMPLEX"
--call dump_collection      100 ** c                  -- Operand to the right of the power operator (**) must be a whole number; found "a COMPLEX"
call dump_collection      a ** 100
--call dump_collection      b ** 100                  -- Object "a COMPLEX" does not understand message "**"
--call dump_collection      c ** 100                  -- Object "a COMPLEX" does not understand message "**"
--call dump_collection      (100+200i) ** a    -- Object "a COMPLEX" does not understand message "**"
--call dump_collection      (100+200i) ** b    -- Object "a COMPLEX" does not understand message "**"
--call dump_collection      (100+200i) ** c    -- Object "a COMPLEX" does not understand message "**"
--call dump_collection      a ** (100+200i)    -- Operand to the right of the power operator (**) must be a whole number; found "a COMPLEX"
--call dump_collection      b ** (100+200i)    -- Operand to the right of the power operator (**) must be a whole number; found "a COMPLEX"
--call dump_collection      c ** (100+200i)    -- Object "a COMPLEX" does not understand message "**"
call dump_collection      a ** a
--call dump_collection      b ** b                    -- Object "a COMPLEX" does not understand message "**"
--call dump_collection      c ** c                    -- Object "a COMPLEX" does not understand message "**"
--call dump_collection      a ** b ** c               -- Operand to the right of the power operator (**) must be a whole number; found "a COMPLEX"

call dump_collection      100 a
call dump_collection      100 b
call dump_collection      100 c
call dump_collection      a 100
call dump_collection      b 100
call dump_collection      c 100
call dump_collection      (100+200i) a
call dump_collection      (100+200i) b
call dump_collection      (100+200i) c
call dump_collection      a (100+200i)
call dump_collection      b (100+200i)
call dump_collection      c (100+200i)
call dump_collection      a a
call dump_collection      b b
call dump_collection      c c
call dump_collection      a b c

call dump_collection      100 || a
call dump_collection      100 || b
call dump_collection      100 || c
call dump_collection      a || 100
call dump_collection      b || 100
call dump_collection      c || 100
call dump_collection      (100+200i) || a
call dump_collection      (100+200i) || b
call dump_collection      (100+200i) || c
call dump_collection      a || (100+200i)
call dump_collection      b || (100+200i)
call dump_collection      c || (100+200i)
call dump_collection      a || a
call dump_collection      b || b
call dump_collection      c || c
call dump_collection      a || b || c

call dump_collection      (100)(a)
call dump_collection      (100)(b)
call dump_collection      (100)(c)
call dump_collection      (a)(100)
call dump_collection      (b)(100)
call dump_collection      (c)(100)
call dump_collection      ((100+200i))(a)
call dump_collection      ((100+200i))(b)
call dump_collection      ((100+200i))(c)
call dump_collection      (a)((100+200i))
call dump_collection      (b)((100+200i))
call dump_collection      (c)((100+200i))
call dump_collection      (a)(a)
call dump_collection      (b)(b)
call dump_collection      (c)(c)
call dump_collection      (a)(b)(c)

call dump_collection      1~upto(10) >= 5
call dump_collection      \ (1~upto(10) >= 5)


ts1day = .TimeSpan~fromDays(1)
ts1hour = .TimeSpan~fromHours(1)
ts1minute = .TimeSpan~fromMinutes(1)
ts1second = .TimeSpan~fromSeconds(1)
ts1microsecond = .TimeSpan~fromMicroseconds(1)
date = .datetime~new(2013,1,10, 12, 30, 10)

call dump_collection      .array~of(ts1microsecond, ts1second, ts1minute, ts1hour, ts1day) + date
call dump_collection      date + .array~of(ts1microsecond, ts1second, ts1minute, ts1hour, ts1day)
