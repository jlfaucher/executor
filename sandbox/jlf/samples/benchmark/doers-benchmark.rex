trace A

count = 10
call run count, .context~package~findRoutine("emptyRoutine")
call run count, {/**/}
call run count, {::r}
call run count, .methods["EMPTYMETHOD"]
-- Here, the coactivities are ended at first call, so very fast...
call run count, {::co}

call run count, .context~package~findRoutine("myRoutine")
call run count, {if item // 1000 == 0 then call charout ,"."}
call run count, {::r if item // 1000 == 0 then call charout ,"."}
call run count, .methods["MYMETHOD"]
-- Current implementation of yield is very costly !  (JLF 2012 mar 23 : with .threadLocal, no longer costly...)
call run count, {::co do forever ; .yield[]; item = arg(1) ; if item // 1000 == 0 then call charout ,"." ; end}
-- 4 times faster when using self~yield (JLF 2012 mar 23 : no longer 4 times faster, because .yield[] now uses .threadLocal...)
call run count, .myCoactivity~new

trace O
--===========================================================================--

count = 200000

call time('r')
r = 0
do i=1 to count
    r += 2 * i
end
say r count "loops, no call :" time('e')~format(2,4)

-------------------------------------------------------------------------------

call time('r')
r = 0
do i=1 to count
    r += double(i)
end
say r "routine double, called" count "times :" time('e')~format(2,4)

-------------------------------------------------------------------------------

call time('r')
f = {return 2 * arg(1)}~doer
r = 0
do i=1 to count
    r += f~do(i)
end
say r "literal {return 2 * arg(1)}~doer before loop, called with ~do" count "times :" time('e')~format(2,4)

call time('r')
f = {return 2 * arg(1)}
r = 0
do i=1 to count
    r += f~do(i)
end
say r "literal {return 2 * arg(1)} before loop, called with ~do" count "times :" time('e')~format(2,4)

call time('r')
f = {return 2 * arg(1)}
r = 0
do i=1 to count
    r += f~(i)
end
say r "literal {return 2 * arg(1)} before loop, called with ~()" count "times :" time('e')~format(2,4)

-------------------------------------------------------------------------------

call time('r')
r = 0
do i=1 to count
    r += {return 2 * arg(1)}~do(i)
end
say r "literal {return 2 * arg(1)} in loop, called with ~do" count "times :" time('e')~format(2,4)

call time('r')
r = 0
do i=1 to count
    r += {return 2 * arg(1)}~(i)
end
say r "literal {return 2 * arg(1)} in loop, called with ~()" count "times :" time('e')~format(2,4)

-------------------------------------------------------------------------------

multiplier = 2

call time('r')
f = {expose multiplier ; return multiplier * arg(1)}
r = 0
do i=1 to count
    r += f~do(i)
end
say r "literal {expose multiplier ; return multiplier * arg(1)} before loop, called with ~do" count "times :" time('e')~format(2,4)

call time('r')
f = {expose multiplier ; return multiplier * arg(1)}
r = 0
do i=1 to count
    r += f~(i)
end
say r "literal {expose multiplier ; return multiplier * arg(1)} before loop, called with ~()" count "times :" time('e')~format(2,4)

call time('r')
r = 0
do i=1 to count
    r += {expose multiplier ; return multiplier * arg(1)}~do(i)
end
say r "literal {expose multiplier ; return multiplier * arg(1)} in loop, called with ~do" count "times :" time('e')~format(2,4)

call time('r')
r = 0
do i=1 to count
    r += {expose multiplier ; return multiplier * arg(1)}~(i)
end
say r "literal {expose multiplier ; return multiplier * arg(1)} in loop, called with ~()" count "times :" time('e')~format(2,4)

say "Ended coactivities:" .Coactivity~endAll

-------------------------------------------------------------------------------

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
    use strict arg item
    if item // 1000 == 0 then call charout ,"."

::method myMethod
    if self // 1000 == 0 then call charout ,"."

::class myCoactivity  inherit Coactivity
::method main -- entry point
    -- Here, self is the coactivity.
    do forever
        self~yield -- More efficient than .yield[], because no need to search for the current coactivity : it's self.
        item = arg(1)
        if item // 1000 == 0 then call charout ,"."
    end

::options NOMACROSPACE
::requires "extension/extensions.cls"
