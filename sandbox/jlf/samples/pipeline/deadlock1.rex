/*
An example of deadlock, and how to avoid it.

When I added the 'pipe' method to co-activity, I did not declare it unguarded.
Because of that, the one-liner below was dead-locked.

task    one-liner               coactivity          pipe                    supplier
T1      .coactivity~new
T1                              init +0
T1                              start +1
T1                              reply
T2                              guard off -1
T2                              guard on when +1
T1      coactivity~pipe
                                -----------------------------------------------------------
T1                              pipe +1 <-- Problem here, must be unguarded to avoid this +1
                                -----------------------------------------------------------
T1                                                  go
T1                                                  begin
T1                                                  coactivity~supplier
T1                              supplier +0
T1                                                  supplier~next
T1                                                                          next
T1                              resume +1
*/

--call Doers.AddVisibilityFrom(.context)

.coactivity~new({.coactivity~yield("a") ; .coactivity~yield("b")})~pipe(.upper|.console)

--::options trace i
::requires "extension/extensions.cls"
::requires "concurrency/coactivity.cls"
::requires "pipeline/pipe_extension.cls"

/***************************************************************
Trace output in case of deadlock (when .coactivity~pipe is guarded)
****************************************************************
T1   A1     V1                >I> Method INIT with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
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
T1   A2                       >I> Routine d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A3                       >I> Routine d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\pipeline\pipe.rex in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\pipeline\pipe.rex
T1   A4                    24 *-* call Doers.AddVisibilityFrom(.context)
T1   A4                       >E>   .CONTEXT => "a RexxContext"
T1   A4                       >A>   "a RexxContext"
T1   A4                    26 *-* .coactivity~new('.coactivity~yield("a") ; .coactivity~yield("b")')~pipe(.upper|.console)
T1   A4                       >E>   .COACTIVITY => "The Coactivity class"
T1   A4                       >L>   ".coactivity~yield("a") ; .coactivity~yield("b")"
T1   A4                       >A>   ".coactivity~yield("a") ; .coactivity~yield("b")"
T1   A5     V2                >I> Method INIT with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A5     V2             83 *-* use strict arg action="main", start=.true, context=.nil, self~object=(self)
T1   A5     V2                >>>   ".coactivity~yield("a") ; .coactivity~yield("b")"
T1   A5     V2                >=>   ACTION <= ".coactivity~yield("a") ; .coactivity~yield("b")"
T1   A5     V2                >E>   .TRUE => "1"
T1   A5     V2                >>>   "1"
T1   A5     V2                >=>   START <= "1"
T1   A5     V2                >E>   .NIL => "The NIL object"
T1   A5     V2                >>>   "The NIL object"
T1   A5     V2                >=>   CONTEXT <= "The NIL object"
T1   A5     V2                >V>   SELF => "a Coactivity"
T1   A5     V2                >>>   "a Coactivity"
T1   A5     V2                >V>   SELF => "a Coactivity"
T1   A5     V2             85 *-* self~doer = action~doer(context)
T1   A5     V2                >V>   SELF => "a Coactivity"
T1   A5     V2                >V>   ACTION => ".coactivity~yield("a") ; .coactivity~yield("b")"
T1   A5     V2                >V>   CONTEXT => "The NIL object"
T1   A5     V2                >A>   "The NIL object"
T1   A5     V2                >M>   "DOER" => "a Routine"
T1   A5     V2                >A>   "a Routine"
T1   A5     V2                >>>   "a Routine"
T1   A5     V2             86 *-* self~status = .Coactivity~notStarted
T1   A5     V2                >V>   SELF => "a Coactivity"
T1   A5     V2                >E>   .COACTIVITY => "The Coactivity class"
T1   A5     V2                >M>   "NOTSTARTED" => "0"
T1   A5     V2                >A>   "0"
T1   A5     V2                >>>   "0"
T1   A5     V2             87 *-* if start
T1   A5     V2                >V>   START => "1"
T1   A5     V2                >>>   "1"
T1   A5     V2             87 *-*   then
T1   A5     V2             87 *-*     self~start
T1   A5     V2                >V>       SELF => "a Coactivity"
T1   A6     V2                >I> Method START with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A6     V2      1*     97 *-* expose status
T1   A6     V2      1*     98 *-* use strict arg -- no arg
T1   A6     V2      1*     99 *-* if status <> .Coactivity~notStarted
T1   A6     V2      1*        >V>   STATUS => "0"
T1   A6     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A6     V2      1*        >M>   "NOTSTARTED" => "0"
T1   A6     V2      1*        >O>   "<>" => "0"
T1   A6     V2      1*        >>>   "0"
T1   A6     V2      1*    100 *-* status = .Coactivity~suspended
T1   A6     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A6     V2      1*        >M>   "SUSPENDED" => "1"
T1   A6     V2      1*        >>>   "1"
T1   A6     V2      1*        >=>   STATUS <= "1"
T1   A6     V2      1*    101 *-* reply self
T1   A6     V2      1*        >V>   SELF => "a Coactivity"
T1   A6     V2      1*        >>>   "a Coactivity"
T2   A6     V2      1*        >I> Method START with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A5     V2      1         >>>       "a Coactivity"
T2   A6     V2      1*    102 *-* .Activity~local~empty
T1   A4                       >M>   "NEW" => "a Coactivity"
T2   A6     V2      1*        >E>   .ACTIVITY => "The ACTIVITY class"
T1   A4                       >E>   .UPPER => "The UPPER class"
T1   A4                       >E>   .CONSOLE => "The CONSOLE class"
T2   A6     V2      1*        >M>   "LOCAL" => "a Directory"
T1   A7     V3                >I> Method | with scope "The PIPESTAGE class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\pipeline\pipe.rex
T2   A6     V2      1*    103 *-* .Activity~local~coactivity = self
T1   A7     V3      1*     66 *-* use strict arg follower
T2   A6     V2      1*        >E>   .ACTIVITY => "The ACTIVITY class"
T1   A7     V3      1*        >>>   "The CONSOLE class"
T2   A6     V2      1*        >M>   "LOCAL" => "a Directory"
T1   A7     V3      1*        >=>   FOLLOWER <= "The CONSOLE class"
T2   A6     V2      1*        >V>   SELF => "a Coactivity"
T1   A7     V3      1*     67 *-* me = self~new                               -- create a new pipeStage instance
T2   A6     V2      1*        >A>   "a Coactivity"
T1   A7     V3      1*        >V>   SELF => "The UPPER class"
T2   A6     V2      1*    104 *-* .Coactivity~table[self] = self
T1   A8     V4                >I> Method INIT with scope "The PIPESTAGE class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\pipeline\pipe.rex
T2   A6     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A8     V4      1*     61 *-* expose next secondary
T2   A6     V2      1*        >M>   "TABLE" => "an IdentityTable"
T1   A8     V4      1*     62 *-* next = .nil
T2   A6     V2      1*        >V>   SELF => "a Coactivity"
T1   A8     V4      1*        >E>   .NIL => "The NIL object"
T2   A6     V2      1*        >A>   "a Coactivity"
T1   A8     V4      1*        >>>   "The NIL object"
T2   A6     V2      1*        >V>   SELF => "a Coactivity"
T1   A8     V4      1*        >=>   NEXT <= "The NIL object"
T2   A6     V2      1*        >A>   "a Coactivity"
T1   A8     V4      1*     63 *-* secondary = .nil                            -- all pipeStages have a secondary output potential
T2   A6     V2      1*    105 *-* signal on any name trapCondition -- catch all
T1   A8     V4      1*        >E>   .NIL => "The NIL object"
T2   A6     V2      1*    106 *-* signal on syntax name trapCondition -- gives better messages
T1   A8     V4      1*        >>>   "The NIL object"
T2   A6     V2      1*    107 *-* guard off
T1   A8     V4      1*        >=>   SECONDARY <= "The NIL object"
T2   A6     V2            108 *-* guard on when status <> .Coactivity~suspended
T1   A7     V3      1*        >M>   "NEW" => "an UPPER"
T2   A6     V2      1*        >V>   STATUS => "1"
T1   A7     V3      1*        >>>   "an UPPER"
T2   A6     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A7     V3      1*        >=>   ME <= "an UPPER"
T2   A6     V2      1*        >M>   "SUSPENDED" => "1"
T1   A7     V3      1*     68 *-* return me|follower                          -- perform the hook up
T2   A6     V2      1*        >O>   "<>" => "0"
T1   A7     V3      1*        >V>   ME => "an UPPER"
T2   A6     V2      1*        >>>   "0"
T1   A7     V3      1*        >V>   FOLLOWER => "The CONSOLE class"
T1   A9     V4                >I> Method | with scope "The PIPESTAGE class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\pipeline\pipe.rex
T1   A9     V4      1*     81 *-* use strict arg follower
T1   A9     V4      1*        >>>   "The CONSOLE class"
T1   A9     V4      1*        >=>   FOLLOWER <= "The CONSOLE class"
T1   A9     V4      1*     82 *-* follower = follower~new                     -- make sure this is an instance
T1   A9     V4      1*        >V>   FOLLOWER => "The CONSOLE class"
T1   A10    V5                >I> Method INIT with scope "The PIPESTAGE class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\pipeline\pipe.rex
T1   A10    V5      1*     61 *-* expose next secondary
T1   A10    V5      1*     62 *-* next = .nil
T1   A10    V5      1*        >E>   .NIL => "The NIL object"
T1   A10    V5      1*        >>>   "The NIL object"
T1   A10    V5      1*        >=>   NEXT <= "The NIL object"
T1   A10    V5      1*     63 *-* secondary = .nil                            -- all pipeStages have a secondary output potential
T1   A10    V5      1*        >E>   .NIL => "The NIL object"
T1   A10    V5      1*        >>>   "The NIL object"
T1   A10    V5      1*        >=>   SECONDARY <= "The NIL object"
T1   A9     V4      1*        >M>   "NEW" => "a CONSOLE"
T1   A9     V4      1*        >>>   "a CONSOLE"
T1   A9     V4      1*        >=>   FOLLOWER <= "a CONSOLE"
T1   A9     V4      1*     83 *-* self~append(follower)                       -- do the chain append logic
T1   A9     V4      1*        >V>   SELF => "an UPPER"
T1   A9     V4      1*        >V>   FOLLOWER => "a CONSOLE"
T1   A9     V4      1*        >A>   "a CONSOLE"
T1   A11    V4      1         >I> Method APPEND with scope "The PIPESTAGE class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\pipeline\pipe.rex
T1   A11    V4      2*     99 *-* expose next
T1   A11    V4      2*    100 *-* use strict arg follower
T1   A11    V4      2*        >>>   "a CONSOLE"
T1   A11    V4      2*        >=>   FOLLOWER <= "a CONSOLE"
T1   A11    V4      2*    101 *-* if .nil == next
T1   A11    V4      2*        >E>   .NIL => "The NIL object"
T1   A11    V4      2*        >V>   NEXT => "The NIL object"
T1   A11    V4      2*        >O>   "==" => "1"
T1   A11    V4      2*        >>>   "1"
T1   A11    V4      2*    101 *-*   then
T1   A11    V4      2*    101 *-*     do                     -- if we're the end already, just update the next
T1   A11    V4      2*    102 *-*       next = follower
T1   A11    V4      2*        >V>         FOLLOWER => "a CONSOLE"
T1   A11    V4      2*        >>>         "a CONSOLE"
T1   A11    V4      2*        >=>         NEXT <= "a CONSOLE"
T1   A11    V4      2*    103 *-*   end
T1   A9     V4      1*     84 *-* return self                                 -- we're our own return value
T1   A9     V4      1*        >V>   SELF => "an UPPER"
T1   A9     V4      1*        >>>   "an UPPER"
T1   A7     V3      1*        >O>   "|" => "an UPPER"
T1   A7     V3      1*        >>>   "an UPPER"
T1   A4                       >O>   "|" => "an UPPER"
T1   A4                       >A>   "an UPPER"
T1   A12    V4                >I> Method GO with scope "The PIPESTAGE class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\pipeline\pipe.rex
T1   A12    V4      1*    130 *-* expose source                               -- get the source supplier
T1   A12    V4      1*    131 *-* use strict arg source                       -- set to the supplied object
T1   A12    V4      1*        >>>   "a Coactivity"
T1   A12    V4      1*        >=>   SOURCE <= "a Coactivity"
T1   A12    V4      1*    132 *-* self~begin                                  -- now go feed the pipeline
T1   A12    V4      1*        >V>   SELF => "an UPPER"
T1   A13    V4      1         >I> Method BEGIN with scope "The PIPESTAGE class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\pipeline\pipe.rex
T1   A13    V4      2*    142 *-* expose source                               -- access the data and next chain
T1   A13    V4      2*    144 *-* engine = source~supplier                    -- get a data supplier
T1   A13    V4      2*        >V>   SOURCE => "a Coactivity"
T1   A14    V2      1         >I> Method SUPPLIER with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A14    V2      1     244 *-* return .LazyCoactivitySupplier~new(self)
T1   A14    V2      1         >E>   .LAZYCOACTIVITYSUPPLIER => "The LAZYCOACTIVITYSUPPLIER class"
T1   A14    V2      1         >V>   SELF => "a Coactivity"
T1   A14    V2      1         >A>   "a Coactivity"
T1   A15    V6                >I> Method INIT with scope "The LAZYCOACTIVITYSUPPLIER class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A15    V6      1*    281 *-* use strict arg coactivity
T1   A15    V6      1*        >>>   "a Coactivity"
T1   A15    V6      1*        >=>   COACTIVITY <= "a Coactivity"
T1   A15    V6      1*    282 *-* empty = .array~new(0) -- Lazy supplier
T1   A15    V6      1*        >E>   .ARRAY => "The Array class"
T1   A15    V6      1*        >L>   "0"
T1   A15    V6      1*        >A>   "0"
T1   A15    V6      1*        >M>   "NEW" => "an Array"
T1   A15    V6      1*        >>>   "an Array"
T1   A15    V6      1*        >=>   EMPTY <= "an Array"
T1   A15    V6      1*    283 *-* self~init:super(empty, empty)
T1   A15    V6      1*        >V>   SELF => "a LAZYCOACTIVITYSUPPLIER"
T1   A15    V6      1*        >V>   SUPER => "The Supplier class"
T1   A15    V6      1*        >V>   EMPTY => "an Array"
T1   A15    V6      1*        >A>   "an Array"
T1   A15    V6      1*        >V>   EMPTY => "an Array"
T1   A15    V6      1*        >A>   "an Array"
T1   A15    V6      1*    284 *-* self~coactivity = coactivity
T1   A15    V6      1*        >V>   SELF => "a LAZYCOACTIVITYSUPPLIER"
T1   A15    V6      1*        >V>   COACTIVITY => "a Coactivity"
T1   A15    V6      1*        >A>   "a Coactivity"
T1   A15    V6      1*        >>>   "a Coactivity"
T1   A15    V6      1*    285 *-* if \self~coactivity~isStarted
T1   A15    V6      1*        >V>   SELF => "a LAZYCOACTIVITYSUPPLIER"
T1   A15    V6      1*        >M>   "COACTIVITY" => "a Coactivity"
T1   A16    V2      1         >I> Method ISSTARTED with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A16    V2      2*    205 *-* return self~status <> .Coactivity~notStarted
T1   A16    V2      2*        >V>   SELF => "a Coactivity"
T1   A16    V2      2*        >M>   "STATUS" => "1"
T1   A16    V2      2*        >E>   .COACTIVITY => "The Coactivity class"
T1   A16    V2      2*        >M>   "NOTSTARTED" => "0"
T1   A16    V2      2*        >O>   "<>" => "1"
T1   A16    V2      2*        >>>   "1"
T1   A15    V6      1*        >M>   "ISSTARTED" => "1"
T1   A15    V6      1*        >P>   "\" => "0"
T1   A15    V6      1*        >>>   "0"
T1   A15    V6      1*    286 *-* self~currentIndex = 0
T1   A15    V6      1*        >V>   SELF => "a LAZYCOACTIVITYSUPPLIER"
T1   A15    V6      1*        >L>   "0"
T1   A15    V6      1*        >A>   "0"
T1   A15    V6      1*        >>>   "0"
T1   A15    V6      1*    287 *-* self~next
T1   A15    V6      1*        >V>   SELF => "a LAZYCOACTIVITYSUPPLIER"
T1   A17    V6      1         >I> Method NEXT with scope "The LAZYCOACTIVITYSUPPLIER class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A17    V6      2*    303 *-* expose currentItem
T1   A17    V6      2*    304 *-* self~coactivity~resume
T1   A17    V6      2*        >V>   SELF => "a LAZYCOACTIVITYSUPPLIER"
T1   A17    V6      2*        >M>   "COACTIVITY" => "a Coactivity"
T1   A18    V2      1         >I> Method RESUME with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A18    V2      2*    176 *-* expose status yieldValue
T1   A18    V2      2*    177 *-* if status == .Coactivity~notStarted
T1   A18    V2      2*        >V>   STATUS => "1"
T1   A18    V2      2*        >E>   .COACTIVITY => "The Coactivity class"
T1   A18    V2      2*        >M>   "NOTSTARTED" => "0"
T1   A18    V2      2*        >O>   "==" => "0"
T1   A18    V2      2*        >>>   "0"
T1   A18    V2      2*    178 *-* if status == .Coactivity~killed
T1   A18    V2      2*        >V>   STATUS => "1"
T1   A18    V2      2*        >E>   .COACTIVITY => "The Coactivity class"
T1   A18    V2      2*        >M>   "KILLED" => "4"
T1   A18    V2      2*        >O>   "==" => "0"
T1   A18    V2      2*        >>>   "0"
T1   A18    V2      2*    179 *-* if status == .Coactivity~ended
T1   A18    V2      2*        >V>   STATUS => "1"
T1   A18    V2      2*        >E>   .COACTIVITY => "The Coactivity class"
T1   A18    V2      2*        >M>   "ENDED" => "3"
T1   A18    V2      2*        >O>   "==" => "0"
T1   A18    V2      2*        >>>   "0"
T1   A18    V2      2*    180 *-* self~arguments = arg(1, "a")
T1   A18    V2      2*        >V>   SELF => "a Coactivity"
T1   A18    V2      2*        >L>   "1"
T1   A18    V2      2*        >A>   "1"
T1   A18    V2      2*        >L>   "a"
T1   A18    V2      2*        >A>   "a"
T1   A18    V2      2*        >F>   ARG => "an Array"
T1   A18    V2      2*        >A>   "an Array"
T1   A18    V2      2*        >>>   "an Array"
T1   A18    V2      2*    181 *-* status = .Coactivity~running
T1   A18    V2      2*        >E>   .COACTIVITY => "The Coactivity class"
T1   A18    V2      2*        >M>   "RUNNING" => "2"
T1   A18    V2      2*        >>>   "2"
T1   A18    V2      2*        >=>   STATUS <= "2"
T1   A18    V2      2*    182 *-* guard off
T1   A18    V2      1     183 *-* guard on when status <> .Coactivity~running
T1   A18    V2      2*        >V>   STATUS => "2"
T1   A18    V2      2*        >E>   .COACTIVITY => "The Coactivity class"
T1   A18    V2      2*        >M>   "RUNNING" => "2"
T1   A18    V2      2*        >O>   "<>" => "0"
T1   A18    V2      2*        >>>   "0"
Deadlock here : both T1 and T2 are waiting...
*/


