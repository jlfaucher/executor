/*
An example of deadlock, and how to avoid it.

The method "init" is guarded and calls "m1" which is also guarded.
So the lock counter is 2 when entering "m1" ("init" + "m1").
The 'guard off' in T2:A3 from "m1" releases the lock for T2:A3, but the counter is still 1, so the dictionary V1 is still locked (by T1:A2 from "init").
When the 'guard on when' is executed, T2:A3 requires a temporary exclusive access to V1, but V1 is already locked.
So the counter becomes 2, and T2:A3 is blocked.
There is a deadlock because "m2" can't be entered to wake-up m1 : m2 is guarded, so need to acquire a lock on V1.

Problem about this trace in case of deadlock : 
At the end, an information is missing because we don't see that "m2" is blocked because of V1.
We should see something like that :
T1   A4     V1      2*        >I> Method M2
That would help for the diagnostic, because you can find which other activity is in competition.
Just search for the previous occurence of the variable dictionary V1, locked by an activity other than T1 :
T2   A3     V1      2*        >I> Method M1

[Previous problem is fixed : see RexxActivation::run]
I see counter=1 instead of 2* because the trace is made before acquiring the lock.
But that's enough to make a good diagnostic.
T1   A4     V1      1         >I> Method M2
*/

c1 = .c~new
call syssleep 0.5
c1~m2 -- wake-up m1
say "done"

::class C
::method init
    expose s
    s = 0
    reply
    guard off -- if I remove this line, then I get a deadlock
    self~m1

::method m1
    expose s
    s = 1
    guard off
    say "before guard" -- here, no lock
    guard on when s <> 1 -- but here, is locked while waiting...
    say "after guard"

::method m2
    expose s
    s = 2

--::options trace i


/***************************************************************
Trace output in case of deadlock
****************************************************************
T1   A1                    21 *-* c1 = .c~new
T1   A1                       >E>   .C => "The C class"
T1   A2     V1                >I> Method INIT with scope "The C class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\deadlock1.rex
T1   A2     V1      1*     28 *-* expose s
T1   A2     V1      1*     29 *-* s = 0
T1   A2     V1      1*        >L>   "0"
T1   A2     V1      1*        >>>   "0"
T1   A2     V1      1*        >=>   S <= "0"
T1   A2     V1      1*     30 *-* reply
T2   A2     V1      1*        >I> Method INIT with scope "The C class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\deadlock1.rex
T1   A1                       >M>   "NEW" => "a C"
T2   A2     V1      1*     32 *-* self~m1
T1   A1                       >>>   "a C"
T2   A2     V1      1*        >V>   SELF => "a C"
T1   A1                       >=>   C1 <= "a C"
T2   A3     V1      1         >I> Method M1 with scope "The C class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\deadlock1.rex
T1   A1                    22 *-* call syssleep 0.5
T2   A3     V1      2*     35 *-* expose s
T1   A1                       >L>   "0.5"
T2   A3     V1      2*     36 *-* s = 1
T1   A1                       >A>   "0.5"
T2   A3     V1      2*        >L>   "1"
T2   A3     V1      2*        >>>   "1"
T2   A3     V1      2*        >=>   S <= "1"
T2   A3     V1      2*     37 *-* guard off
T2   A3     V1      1      38 *-* say "before guard" -- here, no lock
T2   A3     V1      1         >L>   "before guard"
T2   A3     V1      1         >>>   "before guard"
before guard
T2   A3     V1      1      39 *-* guard on when s <> 1 -- but here, is locked while waiting...
T2   A3     V1      2*        >V>   S => "1"
T2   A3     V1      2*        >L>   "1"
T2   A3     V1      2*        >O>   "<>" => "0"
T2   A3     V1      2*        >>>   "0"
T1   A1                       >>>   "0"
T1   A1                    23 *-* c1~m2 -- wake-up m1
T1   A1                       >V>   C1 => "a C"
T1   A4     V1      1         >I> Method M2 with scope "The C class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\deadlock1.rex
*/


/***************************************************************
Trace output when no deadlock
****************************************************************
T1   A1                    25 *-* c1 = .c~new
T1   A1                       >E>   .C => "The C class"
T1   A2     V1                >I> Method INIT with scope "The C class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\deadlock1.rex
T1   A2     V1      1*     32 *-* expose s
T1   A2     V1      1*     33 *-* s = 0
T1   A2     V1      1*        >L>   "0"
T1   A2     V1      1*        >>>   "0"
T1   A2     V1      1*        >=>   S <= "0"
T1   A2     V1      1*     34 *-* reply
T2   A2     V1      1*        >I> Method INIT with scope "The C class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\deadlock1.rex
T1   A1                       >M>   "NEW" => "a C"
T2   A2     V1      1*     35 *-* guard off -- if I remove this line, then I get a deadlock
T1   A1                       >>>   "a C"
T2   A2     V1             36 *-* self~m1
T1   A1                       >=>   C1 <= "a C"
T2   A2     V1                >V>   SELF => "a C"
T1   A1                    26 *-* call syssleep 0.5
T2   A3     V1                >I> Method M1 with scope "The C class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\deadlock1.rex
T1   A1                       >L>   "0.5"
T2   A3     V1      1*     39 *-* expose s
T1   A1                       >A>   "0.5"
T2   A3     V1      1*     40 *-* s = 1
T2   A3     V1      1*        >L>   "1"
T2   A3     V1      1*        >>>   "1"
T2   A3     V1      1*        >=>   S <= "1"
T2   A3     V1      1*     41 *-* guard off
T2   A3     V1             42 *-* say "before guard" -- here, no lock
T2   A3     V1                >L>   "before guard"
T2   A3     V1                >>>   "before guard"
before guard
T2   A3     V1             43 *-* guard on when s <> 1 -- but here, is locked while waiting...
T2   A3     V1      1*        >V>   S => "1"
T2   A3     V1      1*        >L>   "1"
T2   A3     V1      1*        >O>   "<>" => "0"
T2   A3     V1      1*        >>>   "0"
T1   A1                       >>>   "0"
T1   A1                    27 *-* c1~m2 -- wake-up m1
T1   A1                       >V>   C1 => "a C"
T1   A4     V1                >I> Method M2 with scope "The C class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\deadlock1.rex
T1   A4     V1      1*     47 *-* expose s
T1   A4     V1      1*     48 *-* s = 2
T1   A4     V1      1*        >L>   "2"
T1   A4     V1      1*        >>>   "2"
T1   A4     V1      1*        >=>   S <= "2"
T1   A1                    28 *-* say "done"
T2   A3     V1      1*        >V>   S => "2"
T1   A1                       >L>   "done"
T2   A3     V1      1*        >L>   "1"
T1   A1                       >>>   "done"
done
T2   A3     V1      1*        >O>   "<>" => "1"
T2   A3     V1      1*        >>>   "1"
T2   A3     V1      1*     44 *-* say "after guard"
T2   A3     V1      1*        >L>   "after guard"
T2   A3     V1      1*        >>>   "after guard"
after guard
*/

