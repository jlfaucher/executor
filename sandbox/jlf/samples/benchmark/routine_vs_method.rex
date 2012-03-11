-- Windows only : 
-- A routine call is on average 15 times slower than a method call.

count1 = 5
count2 = 100000

durations = .array~new

call charout , "routine call : "
do c1=1 to count1
    call time('r')
    do c2=1 to count2
        call myroutine
    end
    duration = time('e')
    durations[1, c1] = duration
    call charout , duration~format(2,4)
    call charout ," "
end
say

myclass = .myclass
call charout , "method call :  "
do c1=1 to count1
    call time('r')
    do c2=1 to count2
        myclass~mymethod
    end
    duration = time('e')
    durations[2, c1] = duration
    call charout , duration~format(2,4)
    call charout ," "
end
say

call charout , "ratio :        "
do c1=1 to count1
    ratio = durations[1,c1] / durations[2, c1]
    call charout , ratio~format(2,4)
    call charout , " "
end
say

::routine myroutine


::class myclass
::method mymethod class

