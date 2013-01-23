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
v=.myClass~new(step".1")
v=.WeakReference~new(.myClass~new(step".2 weak"))
d = .Directory~new
d[step".3"] = .myClass~new(step".3")
d[step".4"] = .WeakReference~new(.myClass~new(step".4 weak"))
say "*** ----- Creating up to" count "objects -----"
do i = 1 to count
    .object~new
end
say "*** ----- End of objects creation -----"
say "*** leaving myRoutine"

-------------------------------------------------------------------------------
::class myClass

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

