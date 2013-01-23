/*
How long does it take to read/write a variable.
Note : the use of .activity~local is now deprecated. Use .threadLocal instead. 
*/

count1 = 5
count2 = 100000

say "var = 1"
do c1=1 to count1
    call time('r')
    do c2=1 to count2
        var = 1
    end
    call charout , time('e')~format(2,4)" "
end
say

say ".threadLocal['my.var'] = 1"
do c1=1 to count1
    call time('r')
    do c2=1 to count2
        .threadLocal['my.var'] = 1
    end
    call charout , time('e')~format(2,4)" "
end
say

say ".local['my.var1'] = 1"
do c1=1 to count1
    call time('r')
    do c2=1 to count2
        .local['my.var1'] = 1
    end
    call charout , time('e')~format(2,4)" "
end
say

say ".environment['my.var2'] = 1"
do c1=1 to count1
    call time('r')
    do c2=1 to count2
        .environment['my.var2'] = 1
    end
    call charout , time('e')~format(2,4)" "
end
say

say "threadId = .activity~currentThreadId"
do c1=1 to count1
    call time('r')
    do c2=1 to count2
        threadId = .activity~currentThreadId
    end
    call charout , time('e')~format(2,4)" "
end
say

say ".activity~local['var'] = 1"
do c1=1 to count1
    call time('r')
    do c2=1 to count2
        .activity~local['var'] = 1
    end
    call charout , time('e')~format(2,4)" "
end
say

say "v = var"
do c1=1 to count1
    call time('r')
    do c2=1 to count2
        v = var
    end
    call charout , time('e')~format(2,4)" "
end
say

say "v = .context"
do c1=1 to count1
    call time('r')
    do c2=1 to count2
        v = .context
    end
    call charout , time('e')~format(2,4)" "
end
say

say "v = .threadLocal['my.var']"
do c1=1 to count1
    call time('r')
    do c2=1 to count2
        v = .threadLocal['my.var']
    end
    call charout , time('e')~format(2,4)" "
end
say

say "v = .var1"
do c1=1 to count1
    call time('r')
    do c2=1 to count2
        v = .var1
    end
    call charout , time('e')~format(2,4)" "
end
say

say "v = .var2"
do c1=1 to count1
    call time('r')
    do c2=1 to count2
        v = .var2
    end
    call charout , time('e')~format(2,4)" "
end
say

say "v = .activity~local['var']"
do c1=1 to count1
    call time('r')
    do c2=1 to count2
        v = .activity~local['var']
    end
    call charout , time('e')~format(2,4)" "
end
say

::requires "concurrency/activity.cls"
