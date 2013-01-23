/*
An example of deadlock, and how to avoid it.

Here the problem comes from .coactivity~yield at the class level.
If this method is guarded, then there is a deadlock because endAll can't be entered.

Problem about this trace in case of deadlock : 
At the end, an information is missing because we don't see that "endAll" is blocked because of V1.
We should see something like that :
T1   A9     V1      1*        >I> Method ENDALL
That would help for the diagnostic, because you can find which other activity is in competition.
Just search for the previous occurence of the variable dictionary V1, locked by an activity other than T1 :
T2   A7     V1      1*        >I> Method YIELD

[Previous problem is fixed : see RexxActivation::run]
I see counter=1 instead of 1* because the trace is made before acquiring the lock.
But that's enough to make a good diagnostic.
T1   A9     V1      1         >I> Method ENDALL
*/

--call Doers.AddVisibilityFrom(.context)
c = .coactivity~new({.coactivity~yield(1) ; return 2})
say c
say c~resume
--say c~resume -- If we don't resume to get the 2nd value, then we can have a deadlock
say "Ended coactivities:" .Coactivity~endAll

::requires "extension/extensions.cls"
::requires "concurrency/coactivity.cls"
--::options trace i


/***************************************************************
Trace output in case of deadlock
****************************************************************
T1   A1     V1                >I> Method INIT with scope "The Coactivity class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A1     V1      1*     53 *-* self~table = .IdentityTable~new
T1   A1     V1      1*        >V>   SELF => "The Coactivity class"
T1   A1     V1      1*        >E>   .IDENTITYTABLE => "The IdentityTable class"
T1   A1     V1      1*        >M>   "NEW" => "an IdentityTable"
T1   A1     V1      1*        >A>   "an IdentityTable"
T1   A1     V1      1*        >>>   "an IdentityTable"
T1   A1     V1      1*     54 *-* self~makeArrayLimit = 10000 -- not a constant, I think it's useful to let the end user change this value
T1   A1     V1      1*        >V>   SELF => "The Coactivity class"
T1   A1     V1      1*        >L>   "10000"
T1   A1     V1      1*        >A>   "10000"
T1   A1     V1      1*        >>>   "10000"
T1   A2                       >I> Routine D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A3                    21 *-* call Doers.AddVisibilityFrom(.context)
T1   A3                       >E>   .CONTEXT => "a RexxContext"
T1   A3                       >A>   "a RexxContext"
T1   A3                    22 *-* c = .coactivity~new(".coactivity~yield(1) ; return 2")
T1   A3                       >E>   .COACTIVITY => "The Coactivity class"
T1   A3                       >L>   ".coactivity~yield(1) ; return 2"
T1   A3                       >A>   ".coactivity~yield(1) ; return 2"
T1   A4                       >I> Method INIT with scope "The Coactivity class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A4                    83 *-* use strict arg action="main", start=.true, context=.nil, self~object=(self)
T1   A4                       >>>   ".coactivity~yield(1) ; return 2"
T1   A4                       >=>   ACTION <= ".coactivity~yield(1) ; return 2"
T1   A4                       >E>   .TRUE => "1"
T1   A4                       >>>   "1"
T1   A4                       >=>   START <= "1"
T1   A4                       >E>   .NIL => "The NIL object"
T1   A4                       >>>   "The NIL object"
T1   A4                       >=>   CONTEXT <= "The NIL object"
T1   A4                       >V>   SELF => "a Coactivity"
T1   A4                       >>>   "a Coactivity"
T1   A4                       >V>   SELF => "a Coactivity"
T1   A4                    85 *-* self~doer = action~doer(context)
T1   A4                       >V>   SELF => "a Coactivity"
T1   A4                       >V>   ACTION => ".coactivity~yield(1) ; return 2"
T1   A4                       >V>   CONTEXT => "The NIL object"
T1   A4                       >A>   "The NIL object"
T1   A4                       >M>   "DOER" => "a Routine"
T1   A4                       >A>   "a Routine"
T1   A4                       >>>   "a Routine"
T1   A4                    86 *-* self~status = .Coactivity~notStarted
T1   A4                       >V>   SELF => "a Coactivity"
T1   A4                       >E>   .COACTIVITY => "The Coactivity class"
T1   A4                       >M>   "NOTSTARTED" => "0"
T1   A4                       >A>   "0"
T1   A4                       >>>   "0"
T1   A4                    87 *-* if start 
T1   A4                       >V>   START => "1"
T1   A4                       >>>   "1"
T1   A4                    87 *-*   then
T1   A4                    87 *-*     self~start
T1   A4                       >V>       SELF => "a Coactivity"
T1   A5     V2                >I> Method START with scope "The Coactivity class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A5     V2      1*     97 *-* expose status
T1   A5     V2      1*     98 *-* use strict arg -- no arg
T1   A5     V2      1*     99 *-* if status <> .Coactivity~notStarted 
T1   A5     V2      1*        >V>   STATUS => "0"
T1   A5     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A5     V2      1*        >M>   "NOTSTARTED" => "0"
T1   A5     V2      1*        >O>   "<>" => "0"
T1   A5     V2      1*        >>>   "0"
T1   A5     V2      1*    100 *-* status = .Coactivity~suspended
T1   A5     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A5     V2      1*        >M>   "SUSPENDED" => "1"
T1   A5     V2      1*        >>>   "1"
T1   A5     V2      1*        >=>   STATUS <= "1"
T1   A5     V2      1*    101 *-* reply self
T1   A5     V2      1*        >V>   SELF => "a Coactivity"
T1   A5     V2      1*        >>>   "a Coactivity"
T2   A5     V2      1*        >I> Method START with scope "The Coactivity class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A4                       >>>       "a Coactivity"
T2   A5     V2      1*    102 *-* .Activity~local~empty
T1   A3                       >M>   "NEW" => "a Coactivity"
T2   A5     V2      1*        >E>   .ACTIVITY => "The ACTIVITY class"
T1   A3                       >>>   "a Coactivity"
T1   A3                       >=>   C <= "a Coactivity"
T2   A5     V2      1*        >M>   "LOCAL" => "a Directory"
T1   A3                    23 *-* say c
T2   A5     V2      1*    103 *-* .Activity~local~coactivity = self
T1   A3                       >V>   C => "a Coactivity"
T2   A5     V2      1*        >E>   .ACTIVITY => "The ACTIVITY class"
T1   A3                       >>>   "a Coactivity"
T2   A5     V2      1*        >M>   "LOCAL" => "a Directory"
a Coactivity
T2   A5     V2      1*        >V>   SELF => "a Coactivity"
T1   A3                    24 *-* say c~resume
T2   A5     V2      1*        >A>   "a Coactivity"
T1   A3                       >V>   C => "a Coactivity"
T2   A5     V2      1*    104 *-* .Coactivity~table[self] = self
T1   A6     V2      1         >I> Method RESUME with scope "The Coactivity class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T2   A5     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T2   A5     V2      1*        >M>   "TABLE" => "an IdentityTable"
T2   A5     V2      1*        >V>   SELF => "a Coactivity"
T2   A5     V2      1*        >A>   "a Coactivity"
T2   A5     V2      1*        >V>   SELF => "a Coactivity"
T2   A5     V2      1*        >A>   "a Coactivity"
T2   A5     V2      1*    105 *-* signal on any name trapCondition -- catch all
T2   A5     V2      1*    106 *-* signal on syntax name trapCondition -- gives better messages
T2   A5     V2      1*    107 *-* guard off
T2   A5     V2      1     108 *-* guard on when status <> .Coactivity~suspended
T1   A6     V2      1*    176 *-* expose status yieldValue
T1   A6     V2      1*    177 *-* if status == .Coactivity~notStarted 
T1   A6     V2      1*        >V>   STATUS => "1"
T1   A6     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A6     V2      1*        >M>   "NOTSTARTED" => "0"
T1   A6     V2      1*        >O>   "==" => "0"
T1   A6     V2      1*        >>>   "0"
T1   A6     V2      1*    178 *-* if status == .Coactivity~killed 
T1   A6     V2      1*        >V>   STATUS => "1"
T1   A6     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A6     V2      1*        >M>   "KILLED" => "4"
T1   A6     V2      1*        >O>   "==" => "0"
T1   A6     V2      1*        >>>   "0"
T1   A6     V2      1*    179 *-* if status == .Coactivity~ended 
T1   A6     V2      1*        >V>   STATUS => "1"
T1   A6     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A6     V2      1*        >M>   "ENDED" => "3"
T1   A6     V2      1*        >O>   "==" => "0"
T1   A6     V2      1*        >>>   "0"
T1   A6     V2      1*    180 *-* self~arguments = arg(1, "a")
T1   A6     V2      1*        >V>   SELF => "a Coactivity"
T1   A6     V2      1*        >L>   "1"
T1   A6     V2      1*        >A>   "1"
T1   A6     V2      1*        >L>   "a"
T1   A6     V2      1*        >A>   "a"
T1   A6     V2      1*        >F>   ARG => "an Array"
T1   A6     V2      1*        >A>   "an Array"
T1   A6     V2      1*        >>>   "an Array"
T1   A6     V2      1*    181 *-* status = .Coactivity~running
T1   A6     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A6     V2      1*        >M>   "RUNNING" => "2"
T1   A6     V2      1*        >>>   "2"
T1   A6     V2      1*        >=>   STATUS <= "2"
T1   A6     V2      1*    182 *-* guard off
T1   A6     V2      1     183 *-* guard on when status <> .Coactivity~running
T2   A5     V2      1*        >V>   STATUS => "2"
T2   A5     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T2   A5     V2      1*        >M>   "SUSPENDED" => "1"
T2   A5     V2      1*        >O>   "<>" => "1"
T2   A5     V2      1*        >>>   "1"
T2   A5     V2      1*    109 *-* if status == .Coactivity~running 
T2   A5     V2      1*        >V>   STATUS => "2"
T2   A5     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T2   A5     V2      1*        >M>   "RUNNING" => "2"
T2   A5     V2      1*        >O>   "==" => "1"
T2   A5     V2      1*        >>>   "1"
T2   A5     V2      1*    109 *-*   then
T2   A5     V2      1*    109 *-*     do
T2   A5     V2      1*    110 *-*       guard off
T2   A5     V2      1     112 *-*       if self~doer~needsObject 
T1   A6     V2      1*        >V>   STATUS => "2"
T2   A5     V2      1         >V>         SELF => "a Coactivity"
T1   A6     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A6     V2      1*        >M>   "RUNNING" => "2"
T1   A6     V2      1*        >O>   "<>" => "0"
T1   A6     V2      1*        >>>   "0"
T2   A5     V2                >M>         "DOER" => "a Routine"
T2   A5     V2                >M>         "NEEDSOBJECT" => "0"
T2   A5     V2                >>>         "0"
T2   A5     V2            113 *-*         else
T2   A5     V2            113 *-*           self~doer~doWith(self~arguments) -- no object needed (routine)
T2   A5     V2                >V>             SELF => "a Coactivity"
T2   A5     V2                >M>             "DOER" => "a Routine"
T2   A5     V2                >V>             SELF => "a Coactivity"
T2   A5     V2                >M>             "ARGUMENTS" => "an Array"
T2   A5     V2                >A>             "an Array"
T2   A7     V1                >I> Method YIELD with scope "The Coactivity class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T2   A7     V1      1*    143 *-* coactivity = .Activity~local~coactivity
T2   A7     V1      1*        >E>   .ACTIVITY => "The ACTIVITY class"
T2   A7     V1      1*        >M>   "LOCAL" => "a Directory"
T2   A7     V1      1*        >M>   "COACTIVITY" => "a Coactivity"
T2   A7     V1      1*        >>>   "a Coactivity"
T2   A7     V1      1*        >=>   COACTIVITY <= "a Coactivity"
T2   A7     V1      1*    144 *-* if coactivity == .nil 
T2   A7     V1      1*        >V>   COACTIVITY => "a Coactivity"
T2   A7     V1      1*        >E>   .NIL => "The NIL object"
T2   A7     V1      1*        >O>   "==" => "0"
T2   A7     V1      1*        >>>   "0"
T2   A7     V1      1*    145 *-* forward to (coactivity)
T2   A7     V1      1*        >V>   COACTIVITY => "a Coactivity"
T2   A8     V2                >I> Method YIELD with scope "The Coactivity class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T2   A8     V2      1*    151 *-* expose status yieldValue
T2   A8     V2      1*    152 *-* drop yieldValue
T2   A8     V2      1*    153 *-* if status == .Coactivity~killed 
T2   A8     V2      1*        >V>   STATUS => "2"
T2   A8     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T2   A8     V2      1*        >M>   "KILLED" => "4"
T2   A8     V2      1*        >O>   "==" => "0"
T2   A8     V2      1*        >>>   "0"
T2   A8     V2      1*    154 *-* if status == .Coactivity~ended 
T2   A8     V2      1*        >V>   STATUS => "2"
T2   A8     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T2   A8     V2      1*        >M>   "ENDED" => "3"
T2   A8     V2      1*        >O>   "==" => "0"
T2   A8     V2      1*        >>>   "0"
T2   A8     V2      1*    155 *-* if arg() <> 0 
T2   A8     V2      1*        >F>   ARG => "1"
T2   A8     V2      1*        >L>   "0"
T2   A8     V2      1*        >O>   "<>" => "1"
T2   A8     V2      1*        >>>   "1"
T2   A8     V2      1*    155 *-*   then
T2   A8     V2      1*    155 *-*     use strict arg yieldValue -- yieldValue will be returned to the Coactivity's client by 'resume'
T2   A8     V2      1*        >>>       "1"
T2   A8     V2      1*        >=>       YIELDVALUE <= "1"
T2   A8     V2      1*    156 *-* status = .Coactivity~suspended
T2   A8     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T2   A8     V2      1*        >M>   "SUSPENDED" => "1"
T2   A8     V2      1*        >>>   "1"
T2   A8     V2      1*        >=>   STATUS <= "1"
T2   A8     V2      1*    157 *-* guard off
T2   A8     V2      1     158 *-* guard on when status <> .Coactivity~suspended
T1   A6     V2      1*        >V>   STATUS => "1"
T1   A6     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A6     V2      1*        >M>   "RUNNING" => "2"
T1   A6     V2      1*        >O>   "<>" => "1"
T1   A6     V2      1*        >>>   "1"
T1   A6     V2      1*    184 *-* if status == .Coactivity~killed 
T1   A6     V2      1*        >V>   STATUS => "1"
T1   A6     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A6     V2      1*        >M>   "KILLED" => "4"
T1   A6     V2      1*        >O>   "==" => "0"
T1   A6     V2      1*        >>>   "0"
T1   A6     V2      1*    185 *-* if var("yieldValue") 
T1   A6     V2      1*        >L>   "yieldValue"
T1   A6     V2      1*        >A>   "yieldValue"
T1   A6     V2      1*        >F>   VAR => "1"
T1   A6     V2      1*        >>>   "1"
T1   A6     V2      1*    185 *-*   then
T1   A6     V2      1*    185 *-*     return yieldValue
T1   A6     V2      1*        >V>       YIELDVALUE => "1"
T1   A6     V2      1*        >>>       "1"
T1   A3                       >M>   "RESUME" => "1"
T2   A8     V2      1*        >V>   STATUS => "1"
T1   A3                       >>>   "1"
T2   A8     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
1
T2   A8     V2      1*        >M>   "SUSPENDED" => "1"
T1   A3                    26 *-* say "Ended coactivities:" .Coactivity~endAll
T2   A8     V2      1*        >O>   "<>" => "0"
T1   A3                       >L>   "Ended coactivities:"
T2   A8     V2      1*        >>>   "0"
T1   A3                       >E>   .COACTIVITY => "The Coactivity class"
T1   A9     V1      1         >I> Method ENDALL with scope "The Coactivity class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
*/