/***************************************************************
Trace output when no deadlock (.coactivity~pipe is unguarded)
****************************************************************
T1   A1     V1                >I> Method INIT with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
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
T1   A2                       >I> Routine d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A3                       >I> Routine d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\pipeline\pipe.rex in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\pipeline\pipe.rex
T1   A4                    24 *-* call Doers.AddVisibilityFrom(.context)
T1   A4                       >E>   .CONTEXT => "a RexxContext"
T1   A4                       >A>   "a RexxContext"
T1   A4                    26 *-* .coactivity~new('.coactivity~yield("a") ; .coactivity~yield("b")')~pipe(.upper|.console)
T1   A4                       >E>   .COACTIVITY => "The Coactivity class"
T1   A4                       >L>   ".coactivity~yield("a") ; .coactivity~yield("b")"
T1   A4                       >A>   ".coactivity~yield("a") ; .coactivity~yield("b")"
T1   A5     V2                >I> Method INIT with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A5     V2             83 *-* use strict arg action="main", start=.true, context=.nil, self~object=(self)
T1   A5     V2                >>>   ".coactivity~yield("a") ; .coactivity~yield("b")"
T1   A5     V2                >=>   ACTION <= ".coactivity~yield("a") ; .coactivity~yield("b")"
T1   A5     V2                >E>   .TRUE => "1"
T1   A5     V2                >>>   "1"
T1   A5     V2                >=>   START <= "1"
T1   A5     V2                >E>   .NIL => "The NIL object"
T1   A5     V2                >>>   "The NIL object"
T1   A5     V2                >=>   CONTEXT <= "The NIL object"
T1   A5     V2                >V>   SELF => "a Coactivity"
T1   A5     V2                >>>   "a Coactivity"
T1   A5     V2                >V>   SELF => "a Coactivity"
T1   A5     V2             85 *-* self~doer = action~doer(context)
T1   A5     V2                >V>   SELF => "a Coactivity"
T1   A5     V2                >V>   ACTION => ".coactivity~yield("a") ; .coactivity~yield("b")"
T1   A5     V2                >V>   CONTEXT => "The NIL object"
T1   A5     V2                >A>   "The NIL object"
T1   A5     V2                >M>   "DOER" => "a Routine"
T1   A5     V2                >A>   "a Routine"
T1   A5     V2                >>>   "a Routine"
T1   A5     V2             86 *-* self~status = .Coactivity~notStarted
T1   A5     V2                >V>   SELF => "a Coactivity"
T1   A5     V2                >E>   .COACTIVITY => "The Coactivity class"
T1   A5     V2                >M>   "NOTSTARTED" => "0"
T1   A5     V2                >A>   "0"
T1   A5     V2                >>>   "0"
T1   A5     V2             87 *-* if start
T1   A5     V2                >V>   START => "1"
T1   A5     V2                >>>   "1"
T1   A5     V2             87 *-*   then
T1   A5     V2             87 *-*     self~start
T1   A5     V2                >V>       SELF => "a Coactivity"
T1   A6     V2                >I> Method START with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A6     V2      1*     97 *-* expose status
T1   A6     V2      1*     98 *-* use strict arg -- no arg
T1   A6     V2      1*     99 *-* if status <> .Coactivity~notStarted
T1   A6     V2      1*        >V>   STATUS => "0"
T1   A6     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A6     V2      1*        >M>   "NOTSTARTED" => "0"
T1   A6     V2      1*        >O>   "<>" => "0"
T1   A6     V2      1*        >>>   "0"
T1   A6     V2      1*    100 *-* status = .Coactivity~suspended
T1   A6     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A6     V2      1*        >M>   "SUSPENDED" => "1"
T1   A6     V2      1*        >>>   "1"
T1   A6     V2      1*        >=>   STATUS <= "1"
T1   A6     V2      1*    101 *-* reply self
T1   A6     V2      1*        >V>   SELF => "a Coactivity"
T1   A6     V2      1*        >>>   "a Coactivity"
T2   A6     V2      1*        >I> Method START with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A5     V2      1         >>>       "a Coactivity"
T2   A6     V2      1*    102 *-* .Activity~local~empty
T1   A4                       >M>   "NEW" => "a Coactivity"
T2   A6     V2      1*        >E>   .ACTIVITY => "The ACTIVITY class"
T1   A4                       >E>   .UPPER => "The UPPER class"
T1   A4                       >E>   .CONSOLE => "The CONSOLE class"
T2   A6     V2      1*        >M>   "LOCAL" => "a Directory"
T1   A7     V3                >I> Method | with scope "The PIPESTAGE class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\pipeline\pipe.rex
T2   A6     V2      1*    103 *-* .Activity~local~coactivity = self
T1   A7     V3      1*     66 *-* use strict arg follower
T2   A6     V2      1*        >E>   .ACTIVITY => "The ACTIVITY class"
T1   A7     V3      1*        >>>   "The CONSOLE class"
T2   A6     V2      1*        >M>   "LOCAL" => "a Directory"
T1   A7     V3      1*        >=>   FOLLOWER <= "The CONSOLE class"
T2   A6     V2      1*        >V>   SELF => "a Coactivity"
T1   A7     V3      1*     67 *-* me = self~new                               -- create a new pipeStage instance
T2   A6     V2      1*        >A>   "a Coactivity"
T1   A7     V3      1*        >V>   SELF => "The UPPER class"
T2   A6     V2      1*    104 *-* .Coactivity~table[self] = self
T1   A8     V4                >I> Method INIT with scope "The PIPESTAGE class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\pipeline\pipe.rex
T2   A6     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A8     V4      1*     61 *-* expose next secondary
T2   A6     V2      1*        >M>   "TABLE" => "an IdentityTable"
T1   A8     V4      1*     62 *-* next = .nil
T2   A6     V2      1*        >V>   SELF => "a Coactivity"
T1   A8     V4      1*        >E>   .NIL => "The NIL object"
T2   A6     V2      1*        >A>   "a Coactivity"
T1   A8     V4      1*        >>>   "The NIL object"
T2   A6     V2      1*        >V>   SELF => "a Coactivity"
T1   A8     V4      1*        >=>   NEXT <= "The NIL object"
T2   A6     V2      1*        >A>   "a Coactivity"
T1   A8     V4      1*     63 *-* secondary = .nil                            -- all pipeStages have a secondary output potential
T2   A6     V2      1*    105 *-* signal on any name trapCondition -- catch all
T1   A8     V4      1*        >E>   .NIL => "The NIL object"
T2   A6     V2      1*    106 *-* signal on syntax name trapCondition -- gives better messages
T1   A8     V4      1*        >>>   "The NIL object"
T2   A6     V2      1*    107 *-* guard off
T1   A8     V4      1*        >=>   SECONDARY <= "The NIL object"
T2   A6     V2            108 *-* guard on when status <> .Coactivity~suspended
T1   A7     V3      1*        >M>   "NEW" => "an UPPER"
T2   A6     V2      1*        >V>   STATUS => "1"
T1   A7     V3      1*        >>>   "an UPPER"
T2   A6     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A7     V3      1*        >=>   ME <= "an UPPER"
T2   A6     V2      1*        >M>   "SUSPENDED" => "1"
T1   A7     V3      1*     68 *-* return me|follower                          -- perform the hook up
T2   A6     V2      1*        >O>   "<>" => "0"
T1   A7     V3      1*        >V>   ME => "an UPPER"
T2   A6     V2      1*        >>>   "0"
T1   A7     V3      1*        >V>   FOLLOWER => "The CONSOLE class"
T1   A9     V4                >I> Method | with scope "The PIPESTAGE class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\pipeline\pipe.rex
T1   A9     V4      1*     81 *-* use strict arg follower
T1   A9     V4      1*        >>>   "The CONSOLE class"
T1   A9     V4      1*        >=>   FOLLOWER <= "The CONSOLE class"
T1   A9     V4      1*     82 *-* follower = follower~new                     -- make sure this is an instance
T1   A9     V4      1*        >V>   FOLLOWER => "The CONSOLE class"
T1   A10    V5                >I> Method INIT with scope "The PIPESTAGE class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\pipeline\pipe.rex
T1   A10    V5      1*     61 *-* expose next secondary
T1   A10    V5      1*     62 *-* next = .nil
T1   A10    V5      1*        >E>   .NIL => "The NIL object"
T1   A10    V5      1*        >>>   "The NIL object"
T1   A10    V5      1*        >=>   NEXT <= "The NIL object"
T1   A10    V5      1*     63 *-* secondary = .nil                            -- all pipeStages have a secondary output potential
T1   A10    V5      1*        >E>   .NIL => "The NIL object"
T1   A10    V5      1*        >>>   "The NIL object"
T1   A10    V5      1*        >=>   SECONDARY <= "The NIL object"
T1   A9     V4      1*        >M>   "NEW" => "a CONSOLE"
T1   A9     V4      1*        >>>   "a CONSOLE"
T1   A9     V4      1*        >=>   FOLLOWER <= "a CONSOLE"
T1   A9     V4      1*     83 *-* self~append(follower)                       -- do the chain append logic
T1   A9     V4      1*        >V>   SELF => "an UPPER"
T1   A9     V4      1*        >V>   FOLLOWER => "a CONSOLE"
T1   A9     V4      1*        >A>   "a CONSOLE"
T1   A11    V4      1         >I> Method APPEND with scope "The PIPESTAGE class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\pipeline\pipe.rex
T1   A11    V4      2*     99 *-* expose next
T1   A11    V4      2*    100 *-* use strict arg follower
T1   A11    V4      2*        >>>   "a CONSOLE"
T1   A11    V4      2*        >=>   FOLLOWER <= "a CONSOLE"
T1   A11    V4      2*    101 *-* if .nil == next
T1   A11    V4      2*        >E>   .NIL => "The NIL object"
T1   A11    V4      2*        >V>   NEXT => "The NIL object"
T1   A11    V4      2*        >O>   "==" => "1"
T1   A11    V4      2*        >>>   "1"
T1   A11    V4      2*    101 *-*   then
T1   A11    V4      2*    101 *-*     do                     -- if we're the end already, just update the next
T1   A11    V4      2*    102 *-*       next = follower
T1   A11    V4      2*        >V>         FOLLOWER => "a CONSOLE"
T1   A11    V4      2*        >>>         "a CONSOLE"
T1   A11    V4      2*        >=>         NEXT <= "a CONSOLE"
T1   A11    V4      2*    103 *-*   end
T1   A9     V4      1*     84 *-* return self                                 -- we're our own return value
T1   A9     V4      1*        >V>   SELF => "an UPPER"
T1   A9     V4      1*        >>>   "an UPPER"
T1   A7     V3      1*        >O>   "|" => "an UPPER"
T1   A7     V3      1*        >>>   "an UPPER"
T1   A4                       >O>   "|" => "an UPPER"
T1   A4                       >A>   "an UPPER"
T1   A12    V4                >I> Method GO with scope "The PIPESTAGE class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\pipeline\pipe.rex
T1   A12    V4      1*    130 *-* expose source                               -- get the source supplier
T1   A12    V4      1*    131 *-* use strict arg source                       -- set to the supplied object
T1   A12    V4      1*        >>>   "a Coactivity"
T1   A12    V4      1*        >=>   SOURCE <= "a Coactivity"
T1   A12    V4      1*    132 *-* self~begin                                  -- now go feed the pipeline
T1   A12    V4      1*        >V>   SELF => "an UPPER"
T1   A13    V4      1         >I> Method BEGIN with scope "The PIPESTAGE class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\pipeline\pipe.rex
T1   A13    V4      2*    142 *-* expose source                               -- access the data and next chain
T1   A13    V4      2*    144 *-* engine = source~supplier                    -- get a data supplier
T1   A13    V4      2*        >V>   SOURCE => "a Coactivity"
T1   A14    V2                >I> Method SUPPLIER with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A14    V2            244 *-* return .LazyCoactivitySupplier~new(self)
T1   A14    V2                >E>   .LAZYCOACTIVITYSUPPLIER => "The LAZYCOACTIVITYSUPPLIER class"
T1   A14    V2                >V>   SELF => "a Coactivity"
T1   A14    V2                >A>   "a Coactivity"
T1   A15    V6                >I> Method INIT with scope "The LAZYCOACTIVITYSUPPLIER class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A15    V6      1*    281 *-* use strict arg coactivity
T1   A15    V6      1*        >>>   "a Coactivity"
T1   A15    V6      1*        >=>   COACTIVITY <= "a Coactivity"
T1   A15    V6      1*    282 *-* empty = .array~new(0) -- Lazy supplier
T1   A15    V6      1*        >E>   .ARRAY => "The Array class"
T1   A15    V6      1*        >L>   "0"
T1   A15    V6      1*        >A>   "0"
T1   A15    V6      1*        >M>   "NEW" => "an Array"
T1   A15    V6      1*        >>>   "an Array"
T1   A15    V6      1*        >=>   EMPTY <= "an Array"
T1   A15    V6      1*    283 *-* self~init:super(empty, empty)
T1   A15    V6      1*        >V>   SELF => "a LAZYCOACTIVITYSUPPLIER"
T1   A15    V6      1*        >V>   SUPER => "The Supplier class"
T1   A15    V6      1*        >V>   EMPTY => "an Array"
T1   A15    V6      1*        >A>   "an Array"
T1   A15    V6      1*        >V>   EMPTY => "an Array"
T1   A15    V6      1*        >A>   "an Array"
T1   A15    V6      1*    284 *-* self~coactivity = coactivity
T1   A15    V6      1*        >V>   SELF => "a LAZYCOACTIVITYSUPPLIER"
T1   A15    V6      1*        >V>   COACTIVITY => "a Coactivity"
T1   A15    V6      1*        >A>   "a Coactivity"
T1   A15    V6      1*        >>>   "a Coactivity"
T1   A15    V6      1*    285 *-* if \self~coactivity~isStarted
T1   A15    V6      1*        >V>   SELF => "a LAZYCOACTIVITYSUPPLIER"
T1   A15    V6      1*        >M>   "COACTIVITY" => "a Coactivity"
T1   A16    V2                >I> Method ISSTARTED with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A16    V2      1*    205 *-* return self~status <> .Coactivity~notStarted
T1   A16    V2      1*        >V>   SELF => "a Coactivity"
T1   A16    V2      1*        >M>   "STATUS" => "1"
T1   A16    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A16    V2      1*        >M>   "NOTSTARTED" => "0"
T1   A16    V2      1*        >O>   "<>" => "1"
T1   A16    V2      1*        >>>   "1"
T1   A15    V6      1*        >M>   "ISSTARTED" => "1"
T1   A15    V6      1*        >P>   "\" => "0"
T1   A15    V6      1*        >>>   "0"
T1   A15    V6      1*    286 *-* self~currentIndex = 0
T1   A15    V6      1*        >V>   SELF => "a LAZYCOACTIVITYSUPPLIER"
T1   A15    V6      1*        >L>   "0"
T1   A15    V6      1*        >A>   "0"
T1   A15    V6      1*        >>>   "0"
T1   A15    V6      1*    287 *-* self~next
T1   A15    V6      1*        >V>   SELF => "a LAZYCOACTIVITYSUPPLIER"
T1   A17    V6      1         >I> Method NEXT with scope "The LAZYCOACTIVITYSUPPLIER class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A17    V6      2*    303 *-* expose currentItem
T1   A17    V6      2*    304 *-* self~coactivity~resume
T1   A17    V6      2*        >V>   SELF => "a LAZYCOACTIVITYSUPPLIER"
T1   A17    V6      2*        >M>   "COACTIVITY" => "a Coactivity"
T1   A18    V2                >I> Method RESUME with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A18    V2      1*    176 *-* expose status yieldValue
T1   A18    V2      1*    177 *-* if status == .Coactivity~notStarted
T1   A18    V2      1*        >V>   STATUS => "1"
T1   A18    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A18    V2      1*        >M>   "NOTSTARTED" => "0"
T1   A18    V2      1*        >O>   "==" => "0"
T1   A18    V2      1*        >>>   "0"
T1   A18    V2      1*    178 *-* if status == .Coactivity~killed
T1   A18    V2      1*        >V>   STATUS => "1"
T1   A18    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A18    V2      1*        >M>   "KILLED" => "4"
T1   A18    V2      1*        >O>   "==" => "0"
T1   A18    V2      1*        >>>   "0"
T1   A18    V2      1*    179 *-* if status == .Coactivity~ended
T1   A18    V2      1*        >V>   STATUS => "1"
T1   A18    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A18    V2      1*        >M>   "ENDED" => "3"
T1   A18    V2      1*        >O>   "==" => "0"
T1   A18    V2      1*        >>>   "0"
T1   A18    V2      1*    180 *-* self~arguments = arg(1, "a")
T1   A18    V2      1*        >V>   SELF => "a Coactivity"
T1   A18    V2      1*        >L>   "1"
T1   A18    V2      1*        >A>   "1"
T1   A18    V2      1*        >L>   "a"
T1   A18    V2      1*        >A>   "a"
T1   A18    V2      1*        >F>   ARG => "an Array"
T1   A18    V2      1*        >A>   "an Array"
T1   A18    V2      1*        >>>   "an Array"
T1   A18    V2      1*    181 *-* status = .Coactivity~running
T1   A18    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A18    V2      1*        >M>   "RUNNING" => "2"
T1   A18    V2      1*        >>>   "2"
T1   A18    V2      1*        >=>   STATUS <= "2"
T1   A18    V2      1*    182 *-* guard off
T1   A18    V2      1     183 *-* guard on when status <> .Coactivity~running
T2   A6     V2      1*        >V>   STATUS => "2"
T2   A6     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T2   A6     V2      1*        >M>   "SUSPENDED" => "1"
T2   A6     V2      1*        >O>   "<>" => "1"
T2   A6     V2      1*        >>>   "1"
T2   A6     V2      1*    109 *-* if status == .Coactivity~running
T2   A6     V2      1*        >V>   STATUS => "2"
T2   A6     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T2   A6     V2      1*        >M>   "RUNNING" => "2"
T2   A6     V2      1*        >O>   "==" => "1"
T2   A6     V2      1*        >>>   "1"
T2   A6     V2      1*    109 *-*   then
T2   A6     V2      1*    109 *-*     do
T2   A6     V2      1*    110 *-*       guard off
T2   A6     V2      1     112 *-*       if self~doer~needsObject
T1   A18    V2      1*        >V>   STATUS => "2"
T2   A6     V2      1         >V>         SELF => "a Coactivity"
T1   A18    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A18    V2      1*        >M>   "RUNNING" => "2"
T1   A18    V2      1*        >O>   "<>" => "0"
T1   A18    V2      1*        >>>   "0"
T2   A6     V2                >M>         "DOER" => "a Routine"
T2   A6     V2                >M>         "NEEDSOBJECT" => "0"
T2   A6     V2                >>>         "0"
T2   A6     V2            113 *-*         else
T2   A6     V2            113 *-*           self~doer~doWith(self~arguments) -- no object needed (routine)
T2   A6     V2                >V>             SELF => "a Coactivity"
T2   A6     V2                >M>             "DOER" => "a Routine"
T2   A6     V2                >V>             SELF => "a Coactivity"
T2   A6     V2                >M>             "ARGUMENTS" => "an Array"
T2   A6     V2                >A>             "an Array"
T2   A19    V1                >I> Method YIELD with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T2   A19    V1            143 *-* coactivity = .Activity~local~coactivity
T2   A19    V1                >E>   .ACTIVITY => "The ACTIVITY class"
T2   A19    V1                >M>   "LOCAL" => "a Directory"
T2   A19    V1                >M>   "COACTIVITY" => "a Coactivity"
T2   A19    V1                >>>   "a Coactivity"
T2   A19    V1                >=>   COACTIVITY <= "a Coactivity"
T2   A19    V1            144 *-* if coactivity == .nil
T2   A19    V1                >V>   COACTIVITY => "a Coactivity"
T2   A19    V1                >E>   .NIL => "The NIL object"
T2   A19    V1                >O>   "==" => "0"
T2   A19    V1                >>>   "0"
T2   A19    V1            145 *-* forward to (coactivity)
T2   A19    V1                >V>   COACTIVITY => "a Coactivity"
T2   A20    V2                >I> Method YIELD with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T2   A20    V2      1*    151 *-* expose status yieldValue
T2   A20    V2      1*    152 *-* drop yieldValue
T2   A20    V2      1*    153 *-* if status == .Coactivity~killed
T2   A20    V2      1*        >V>   STATUS => "2"
T2   A20    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T2   A20    V2      1*        >M>   "KILLED" => "4"
T2   A20    V2      1*        >O>   "==" => "0"
T2   A20    V2      1*        >>>   "0"
T2   A20    V2      1*    154 *-* if status == .Coactivity~ended
T2   A20    V2      1*        >V>   STATUS => "2"
T2   A20    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T2   A20    V2      1*        >M>   "ENDED" => "3"
T2   A20    V2      1*        >O>   "==" => "0"
T2   A20    V2      1*        >>>   "0"
T2   A20    V2      1*    155 *-* if arg() <> 0
T2   A20    V2      1*        >F>   ARG => "1"
T2   A20    V2      1*        >L>   "0"
T2   A20    V2      1*        >O>   "<>" => "1"
T2   A20    V2      1*        >>>   "1"
T2   A20    V2      1*    155 *-*   then
T2   A20    V2      1*    155 *-*     use strict arg yieldValue -- yieldValue will be returned to the Coactivity's client by 'resume'
T2   A20    V2      1*        >>>       "a"
T2   A20    V2      1*        >=>       YIELDVALUE <= "a"
T2   A20    V2      1*    156 *-* status = .Coactivity~suspended
T2   A20    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T2   A20    V2      1*        >M>   "SUSPENDED" => "1"
T2   A20    V2      1*        >>>   "1"
T2   A20    V2      1*        >=>   STATUS <= "1"
T2   A20    V2      1*    157 *-* guard off
T2   A20    V2      1     158 *-* guard on when status <> .Coactivity~suspended
T1   A18    V2      1*        >V>   STATUS => "1"
T1   A18    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A18    V2      1*        >M>   "RUNNING" => "2"
T1   A18    V2      1*        >O>   "<>" => "1"
T1   A18    V2      1*        >>>   "1"
T1   A18    V2      1*    184 *-* if status == .Coactivity~killed
T1   A18    V2      1*        >V>   STATUS => "1"
T1   A18    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A18    V2      1*        >M>   "KILLED" => "4"
T1   A18    V2      1*        >O>   "==" => "0"
T1   A18    V2      1*        >>>   "0"
T1   A18    V2      1*    185 *-* if var("yieldValue")
T1   A18    V2      1*        >L>   "yieldValue"
T1   A18    V2      1*        >A>   "yieldValue"
T1   A18    V2      1*        >F>   VAR => "1"
T1   A18    V2      1*        >>>   "1"
T1   A18    V2      1*    185 *-*   then
T1   A18    V2      1*    185 *-*     return yieldValue
T1   A18    V2      1*        >V>       YIELDVALUE => "a"
T1   A18    V2      1*        >>>       "a"
T1   A17    V6      2*        >>>   "a"
T2   A20    V2      1*        >V>   STATUS => "1"
T1   A17    V6      2*    305 *-* drop currentItem
T2   A20    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A17    V6      2*    306 *-* if var("result")
T2   A20    V2      1*        >M>   "SUSPENDED" => "1"
T1   A17    V6      2*        >L>   "result"
T2   A20    V2      1*        >O>   "<>" => "0"
T1   A17    V6      2*        >A>   "result"
T2   A20    V2      1*        >>>   "0"
T1   A17    V6      2*        >F>   VAR => "1"
T1   A17    V6      2*        >>>   "1"
T1   A17    V6      2*    306 *-*   then
T1   A17    V6      2*    306 *-*     do
T1   A17    V6      2*    307 *-*       self~currentItem = result
T1   A17    V6      2*        >V>         SELF => "a LAZYCOACTIVITYSUPPLIER"
T1   A17    V6      2*        >V>         RESULT => "a"
T1   A17    V6      2*        >A>         "a"
T1   A17    V6      2*        >>>         "a"
T1   A17    V6      2*    308 *-*       self~currentIndex += 1
T1   A17    V6      2*        >V>         SELF => "a LAZYCOACTIVITYSUPPLIER"
T1   A17    V6      2*        >V>         SELF => "a LAZYCOACTIVITYSUPPLIER"
T1   A17    V6      2*        >M>         "CURRENTINDEX" => "0"
T1   A17    V6      2*        >L>         "1"
T1   A17    V6      2*        >O>         "+" => "1"
T1   A17    V6      2*        >A>         "1"
T1   A17    V6      2*        >>>         "1"
T1   A17    V6      2*    309 *-*       self~isAvailable = .true
T1   A17    V6      2*        >V>         SELF => "a LAZYCOACTIVITYSUPPLIER"
T1   A17    V6      2*        >E>         .TRUE => "1"
T1   A17    V6      2*        >A>         "1"
T1   A17    V6      2*        >>>         "1"
T1   A17    V6      2*    310 *-*   end
T1   A14    V2                >M>   "NEW" => "a LAZYCOACTIVITYSUPPLIER"
T1   A14    V2                >>>   "a LAZYCOACTIVITYSUPPLIER"
T1   A13    V4      2*        >M>   "SUPPLIER" => "a LAZYCOACTIVITYSUPPLIER"
T1   A13    V4      2*        >>>   "a LAZYCOACTIVITYSUPPLIER"
T1   A13    V4      2*        >=>   ENGINE <= "a LAZYCOACTIVITYSUPPLIER"
T1   A13    V4      2*    145 *-* do while engine~available                   -- while more data
T1   A13    V4      2*        >V>     ENGINE => "a LAZYCOACTIVITYSUPPLIER"
T1   A21    V6                >I> Method AVAILABLE with scope "The LAZYCOACTIVITYSUPPLIER class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A21    V6      1*    291 *-* return self~isAvailable
T1   A21    V6      1*        >V>   SELF => "a LAZYCOACTIVITYSUPPLIER"
T1   A21    V6      1*        >M>   "ISAVAILABLE" => "1"
T1   A21    V6      1*        >>>   "1"
T1   A13    V4      2*        >M>     "AVAILABLE" => "1"
T1   A13    V4      2*        >>>     "1"
T1   A13    V4      2*    146 *-*   self~process(engine~item)                 -- pump this down the pipe
T1   A13    V4      2*        >V>     SELF => "an UPPER"
T1   A13    V4      2*        >V>     ENGINE => "a LAZYCOACTIVITYSUPPLIER"
T1   A22    V6                >I> Method ITEM with scope "The LAZYCOACTIVITYSUPPLIER class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A22    V6      1*    299 *-* if self~isAvailable
T1   A22    V6      1*        >V>   SELF => "a LAZYCOACTIVITYSUPPLIER"
T1   A22    V6      1*        >M>   "ISAVAILABLE" => "1"
T1   A22    V6      1*        >>>   "1"
T1   A22    V6      1*    299 *-*   then
T1   A22    V6      1*    299 *-*     return self~currentItem
T1   A22    V6      1*        >V>       SELF => "a LAZYCOACTIVITYSUPPLIER"
T1   A22    V6      1*        >M>       "CURRENTITEM" => "a"
T1   A22    V6      1*        >>>       "a"
T1   A13    V4      2*        >M>     "ITEM" => "a"
T1   A13    V4      2*        >A>     "a"
T1   A23    V7                >I> Method PROCESS with scope "The UPPER class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\pipeline\pipe.rex
T1   A23    V7      1*    257 *-* use strict arg value                        -- get the data item
T1   A23    V7      1*        >>>   "a"
T1   A23    V7      1*        >=>   VALUE <= "a"
T1   A23    V7      1*    258 *-* self~write(value~upper)                     -- send it along in upper form
T1   A23    V7      1*        >V>   SELF => "an UPPER"
T1   A23    V7      1*        >V>   VALUE => "a"
T1   A23    V7      1*        >M>   "UPPER" => "A"
T1   A23    V7      1*        >A>   "A"
T1   A24    V4      2         >I> Method WRITE with scope "The PIPESTAGE class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\pipeline\pipe.rex
T1   A24    V4      3*    156 *-* expose next
T1   A24    V4      3*    157 *-* use strict arg data
T1   A24    V4      3*        >>>   "A"
T1   A24    V4      3*        >=>   DATA <= "A"
T1   A24    V4      3*    158 *-* if .nil <> next
T1   A24    V4      3*        >E>   .NIL => "The NIL object"
T1   A24    V4      3*        >V>   NEXT => "a CONSOLE"
T1   A24    V4      3*        >O>   "<>" => "1"
T1   A24    V4      3*        >>>   "1"
T1   A24    V4      3*    158 *-*   then
T1   A24    V4      3*    158 *-*     do
T1   A24    V4      3*    159 *-*       next~process(data)                      -- only forward if we have a successor
T1   A24    V4      3*        >V>         NEXT => "a CONSOLE"
T1   A24    V4      3*        >V>         DATA => "A"
T1   A24    V4      3*        >A>         "A"
T1   A25    V8                >I> Method PROCESS with scope "The CONSOLE class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\pipeline\pipe.rex
T1   A25    V8      1*    579 *-* use strict arg value                        -- get the data value
T1   A25    V8      1*        >>>   "A"
T1   A25    V8      1*        >=>   VALUE <= "A"
T1   A25    V8      1*    580 *-* say value                                   -- display this item
T1   A25    V8      1*        >V>   VALUE => "A"
T1   A25    V8      1*        >>>   "A"
A
T1   A25    V8      1*    581 *-* forward class(super)
T1   A25    V8      1*        >V>   SUPER => "The PIPESTAGE class"
T1   A26    V5                >I> Method PROCESS with scope "The PIPESTAGE class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\pipeline\pipe.rex
T1   A26    V5      1*    152 *-* use strict arg value                        -- get the data item
T1   A26    V5      1*        >>>   "A"
T1   A26    V5      1*        >=>   VALUE <= "A"
T1   A26    V5      1*    153 *-* self~write(value)                           -- send this down the line
T1   A26    V5      1*        >V>   SELF => "a CONSOLE"
T1   A26    V5      1*        >V>   VALUE => "A"
T1   A26    V5      1*        >A>   "A"
T1   A27    V5      1         >I> Method WRITE with scope "The PIPESTAGE class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\pipeline\pipe.rex
T1   A27    V5      2*    156 *-* expose next
T1   A27    V5      2*    157 *-* use strict arg data
T1   A27    V5      2*        >>>   "A"
T1   A27    V5      2*        >=>   DATA <= "A"
T1   A27    V5      2*    158 *-* if .nil <> next
T1   A27    V5      2*        >E>   .NIL => "The NIL object"
T1   A27    V5      2*        >V>   NEXT => "The NIL object"
T1   A27    V5      2*        >O>   "<>" => "0"
T1   A27    V5      2*        >>>   "0"
T1   A24    V4      3*    160 *-*   end
T1   A13    V4      2*    147 *-*   engine~next                               -- get the next data item
T1   A13    V4      2*        >V>     ENGINE => "a LAZYCOACTIVITYSUPPLIER"
T1   A28    V6                >I> Method NEXT with scope "The LAZYCOACTIVITYSUPPLIER class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A28    V6      1*    303 *-* expose currentItem
T1   A28    V6      1*    304 *-* self~coactivity~resume
T1   A28    V6      1*        >V>   SELF => "a LAZYCOACTIVITYSUPPLIER"
T1   A28    V6      1*        >M>   "COACTIVITY" => "a Coactivity"
T1   A29    V2                >I> Method RESUME with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A29    V2      1*    176 *-* expose status yieldValue
T1   A29    V2      1*    177 *-* if status == .Coactivity~notStarted
T1   A29    V2      1*        >V>   STATUS => "1"
T1   A29    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A29    V2      1*        >M>   "NOTSTARTED" => "0"
T1   A29    V2      1*        >O>   "==" => "0"
T1   A29    V2      1*        >>>   "0"
T1   A29    V2      1*    178 *-* if status == .Coactivity~killed
T1   A29    V2      1*        >V>   STATUS => "1"
T1   A29    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A29    V2      1*        >M>   "KILLED" => "4"
T1   A29    V2      1*        >O>   "==" => "0"
T1   A29    V2      1*        >>>   "0"
T1   A29    V2      1*    179 *-* if status == .Coactivity~ended
T1   A29    V2      1*        >V>   STATUS => "1"
T1   A29    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A29    V2      1*        >M>   "ENDED" => "3"
T1   A29    V2      1*        >O>   "==" => "0"
T1   A29    V2      1*        >>>   "0"
T1   A29    V2      1*    180 *-* self~arguments = arg(1, "a")
T1   A29    V2      1*        >V>   SELF => "a Coactivity"
T1   A29    V2      1*        >L>   "1"
T1   A29    V2      1*        >A>   "1"
T1   A29    V2      1*        >L>   "a"
T1   A29    V2      1*        >A>   "a"
T1   A29    V2      1*        >F>   ARG => "an Array"
T1   A29    V2      1*        >A>   "an Array"
T1   A29    V2      1*        >>>   "an Array"
T1   A29    V2      1*    181 *-* status = .Coactivity~running
T1   A29    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A29    V2      1*        >M>   "RUNNING" => "2"
T1   A29    V2      1*        >>>   "2"
T1   A29    V2      1*        >=>   STATUS <= "2"
T1   A29    V2      1*    182 *-* guard off
T1   A29    V2      1     183 *-* guard on when status <> .Coactivity~running
T2   A20    V2      1*        >V>   STATUS => "2"
T2   A20    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T2   A20    V2      1*        >M>   "SUSPENDED" => "1"
T2   A20    V2      1*        >O>   "<>" => "1"
T2   A20    V2      1*        >>>   "1"
T2   A20    V2      1*    159 *-* if status == .Coactivity~killed
T2   A20    V2      1*        >V>   STATUS => "2"
T2   A20    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T2   A20    V2      1*        >M>   "KILLED" => "4"
T2   A20    V2      1*        >O>   "==" => "0"
T2   A20    V2      1*        >>>   "0"
T2   A20    V2      1*    160 *-* if status == .Coactivity~ended
T2   A20    V2      1*        >V>   STATUS => "2"
T2   A20    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T2   A20    V2      1*        >M>   "ENDED" => "3"
T2   A20    V2      1*        >O>   "==" => "0"
T2   A20    V2      1*        >>>   "0"
T2   A20    V2      1*    161 *-* return self~arguments -- returns the arguments that the coactivity's client passed to 'resume'
T2   A20    V2      1*        >V>   SELF => "a Coactivity"
T2   A20    V2      1*        >M>   "ARGUMENTS" => "an Array"
T2   A20    V2      1*        >>>   "an Array"
T2   A30    V1                >I> Method YIELD with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A29    V2      1*        >V>   STATUS => "2"
T2   A30    V1            143 *-* coactivity = .Activity~local~coactivity
T1   A29    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T2   A30    V1                >E>   .ACTIVITY => "The ACTIVITY class"
T1   A29    V2      1*        >M>   "RUNNING" => "2"
T2   A30    V1                >M>   "LOCAL" => "a Directory"
T1   A29    V2      1*        >O>   "<>" => "0"
T2   A30    V1                >M>   "COACTIVITY" => "a Coactivity"
T1   A29    V2      1*        >>>   "0"
T2   A30    V1                >>>   "a Coactivity"
T2   A30    V1                >=>   COACTIVITY <= "a Coactivity"
T2   A30    V1            144 *-* if coactivity == .nil
T2   A30    V1                >V>   COACTIVITY => "a Coactivity"
T2   A30    V1                >E>   .NIL => "The NIL object"
T2   A30    V1                >O>   "==" => "0"
T2   A30    V1                >>>   "0"
T2   A30    V1            145 *-* forward to (coactivity)
T2   A30    V1                >V>   COACTIVITY => "a Coactivity"
T2   A31    V2                >I> Method YIELD with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T2   A31    V2      1*    151 *-* expose status yieldValue
T2   A31    V2      1*    152 *-* drop yieldValue
T2   A31    V2      1*    153 *-* if status == .Coactivity~killed
T2   A31    V2      1*        >V>   STATUS => "2"
T2   A31    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T2   A31    V2      1*        >M>   "KILLED" => "4"
T2   A31    V2      1*        >O>   "==" => "0"
T2   A31    V2      1*        >>>   "0"
T2   A31    V2      1*    154 *-* if status == .Coactivity~ended
T2   A31    V2      1*        >V>   STATUS => "2"
T2   A31    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T2   A31    V2      1*        >M>   "ENDED" => "3"
T2   A31    V2      1*        >O>   "==" => "0"
T2   A31    V2      1*        >>>   "0"
T2   A31    V2      1*    155 *-* if arg() <> 0
T2   A31    V2      1*        >F>   ARG => "1"
T2   A31    V2      1*        >L>   "0"
T2   A31    V2      1*        >O>   "<>" => "1"
T2   A31    V2      1*        >>>   "1"
T2   A31    V2      1*    155 *-*   then
T2   A31    V2      1*    155 *-*     use strict arg yieldValue -- yieldValue will be returned to the Coactivity's client by 'resume'
T2   A31    V2      1*        >>>       "b"
T2   A31    V2      1*        >=>       YIELDVALUE <= "b"
T2   A31    V2      1*    156 *-* status = .Coactivity~suspended
T2   A31    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T2   A31    V2      1*        >M>   "SUSPENDED" => "1"
T2   A31    V2      1*        >>>   "1"
T2   A31    V2      1*        >=>   STATUS <= "1"
T2   A31    V2      1*    157 *-* guard off
T2   A31    V2      1     158 *-* guard on when status <> .Coactivity~suspended
T1   A29    V2      1*        >V>   STATUS => "1"
T1   A29    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A29    V2      1*        >M>   "RUNNING" => "2"
T1   A29    V2      1*        >O>   "<>" => "1"
T1   A29    V2      1*        >>>   "1"
T1   A29    V2      1*    184 *-* if status == .Coactivity~killed
T1   A29    V2      1*        >V>   STATUS => "1"
T1   A29    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A29    V2      1*        >M>   "KILLED" => "4"
T1   A29    V2      1*        >O>   "==" => "0"
T1   A29    V2      1*        >>>   "0"
T1   A29    V2      1*    185 *-* if var("yieldValue")
T1   A29    V2      1*        >L>   "yieldValue"
T1   A29    V2      1*        >A>   "yieldValue"
T1   A29    V2      1*        >F>   VAR => "1"
T1   A29    V2      1*        >>>   "1"
T1   A29    V2      1*    185 *-*   then
T1   A29    V2      1*    185 *-*     return yieldValue
T1   A29    V2      1*        >V>       YIELDVALUE => "b"
T1   A29    V2      1*        >>>       "b"
T1   A28    V6      1*        >>>   "b"
T2   A31    V2      1*        >V>   STATUS => "1"
T1   A28    V6      1*    305 *-* drop currentItem
T2   A31    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A28    V6      1*    306 *-* if var("result")
T2   A31    V2      1*        >M>   "SUSPENDED" => "1"
T1   A28    V6      1*        >L>   "result"
T2   A31    V2      1*        >O>   "<>" => "0"
T1   A28    V6      1*        >A>   "result"
T2   A31    V2      1*        >>>   "0"
T1   A28    V6      1*        >F>   VAR => "1"
T1   A28    V6      1*        >>>   "1"
T1   A28    V6      1*    306 *-*   then
T1   A28    V6      1*    306 *-*     do
T1   A28    V6      1*    307 *-*       self~currentItem = result
T1   A28    V6      1*        >V>         SELF => "a LAZYCOACTIVITYSUPPLIER"
T1   A28    V6      1*        >V>         RESULT => "b"
T1   A28    V6      1*        >A>         "b"
T1   A28    V6      1*        >>>         "b"
T1   A28    V6      1*    308 *-*       self~currentIndex += 1
T1   A28    V6      1*        >V>         SELF => "a LAZYCOACTIVITYSUPPLIER"
T1   A28    V6      1*        >V>         SELF => "a LAZYCOACTIVITYSUPPLIER"
T1   A28    V6      1*        >M>         "CURRENTINDEX" => "1"
T1   A28    V6      1*        >L>         "1"
T1   A28    V6      1*        >O>         "+" => "2"
T1   A28    V6      1*        >A>         "2"
T1   A28    V6      1*        >>>         "2"
T1   A28    V6      1*    309 *-*       self~isAvailable = .true
T1   A28    V6      1*        >V>         SELF => "a LAZYCOACTIVITYSUPPLIER"
T1   A28    V6      1*        >E>         .TRUE => "1"
T1   A28    V6      1*        >A>         "1"
T1   A28    V6      1*        >>>         "1"
T1   A28    V6      1*    310 *-*   end
T1   A13    V4      2*    148 *-* end
T1   A13    V4      2*    145 *-* do while engine~available                   -- while more data
T1   A13    V4      2*        >V>     ENGINE => "a LAZYCOACTIVITYSUPPLIER"
T1   A32    V6                >I> Method AVAILABLE with scope "The LAZYCOACTIVITYSUPPLIER class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A32    V6      1*    291 *-* return self~isAvailable
T1   A32    V6      1*        >V>   SELF => "a LAZYCOACTIVITYSUPPLIER"
T1   A32    V6      1*        >M>   "ISAVAILABLE" => "1"
T1   A32    V6      1*        >>>   "1"
T1   A13    V4      2*        >M>     "AVAILABLE" => "1"
T1   A13    V4      2*        >>>     "1"
T1   A13    V4      2*    146 *-*   self~process(engine~item)                 -- pump this down the pipe
T1   A13    V4      2*        >V>     SELF => "an UPPER"
T1   A13    V4      2*        >V>     ENGINE => "a LAZYCOACTIVITYSUPPLIER"
T1   A33    V6                >I> Method ITEM with scope "The LAZYCOACTIVITYSUPPLIER class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A33    V6      1*    299 *-* if self~isAvailable
T1   A33    V6      1*        >V>   SELF => "a LAZYCOACTIVITYSUPPLIER"
T1   A33    V6      1*        >M>   "ISAVAILABLE" => "1"
T1   A33    V6      1*        >>>   "1"
T1   A33    V6      1*    299 *-*   then
T1   A33    V6      1*    299 *-*     return self~currentItem
T1   A33    V6      1*        >V>       SELF => "a LAZYCOACTIVITYSUPPLIER"
T1   A33    V6      1*        >M>       "CURRENTITEM" => "b"
T1   A33    V6      1*        >>>       "b"
T1   A13    V4      2*        >M>     "ITEM" => "b"
T1   A13    V4      2*        >A>     "b"
T1   A34    V7                >I> Method PROCESS with scope "The UPPER class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\pipeline\pipe.rex
T1   A34    V7      1*    257 *-* use strict arg value                        -- get the data item
T1   A34    V7      1*        >>>   "b"
T1   A34    V7      1*        >=>   VALUE <= "b"
T1   A34    V7      1*    258 *-* self~write(value~upper)                     -- send it along in upper form
T1   A34    V7      1*        >V>   SELF => "an UPPER"
T1   A34    V7      1*        >V>   VALUE => "b"
T1   A34    V7      1*        >M>   "UPPER" => "B"
T1   A34    V7      1*        >A>   "B"
T1   A35    V4      2         >I> Method WRITE with scope "The PIPESTAGE class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\pipeline\pipe.rex
T1   A35    V4      3*    156 *-* expose next
T1   A35    V4      3*    157 *-* use strict arg data
T1   A35    V4      3*        >>>   "B"
T1   A35    V4      3*        >=>   DATA <= "B"
T1   A35    V4      3*    158 *-* if .nil <> next
T1   A35    V4      3*        >E>   .NIL => "The NIL object"
T1   A35    V4      3*        >V>   NEXT => "a CONSOLE"
T1   A35    V4      3*        >O>   "<>" => "1"
T1   A35    V4      3*        >>>   "1"
T1   A35    V4      3*    158 *-*   then
T1   A35    V4      3*    158 *-*     do
T1   A35    V4      3*    159 *-*       next~process(data)                      -- only forward if we have a successor
T1   A35    V4      3*        >V>         NEXT => "a CONSOLE"
T1   A35    V4      3*        >V>         DATA => "B"
T1   A35    V4      3*        >A>         "B"
T1   A36    V8                >I> Method PROCESS with scope "The CONSOLE class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\pipeline\pipe.rex
T1   A36    V8      1*    579 *-* use strict arg value                        -- get the data value
T1   A36    V8      1*        >>>   "B"
T1   A36    V8      1*        >=>   VALUE <= "B"
T1   A36    V8      1*    580 *-* say value                                   -- display this item
T1   A36    V8      1*        >V>   VALUE => "B"
T1   A36    V8      1*        >>>   "B"
B
T1   A36    V8      1*    581 *-* forward class(super)
T1   A36    V8      1*        >V>   SUPER => "The PIPESTAGE class"
T1   A37    V5                >I> Method PROCESS with scope "The PIPESTAGE class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\pipeline\pipe.rex
T1   A37    V5      1*    152 *-* use strict arg value                        -- get the data item
T1   A37    V5      1*        >>>   "B"
T1   A37    V5      1*        >=>   VALUE <= "B"
T1   A37    V5      1*    153 *-* self~write(value)                           -- send this down the line
T1   A37    V5      1*        >V>   SELF => "a CONSOLE"
T1   A37    V5      1*        >V>   VALUE => "B"
T1   A37    V5      1*        >A>   "B"
T1   A38    V5      1         >I> Method WRITE with scope "The PIPESTAGE class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\pipeline\pipe.rex
T1   A38    V5      2*    156 *-* expose next
T1   A38    V5      2*    157 *-* use strict arg data
T1   A38    V5      2*        >>>   "B"
T1   A38    V5      2*        >=>   DATA <= "B"
T1   A38    V5      2*    158 *-* if .nil <> next
T1   A38    V5      2*        >E>   .NIL => "The NIL object"
T1   A38    V5      2*        >V>   NEXT => "The NIL object"
T1   A38    V5      2*        >O>   "<>" => "0"
T1   A38    V5      2*        >>>   "0"
T1   A35    V4      3*    160 *-*   end
T1   A13    V4      2*    147 *-*   engine~next                               -- get the next data item
T1   A13    V4      2*        >V>     ENGINE => "a LAZYCOACTIVITYSUPPLIER"
T1   A39    V6                >I> Method NEXT with scope "The LAZYCOACTIVITYSUPPLIER class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A39    V6      1*    303 *-* expose currentItem
T1   A39    V6      1*    304 *-* self~coactivity~resume
T1   A39    V6      1*        >V>   SELF => "a LAZYCOACTIVITYSUPPLIER"
T1   A39    V6      1*        >M>   "COACTIVITY" => "a Coactivity"
T1   A40    V2                >I> Method RESUME with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A40    V2      1*    176 *-* expose status yieldValue
T1   A40    V2      1*    177 *-* if status == .Coactivity~notStarted
T1   A40    V2      1*        >V>   STATUS => "1"
T1   A40    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A40    V2      1*        >M>   "NOTSTARTED" => "0"
T1   A40    V2      1*        >O>   "==" => "0"
T1   A40    V2      1*        >>>   "0"
T1   A40    V2      1*    178 *-* if status == .Coactivity~killed
T1   A40    V2      1*        >V>   STATUS => "1"
T1   A40    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A40    V2      1*        >M>   "KILLED" => "4"
T1   A40    V2      1*        >O>   "==" => "0"
T1   A40    V2      1*        >>>   "0"
T1   A40    V2      1*    179 *-* if status == .Coactivity~ended
T1   A40    V2      1*        >V>   STATUS => "1"
T1   A40    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A40    V2      1*        >M>   "ENDED" => "3"
T1   A40    V2      1*        >O>   "==" => "0"
T1   A40    V2      1*        >>>   "0"
T1   A40    V2      1*    180 *-* self~arguments = arg(1, "a")
T1   A40    V2      1*        >V>   SELF => "a Coactivity"
T1   A40    V2      1*        >L>   "1"
T1   A40    V2      1*        >A>   "1"
T1   A40    V2      1*        >L>   "a"
T1   A40    V2      1*        >A>   "a"
T1   A40    V2      1*        >F>   ARG => "an Array"
T1   A40    V2      1*        >A>   "an Array"
T1   A40    V2      1*        >>>   "an Array"
T1   A40    V2      1*    181 *-* status = .Coactivity~running
T1   A40    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A40    V2      1*        >M>   "RUNNING" => "2"
T1   A40    V2      1*        >>>   "2"
T1   A40    V2      1*        >=>   STATUS <= "2"
T1   A40    V2      1*    182 *-* guard off
T1   A40    V2      1     183 *-* guard on when status <> .Coactivity~running
T2   A31    V2      1*        >V>   STATUS => "2"
T2   A31    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T2   A31    V2      1*        >M>   "SUSPENDED" => "1"
T2   A31    V2      1*        >O>   "<>" => "1"
T2   A31    V2      1*        >>>   "1"
T2   A31    V2      1*    159 *-* if status == .Coactivity~killed
T2   A31    V2      1*        >V>   STATUS => "2"
T2   A31    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T2   A31    V2      1*        >M>   "KILLED" => "4"
T2   A31    V2      1*        >O>   "==" => "0"
T2   A31    V2      1*        >>>   "0"
T2   A31    V2      1*    160 *-* if status == .Coactivity~ended
T2   A31    V2      1*        >V>   STATUS => "2"
T2   A31    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T2   A31    V2      1*        >M>   "ENDED" => "3"
T2   A31    V2      1*        >O>   "==" => "0"
T2   A31    V2      1*        >>>   "0"
T2   A31    V2      1*    161 *-* return self~arguments -- returns the arguments that the coactivity's client passed to 'resume'
T2   A31    V2      1*        >V>   SELF => "a Coactivity"
T2   A31    V2      1*        >M>   "ARGUMENTS" => "an Array"
T2   A31    V2      1*        >>>   "an Array"
T2   A6     V2      1     114 *-*       guard on
T1   A40    V2      1*        >V>   STATUS => "2"
T1   A40    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A40    V2      1*        >M>   "RUNNING" => "2"
T1   A40    V2      1*        >O>   "<>" => "0"
T1   A40    V2      1*        >>>   "0"
T2   A6     V2      1*    115 *-*       if var("result")
T2   A6     V2      1*        >L>         "result"
T2   A6     V2      1*        >A>         "result"
T2   A6     V2      1*        >F>         VAR => "0"
T2   A6     V2      1*        >>>         "0"
T2   A6     V2      1*    116 *-*         else
T2   A6     V2      1*    116 *-*           self~yieldLast
T2   A6     V2      1*        >V>             SELF => "a Coactivity"
T2   A41    V2      1         >I> Method YIELDLAST with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T2   A41    V2      2*    168 *-* expose yieldValue
T2   A41    V2      2*    169 *-* drop yieldValue
T2   A41    V2      2*    170 *-* if arg() <> 0
T2   A41    V2      2*        >F>   ARG => "0"
T2   A41    V2      2*        >L>   "0"
T2   A41    V2      2*        >O>   "<>" => "0"
T2   A41    V2      2*        >>>   "0"
T2   A6     V2      1*    117 *-*       status = .Coactivity~ended
T2   A6     V2      1*        >E>         .COACTIVITY => "The Coactivity class"
T2   A6     V2      1*        >M>         "ENDED" => "3"
T2   A6     V2      1*        >>>         "3"
T2   A6     V2      1*        >=>         STATUS <= "3"
T2   A6     V2      1*    118 *-*   end
T2   A6     V2      1*    119 *-* trapCondition:
T2   A6     V2      1*    120 *-* self~kill -- maybe already killed or ended
T2   A6     V2      1*        >V>   SELF => "a Coactivity"
T2   A42    V2      1         >I> Method KILL with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T2   A42    V2      2*    197 *-* if self~status == .Coactivity~ended
T2   A42    V2      2*        >V>   SELF => "a Coactivity"
T2   A42    V2      2*        >M>   "STATUS" => "3"
T2   A42    V2      2*        >E>   .COACTIVITY => "The Coactivity class"
T2   A42    V2      2*        >M>   "ENDED" => "3"
T2   A42    V2      2*        >O>   "==" => "1"
T2   A42    V2      2*        >>>   "1"
T2   A42    V2      2*    197 *-*   then
T2   A42    V2      2*    197 *-*     return .false
T2   A42    V2      2*        >E>       .FALSE => "0"
T2   A42    V2      2*        >>>       "0"
T2   A6     V2      1*        >>>   "0"
T2   A6     V2      1*    121 *-* if self~hasMethod("onTerminate")
T2   A6     V2      1*        >V>   SELF => "a Coactivity"
T2   A6     V2      1*        >L>   "onTerminate"
T2   A6     V2      1*        >A>   "onTerminate"
T2   A6     V2      1*        >M>   "HASMETHOD" => "0"
T2   A6     V2      1*        >>>   "0"
T2   A6     V2      1*    122 *-* .Coactivity~table~remove(self)
T2   A6     V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T2   A6     V2      1*        >M>   "TABLE" => "an IdentityTable"
T2   A6     V2      1*        >V>   SELF => "a Coactivity"
T2   A6     V2      1*        >A>   "a Coactivity"
T2   A6     V2      1*        >>>   "a Coactivity"
T2   A6     V2      1*    123 *-* .Activity~local~empty
T2   A6     V2      1*        >E>   .ACTIVITY => "The ACTIVITY class"
T2   A6     V2      1*        >M>   "LOCAL" => "a Directory"
T2   A6     V2      1*    124 *-* if self~isKilled & condition("o") <> .nil
T2   A6     V2      1*        >V>   SELF => "a Coactivity"
T2   A43    V2      1         >I> Method ISKILLED with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T2   A43    V2      2*    217 *-* return self~status == .Coactivity~killed
T2   A43    V2      2*        >V>   SELF => "a Coactivity"
T2   A43    V2      2*        >M>   "STATUS" => "3"
T2   A43    V2      2*        >E>   .COACTIVITY => "The Coactivity class"
T2   A43    V2      2*        >M>   "KILLED" => "4"
T2   A43    V2      2*        >O>   "==" => "0"
T2   A43    V2      2*        >>>   "0"
T2   A6     V2      1*        >M>   "ISKILLED" => "0"
T2   A6     V2      1*        >L>   "o"
T2   A6     V2      1*        >A>   "o"
T2   A6     V2      1*        >F>   CONDITION => "The NIL object"
T2   A6     V2      1*        >E>   .NIL => "The NIL object"
T2   A6     V2      1*        >O>   "<>" => "0"
T2   A6     V2      1*        >O>   "&" => "0"
T2   A6     V2      1*        >>>   "0"
T1   A40    V2      1*        >V>   STATUS => "3"
T1   A40    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A40    V2      1*        >M>   "RUNNING" => "2"
T1   A40    V2      1*        >O>   "<>" => "1"
T1   A40    V2      1*        >>>   "1"
T1   A40    V2      1*    184 *-* if status == .Coactivity~killed
T1   A40    V2      1*        >V>   STATUS => "3"
T1   A40    V2      1*        >E>   .COACTIVITY => "The Coactivity class"
T1   A40    V2      1*        >M>   "KILLED" => "4"
T1   A40    V2      1*        >O>   "==" => "0"
T1   A40    V2      1*        >>>   "0"
T1   A40    V2      1*    185 *-* if var("yieldValue")
T1   A40    V2      1*        >L>   "yieldValue"
T1   A40    V2      1*        >A>   "yieldValue"
T1   A40    V2      1*        >F>   VAR => "0"
T1   A40    V2      1*        >>>   "0"
T1   A39    V6      1*    305 *-* drop currentItem
T1   A39    V6      1*    306 *-* if var("result")
T1   A39    V6      1*        >L>   "result"
T1   A39    V6      1*        >A>   "result"
T1   A39    V6      1*        >F>   VAR => "0"
T1   A39    V6      1*        >>>   "0"
T1   A39    V6      1*    311 *-*   else
T1   A39    V6      1*    311 *-*     self~isAvailable = .false
T1   A39    V6      1*        >V>       SELF => "a LAZYCOACTIVITYSUPPLIER"
T1   A39    V6      1*        >E>       .FALSE => "0"
T1   A39    V6      1*        >A>       "0"
T1   A39    V6      1*        >>>       "0"
T1   A13    V4      2*    148 *-* end
T1   A13    V4      2*    145 *-* do while engine~available                   -- while more data
T1   A13    V4      2*        >V>     ENGINE => "a LAZYCOACTIVITYSUPPLIER"
T1   A44    V6                >I> Method AVAILABLE with scope "The LAZYCOACTIVITYSUPPLIER class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1   A44    V6      1*    291 *-* return self~isAvailable
T1   A44    V6      1*        >V>   SELF => "a LAZYCOACTIVITYSUPPLIER"
T1   A44    V6      1*        >M>   "ISAVAILABLE" => "0"
T1   A44    V6      1*        >>>   "0"
T1   A13    V4      2*        >M>     "AVAILABLE" => "0"
T1   A13    V4      2*        >>>     "0"
T1   A13    V4      2*    149 *-* self~eof                                    -- signal that processing is finished
T1   A13    V4      2*        >V>   SELF => "an UPPER"
T1   A45    V4      2         >I> Method EOF with scope "The PIPESTAGE class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\pipeline\pipe.rex
T1   A45    V4      3*    173 *-* expose next secondary
T1   A45    V4      3*    174 *-* if .nil <> next
T1   A45    V4      3*        >E>   .NIL => "The NIL object"
T1   A45    V4      3*        >V>   NEXT => "a CONSOLE"
T1   A45    V4      3*        >O>   "<>" => "1"
T1   A45    V4      3*        >>>   "1"
T1   A45    V4      3*    174 *-*   then
T1   A45    V4      3*    174 *-*     do
T1   A45    V4      3*    175 *-*       next~eof                                -- only forward if we have a successor
T1   A45    V4      3*        >V>         NEXT => "a CONSOLE"
T1   A46    V5                >I> Method EOF with scope "The PIPESTAGE class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\pipeline\pipe.rex
T1   A46    V5      1*    173 *-* expose next secondary
T1   A46    V5      1*    174 *-* if .nil <> next
T1   A46    V5      1*        >E>   .NIL => "The NIL object"
T1   A46    V5      1*        >V>   NEXT => "The NIL object"
T1   A46    V5      1*        >O>   "<>" => "0"
T1   A46    V5      1*        >>>   "0"
T1   A46    V5      1*    177 *-* if .nil <> secondary
T1   A46    V5      1*        >E>   .NIL => "The NIL object"
T1   A46    V5      1*        >V>   SECONDARY => "The NIL object"
T1   A46    V5      1*        >O>   "<>" => "0"
T1   A46    V5      1*        >>>   "0"
T1   A45    V4      3*    176 *-*   end
T1   A45    V4      3*    177 *-* if .nil <> secondary
T1   A45    V4      3*        >E>   .NIL => "The NIL object"
T1   A45    V4      3*        >V>   SECONDARY => "The NIL object"
T1   A45    V4      3*        >O>   "<>" => "0"
T1   A45    V4      3*        >>>   "0"
*/
