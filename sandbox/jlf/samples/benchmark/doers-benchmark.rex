/*
trace A
count = 10
call run count, .context~package~findRoutine("emptyRoutine")
call run count, {/**/}
call run count, {::r}
call run count, .methods["EMPTYMETHOD"]
call run count, {::m}
-- Here, the coactivities are ended at first call, so very fast...
call run count, {::r.c}
-- for a coactive method, the self must be passed whith ~doer
call run count, {::m.c}~doer(.nil)

call run count, .context~package~findRoutine("myRoutine")
call run count, {if value // 1000 == 0 then call charout ,"."}
call run count, {::r if value // 1000 == 0 then call charout ,"."}
call run count, .methods["MYMETHOD"]
call run count, {::m if self // 1000 == 0 then call charout ,"."}
-- Current implementation of yield is very costly !
call run count, {::r.c do forever ; args = .yield[]; value = args[1] ; if value // 1000 == 0 then call charout ,"." ; end}
call run count, {::m.c do forever ; args = .yield[]; value = args[1] ; if value // 1000 == 0 then call charout ,"." ; end}~doer(.nil)
-- 4 times faster when using self~yield
call run count, .myCoactivity~new

trace O
*/
count = 200000

call time('r')
r = 0
do i=1 to count
    r += 2 * i
end
say r count "loops, no call :" time('e')~format(2,4)

call time('r')
r = 0
do i=1 to count
    r += double(i)
end
say r "routine double, called" count "times :" time('e')~format(2,4)

call time('r')
f = {return 2 * arg(1)}
r = 0
do i=1 to count
    r += f~(i)
end
say r "literal {return 2 * arg(1)} before loop, called" count "times :" time('e')~format(2,4)

-- With immediate parsing, there is no loss of performance when the literal is in the loop
call time('r')
r = 0
do i=1 to count
    r += {return 2 * arg(1)}~(i)
end
say r "literal {return 2 * arg(1)} in loop, called" count "times :" time('e')~format(2,4)

call time('r')
f = {:return 2 * arg(1)}
r = 0
do i=1 to count
    r += f~(i)
end
say r "literal {:return 2 * arg(1)} before loop, called" count "times :" time('e')~format(2,4)

-- With deferred parsing, there is a big loss of performance when the literal is in the loop
call time('r')
r = 0
do i=1 to count
    r += {:return 2 * arg(1)}~(i)
end
say r "literal {:return 2 * arg(1)} in loop, called" count "times :" time('e')~format(2,4)

call time('r')
f = {::m return 2 * self}
r = 0
do i=1 to count
    r += f~(i)
end
say r "literal {::m return 2 * self} before loop, called" count "times :" time('e')~format(2,4)

-- With deferred parsing, there is a big loss of performance when the literal is in the loop
call time('r')
r = 0
do i=1 to count
    r += {::m return 2 * self}~(i)
end
say r "literal {::m return 2 * self} in loop, called" count "times :" time('e')~format(2,4)

multiplier = 2

call time('r')
f = {::cl expose multiplier ; return multiplier * arg(1)}
r = 0
do i=1 to count
    r += f~(i)
end
say r "literal {::cl expose multiplier ; return multiplier * arg(1)} before loop, called" count "times :" time('e')~format(2,4)

-- With deferred parsing, there is a big loss of performance when the literal is in the loop
call time('r')
r = 0
do i=1 to count
    r += {::cl expose multiplier ; return multiplier * arg(1)}~(i)
end
say r "literal {::cl expose multiplier ; return multiplier * arg(1)} in loop, called" count "times :" time('e')~format(2,4)

say "Ended coactivities:" .Coactivity~endAll

::routine run
    use strict arg count, doer
    call time('r')
    call runN count, doer
    mean = time('e')/count
    say "mean="mean~format(2,4)

::routine runN
    use strict arg count, doer
    do count
        call time('r')
        10000~times(doer)
        call charout ,time('e')~format(2,4)" "
    end

::routine emptyRoutine

::routine double
    return 2 * arg(1)

::method emptyMethod

::routine myRoutine
    use strict arg value
    if value // 1000 == 0 then call charout ,"."

::method myMethod
    if self // 1000 == 0 then call charout ,"."

::class myCoactivity  inherit Coactivity
::method main -- entry point
    -- Here, self is the coactivity.
    do forever
        args = self~yield -- More efficient than .yield[], because no need to search for the current coactivity : it's self.
        value = args[1]
        if value // 1000 == 0 then call charout ,"."
    end

::options NOMACROSPACE
::requires "extension/extensions.cls"
