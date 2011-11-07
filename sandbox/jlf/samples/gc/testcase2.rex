/*
If you call this script without argument then
- a security manager is attached to the package
- a GC is triggered by creating 10000 objects

If you call this script by passing a whole number N as argument then
- no security manager is used
- N objects are created (should be big enough to trigger a GC)
*/

if arg() == 0 then .context~package~setSecurityManager(.securityManager~new)
use arg count=10000
call myRoutine count, 1
call myRoutine count, 2
say "*** interpreter is halting"

-------------------------------------------------------------------------------
::routine myRoutine
use arg count, step
say "*** entering myRoutine"

options "NOMACROSPACE"
-- This option is really, really, really useful !!! 
-- Calling SysQueryProcess in the loop triggers a socket connection with rxapi at each iteration (without this option)
--                          with option     without option
--  10_000 iterations :     0.532           4.829
-- 100_000 iterations :     2.172           44.470 

v=.myClass~new(step".1")
v=.WeakReference~new(.myClass~new(step".2 weak"))
d = .Directory~new
d[step".3"] = .myClass~new(step".3")
d[step".4"] = .WeakReference~new(.myClass~new(step".4 weak"))
say "*** ----- Creating up to" count "objects -----"
do i = 1 to count
    .object~new

    if step == 1 then do
        -- The uninit methods are not called inside this loop when using only predefined functions/methods.
        p=.context~package
        a=.array~new(100)
        r=random()
        pid=SysQueryProcess("PID")
    end
    
    if step == 2 then do
        -- The unit methods are called during the loop (if GC) when using user-defined procedures/routines/methods
        call myProc
        call myRoutine2
        .myClass~m1
    end
end
say "*** ----- End of objects creation -----"
say "*** leaving myRoutine"

myProc:
return


-------------------------------------------------------------------------------
::routine myRoutine2
return

-------------------------------------------------------------------------------
::class myClass

::method m1 class
return

::method init
expose tag
use arg tag
say "*** init" tag

::method uninit
expose tag
say "*** uninit" tag

-------------------------------------------------------------------------------
::class securityManager
::method unknown
return 0