/***************************************************************
Trace output when no deadlock
****************************************************************
T1   A1     V1                >I> Method INIT with scope "The Coactivity class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A1     V1      1*     53 *-* self~table = .IdentityTable~new
T1   A1     V1      1*        >V>   SELF => "The Coactivity class"
T1   A1     V1      1*        >E>   .IDENTITYTABLE => "The IdentityTable class"
T1   A1     V1      1*        >M>   "NEW" => "an IdentityTable"
T1   A1     V1      1*        >A>   "an IdentityTable"
T1   A1     V1      1*        >>>   "an IdentityTable"
T1   A1     V1      1*     54 *-* self~makeArrayLimit = 10000 -- not a constant, I think it's useful to let the end user change this value
T1   A1     V1      1*        >V>   SELF => "The Coactivity class"
T1   A1     V1      1*        >L>   "10000"
T1   A1     V1      1*        >A>   "10000"
T1   A1     V1      1*        >>>   "10000"
T1   A2                       >I> Routine D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A3                    21 *-* call Doers.AddVisibilityFrom(.context)
T1   A3                       >E>   .CONTEXT => "a RexxContext"
T1   A3                       >A>   "a RexxContext"
T1   A3                    22 *-* c = .coactivity~new(".coactivity~yield(1) ; return 2")
T1   A3                       >E>   .COACTIVITY => "The Coactivity class"
T1   A3                       >L>   ".coactivity~yield(1) ; return 2"
T1   A3                       >A>   ".coactivity~yield(1) ; return 2"
T1   A4                       >I> Method INIT with scope "The Coactivity class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A4                    83 *-* use strict arg action="main", start=.true, context=.nil, self~object=(self)
T1   A4                       >>>   ".coactivity~yield(1) ; return 2"
T1   A4                       >=>   ACTION <= ".coactivity~yield(1) ; return 2"
T1   A4                       >E>   .TRUE => "1"
T1   A4                       >>>   "1"
T1   A4                       >=>   START <= "1"
T1   A4                       >E>   .NIL => "The NIL object"
T1   A4                       >>>   "The NIL object"
T1   A4                       >=>   CONTEXT <= "The NIL object"
T1   A4                       >V>   SELF => "a Coactivity"
T1   A4                       >>>   "a Coactivity"
T1   A4                       >V>   SELF => "a Coactivity"
T1   A4                    85 *-* self~doer = action~doer(context)
T1   A4                       >V>   SELF => "a Coactivity"
T1   A4                       >V>   ACTION => ".coactivity~yield(1) ; return 2"
T1   A4                       >V>   CONTEXT => "The NIL object"
T1   A4                       >A>   "The NIL object"
T1   A4                       >M>   "DOER" => "a Routine"
T1   A4                       >A>   "a Routine"
T1   A4                       >>>   "a Routine"
T1   A4                    86 *-* self~status = .Coactivity~notStarted
T1   A4                       >V>   SELF => "a Coactivity"
T1   A4                       >E>   .COACTIVITY => "The Coactivity class"
T1   A4                       >M>   "NOTSTARTED" => "0"
T1   A4                       >A>   "0"
T1   A4                       >>>   "0"
T1   A4                    87 *-* if start 
T1   A4                       >V>   START => "1"
T1   A4                       >>>   "1"
T1   A4                    87 *-*   then
T1   A4                    87 *-*     self~start
T1   A4                       >V>       SELF => "a Coactivity"
T1   A5     V2                >I> Method START with scope "The Coactivity class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A5     V2      1*     97 *-* expose status
T1   A5     V2      1*     98 *-* use strict arg -- no arg
T1   A5     V2      1*     99 *-* if status <> .Coactivity~notStarted 
T1   A5     V2      1*        >V>   STATUS => "0"
T1   A5     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A5     V2      1*        >M>   "NOTSTARTED" => "0"
T1   A5     V2      1*        >O>   "<>" => "0"
T1   A5     V2      1*        >>>   "0"
T1   A5     V2      1*    100 *-* status = .Coactivity~suspended
T1   A5     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A5     V2      1*        >M>   "SUSPENDED" => "1"
T1   A5     V2      1*        >>>   "1"
T1   A5     V2      1*        >=>   STATUS <= "1"
T1   A5     V2      1*    101 *-* reply self
T1   A5     V2      1*        >V>   SELF => "a Coactivity"
T1   A5     V2      1*        >>>   "a Coactivity"
T2   A5     V2      1*        >I> Method START with scope "The Coactivity class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A4                       >>>       "a Coactivity"
T2   A5     V2      1*    102 *-* .Activity~local~empty
T1   A3                       >M>   "NEW" => "a Coactivity"
T2   A5     V2      1*        >E>   .ACTIVITY => "The ACTIVITY class"
T1   A3                       >>>   "a Coactivity"
T1   A3                       >=>   C <= "a Coactivity"
T2   A5     V2      1*        >M>   "LOCAL" => "a Directory"
T1   A3                    23 *-* say c
T2   A5     V2      1*    103 *-* .Activity~local~coactivity = self
T1   A3                       >V>   C => "a Coactivity"
T2   A5     V2      1*        >E>   .ACTIVITY => "The ACTIVITY class"
T1   A3                       >>>   "a Coactivity"
T2   A5     V2      1*        >M>   "LOCAL" => "a Directory"
a Coactivity
T2   A5     V2      1*        >V>   SELF => "a Coactivity"
T1   A3                    24 *-* say c~resume
T2   A5     V2      1*        >A>   "a Coactivity"
T1   A3                       >V>   C => "a Coactivity"
T2   A5     V2      1*    104 *-* .Coactivity~table[self] = self
T1   A6     V2      1         >I> Method RESUME with scope "The Coactivity class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T2   A5     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T2   A5     V2      1*        >M>   "TABLE" => "an IdentityTable"
T2   A5     V2      1*        >V>   SELF => "a Coactivity"
T2   A5     V2      1*        >A>   "a Coactivity"
T2   A5     V2      1*        >V>   SELF => "a Coactivity"
T2   A5     V2      1*        >A>   "a Coactivity"
T2   A5     V2      1*    105 *-* signal on any name trapCondition -- catch all
T2   A5     V2      1*    106 *-* signal on syntax name trapCondition -- gives better messages
T2   A5     V2      1*    107 *-* guard off
T2   A5     V2      1     108 *-* guard on when status <> .Coactivity~suspended
T1   A6     V2      1*    176 *-* expose status yieldValue
T1   A6     V2      1*    177 *-* if status == .Coactivity~notStarted 
T1   A6     V2      1*        >V>   STATUS => "1"
T1   A6     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A6     V2      1*        >M>   "NOTSTARTED" => "0"
T1   A6     V2      1*        >O>   "==" => "0"
T1   A6     V2      1*        >>>   "0"
T1   A6     V2      1*    178 *-* if status == .Coactivity~killed 
T1   A6     V2      1*        >V>   STATUS => "1"
T1   A6     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A6     V2      1*        >M>   "KILLED" => "4"
T1   A6     V2      1*        >O>   "==" => "0"
T1   A6     V2      1*        >>>   "0"
T1   A6     V2      1*    179 *-* if status == .Coactivity~ended 
T1   A6     V2      1*        >V>   STATUS => "1"
T1   A6     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A6     V2      1*        >M>   "ENDED" => "3"
T1   A6     V2      1*        >O>   "==" => "0"
T1   A6     V2      1*        >>>   "0"
T1   A6     V2      1*    180 *-* self~arguments = arg(1, "a")
T1   A6     V2      1*        >V>   SELF => "a Coactivity"
T1   A6     V2      1*        >L>   "1"
T1   A6     V2      1*        >A>   "1"
T1   A6     V2      1*        >L>   "a"
T1   A6     V2      1*        >A>   "a"
T1   A6     V2      1*        >F>   ARG => "an Array"
T1   A6     V2      1*        >A>   "an Array"
T1   A6     V2      1*        >>>   "an Array"
T1   A6     V2      1*    181 *-* status = .Coactivity~running
T1   A6     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A6     V2      1*        >M>   "RUNNING" => "2"
T1   A6     V2      1*        >>>   "2"
T1   A6     V2      1*        >=>   STATUS <= "2"
T1   A6     V2      1*    182 *-* guard off
T1   A6     V2      1     183 *-* guard on when status <> .Coactivity~running
T2   A5     V2      1*        >V>   STATUS => "2"
T2   A5     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T2   A5     V2      1*        >M>   "SUSPENDED" => "1"
T2   A5     V2      1*        >O>   "<>" => "1"
T2   A5     V2      1*        >>>   "1"
T2   A5     V2      1*    109 *-* if status == .Coactivity~running 
T2   A5     V2      1*        >V>   STATUS => "2"
T2   A5     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T2   A5     V2      1*        >M>   "RUNNING" => "2"
T2   A5     V2      1*        >O>   "==" => "1"
T2   A5     V2      1*        >>>   "1"
T2   A5     V2      1*    109 *-*   then
T2   A5     V2      1*    109 *-*     do
T2   A5     V2      1*    110 *-*       guard off
T2   A5     V2      1     112 *-*       if self~doer~needsObject 
T1   A6     V2      1*        >V>   STATUS => "2"
T2   A5     V2      1         >V>         SELF => "a Coactivity"
T1   A6     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A6     V2      1*        >M>   "RUNNING" => "2"
T1   A6     V2      1*        >O>   "<>" => "0"
T1   A6     V2      1*        >>>   "0"
T2   A5     V2                >M>         "DOER" => "a Routine"
T2   A5     V2                >M>         "NEEDSOBJECT" => "0"
T2   A5     V2                >>>         "0"
T2   A5     V2            113 *-*         else
T2   A5     V2            113 *-*           self~doer~doWith(self~arguments) -- no object needed (routine)
T2   A5     V2                >V>             SELF => "a Coactivity"
T2   A5     V2                >M>             "DOER" => "a Routine"
T2   A5     V2                >V>             SELF => "a Coactivity"
T2   A5     V2                >M>             "ARGUMENTS" => "an Array"
T2   A5     V2                >A>             "an Array"
T2   A7                       >I> Method YIELD with scope "The Coactivity class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T2   A7                   143 *-* coactivity = .Activity~local~coactivity
T2   A7                       >E>   .ACTIVITY => "The ACTIVITY class"
T2   A7                       >M>   "LOCAL" => "a Directory"
T2   A7                       >M>   "COACTIVITY" => "a Coactivity"
T2   A7                       >>>   "a Coactivity"
T2   A7                       >=>   COACTIVITY <= "a Coactivity"
T2   A7                   144 *-* if coactivity == .nil 
T2   A7                       >V>   COACTIVITY => "a Coactivity"
T2   A7                       >E>   .NIL => "The NIL object"
T2   A7                       >O>   "==" => "0"
T2   A7                       >>>   "0"
T2   A7                   145 *-* forward to (coactivity)
T2   A7                       >V>   COACTIVITY => "a Coactivity"
T2   A8     V2                >I> Method YIELD with scope "The Coactivity class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T2   A8     V2      1*    151 *-* expose status yieldValue
T2   A8     V2      1*    152 *-* drop yieldValue
T2   A8     V2      1*    153 *-* if status == .Coactivity~killed 
T2   A8     V2      1*        >V>   STATUS => "2"
T2   A8     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T2   A8     V2      1*        >M>   "KILLED" => "4"
T2   A8     V2      1*        >O>   "==" => "0"
T2   A8     V2      1*        >>>   "0"
T2   A8     V2      1*    154 *-* if status == .Coactivity~ended 
T2   A8     V2      1*        >V>   STATUS => "2"
T2   A8     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T2   A8     V2      1*        >M>   "ENDED" => "3"
T2   A8     V2      1*        >O>   "==" => "0"
T2   A8     V2      1*        >>>   "0"
T2   A8     V2      1*    155 *-* if arg() <> 0 
T2   A8     V2      1*        >F>   ARG => "1"
T2   A8     V2      1*        >L>   "0"
T2   A8     V2      1*        >O>   "<>" => "1"
T2   A8     V2      1*        >>>   "1"
T2   A8     V2      1*    155 *-*   then
T2   A8     V2      1*    155 *-*     use strict arg yieldValue -- yieldValue will be returned to the Coactivity's client by 'resume'
T2   A8     V2      1*        >>>       "1"
T2   A8     V2      1*        >=>       YIELDVALUE <= "1"
T2   A8     V2      1*    156 *-* status = .Coactivity~suspended
T2   A8     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T2   A8     V2      1*        >M>   "SUSPENDED" => "1"
T2   A8     V2      1*        >>>   "1"
T2   A8     V2      1*        >=>   STATUS <= "1"
T2   A8     V2      1*    157 *-* guard off
T2   A8     V2      1     158 *-* guard on when status <> .Coactivity~suspended
T1   A6     V2      1*        >V>   STATUS => "1"
T1   A6     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A6     V2      1*        >M>   "RUNNING" => "2"
T1   A6     V2      1*        >O>   "<>" => "1"
T1   A6     V2      1*        >>>   "1"
T1   A6     V2      1*    184 *-* if status == .Coactivity~killed 
T1   A6     V2      1*        >V>   STATUS => "1"
T1   A6     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A6     V2      1*        >M>   "KILLED" => "4"
T1   A6     V2      1*        >O>   "==" => "0"
T1   A6     V2      1*        >>>   "0"
T1   A6     V2      1*    185 *-* if var("yieldValue") 
T1   A6     V2      1*        >L>   "yieldValue"
T1   A6     V2      1*        >A>   "yieldValue"
T1   A6     V2      1*        >F>   VAR => "1"
T1   A6     V2      1*        >>>   "1"
T1   A6     V2      1*    185 *-*   then
T1   A6     V2      1*    185 *-*     return yieldValue
T1   A6     V2      1*        >V>       YIELDVALUE => "1"
T1   A6     V2      1*        >>>       "1"
T1   A3                       >M>   "RESUME" => "1"
T2   A8     V2      1*        >V>   STATUS => "1"
T1   A3                       >>>   "1"
T2   A8     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
1
T2   A8     V2      1*        >M>   "SUSPENDED" => "1"
T1   A3                    26 *-* say "Ended coactivities:" .Coactivity~endAll
T2   A8     V2      1*        >O>   "<>" => "0"
T1   A3                       >L>   "Ended coactivities:"
T2   A8     V2      1*        >>>   "0"
T1   A3                       >E>   .COACTIVITY => "The Coactivity class"
T1   A9     V1                >I> Method ENDALL with scope "The Coactivity class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A9     V1      1*     62 *-* count = 0
T1   A9     V1      1*        >L>   "0"
T1   A9     V1      1*        >>>   "0"
T1   A9     V1      1*        >=>   COUNT <= "0"
T1   A9     V1      1*     63 *-* do coactivity over self~table~allIndexes
T1   A9     V1      1*        >V>     SELF => "The Coactivity class"
T1   A9     V1      1*        >M>     "TABLE" => "an IdentityTable"
T1   A9     V1      1*        >M>     "ALLINDEXES" => "an Array"
T1   A9     V1      1*        >>>     "an Array"
T1   A9     V1      1*        >=>     COACTIVITY <= "a Coactivity"
T1   A9     V1      1*        >>>     "a Coactivity"
T1   A9     V1      1*     64 *-*   if coactivity~end 
T1   A9     V1      1*        >V>     COACTIVITY => "a Coactivity"
T1   A10    V2                >I> Method END with scope "The Coactivity class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A10    V2      1*    189 *-* if self~status == .Coactivity~ended 
T1   A10    V2      1*        >V>   SELF => "a Coactivity"
T1   A10    V2      1*        >M>   "STATUS" => "1"
T1   A10    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A10    V2      1*        >M>   "ENDED" => "3"
T1   A10    V2      1*        >O>   "==" => "0"
T1   A10    V2      1*        >>>   "0"
T1   A10    V2      1*    190 *-* if self~status == .Coactivity~killed 
T1   A10    V2      1*        >V>   SELF => "a Coactivity"
T1   A10    V2      1*        >M>   "STATUS" => "1"
T1   A10    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A10    V2      1*        >M>   "KILLED" => "4"
T1   A10    V2      1*        >O>   "==" => "0"
T1   A10    V2      1*        >>>   "0"
T1   A10    V2      1*    192 *-* self~status = .Coactivity~ended
T1   A10    V2      1*        >V>   SELF => "a Coactivity"
T1   A10    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A10    V2      1*        >M>   "ENDED" => "3"
T1   A10    V2      1*        >A>   "3"
T1   A10    V2      1*        >>>   "3"
T1   A10    V2      1*    193 *-* return .true
T1   A10    V2      1*        >E>   .TRUE => "1"
T1   A10    V2      1*        >>>   "1"
T1   A9     V1      1*        >M>     "END" => "1"
T2   A8     V2      1*        >V>   STATUS => "3"
T1   A9     V1      1*        >>>     "1"
T2   A8     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A9     V1      1*     64 *-*     then
T2   A8     V2      1*        >M>   "SUSPENDED" => "1"
T1   A9     V1      1*     64 *-*       count += 1
T2   A8     V2      1*        >O>   "<>" => "1"
T1   A9     V1      1*        >V>         COUNT => "0"
T2   A8     V2      1*        >>>   "1"
T1   A9     V1      1*        >L>         "1"
T2   A8     V2      1*    159 *-* if status == .Coactivity~killed 
T1   A9     V1      1*        >O>         "+" => "1"
T2   A8     V2      1*        >V>   STATUS => "3"
T1   A9     V1      1*        >>>         "1"
T2   A8     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A9     V1      1*        >=>         COUNT <= "1"
T2   A8     V2      1*        >M>   "KILLED" => "4"
T1   A9     V1      1*     65 *-* end
T2   A8     V2      1*        >O>   "==" => "0"
T1   A9     V1      1*     63 *-* do coactivity over self~table~allIndexes
T2   A8     V2      1*        >>>   "0"
T1   A9     V1      1*     66 *-* return count
T2   A8     V2      1*    160 *-* if status == .Coactivity~ended 
T1   A9     V1      1*        >V>   COUNT => "1"
T2   A8     V2      1*        >V>   STATUS => "3"
T1   A9     V1      1*        >>>   "1"
T2   A8     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A3                       >M>   "ENDALL" => "1"
T2   A8     V2      1*        >M>   "ENDED" => "3"
T1   A3                       >O>   " " => "Ended coactivities: 1"
T2   A8     V2      1*        >O>   "==" => "1"
T1   A3                       >>>   "Ended coactivities: 1"
Ended coactivities: 1
T2   A8     V2      1*        >>>   "1"
T2   A8     V2      1*    160 *-*   then
T2   A8     V2      1*    160 *-*     raise syntax 93.900 array ("Coactivity is ended") -- this is to unwind any nested invocation and return to 'start'
T2   A8     V2      1*        >L>       "93.900"
T2   A8     V2      1*        >L>       "Coactivity is ended"
T2   A5     V2            119 *-* trapCondition:
T2   A5     V2            120 *-* self~kill -- maybe already killed or ended
T2   A5     V2                >V>   SELF => "a Coactivity"
T2   A11    V2                >I> Method KILL with scope "The Coactivity class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T2   A11    V2      1*    197 *-* if self~status == .Coactivity~ended 
T2   A11    V2      1*        >V>   SELF => "a Coactivity"
T2   A11    V2      1*        >M>   "STATUS" => "3"
T2   A11    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T2   A11    V2      1*        >M>   "ENDED" => "3"
T2   A11    V2      1*        >O>   "==" => "1"
T2   A11    V2      1*        >>>   "1"
T2   A11    V2      1*    197 *-*   then
T2   A11    V2      1*    197 *-*     return .false
T2   A11    V2      1*        >E>       .FALSE => "0"
T2   A11    V2      1*        >>>       "0"
T2   A5     V2                >>>   "0"
T2   A5     V2            121 *-* if self~hasMethod("onTerminate") 
T2   A5     V2                >V>   SELF => "a Coactivity"
T2   A5     V2                >L>   "onTerminate"
T2   A5     V2                >A>   "onTerminate"
T2   A5     V2                >M>   "HASMETHOD" => "0"
T2   A5     V2                >>>   "0"
T2   A5     V2            122 *-* .Coactivity~table~remove(self)
T2   A5     V2                >E>   .COACTIVITY => "The Coactivity class"
T2   A5     V2                >M>   "TABLE" => "an IdentityTable"
T2   A5     V2                >V>   SELF => "a Coactivity"
T2   A5     V2                >A>   "a Coactivity"
T2   A5     V2                >>>   "a Coactivity"
T2   A5     V2            123 *-* .Activity~local~empty
T2   A5     V2                >E>   .ACTIVITY => "The ACTIVITY class"
T2   A5     V2                >M>   "LOCAL" => "a Directory"
T2   A5     V2            124 *-* if self~isKilled & condition("o") <> .nil 
T2   A5     V2                >V>   SELF => "a Coactivity"
T2   A12    V2                >I> Method ISKILLED with scope "The Coactivity class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T2   A12    V2      1*    217 *-* return self~status == .Coactivity~killed
T2   A12    V2      1*        >V>   SELF => "a Coactivity"
T2   A12    V2      1*        >M>   "STATUS" => "3"
T2   A12    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T2   A12    V2      1*        >M>   "KILLED" => "4"
T2   A12    V2      1*        >O>   "==" => "0"
T2   A12    V2      1*        >>>   "0"
T2   A5     V2                >M>   "ISKILLED" => "0"
T2   A5     V2                >L>   "o"
T2   A5     V2                >A>   "o"
T2   A5     V2                >F>   CONDITION => "a Directory"
T2   A5     V2                >E>   .NIL => "The NIL object"
T2   A5     V2                >O>   "<>" => "1"
T2   A5     V2                >O>   "&" => "0"
T2   A5     V2                >>>   "0"
*/

