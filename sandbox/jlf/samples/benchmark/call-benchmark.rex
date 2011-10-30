/*
Repeat 10 times a piece of code which calls 10000 times a procedure / routine by name / .routine / class method / instance method
Why is a .routine call slower than a method call (undex WinXP - almost no difference under MacOsX)?

Under WinXP
    34 *-* count = 10
    35 *-* call run count, "p"     -- procedure
 0.0150  0.0000  0.0160  0.0000  0.0160  0.0160  0.0150  0.0160  0.0160  0.0000 mean= 0.0125
    36 *-* call run count, "rn"    -- routine by name
 0.2350  0.2500  0.2340  0.2340  0.2500  0.2500  0.2500  0.2350  0.2500  0.2340 mean= 0.2422    <-- SLOW when compared to a method call
    37 *-* call run count, "r"     -- routine
 0.2340  0.2500  0.2340  0.2500  0.2350  0.2340  0.2660  0.2340  0.2500  0.2500 mean= 0.2437    <-- SLOW when compared to a method call
    38 *-* call run count, "cm"    -- class method
 0.0160  0.0150  0.0160  0.0160  0.0000  0.0150  0.0160  0.0160  0.0150  0.0160 mean= 0.0141
    39 *-* call run count, "im"    -- instance method
 0.0150  0.0160  0.0160  0.0150  0.0160  0.0160  0.0000  0.0150  0.0160  0.0150 mean= 0.0140
 
Under MacOsX
    34 *-* count = 10
    35 *-* call run count, "p"     -- procedure
 0.0113  0.0139  0.0257  0.0064  0.0066  0.0104  0.0079  0.0058  0.0103  0.0063 mean= 0.0110
    36 *-* call run count, "rn"    -- routine by name
 0.0124  0.0083  0.0088  0.0139  0.0087  0.0084  0.0122  0.0088  0.0122  0.0083 mean= 0.0103    <-- not slow when compared to a method call
    37 *-* call run count, "r"     -- routine
 0.0084  0.0145  0.0090  0.0087  0.0122  0.0085  0.0120  0.0085  0.0084  0.0122 mean= 0.0104    <-- not slow when compared to a method call
    38 *-* call run count, "cm"    -- class method
 0.0072  0.0072  0.0108  0.0072  0.0130  0.0071  0.0073  0.0109  0.0072  0.0074 mean= 0.0087
    39 *-* call run count, "im"    -- instance method
 0.0115  0.0072  0.0109  0.0088  0.0077  0.0112  0.0073  0.0072  0.0114  0.0074 mean= 0.0092

*/

trace A
count = 10
call run count, "p"     -- procedure
call run count, "rn"    -- routine by name
call run count, "r"     -- routine
call run count, "cm"    -- class method
call run count, "im"    -- instance method

::routine run
    use strict arg count, test
    call time('r')
    if test == "p" then call runProcedureN count
    else if test == "rn" then call runRoutineByNameN count
    else if test == "r" then call runRoutineN count, .context~package~findRoutine("myRoutine") 
    else if test == "cm" then call runMethodN count, .myClass
    else if test == "im" then call runMethodN count, .myClass~new
    mean = time('e')/count
    say "mean="mean~format(2,4)
    return

::routine runProcedureN
    use strict arg count
    do count
        call time('r')
        do value=1 to 10000
            call myProcedure value
        end
        call charout ,time('e')~format(2,4)" "
    end
    return

myProcedure: procedure
    use strict arg value
    return

::routine runRoutineByNameN
    use strict arg count
    do count
        call time('r')
        do value=1 to 10000
            call myRoutine value
        end
        call charout ,time('e')~format(2,4)" "
    end
    return

::routine runRoutineN
    use strict arg count, routine
    do count
        call time('r')
        do value=1 to 10000
            routine~call(value)
        end
        call charout ,time('e')~format(2,4)" "
    end
    return

::routine runMethodN
    use strict arg count, object
    do count
        call time('r')
        do value=1 to 10000
            object~myMethod(value)
        end
        call charout ,time('e')~format(2,4)" "
    end
    return

::routine myRoutine
    use strict arg value
    return

::class myClass
::method myMethod class
    use strict arg value
    return
::method myMethod
    use strict arg value
    return

