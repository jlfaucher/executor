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
