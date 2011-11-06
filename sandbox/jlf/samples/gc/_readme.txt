testcase1.rex :
To test the impact of a security manager.
See the comments a the begining of the file for the usage.
The output files have been generated after activation of the VERBOSE_GC
See trunk/interpreter/memory/RexxMemory.hpp
See internals/notes/uninit.txt.txt.
New verbose messages have been added to trace the calls to uninit.
See verbose_uninit.patch


testcase1.output.default.txt
With a security manager, two calls to myRoutine which creates 10_000 objects at each call.
There is a GC at each call, during the loop.
Step 1 : 4 objects created, 3 uninit called.
         The object 1.1 has been GC'ed since no longer referenced by v (ok).
         The weak references 1.2 and 1.4 have been GC'ed, despite the directory which still exists (ok).
         The object not yet GC'ed is 1.3, which is the not weak reference stored in the directory.
         Since the directory itself can't be GC'ed during the loop, this is ok.
Step 2 : 4 objects created, 4 uninit called.
         The object 1.3 created during step 1 has been GC'ed, since the referencing directory 
         created during step 1 no longer exists in step 2.
         For the other objects, it's like step 1. Only 2.3 is not GC'd during the loop.
Halting: The object 2.3 is GC'ed since the referencing directory no longer exists (ok).


testcase1.output.default.vv.zip
Same as previous, but very verbose (vv)
I keep it for the records, to remember how often checkUninitQueue is called from RexxActivation::run.
But I no longer generate such verbose traces.


testcase1.output.10_000.txt
No security manager, two calls to myRoutine which creates 10_000 objects at each call.
Step 1 : no GC
Step 2 : no GC
Halting: the first GC happens here. And so the uninits (ok).


testcase1.output.100_000.txt
No security manager, two calls to myRoutine which creates 100_000 objects at each call.
Step 1 : no GC
Step 2 : there is a GC during the loop, but NO uninit...
         the uninits are triggered AFTER the loop. Why ?
         all the objects of step 1 and step 2 are GC'ed, except 2.3 (ok)
Halting: The object 2.3 is GC'ed since the referencing directory no longer exists (ok).



testcase1.output.1000_000.txt
No security manager, two calls to myRoutine which creates 1_000_000 objects at each call.
Step 1 : 6 GC during the loop, but NO uninits.
         the uninits are triggered AFTER the loop.
         Notice the value of pendingUninits=18 (6 GC * 3 zombies). Is it a problem to have 18 instead of 3 ?
Step 2 : 7 GC during the loop, but NO uninits.
         the uninits are triggered AFTER the loop.
         pendingUninits=28 (7 GC * 4 zombies)
Halting: The object 2.3 is GC'ed since the referencing directory no longer exists (ok).
