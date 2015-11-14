/*
How long does it take to read/write a variable.
Note : the use of .activity~local is now deprecated. Use .threadLocal instead.

.activity~local: Standard ooRexx is at least 10x slower than executor.
The option "nomacrospace" has a real impact.

ooRexx 4.2 & 5.0 (MacOs)
------------------------
.activity~local['var'] = 1      6.6917  6.5218  6.5477  6.7243  6.6169
v = .activity~local['var']      6.2027  6.7891  6.2076  6.6844  6.5391

executor (MacOs)
----------------
.activity~local['var'] = 1      0.6428  0.6378  0.6523  0.6126  0.6321
v = .activity~local['var']      0.6832  0.6040  0.6094  0.6212  0.6133

.threadLocal is 15x faster than .activity~local.
.threadLocal is 150x faster than .activity~local in standard ooRexx.

.threadLocal['my.var'] = 1      0.0435  0.0417  0.0461  0.0375  0.0364
v = .threadLocal['my.var']      0.0414  0.0377  0.0376  0.0427  0.0348

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

if .threadLocal~isA(.Directory) then do
    say ".threadLocal['my.var'] = 1"
    do c1=1 to count1
        call time('r')
        do c2=1 to count2
            .threadLocal['my.var'] = 1
        end
        call charout , time('e')~format(2,4)" "
    end
    say
end

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

if .threadLocal~isA(.Directory) then do
    say "v = .threadLocal['my.var']"
    do c1=1 to count1
        call time('r')
        do c2=1 to count2
            v = .threadLocal['my.var']
        end
        call charout , time('e')~format(2,4)" "
    end
    say
end

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
