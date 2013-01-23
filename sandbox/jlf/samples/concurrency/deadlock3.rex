/*
An example of deadlock, and how to avoid it.

Here the problem comes from .RoutineDoer~needsObject and ~doWith which were guarded
and applied on the same instance of routine from two distinct activities (T2 and T3).
The method ~doWith can be active during a long period when under control of a
coactivity (which is the case here).
These two methods are user-defined methods, added by extension on the predefined
class .Routine. A routine instance has no state to protect against concurrent access,
but the behaviour of the interpreter is to always lock the object variables when
entering in a guarded method defined by the user.
It seems that the predefined methods do not trigger this locking, even if declared
guarded (to confirm, I could be wrong here... [later] I confirm).

~times.generate forwards to ~generate.downto.
The shared routine instance is created from the source literal {...}.
::method yield.downto --unguarded -- coactive
    use strict arg lowerLimit, action={arg(1)}
    c = .Coactivity~new{
        -- expose self lowerLimit action        -- to activate when closure supported
        use strict arg self, lowerLimit, action -- to remove when closure supported
        .yield[]                                -- to remove when closure supported
        -- parse only once, before iteration
        if action~hasMethod("functionDoer") then doer = action~functionDoer("use arg value")
                                            else doer = action~doer
        do i = self to lowerLimit by -1
            doer~do(i)
            if var("result") then .yield[result]
        end
    }
    c~resume(self, lowerLimit, action) -- to remove when closure supported
    return c

There was a deadlock because ~needsObject and ~doWith (applied on the same routine instance) were guarded.
While the first coactivity was not ended, there was a lock on V7 :
T2	A18	V7	1	*	method	The RoutineDoer class	DOWITH
And since the same instance of routine was used for the second coactivity, the deadlock was here :
T3	A34	V7	1	 	method	The RoutineDoer class	NEEDSOBJECT

To avoid the deadlock, all the methods of .RoutineDoer have been declared unguarded.
In theory, only ~do and ~doWith had to be declared unguarded, but it doesn't hurt to declare more methods unguarded.

*/

c = 1000~times.generate
c = 1000~times.generate
say "Ended coactivities:" .Coactivity~endAll

::requires "extension/extensions.cls"


/***************************************************************
Trace output (CSV) in case of deadlock
****************************************************************
T1	A1	V1	.	 	method	The Activity class	INIT	      	>I>	Method INIT with scope "The Activity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\activity.cls
T1	A1	V1	1	*	method	The Activity class	INIT	24	*-*	expose directory
T1	A1	V1	1	*	method	The Activity class	INIT	25	*-*	directory = .Directory~new
T1	A1	V1	1	*	method	The Activity class	INIT	      	>E>	  .DIRECTORY => "The Directory class"
T1	A1	V1	1	*	method	The Activity class	INIT	      	>M>	  "NEW" => "a Directory"
T1	A1	V1	1	*	method	The Activity class	INIT	      	>>>	  "a Directory"
T1	A1	V1	1	*	method	The Activity class	INIT	      	>=>	  DIRECTORY <= "a Directory"
T1	A2	.	.	 	routine		d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\activity.cls	      	>I>	Routine d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\activity.cls in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\activity.cls
T1	A2	.	.	 	routine		d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\activity.cls	6	*-*	if .context~package~loadLibrary("rxunixsys")
T1	A2	.	.	 	routine		d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\activity.cls	      	>E>	  .CONTEXT => "a RexxContext"
T1	A2	.	.	 	routine		d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\activity.cls	      	>M>	  "PACKAGE" => "a Package"
T1	A2	.	.	 	routine		d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\activity.cls	      	>L>	  "rxunixsys"
T1	A2	.	.	 	routine		d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\activity.cls	      	>A>	  "rxunixsys"
T1	A2	.	.	 	routine		d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\activity.cls	      	>M>	  "LOADLIBRARY" => "0"
T1	A2	.	.	 	routine		d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\activity.cls	      	>>>	  "0"
T1	A2	.	.	 	routine		d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\activity.cls	8	*-*	  else
T1	A2	.	.	 	routine		d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\activity.cls	9	*-*	    .local~rxunixsys.loaded = .false
T1	A2	.	.	 	routine		d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\activity.cls	      	>E>	      .LOCAL => "The Local Directory"
T1	A2	.	.	 	routine		d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\activity.cls	      	>E>	      .FALSE => "0"
T1	A2	.	.	 	routine		d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\activity.cls	      	>A>	      "0"
T1	A3	V2	.	 	method	The Coactivity class	INIT	      	>I>	Method INIT with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1	A3	V2	1	*	method	The Coactivity class	INIT	62	*-*	self~table = .IdentityTable~new
T1	A3	V2	1	*	method	The Coactivity class	INIT	      	>V>	  SELF => "The Coactivity class"
T1	A3	V2	1	*	method	The Coactivity class	INIT	      	>E>	  .IDENTITYTABLE => "The IdentityTable class"
T1	A3	V2	1	*	method	The Coactivity class	INIT	      	>M>	  "NEW" => "an IdentityTable"
T1	A3	V2	1	*	method	The Coactivity class	INIT	      	>A>	  "an IdentityTable"
T1	A3	V2	1	*	method	The Coactivity class	INIT	      	>>>	  "an IdentityTable"
T1	A3	V2	1	*	method	The Coactivity class	INIT	63	*-*	self~makeArrayLimit = 10000 -- not a constant, I think it's useful to let the end user change this value
T1	A3	V2	1	*	method	The Coactivity class	INIT	      	>V>	  SELF => "The Coactivity class"
T1	A3	V2	1	*	method	The Coactivity class	INIT	      	>L>	  "10000"
T1	A3	V2	1	*	method	The Coactivity class	INIT	      	>A>	  "10000"
T1	A3	V2	1	*	method	The Coactivity class	INIT	      	>>>	  "10000"
T1	A4	.	.	 	routine		d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls	      	>I>	Routine d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1	A5	.	.	 	routine		d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\extension\doers.cls	      	>I>	Routine d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\extension\doers.cls in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\extension\doers.cls
T1	A6	.	.	 	routine		d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\extension\functionals.cls	      	>I>	Routine d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\extension\functionals.cls in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\extension\functionals.cls
T1	A7	V3	.	 	method	The StringRepeater class	TIMES.YIELD	      	>I>	Method TIMES.YIELD with scope "The StringRepeater class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\extension\functionals.cls
T1	A7	V3	1	*	method	The StringRepeater class	TIMES.YIELD	301	*-*	use strict arg action={arg(1)}
T1	A7	V3	1	*	method	The StringRepeater class	TIMES.YIELD	      	>L>	  "a RexxContextualSource"
T1	A7	V3	1	*	method	The StringRepeater class	TIMES.YIELD	      	>>>	  "a RexxContextualSource"
T1	A7	V3	1	*	method	The StringRepeater class	TIMES.YIELD	      	>=>	  ACTION <= "a RexxContextualSource"
T1	A7	V3	1	*	method	The StringRepeater class	TIMES.YIELD	302	*-*	forward to 1 message "yield.upto" array(self, action)
T1	A7	V3	1	*	method	The StringRepeater class	TIMES.YIELD	      	>L>	  "1"
T1	A7	V3	1	*	method	The StringRepeater class	TIMES.YIELD	      	>L>	  "yield.upto"
T1	A7	V3	1	*	method	The StringRepeater class	TIMES.YIELD	      	>V>	  SELF => "1000"
T1	A7	V3	1	*	method	The StringRepeater class	TIMES.YIELD	      	>V>	  ACTION => "a RexxContextualSource"
T1	A8	V4	.	 	method	The StringRepeater class	YIELD.UPTO	      	>I>	Method YIELD.UPTO with scope "The StringRepeater class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\extension\functionals.cls
T1	A8	V4	1	*	method	The StringRepeater class	YIELD.UPTO	335	*-*	use strict arg upperLimit, action={arg(1)}
T1	A8	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>>>	  "1000"
T1	A8	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>=>	  UPPERLIMIT <= "1000"
T1	A8	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>>>	  "a RexxContextualSource"
T1	A8	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>=>	  ACTION <= "a RexxContextualSource"
T1	A8	V4	1	*	method	The StringRepeater class	YIELD.UPTO	336	*-*	c = .Coactivity~new{        -- expose self upperLimit action        -- to activate when closure supported        use strict arg self, upperLimit, action -- to remove when closure supported        .yield[]                                -- to remove when closure supported        -- parse only once, before iteration        if action~hasMethod("functionDoer") then doer = action~functionDoer("use arg value")                                            else doer = action~doer        do i = self to upperLimit            doer~do(i)            if var("result") then .yield[result]        end    }
T1	A8	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>E>	  .COACTIVITY => "The Coactivity class"
T1	A8	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>L>	  "a RexxContextualSource"
T1	A8	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>A>	  "a RexxContextualSource"
T1	A9	V5	.	 	method	The Coactivity class	INIT	      	>I>	Method INIT with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1	A9	V5	.	 	method	The Coactivity class	INIT	96	*-*	expose doer object status
T1	A9	V5	.	 	method	The Coactivity class	INIT	97	*-*	use strict arg action="main", start=.true, object=(self)
T1	A9	V5	.	 	method	The Coactivity class	INIT	      	>>>	  "a RexxContextualSource"
T1	A9	V5	.	 	method	The Coactivity class	INIT	      	>=>	  ACTION <= "a RexxContextualSource"
T1	A9	V5	.	 	method	The Coactivity class	INIT	      	>E>	  .TRUE => "1"
T1	A9	V5	.	 	method	The Coactivity class	INIT	      	>>>	  "1"
T1	A9	V5	.	 	method	The Coactivity class	INIT	      	>=>	  START <= "1"
T1	A9	V5	.	 	method	The Coactivity class	INIT	      	>V>	  SELF => "a Coactivity"
T1	A9	V5	.	 	method	The Coactivity class	INIT	      	>>>	  "a Coactivity"
T1	A9	V5	.	 	method	The Coactivity class	INIT	      	>=>	  OBJECT <= "a Coactivity"
T1	A9	V5	.	 	method	The Coactivity class	INIT	99	*-*	doer = action~doer
T1	A9	V5	.	 	method	The Coactivity class	INIT	      	>V>	  ACTION => "a RexxContextualSource"
T1	A10	V6	.	 	method	The RexxContextualSourceDoer class	DOER	      	>I>	Method DOER with scope "The RexxContextualSourceDoer class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\extension\doers.cls
T1	A10	V6	1	*	method	The RexxContextualSourceDoer class	DOER	359	*-*	use strict arg object=.nil -- optional object, needed when the source is tagged ::method
T1	A10	V6	1	*	method	The RexxContextualSourceDoer class	DOER	      	>E>	  .NIL => "The NIL object"
T1	A10	V6	1	*	method	The RexxContextualSourceDoer class	DOER	      	>>>	  "The NIL object"
T1	A10	V6	1	*	method	The RexxContextualSourceDoer class	DOER	      	>=>	  OBJECT <= "The NIL object"
T1	A10	V6	1	*	method	The RexxContextualSourceDoer class	DOER	360	*-*	if self~executable <> .nil
T1	A10	V6	1	*	method	The RexxContextualSourceDoer class	DOER	      	>V>	  SELF => "a RexxContextualSource"
T1	A10	V6	1	*	method	The RexxContextualSourceDoer class	DOER	      	>M>	  "EXECUTABLE" => "a Routine"
T1	A10	V6	1	*	method	The RexxContextualSourceDoer class	DOER	      	>E>	  .NIL => "The NIL object"
T1	A10	V6	1	*	method	The RexxContextualSourceDoer class	DOER	      	>O>	  "<>" => "1"
T1	A10	V6	1	*	method	The RexxContextualSourceDoer class	DOER	      	>>>	  "1"
T1	A10	V6	1	*	method	The RexxContextualSourceDoer class	DOER	360	*-*	  then
T1	A10	V6	1	*	method	The RexxContextualSourceDoer class	DOER	360	*-*	    return self~executable
T1	A10	V6	1	*	method	The RexxContextualSourceDoer class	DOER	      	>V>	      SELF => "a RexxContextualSource"
T1	A10	V6	1	*	method	The RexxContextualSourceDoer class	DOER	      	>M>	      "EXECUTABLE" => "a Routine"
T1	A10	V6	1	*	method	The RexxContextualSourceDoer class	DOER	      	>>>	      "a Routine"
T1	A9	V5	.	 	method	The Coactivity class	INIT	      	>M>	  "DOER" => "a Routine"
T1	A9	V5	.	 	method	The Coactivity class	INIT	      	>>>	  "a Routine"
T1	A9	V5	.	 	method	The Coactivity class	INIT	      	>=>	  DOER <= "a Routine"
T1	A9	V5	.	 	method	The Coactivity class	INIT	100	*-*	status = .Coactivity~notStarted
T1	A9	V5	.	 	method	The Coactivity class	INIT	      	>E>	  .COACTIVITY => "The Coactivity class"
T1	A9	V5	.	 	method	The Coactivity class	INIT	      	>M>	  "NOTSTARTED" => "0"
T1	A9	V5	.	 	method	The Coactivity class	INIT	      	>>>	  "0"
T1	A9	V5	.	 	method	The Coactivity class	INIT	      	>=>	  STATUS <= "0"
T1	A9	V5	.	 	method	The Coactivity class	INIT	101	*-*	if start
T1	A9	V5	.	 	method	The Coactivity class	INIT	      	>V>	  START => "1"
T1	A9	V5	.	 	method	The Coactivity class	INIT	      	>>>	  "1"
T1	A9	V5	.	 	method	The Coactivity class	INIT	101	*-*	  then
T1	A9	V5	.	 	method	The Coactivity class	INIT	101	*-*	    self~start
T1	A9	V5	.	 	method	The Coactivity class	INIT	      	>V>	      SELF => "a Coactivity"
T1	A11	V5	.	 	method	The Coactivity class	START	      	>I>	Method START with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1	A11	V5	1	*	method	The Coactivity class	START	116	*-*	expose arguments doer object status
T1	A11	V5	1	*	method	The Coactivity class	START	117	*-*	use strict arg -- no arg
T1	A11	V5	1	*	method	The Coactivity class	START	118	*-*	if status <> .Coactivity~notStarted
T1	A11	V5	1	*	method	The Coactivity class	START	      	>V>	  STATUS => "0"
T1	A11	V5	1	*	method	The Coactivity class	START	      	>E>	  .COACTIVITY => "The Coactivity class"
T1	A11	V5	1	*	method	The Coactivity class	START	      	>M>	  "NOTSTARTED" => "0"
T1	A11	V5	1	*	method	The Coactivity class	START	      	>O>	  "<>" => "0"
T1	A11	V5	1	*	method	The Coactivity class	START	      	>>>	  "0"
T1	A11	V5	1	*	method	The Coactivity class	START	119	*-*	status = .Coactivity~suspended
T1	A11	V5	1	*	method	The Coactivity class	START	      	>E>	  .COACTIVITY => "The Coactivity class"
T1	A11	V5	1	*	method	The Coactivity class	START	      	>M>	  "SUSPENDED" => "1"
T1	A11	V5	1	*	method	The Coactivity class	START	      	>>>	  "1"
T1	A11	V5	1	*	method	The Coactivity class	START	      	>=>	  STATUS <= "1"
T1	A11	V5	1	*	method	The Coactivity class	START	120	*-*	reply self
T1	A11	V5	1	*	method	The Coactivity class	START	      	>V>	  SELF => "a Coactivity"
T1	A11	V5	1	*	method	The Coactivity class	START	      	>>>	  "a Coactivity"
T2	A11	V5	1	*	method	The Coactivity class	START	      	>I>	Method START with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1	A9	V5	1	 	method	The Coactivity class	INIT	      	>>>	      "a Coactivity"
T2	A11	V5	1	*	method	The Coactivity class	START	121	*-*	.Activity~local~empty
T1	A8	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>M>	  "NEW" => "a Coactivity"
T2	A11	V5	1	*	method	The Coactivity class	START	      	>E>	  .ACTIVITY => "The Activity class"
T1	A8	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>>>	  "a Coactivity"
T2	A12	V1	.	 	method	The Activity class	LOCAL	      	>I>	Method LOCAL with scope "The Activity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\activity.cls
T1	A8	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>=>	  C <= "a Coactivity"
T2	A12	V1	1	*	method	The Activity class	LOCAL	34	*-*	expose directory
T1	A8	V4	1	*	method	The StringRepeater class	YIELD.UPTO	348	*-*	c~resume(self, upperLimit, action) -- to remove when closure supported
T2	A12	V1	1	*	method	The Activity class	LOCAL	35	*-*	threadId=self~currentThreadId
T1	A8	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>V>	  C => "a Coactivity"
T2	A12	V1	1	*	method	The Activity class	LOCAL	      	>V>	  SELF => "The Activity class"
T1	A8	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>V>	  SELF => "1"
T2	A13	V1	1	 	method	The Activity class	CURRENTTHREADID	      	>I>	Method CURRENTTHREADID with scope "The Activity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\activity.cls
T1	A8	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>A>	  "1"
T2	A13	V1	2	*	method	The Activity class	CURRENTTHREADID	29	*-*	if .rxunixsys.loaded
T1	A8	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>V>	  UPPERLIMIT => "1000"
T2	A13	V1	2	*	method	The Activity class	CURRENTTHREADID	      	>E>	  .RXUNIXSYS.LOADED => "0"
T1	A8	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>A>	  "1000"
T2	A13	V1	2	*	method	The Activity class	CURRENTTHREADID	      	>>>	  "0"
T1	A8	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>V>	  ACTION => "a RexxContextualSource"
T2	A13	V1	2	*	method	The Activity class	CURRENTTHREADID	30	*-*	  else
T1	A8	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>A>	  "a RexxContextualSource"
T2	A13	V1	2	*	method	The Activity class	CURRENTTHREADID	30	*-*	    return SysQueryProcess("TID") -- Windows
T1	A14	V5	1	 	method	The Coactivity class	RESUME	      	>I>	Method RESUME with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T2	A13	V1	2	*	method	The Activity class	CURRENTTHREADID	      	>L>	      "TID"
T2	A13	V1	2	*	method	The Activity class	CURRENTTHREADID	      	>A>	      "TID"
T2	A13	V1	2	*	method	The Activity class	CURRENTTHREADID	      	>F>	      SYSQUERYPROCESS => "24140"
T2	A13	V1	2	*	method	The Activity class	CURRENTTHREADID	      	>>>	      "24140"
T2	A12	V1	1	*	method	The Activity class	LOCAL	      	>M>	  "CURRENTTHREADID" => "24140"
T2	A12	V1	1	*	method	The Activity class	LOCAL	      	>>>	  "24140"
T2	A12	V1	1	*	method	The Activity class	LOCAL	      	>=>	  THREADID <= "24140"
T2	A12	V1	1	*	method	The Activity class	LOCAL	36	*-*	local = directory[threadId]
T2	A12	V1	1	*	method	The Activity class	LOCAL	      	>V>	  DIRECTORY => "a Directory"
T2	A12	V1	1	*	method	The Activity class	LOCAL	      	>V>	  THREADID => "24140"
T2	A12	V1	1	*	method	The Activity class	LOCAL	      	>A>	  "24140"
T2	A12	V1	1	*	method	The Activity class	LOCAL	      	>M>	  "[]" => "The NIL object"
T2	A12	V1	1	*	method	The Activity class	LOCAL	      	>>>	  "The NIL object"
T2	A12	V1	1	*	method	The Activity class	LOCAL	      	>=>	  LOCAL <= "The NIL object"
T2	A12	V1	1	*	method	The Activity class	LOCAL	37	*-*	if local == .nil
T2	A12	V1	1	*	method	The Activity class	LOCAL	      	>V>	  LOCAL => "The NIL object"
T2	A12	V1	1	*	method	The Activity class	LOCAL	      	>E>	  .NIL => "The NIL object"
T2	A12	V1	1	*	method	The Activity class	LOCAL	      	>O>	  "==" => "1"
T2	A12	V1	1	*	method	The Activity class	LOCAL	      	>>>	  "1"
T2	A12	V1	1	*	method	The Activity class	LOCAL	37	*-*	  then
T2	A12	V1	1	*	method	The Activity class	LOCAL	37	*-*	    do
T2	A12	V1	1	*	method	The Activity class	LOCAL	38	*-*	      local = .Directory~new
T2	A12	V1	1	*	method	The Activity class	LOCAL	      	>E>	        .DIRECTORY => "The Directory class"
T2	A12	V1	1	*	method	The Activity class	LOCAL	      	>M>	        "NEW" => "a Directory"
T2	A12	V1	1	*	method	The Activity class	LOCAL	      	>>>	        "a Directory"
T2	A12	V1	1	*	method	The Activity class	LOCAL	      	>=>	        LOCAL <= "a Directory"
T2	A12	V1	1	*	method	The Activity class	LOCAL	39	*-*	      directory[threadId] = local
T2	A12	V1	1	*	method	The Activity class	LOCAL	      	>V>	        DIRECTORY => "a Directory"
T2	A12	V1	1	*	method	The Activity class	LOCAL	      	>V>	        LOCAL => "a Directory"
T2	A12	V1	1	*	method	The Activity class	LOCAL	      	>A>	        "a Directory"
T2	A12	V1	1	*	method	The Activity class	LOCAL	      	>V>	        THREADID => "24140"
T2	A12	V1	1	*	method	The Activity class	LOCAL	      	>A>	        "24140"
T2	A12	V1	1	*	method	The Activity class	LOCAL	40	*-*	  end
T2	A12	V1	1	*	method	The Activity class	LOCAL	41	*-*	return local
T2	A12	V1	1	*	method	The Activity class	LOCAL	      	>V>	  LOCAL => "a Directory"
T2	A12	V1	1	*	method	The Activity class	LOCAL	      	>>>	  "a Directory"
T2	A11	V5	1	*	method	The Coactivity class	START	      	>M>	  "LOCAL" => "a Directory"
T2	A11	V5	1	*	method	The Coactivity class	START	122	*-*	.Activity~local~coactivity = self
T2	A11	V5	1	*	method	The Coactivity class	START	      	>E>	  .ACTIVITY => "The Activity class"
T2	A15	V1	.	 	method	The Activity class	LOCAL	      	>I>	Method LOCAL with scope "The Activity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\activity.cls
T2	A15	V1	1	*	method	The Activity class	LOCAL	34	*-*	expose directory
T2	A15	V1	1	*	method	The Activity class	LOCAL	35	*-*	threadId=self~currentThreadId
T2	A15	V1	1	*	method	The Activity class	LOCAL	      	>V>	  SELF => "The Activity class"
T2	A16	V1	1	 	method	The Activity class	CURRENTTHREADID	      	>I>	Method CURRENTTHREADID with scope "The Activity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\activity.cls
T2	A16	V1	2	*	method	The Activity class	CURRENTTHREADID	29	*-*	if .rxunixsys.loaded
T2	A16	V1	2	*	method	The Activity class	CURRENTTHREADID	      	>E>	  .RXUNIXSYS.LOADED => "0"
T2	A16	V1	2	*	method	The Activity class	CURRENTTHREADID	      	>>>	  "0"
T2	A16	V1	2	*	method	The Activity class	CURRENTTHREADID	30	*-*	  else
T2	A16	V1	2	*	method	The Activity class	CURRENTTHREADID	30	*-*	    return SysQueryProcess("TID") -- Windows
T2	A16	V1	2	*	method	The Activity class	CURRENTTHREADID	      	>L>	      "TID"
T2	A16	V1	2	*	method	The Activity class	CURRENTTHREADID	      	>A>	      "TID"
T2	A16	V1	2	*	method	The Activity class	CURRENTTHREADID	      	>F>	      SYSQUERYPROCESS => "24140"
T2	A16	V1	2	*	method	The Activity class	CURRENTTHREADID	      	>>>	      "24140"
T2	A15	V1	1	*	method	The Activity class	LOCAL	      	>M>	  "CURRENTTHREADID" => "24140"
T2	A15	V1	1	*	method	The Activity class	LOCAL	      	>>>	  "24140"
T2	A15	V1	1	*	method	The Activity class	LOCAL	      	>=>	  THREADID <= "24140"
T2	A15	V1	1	*	method	The Activity class	LOCAL	36	*-*	local = directory[threadId]
T2	A15	V1	1	*	method	The Activity class	LOCAL	      	>V>	  DIRECTORY => "a Directory"
T2	A15	V1	1	*	method	The Activity class	LOCAL	      	>V>	  THREADID => "24140"
T2	A15	V1	1	*	method	The Activity class	LOCAL	      	>A>	  "24140"
T2	A15	V1	1	*	method	The Activity class	LOCAL	      	>M>	  "[]" => "a Directory"
T2	A15	V1	1	*	method	The Activity class	LOCAL	      	>>>	  "a Directory"
T2	A15	V1	1	*	method	The Activity class	LOCAL	      	>=>	  LOCAL <= "a Directory"
T2	A15	V1	1	*	method	The Activity class	LOCAL	37	*-*	if local == .nil
T2	A15	V1	1	*	method	The Activity class	LOCAL	      	>V>	  LOCAL => "a Directory"
T2	A15	V1	1	*	method	The Activity class	LOCAL	      	>E>	  .NIL => "The NIL object"
T2	A15	V1	1	*	method	The Activity class	LOCAL	      	>O>	  "==" => "0"
T2	A15	V1	1	*	method	The Activity class	LOCAL	      	>>>	  "0"
T2	A15	V1	1	*	method	The Activity class	LOCAL	41	*-*	return local
T2	A15	V1	1	*	method	The Activity class	LOCAL	      	>V>	  LOCAL => "a Directory"
T2	A15	V1	1	*	method	The Activity class	LOCAL	      	>>>	  "a Directory"
T2	A11	V5	1	*	method	The Coactivity class	START	      	>M>	  "LOCAL" => "a Directory"
T2	A11	V5	1	*	method	The Coactivity class	START	      	>V>	  SELF => "a Coactivity"
T2	A11	V5	1	*	method	The Coactivity class	START	      	>A>	  "a Coactivity"
T2	A11	V5	1	*	method	The Coactivity class	START	123	*-*	.Coactivity~table[self] = self
T2	A11	V5	1	*	method	The Coactivity class	START	      	>E>	  .COACTIVITY => "The Coactivity class"
T2	A11	V5	1	*	method	The Coactivity class	START	      	>M>	  "TABLE" => "an IdentityTable"
T2	A11	V5	1	*	method	The Coactivity class	START	      	>V>	  SELF => "a Coactivity"
T2	A11	V5	1	*	method	The Coactivity class	START	      	>A>	  "a Coactivity"
T2	A11	V5	1	*	method	The Coactivity class	START	      	>V>	  SELF => "a Coactivity"
T2	A11	V5	1	*	method	The Coactivity class	START	      	>A>	  "a Coactivity"
T2	A11	V5	1	*	method	The Coactivity class	START	124	*-*	signal on any name trapCondition -- catch all
T2	A11	V5	1	*	method	The Coactivity class	START	125	*-*	signal on syntax name trapCondition -- gives better messages
T2	A11	V5	1	*	method	The Coactivity class	START	126	*-*	guard off
T2	A11	V5	1	 	method	The Coactivity class	START	127	*-*	guard on when status <> .Coactivity~suspended
T1	A14	V5	1	*	method	The Coactivity class	RESUME	195	*-*	expose arguments status yieldValue
T1	A14	V5	1	*	method	The Coactivity class	RESUME	196	*-*	if status == .Coactivity~notStarted
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>V>	  STATUS => "1"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>E>	  .COACTIVITY => "The Coactivity class"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>M>	  "NOTSTARTED" => "0"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>O>	  "==" => "0"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>>>	  "0"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	197	*-*	if status == .Coactivity~killed
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>V>	  STATUS => "1"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>E>	  .COACTIVITY => "The Coactivity class"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>M>	  "KILLED" => "4"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>O>	  "==" => "0"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>>>	  "0"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	198	*-*	if status == .Coactivity~ended
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>V>	  STATUS => "1"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>E>	  .COACTIVITY => "The Coactivity class"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>M>	  "ENDED" => "3"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>O>	  "==" => "0"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>>>	  "0"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	199	*-*	arguments = arg(1, "a")
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>L>	  "1"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>A>	  "1"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>L>	  "a"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>A>	  "a"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>F>	  ARG => "an Array"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>>>	  "an Array"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>=>	  ARGUMENTS <= "an Array"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	200	*-*	status = .Coactivity~running
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>E>	  .COACTIVITY => "The Coactivity class"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>M>	  "RUNNING" => "2"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>>>	  "2"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>=>	  STATUS <= "2"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	201	*-*	guard off
T1	A14	V5	1	 	method	The Coactivity class	RESUME	202	*-*	guard on when status <> .Coactivity~running
T2	A11	V5	1	*	method	The Coactivity class	START	      	>V>	  STATUS => "2"
T2	A11	V5	1	*	method	The Coactivity class	START	      	>E>	  .COACTIVITY => "The Coactivity class"
T2	A11	V5	1	*	method	The Coactivity class	START	      	>M>	  "SUSPENDED" => "1"
T2	A11	V5	1	*	method	The Coactivity class	START	      	>O>	  "<>" => "1"
T2	A11	V5	1	*	method	The Coactivity class	START	      	>>>	  "1"
T2	A11	V5	1	*	method	The Coactivity class	START	128	*-*	if status == .Coactivity~running
T2	A11	V5	1	*	method	The Coactivity class	START	      	>V>	  STATUS => "2"
T2	A11	V5	1	*	method	The Coactivity class	START	      	>E>	  .COACTIVITY => "The Coactivity class"
T2	A11	V5	1	*	method	The Coactivity class	START	      	>M>	  "RUNNING" => "2"
T2	A11	V5	1	*	method	The Coactivity class	START	      	>O>	  "==" => "1"
T2	A11	V5	1	*	method	The Coactivity class	START	      	>>>	  "1"
T2	A11	V5	1	*	method	The Coactivity class	START	128	*-*	  then
T2	A11	V5	1	*	method	The Coactivity class	START	128	*-*	    do
T2	A11	V5	1	*	method	The Coactivity class	START	129	*-*	      guard off
T2	A11	V5	1	 	method	The Coactivity class	START	131	*-*	      if doer~needsObject
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>V>	  STATUS => "2"
T2	A11	V5	1	 	method	The Coactivity class	START	      	>V>	        DOER => "a Routine"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>E>	  .COACTIVITY => "The Coactivity class"
T2	A17	V7	.	 	method	The RoutineDoer class	NEEDSOBJECT	      	>I>	Method NEEDSOBJECT with scope "The RoutineDoer class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\extension\doers.cls
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>M>	  "RUNNING" => "2"
T2	A17	V7	1	*	method	The RoutineDoer class	NEEDSOBJECT	271	*-*	return .false -- No need to pass an object as first argument when calling do or doWith
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>O>	  "<>" => "0"
T2	A17	V7	1	*	method	The RoutineDoer class	NEEDSOBJECT	      	>E>	  .FALSE => "0"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>>>	  "0"
T2	A17	V7	1	*	method	The RoutineDoer class	NEEDSOBJECT	      	>>>	  "0"
T2	A11	V5	.	 	method	The Coactivity class	START	      	>M>	        "NEEDSOBJECT" => "0"
T2	A11	V5	.	 	method	The Coactivity class	START	      	>>>	        "0"
T2	A11	V5	.	 	method	The Coactivity class	START	132	*-*	        else
T2	A11	V5	.	 	method	The Coactivity class	START	132	*-*	          doer~doWith(arguments) -- no object needed (routine)
T2	A11	V5	.	 	method	The Coactivity class	START	      	>V>	            DOER => "a Routine"
T2	A11	V5	.	 	method	The Coactivity class	START	      	>V>	            ARGUMENTS => "an Array"
T2	A11	V5	.	 	method	The Coactivity class	START	      	>A>	            "an Array"
T2	A18	V7	.	 	method	The RoutineDoer class	DOWITH	      	>I>	Method DOWITH with scope "The RoutineDoer class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\extension\doers.cls
T2	A18	V7	1	*	method	The RoutineDoer class	DOWITH	278	*-*	use strict arg array
T2	A18	V7	1	*	method	The RoutineDoer class	DOWITH	      	>>>	  "an Array"
T2	A18	V7	1	*	method	The RoutineDoer class	DOWITH	      	>=>	  ARRAY <= "an Array"
T2	A18	V7	1	*	method	The RoutineDoer class	DOWITH	279	*-*	self~callWith(array)
T2	A18	V7	1	*	method	The RoutineDoer class	DOWITH	      	>V>	  SELF => "a Routine"
T2	A18	V7	1	*	method	The RoutineDoer class	DOWITH	      	>V>	  ARRAY => "an Array"
T2	A18	V7	1	*	method	The RoutineDoer class	DOWITH	      	>A>	  "an Array"
T2	A19	V8	.	 	method	The yield class	[]	      	>I>	Method [] with scope "The yield class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T2	A19	V8	.	 	method	The yield class	[]	29	*-*	forward message ("yield") to (.Coactivity)
T2	A19	V8	.	 	method	The yield class	[]	      	>E>	  .COACTIVITY => "The Coactivity class"
T2	A19	V8	.	 	method	The yield class	[]	      	>L>	  "yield"
T2	A20	V2	.	 	method	The Coactivity class	YIELD	      	>I>	Method YIELD with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T2	A20	V2	.	 	method	The Coactivity class	YIELD	162	*-*	coactivity = .Activity~local~coactivity
T2	A20	V2	.	 	method	The Coactivity class	YIELD	      	>E>	  .ACTIVITY => "The Activity class"
T2	A21	V1	.	 	method	The Activity class	LOCAL	      	>I>	Method LOCAL with scope "The Activity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\activity.cls
T2	A21	V1	1	*	method	The Activity class	LOCAL	34	*-*	expose directory
T2	A21	V1	1	*	method	The Activity class	LOCAL	35	*-*	threadId=self~currentThreadId
T2	A21	V1	1	*	method	The Activity class	LOCAL	      	>V>	  SELF => "The Activity class"
T2	A22	V1	1	 	method	The Activity class	CURRENTTHREADID	      	>I>	Method CURRENTTHREADID with scope "The Activity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\activity.cls
T2	A22	V1	2	*	method	The Activity class	CURRENTTHREADID	29	*-*	if .rxunixsys.loaded
T2	A22	V1	2	*	method	The Activity class	CURRENTTHREADID	      	>E>	  .RXUNIXSYS.LOADED => "0"
T2	A22	V1	2	*	method	The Activity class	CURRENTTHREADID	      	>>>	  "0"
T2	A22	V1	2	*	method	The Activity class	CURRENTTHREADID	30	*-*	  else
T2	A22	V1	2	*	method	The Activity class	CURRENTTHREADID	30	*-*	    return SysQueryProcess("TID") -- Windows
T2	A22	V1	2	*	method	The Activity class	CURRENTTHREADID	      	>L>	      "TID"
T2	A22	V1	2	*	method	The Activity class	CURRENTTHREADID	      	>A>	      "TID"
T2	A22	V1	2	*	method	The Activity class	CURRENTTHREADID	      	>F>	      SYSQUERYPROCESS => "24140"
T2	A22	V1	2	*	method	The Activity class	CURRENTTHREADID	      	>>>	      "24140"
T2	A21	V1	1	*	method	The Activity class	LOCAL	      	>M>	  "CURRENTTHREADID" => "24140"
T2	A21	V1	1	*	method	The Activity class	LOCAL	      	>>>	  "24140"
T2	A21	V1	1	*	method	The Activity class	LOCAL	      	>=>	  THREADID <= "24140"
T2	A21	V1	1	*	method	The Activity class	LOCAL	36	*-*	local = directory[threadId]
T2	A21	V1	1	*	method	The Activity class	LOCAL	      	>V>	  DIRECTORY => "a Directory"
T2	A21	V1	1	*	method	The Activity class	LOCAL	      	>V>	  THREADID => "24140"
T2	A21	V1	1	*	method	The Activity class	LOCAL	      	>A>	  "24140"
T2	A21	V1	1	*	method	The Activity class	LOCAL	      	>M>	  "[]" => "a Directory"
T2	A21	V1	1	*	method	The Activity class	LOCAL	      	>>>	  "a Directory"
T2	A21	V1	1	*	method	The Activity class	LOCAL	      	>=>	  LOCAL <= "a Directory"
T2	A21	V1	1	*	method	The Activity class	LOCAL	37	*-*	if local == .nil
T2	A21	V1	1	*	method	The Activity class	LOCAL	      	>V>	  LOCAL => "a Directory"
T2	A21	V1	1	*	method	The Activity class	LOCAL	      	>E>	  .NIL => "The NIL object"
T2	A21	V1	1	*	method	The Activity class	LOCAL	      	>O>	  "==" => "0"
T2	A21	V1	1	*	method	The Activity class	LOCAL	      	>>>	  "0"
T2	A21	V1	1	*	method	The Activity class	LOCAL	41	*-*	return local
T2	A21	V1	1	*	method	The Activity class	LOCAL	      	>V>	  LOCAL => "a Directory"
T2	A21	V1	1	*	method	The Activity class	LOCAL	      	>>>	  "a Directory"
T2	A20	V2	.	 	method	The Coactivity class	YIELD	      	>M>	  "LOCAL" => "a Directory"
T2	A20	V2	.	 	method	The Coactivity class	YIELD	      	>M>	  "COACTIVITY" => "a Coactivity"
T2	A20	V2	.	 	method	The Coactivity class	YIELD	      	>>>	  "a Coactivity"
T2	A20	V2	.	 	method	The Coactivity class	YIELD	      	>=>	  COACTIVITY <= "a Coactivity"
T2	A20	V2	.	 	method	The Coactivity class	YIELD	163	*-*	if coactivity == .nil
T2	A20	V2	.	 	method	The Coactivity class	YIELD	      	>V>	  COACTIVITY => "a Coactivity"
T2	A20	V2	.	 	method	The Coactivity class	YIELD	      	>E>	  .NIL => "The NIL object"
T2	A20	V2	.	 	method	The Coactivity class	YIELD	      	>O>	  "==" => "0"
T2	A20	V2	.	 	method	The Coactivity class	YIELD	      	>>>	  "0"
T2	A20	V2	.	 	method	The Coactivity class	YIELD	164	*-*	forward to (coactivity)
T2	A20	V2	.	 	method	The Coactivity class	YIELD	      	>V>	  COACTIVITY => "a Coactivity"
T2	A23	V5	.	 	method	The Coactivity class	YIELD	      	>I>	Method YIELD with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T2	A23	V5	1	*	method	The Coactivity class	YIELD	170	*-*	expose arguments status yieldValue
T2	A23	V5	1	*	method	The Coactivity class	YIELD	171	*-*	drop yieldValue
T2	A23	V5	1	*	method	The Coactivity class	YIELD	172	*-*	if status == .Coactivity~killed
T2	A23	V5	1	*	method	The Coactivity class	YIELD	      	>V>	  STATUS => "2"
T2	A23	V5	1	*	method	The Coactivity class	YIELD	      	>E>	  .COACTIVITY => "The Coactivity class"
T2	A23	V5	1	*	method	The Coactivity class	YIELD	      	>M>	  "KILLED" => "4"
T2	A23	V5	1	*	method	The Coactivity class	YIELD	      	>O>	  "==" => "0"
T2	A23	V5	1	*	method	The Coactivity class	YIELD	      	>>>	  "0"
T2	A23	V5	1	*	method	The Coactivity class	YIELD	173	*-*	if status == .Coactivity~ended
T2	A23	V5	1	*	method	The Coactivity class	YIELD	      	>V>	  STATUS => "2"
T2	A23	V5	1	*	method	The Coactivity class	YIELD	      	>E>	  .COACTIVITY => "The Coactivity class"
T2	A23	V5	1	*	method	The Coactivity class	YIELD	      	>M>	  "ENDED" => "3"
T2	A23	V5	1	*	method	The Coactivity class	YIELD	      	>O>	  "==" => "0"
T2	A23	V5	1	*	method	The Coactivity class	YIELD	      	>>>	  "0"
T2	A23	V5	1	*	method	The Coactivity class	YIELD	174	*-*	if arg() <> 0
T2	A23	V5	1	*	method	The Coactivity class	YIELD	      	>F>	  ARG => "0"
T2	A23	V5	1	*	method	The Coactivity class	YIELD	      	>L>	  "0"
T2	A23	V5	1	*	method	The Coactivity class	YIELD	      	>O>	  "<>" => "0"
T2	A23	V5	1	*	method	The Coactivity class	YIELD	      	>>>	  "0"
T2	A23	V5	1	*	method	The Coactivity class	YIELD	175	*-*	status = .Coactivity~suspended
T2	A23	V5	1	*	method	The Coactivity class	YIELD	      	>E>	  .COACTIVITY => "The Coactivity class"
T2	A23	V5	1	*	method	The Coactivity class	YIELD	      	>M>	  "SUSPENDED" => "1"
T2	A23	V5	1	*	method	The Coactivity class	YIELD	      	>>>	  "1"
T2	A23	V5	1	*	method	The Coactivity class	YIELD	      	>=>	  STATUS <= "1"
T2	A23	V5	1	*	method	The Coactivity class	YIELD	176	*-*	guard off
T2	A23	V5	1	 	method	The Coactivity class	YIELD	177	*-*	guard on when status <> .Coactivity~suspended
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>V>	  STATUS => "1"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>E>	  .COACTIVITY => "The Coactivity class"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>M>	  "RUNNING" => "2"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>O>	  "<>" => "1"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>>>	  "1"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	203	*-*	if status == .Coactivity~killed
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>V>	  STATUS => "1"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>E>	  .COACTIVITY => "The Coactivity class"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>M>	  "KILLED" => "4"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>O>	  "==" => "0"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>>>	  "0"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	204	*-*	if var("yieldValue")
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>L>	  "yieldValue"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>A>	  "yieldValue"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>F>	  VAR => "0"
T1	A14	V5	1	*	method	The Coactivity class	RESUME	      	>>>	  "0"
T1	A8	V4	1	*	method	The StringRepeater class	YIELD.UPTO	349	*-*	return c
T2	A23	V5	1	*	method	The Coactivity class	YIELD	      	>V>	  STATUS => "1"
T1	A8	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>V>	  C => "a Coactivity"
T2	A23	V5	1	*	method	The Coactivity class	YIELD	      	>E>	  .COACTIVITY => "The Coactivity class"
T1	A8	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>>>	  "a Coactivity"
T2	A23	V5	1	*	method	The Coactivity class	YIELD	      	>M>	  "SUSPENDED" => "1"
T1	A24	V3	.	 	method	The StringRepeater class	TIMES.YIELD	      	>I>	Method TIMES.YIELD with scope "The StringRepeater class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\extension\functionals.cls
T2	A23	V5	1	*	method	The Coactivity class	YIELD	      	>O>	  "<>" => "0"
T1	A24	V3	1	*	method	The StringRepeater class	TIMES.YIELD	301	*-*	use strict arg action={arg(1)}
T2	A23	V5	1	*	method	The Coactivity class	YIELD	      	>>>	  "0"
T1	A24	V3	1	*	method	The StringRepeater class	TIMES.YIELD	      	>L>	  "a RexxContextualSource"
T1	A24	V3	1	*	method	The StringRepeater class	TIMES.YIELD	      	>>>	  "a RexxContextualSource"
T1	A24	V3	1	*	method	The StringRepeater class	TIMES.YIELD	      	>=>	  ACTION <= "a RexxContextualSource"
T1	A24	V3	1	*	method	The StringRepeater class	TIMES.YIELD	302	*-*	forward to 1 message "yield.upto" array(self, action)
T1	A24	V3	1	*	method	The StringRepeater class	TIMES.YIELD	      	>L>	  "1"
T1	A24	V3	1	*	method	The StringRepeater class	TIMES.YIELD	      	>L>	  "yield.upto"
T1	A24	V3	1	*	method	The StringRepeater class	TIMES.YIELD	      	>V>	  SELF => "1000"
T1	A24	V3	1	*	method	The StringRepeater class	TIMES.YIELD	      	>V>	  ACTION => "a RexxContextualSource"
T1	A25	V4	.	 	method	The StringRepeater class	YIELD.UPTO	      	>I>	Method YIELD.UPTO with scope "The StringRepeater class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\extension\functionals.cls
T1	A25	V4	1	*	method	The StringRepeater class	YIELD.UPTO	335	*-*	use strict arg upperLimit, action={arg(1)}
T1	A25	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>>>	  "1000"
T1	A25	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>=>	  UPPERLIMIT <= "1000"
T1	A25	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>>>	  "a RexxContextualSource"
T1	A25	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>=>	  ACTION <= "a RexxContextualSource"
T1	A25	V4	1	*	method	The StringRepeater class	YIELD.UPTO	336	*-*	c = .Coactivity~new{        -- expose self upperLimit action        -- to activate when closure supported        use strict arg self, upperLimit, action -- to remove when closure supported        .yield[]                                -- to remove when closure supported        -- parse only once, before iteration        if action~hasMethod("functionDoer") then doer = action~functionDoer("use arg value")                                            else doer = action~doer        do i = self to upperLimit            doer~do(i)            if var("result") then .yield[result]        end    }
T1	A25	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>E>	  .COACTIVITY => "The Coactivity class"
T1	A25	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>L>	  "a RexxContextualSource"
T1	A25	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>A>	  "a RexxContextualSource"
T1	A26	V9	.	 	method	The Coactivity class	INIT	      	>I>	Method INIT with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1	A26	V9	.	 	method	The Coactivity class	INIT	96	*-*	expose doer object status
T1	A26	V9	.	 	method	The Coactivity class	INIT	97	*-*	use strict arg action="main", start=.true, object=(self)
T1	A26	V9	.	 	method	The Coactivity class	INIT	      	>>>	  "a RexxContextualSource"
T1	A26	V9	.	 	method	The Coactivity class	INIT	      	>=>	  ACTION <= "a RexxContextualSource"
T1	A26	V9	.	 	method	The Coactivity class	INIT	      	>E>	  .TRUE => "1"
T1	A26	V9	.	 	method	The Coactivity class	INIT	      	>>>	  "1"
T1	A26	V9	.	 	method	The Coactivity class	INIT	      	>=>	  START <= "1"
T1	A26	V9	.	 	method	The Coactivity class	INIT	      	>V>	  SELF => "a Coactivity"
T1	A26	V9	.	 	method	The Coactivity class	INIT	      	>>>	  "a Coactivity"
T1	A26	V9	.	 	method	The Coactivity class	INIT	      	>=>	  OBJECT <= "a Coactivity"
T1	A26	V9	.	 	method	The Coactivity class	INIT	99	*-*	doer = action~doer
T1	A26	V9	.	 	method	The Coactivity class	INIT	      	>V>	  ACTION => "a RexxContextualSource"
T1	A27	V10	.	 	method	The RexxContextualSourceDoer class	DOER	      	>I>	Method DOER with scope "The RexxContextualSourceDoer class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\extension\doers.cls
T1	A27	V10	1	*	method	The RexxContextualSourceDoer class	DOER	359	*-*	use strict arg object=.nil -- optional object, needed when the source is tagged ::method
T1	A27	V10	1	*	method	The RexxContextualSourceDoer class	DOER	      	>E>	  .NIL => "The NIL object"
T1	A27	V10	1	*	method	The RexxContextualSourceDoer class	DOER	      	>>>	  "The NIL object"
T1	A27	V10	1	*	method	The RexxContextualSourceDoer class	DOER	      	>=>	  OBJECT <= "The NIL object"
T1	A27	V10	1	*	method	The RexxContextualSourceDoer class	DOER	360	*-*	if self~executable <> .nil
T1	A27	V10	1	*	method	The RexxContextualSourceDoer class	DOER	      	>V>	  SELF => "a RexxContextualSource"
T1	A27	V10	1	*	method	The RexxContextualSourceDoer class	DOER	      	>M>	  "EXECUTABLE" => "a Routine"
T1	A27	V10	1	*	method	The RexxContextualSourceDoer class	DOER	      	>E>	  .NIL => "The NIL object"
T1	A27	V10	1	*	method	The RexxContextualSourceDoer class	DOER	      	>O>	  "<>" => "1"
T1	A27	V10	1	*	method	The RexxContextualSourceDoer class	DOER	      	>>>	  "1"
T1	A27	V10	1	*	method	The RexxContextualSourceDoer class	DOER	360	*-*	  then
T1	A27	V10	1	*	method	The RexxContextualSourceDoer class	DOER	360	*-*	    return self~executable
T1	A27	V10	1	*	method	The RexxContextualSourceDoer class	DOER	      	>V>	      SELF => "a RexxContextualSource"
T1	A27	V10	1	*	method	The RexxContextualSourceDoer class	DOER	      	>M>	      "EXECUTABLE" => "a Routine"
T1	A27	V10	1	*	method	The RexxContextualSourceDoer class	DOER	      	>>>	      "a Routine"
T1	A26	V9	.	 	method	The Coactivity class	INIT	      	>M>	  "DOER" => "a Routine"
T1	A26	V9	.	 	method	The Coactivity class	INIT	      	>>>	  "a Routine"
T1	A26	V9	.	 	method	The Coactivity class	INIT	      	>=>	  DOER <= "a Routine"
T1	A26	V9	.	 	method	The Coactivity class	INIT	100	*-*	status = .Coactivity~notStarted
T1	A26	V9	.	 	method	The Coactivity class	INIT	      	>E>	  .COACTIVITY => "The Coactivity class"
T1	A26	V9	.	 	method	The Coactivity class	INIT	      	>M>	  "NOTSTARTED" => "0"
T1	A26	V9	.	 	method	The Coactivity class	INIT	      	>>>	  "0"
T1	A26	V9	.	 	method	The Coactivity class	INIT	      	>=>	  STATUS <= "0"
T1	A26	V9	.	 	method	The Coactivity class	INIT	101	*-*	if start
T1	A26	V9	.	 	method	The Coactivity class	INIT	      	>V>	  START => "1"
T1	A26	V9	.	 	method	The Coactivity class	INIT	      	>>>	  "1"
T1	A26	V9	.	 	method	The Coactivity class	INIT	101	*-*	  then
T1	A26	V9	.	 	method	The Coactivity class	INIT	101	*-*	    self~start
T1	A26	V9	.	 	method	The Coactivity class	INIT	      	>V>	      SELF => "a Coactivity"
T1	A28	V9	.	 	method	The Coactivity class	START	      	>I>	Method START with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1	A28	V9	1	*	method	The Coactivity class	START	116	*-*	expose arguments doer object status
T1	A28	V9	1	*	method	The Coactivity class	START	117	*-*	use strict arg -- no arg
T1	A28	V9	1	*	method	The Coactivity class	START	118	*-*	if status <> .Coactivity~notStarted
T1	A28	V9	1	*	method	The Coactivity class	START	      	>V>	  STATUS => "0"
T1	A28	V9	1	*	method	The Coactivity class	START	      	>E>	  .COACTIVITY => "The Coactivity class"
T1	A28	V9	1	*	method	The Coactivity class	START	      	>M>	  "NOTSTARTED" => "0"
T1	A28	V9	1	*	method	The Coactivity class	START	      	>O>	  "<>" => "0"
T1	A28	V9	1	*	method	The Coactivity class	START	      	>>>	  "0"
T1	A28	V9	1	*	method	The Coactivity class	START	119	*-*	status = .Coactivity~suspended
T1	A28	V9	1	*	method	The Coactivity class	START	      	>E>	  .COACTIVITY => "The Coactivity class"
T1	A28	V9	1	*	method	The Coactivity class	START	      	>M>	  "SUSPENDED" => "1"
T1	A28	V9	1	*	method	The Coactivity class	START	      	>>>	  "1"
T1	A28	V9	1	*	method	The Coactivity class	START	      	>=>	  STATUS <= "1"
T1	A28	V9	1	*	method	The Coactivity class	START	120	*-*	reply self
T1	A28	V9	1	*	method	The Coactivity class	START	      	>V>	  SELF => "a Coactivity"
T1	A28	V9	1	*	method	The Coactivity class	START	      	>>>	  "a Coactivity"
T3	A28	V9	1	*	method	The Coactivity class	START	      	>I>	Method START with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1	A26	V9	1	 	method	The Coactivity class	INIT	      	>>>	      "a Coactivity"
T3	A28	V9	1	*	method	The Coactivity class	START	121	*-*	.Activity~local~empty
T1	A25	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>M>	  "NEW" => "a Coactivity"
T3	A28	V9	1	*	method	The Coactivity class	START	      	>E>	  .ACTIVITY => "The Activity class"
T1	A25	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>>>	  "a Coactivity"
T3	A29	V1	.	 	method	The Activity class	LOCAL	      	>I>	Method LOCAL with scope "The Activity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\activity.cls
T1	A25	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>=>	  C <= "a Coactivity"
T3	A29	V1	1	*	method	The Activity class	LOCAL	34	*-*	expose directory
T1	A25	V4	1	*	method	The StringRepeater class	YIELD.UPTO	348	*-*	c~resume(self, upperLimit, action) -- to remove when closure supported
T3	A29	V1	1	*	method	The Activity class	LOCAL	35	*-*	threadId=self~currentThreadId
T1	A25	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>V>	  C => "a Coactivity"
T3	A29	V1	1	*	method	The Activity class	LOCAL	      	>V>	  SELF => "The Activity class"
T1	A25	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>V>	  SELF => "1"
T3	A30	V1	1	 	method	The Activity class	CURRENTTHREADID	      	>I>	Method CURRENTTHREADID with scope "The Activity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\activity.cls
T1	A25	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>A>	  "1"
T3	A30	V1	2	*	method	The Activity class	CURRENTTHREADID	29	*-*	if .rxunixsys.loaded
T1	A25	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>V>	  UPPERLIMIT => "1000"
T3	A30	V1	2	*	method	The Activity class	CURRENTTHREADID	      	>E>	  .RXUNIXSYS.LOADED => "0"
T1	A25	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>A>	  "1000"
T3	A30	V1	2	*	method	The Activity class	CURRENTTHREADID	      	>>>	  "0"
T1	A25	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>V>	  ACTION => "a RexxContextualSource"
T3	A30	V1	2	*	method	The Activity class	CURRENTTHREADID	30	*-*	  else
T1	A25	V4	1	*	method	The StringRepeater class	YIELD.UPTO	      	>A>	  "a RexxContextualSource"
T3	A30	V1	2	*	method	The Activity class	CURRENTTHREADID	30	*-*	    return SysQueryProcess("TID") -- Windows
T1	A31	V9	1	 	method	The Coactivity class	RESUME	      	>I>	Method RESUME with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T3	A30	V1	2	*	method	The Activity class	CURRENTTHREADID	      	>L>	      "TID"
T3	A30	V1	2	*	method	The Activity class	CURRENTTHREADID	      	>A>	      "TID"
T3	A30	V1	2	*	method	The Activity class	CURRENTTHREADID	      	>F>	      SYSQUERYPROCESS => "24512"
T3	A30	V1	2	*	method	The Activity class	CURRENTTHREADID	      	>>>	      "24512"
T3	A29	V1	1	*	method	The Activity class	LOCAL	      	>M>	  "CURRENTTHREADID" => "24512"
T3	A29	V1	1	*	method	The Activity class	LOCAL	      	>>>	  "24512"
T3	A29	V1	1	*	method	The Activity class	LOCAL	      	>=>	  THREADID <= "24512"
T3	A29	V1	1	*	method	The Activity class	LOCAL	36	*-*	local = directory[threadId]
T3	A29	V1	1	*	method	The Activity class	LOCAL	      	>V>	  DIRECTORY => "a Directory"
T3	A29	V1	1	*	method	The Activity class	LOCAL	      	>V>	  THREADID => "24512"
T3	A29	V1	1	*	method	The Activity class	LOCAL	      	>A>	  "24512"
T3	A29	V1	1	*	method	The Activity class	LOCAL	      	>M>	  "[]" => "The NIL object"
T3	A29	V1	1	*	method	The Activity class	LOCAL	      	>>>	  "The NIL object"
T3	A29	V1	1	*	method	The Activity class	LOCAL	      	>=>	  LOCAL <= "The NIL object"
T3	A29	V1	1	*	method	The Activity class	LOCAL	37	*-*	if local == .nil
T3	A29	V1	1	*	method	The Activity class	LOCAL	      	>V>	  LOCAL => "The NIL object"
T3	A29	V1	1	*	method	The Activity class	LOCAL	      	>E>	  .NIL => "The NIL object"
T3	A29	V1	1	*	method	The Activity class	LOCAL	      	>O>	  "==" => "1"
T3	A29	V1	1	*	method	The Activity class	LOCAL	      	>>>	  "1"
T3	A29	V1	1	*	method	The Activity class	LOCAL	37	*-*	  then
T3	A29	V1	1	*	method	The Activity class	LOCAL	37	*-*	    do
T3	A29	V1	1	*	method	The Activity class	LOCAL	38	*-*	      local = .Directory~new
T3	A29	V1	1	*	method	The Activity class	LOCAL	      	>E>	        .DIRECTORY => "The Directory class"
T3	A29	V1	1	*	method	The Activity class	LOCAL	      	>M>	        "NEW" => "a Directory"
T3	A29	V1	1	*	method	The Activity class	LOCAL	      	>>>	        "a Directory"
T3	A29	V1	1	*	method	The Activity class	LOCAL	      	>=>	        LOCAL <= "a Directory"
T3	A29	V1	1	*	method	The Activity class	LOCAL	39	*-*	      directory[threadId] = local
T3	A29	V1	1	*	method	The Activity class	LOCAL	      	>V>	        DIRECTORY => "a Directory"
T3	A29	V1	1	*	method	The Activity class	LOCAL	      	>V>	        LOCAL => "a Directory"
T3	A29	V1	1	*	method	The Activity class	LOCAL	      	>A>	        "a Directory"
T3	A29	V1	1	*	method	The Activity class	LOCAL	      	>V>	        THREADID => "24512"
T3	A29	V1	1	*	method	The Activity class	LOCAL	      	>A>	        "24512"
T3	A29	V1	1	*	method	The Activity class	LOCAL	40	*-*	  end
T3	A29	V1	1	*	method	The Activity class	LOCAL	41	*-*	return local
T3	A29	V1	1	*	method	The Activity class	LOCAL	      	>V>	  LOCAL => "a Directory"
T3	A29	V1	1	*	method	The Activity class	LOCAL	      	>>>	  "a Directory"
T3	A28	V9	1	*	method	The Coactivity class	START	      	>M>	  "LOCAL" => "a Directory"
T3	A28	V9	1	*	method	The Coactivity class	START	122	*-*	.Activity~local~coactivity = self
T3	A28	V9	1	*	method	The Coactivity class	START	      	>E>	  .ACTIVITY => "The Activity class"
T3	A32	V1	.	 	method	The Activity class	LOCAL	      	>I>	Method LOCAL with scope "The Activity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\activity.cls
T3	A32	V1	1	*	method	The Activity class	LOCAL	34	*-*	expose directory
T3	A32	V1	1	*	method	The Activity class	LOCAL	35	*-*	threadId=self~currentThreadId
T3	A32	V1	1	*	method	The Activity class	LOCAL	      	>V>	  SELF => "The Activity class"
T3	A33	V1	1	 	method	The Activity class	CURRENTTHREADID	      	>I>	Method CURRENTTHREADID with scope "The Activity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\activity.cls
T3	A33	V1	2	*	method	The Activity class	CURRENTTHREADID	29	*-*	if .rxunixsys.loaded
T3	A33	V1	2	*	method	The Activity class	CURRENTTHREADID	      	>E>	  .RXUNIXSYS.LOADED => "0"
T3	A33	V1	2	*	method	The Activity class	CURRENTTHREADID	      	>>>	  "0"
T3	A33	V1	2	*	method	The Activity class	CURRENTTHREADID	30	*-*	  else
T3	A33	V1	2	*	method	The Activity class	CURRENTTHREADID	30	*-*	    return SysQueryProcess("TID") -- Windows
T3	A33	V1	2	*	method	The Activity class	CURRENTTHREADID	      	>L>	      "TID"
T3	A33	V1	2	*	method	The Activity class	CURRENTTHREADID	      	>A>	      "TID"
T3	A33	V1	2	*	method	The Activity class	CURRENTTHREADID	      	>F>	      SYSQUERYPROCESS => "24512"
T3	A33	V1	2	*	method	The Activity class	CURRENTTHREADID	      	>>>	      "24512"
T3	A32	V1	1	*	method	The Activity class	LOCAL	      	>M>	  "CURRENTTHREADID" => "24512"
T3	A32	V1	1	*	method	The Activity class	LOCAL	      	>>>	  "24512"
T3	A32	V1	1	*	method	The Activity class	LOCAL	      	>=>	  THREADID <= "24512"
T3	A32	V1	1	*	method	The Activity class	LOCAL	36	*-*	local = directory[threadId]
T3	A32	V1	1	*	method	The Activity class	LOCAL	      	>V>	  DIRECTORY => "a Directory"
T3	A32	V1	1	*	method	The Activity class	LOCAL	      	>V>	  THREADID => "24512"
T3	A32	V1	1	*	method	The Activity class	LOCAL	      	>A>	  "24512"
T3	A32	V1	1	*	method	The Activity class	LOCAL	      	>M>	  "[]" => "a Directory"
T3	A32	V1	1	*	method	The Activity class	LOCAL	      	>>>	  "a Directory"
T3	A32	V1	1	*	method	The Activity class	LOCAL	      	>=>	  LOCAL <= "a Directory"
T3	A32	V1	1	*	method	The Activity class	LOCAL	37	*-*	if local == .nil
T3	A32	V1	1	*	method	The Activity class	LOCAL	      	>V>	  LOCAL => "a Directory"
T3	A32	V1	1	*	method	The Activity class	LOCAL	      	>E>	  .NIL => "The NIL object"
T3	A32	V1	1	*	method	The Activity class	LOCAL	      	>O>	  "==" => "0"
T3	A32	V1	1	*	method	The Activity class	LOCAL	      	>>>	  "0"
T3	A32	V1	1	*	method	The Activity class	LOCAL	41	*-*	return local
T3	A32	V1	1	*	method	The Activity class	LOCAL	      	>V>	  LOCAL => "a Directory"
T3	A32	V1	1	*	method	The Activity class	LOCAL	      	>>>	  "a Directory"
T3	A28	V9	1	*	method	The Coactivity class	START	      	>M>	  "LOCAL" => "a Directory"
T3	A28	V9	1	*	method	The Coactivity class	START	      	>V>	  SELF => "a Coactivity"
T3	A28	V9	1	*	method	The Coactivity class	START	      	>A>	  "a Coactivity"
T3	A28	V9	1	*	method	The Coactivity class	START	123	*-*	.Coactivity~table[self] = self
T3	A28	V9	1	*	method	The Coactivity class	START	      	>E>	  .COACTIVITY => "The Coactivity class"
T3	A28	V9	1	*	method	The Coactivity class	START	      	>M>	  "TABLE" => "an IdentityTable"
T3	A28	V9	1	*	method	The Coactivity class	START	      	>V>	  SELF => "a Coactivity"
T3	A28	V9	1	*	method	The Coactivity class	START	      	>A>	  "a Coactivity"
T3	A28	V9	1	*	method	The Coactivity class	START	      	>V>	  SELF => "a Coactivity"
T3	A28	V9	1	*	method	The Coactivity class	START	      	>A>	  "a Coactivity"
T3	A28	V9	1	*	method	The Coactivity class	START	124	*-*	signal on any name trapCondition -- catch all
T3	A28	V9	1	*	method	The Coactivity class	START	125	*-*	signal on syntax name trapCondition -- gives better messages
T3	A28	V9	1	*	method	The Coactivity class	START	126	*-*	guard off
T3	A28	V9	1	 	method	The Coactivity class	START	127	*-*	guard on when status <> .Coactivity~suspended
T1	A31	V9	1	*	method	The Coactivity class	RESUME	195	*-*	expose arguments status yieldValue
T1	A31	V9	1	*	method	The Coactivity class	RESUME	196	*-*	if status == .Coactivity~notStarted
T1	A31	V9	1	*	method	The Coactivity class	RESUME	      	>V>	  STATUS => "1"
T1	A31	V9	1	*	method	The Coactivity class	RESUME	      	>E>	  .COACTIVITY => "The Coactivity class"
T1	A31	V9	1	*	method	The Coactivity class	RESUME	      	>M>	  "NOTSTARTED" => "0"
T1	A31	V9	1	*	method	The Coactivity class	RESUME	      	>O>	  "==" => "0"
T1	A31	V9	1	*	method	The Coactivity class	RESUME	      	>>>	  "0"
T1	A31	V9	1	*	method	The Coactivity class	RESUME	197	*-*	if status == .Coactivity~killed
T1	A31	V9	1	*	method	The Coactivity class	RESUME	      	>V>	  STATUS => "1"
T1	A31	V9	1	*	method	The Coactivity class	RESUME	      	>E>	  .COACTIVITY => "The Coactivity class"
T1	A31	V9	1	*	method	The Coactivity class	RESUME	      	>M>	  "KILLED" => "4"
T1	A31	V9	1	*	method	The Coactivity class	RESUME	      	>O>	  "==" => "0"
T1	A31	V9	1	*	method	The Coactivity class	RESUME	      	>>>	  "0"
T1	A31	V9	1	*	method	The Coactivity class	RESUME	198	*-*	if status == .Coactivity~ended
T1	A31	V9	1	*	method	The Coactivity class	RESUME	      	>V>	  STATUS => "1"
T1	A31	V9	1	*	method	The Coactivity class	RESUME	      	>E>	  .COACTIVITY => "The Coactivity class"
T1	A31	V9	1	*	method	The Coactivity class	RESUME	      	>M>	  "ENDED" => "3"
T1	A31	V9	1	*	method	The Coactivity class	RESUME	      	>O>	  "==" => "0"
T1	A31	V9	1	*	method	The Coactivity class	RESUME	      	>>>	  "0"
T1	A31	V9	1	*	method	The Coactivity class	RESUME	199	*-*	arguments = arg(1, "a")
T1	A31	V9	1	*	method	The Coactivity class	RESUME	      	>L>	  "1"
T1	A31	V9	1	*	method	The Coactivity class	RESUME	      	>A>	  "1"
T1	A31	V9	1	*	method	The Coactivity class	RESUME	      	>L>	  "a"
T1	A31	V9	1	*	method	The Coactivity class	RESUME	      	>A>	  "a"
T1	A31	V9	1	*	method	The Coactivity class	RESUME	      	>F>	  ARG => "an Array"
T1	A31	V9	1	*	method	The Coactivity class	RESUME	      	>>>	  "an Array"
T1	A31	V9	1	*	method	The Coactivity class	RESUME	      	>=>	  ARGUMENTS <= "an Array"
T1	A31	V9	1	*	method	The Coactivity class	RESUME	200	*-*	status = .Coactivity~running
T1	A31	V9	1	*	method	The Coactivity class	RESUME	      	>E>	  .COACTIVITY => "The Coactivity class"
T1	A31	V9	1	*	method	The Coactivity class	RESUME	      	>M>	  "RUNNING" => "2"
T1	A31	V9	1	*	method	The Coactivity class	RESUME	      	>>>	  "2"
T1	A31	V9	1	*	method	The Coactivity class	RESUME	      	>=>	  STATUS <= "2"
T1	A31	V9	1	*	method	The Coactivity class	RESUME	201	*-*	guard off
T1	A31	V9	1	 	method	The Coactivity class	RESUME	202	*-*	guard on when status <> .Coactivity~running
T3	A28	V9	1	*	method	The Coactivity class	START	      	>V>	  STATUS => "2"
T3	A28	V9	1	*	method	The Coactivity class	START	      	>E>	  .COACTIVITY => "The Coactivity class"
T3	A28	V9	1	*	method	The Coactivity class	START	      	>M>	  "SUSPENDED" => "1"
T3	A28	V9	1	*	method	The Coactivity class	START	      	>O>	  "<>" => "1"
T3	A28	V9	1	*	method	The Coactivity class	START	      	>>>	  "1"
T3	A28	V9	1	*	method	The Coactivity class	START	128	*-*	if status == .Coactivity~running
T3	A28	V9	1	*	method	The Coactivity class	START	      	>V>	  STATUS => "2"
T3	A28	V9	1	*	method	The Coactivity class	START	      	>E>	  .COACTIVITY => "The Coactivity class"
T3	A28	V9	1	*	method	The Coactivity class	START	      	>M>	  "RUNNING" => "2"
T3	A28	V9	1	*	method	The Coactivity class	START	      	>O>	  "==" => "1"
T3	A28	V9	1	*	method	The Coactivity class	START	      	>>>	  "1"
T3	A28	V9	1	*	method	The Coactivity class	START	128	*-*	  then
T3	A28	V9	1	*	method	The Coactivity class	START	128	*-*	    do
T3	A28	V9	1	*	method	The Coactivity class	START	129	*-*	      guard off
T3	A28	V9	1	 	method	The Coactivity class	START	131	*-*	      if doer~needsObject
T1	A31	V9	1	*	method	The Coactivity class	RESUME	      	>V>	  STATUS => "2"
T3	A28	V9	1	 	method	The Coactivity class	START	      	>V>	        DOER => "a Routine"
T1	A31	V9	1	*	method	The Coactivity class	RESUME	      	>E>	  .COACTIVITY => "The Coactivity class"
T3	A34	V7	1	 	method	The RoutineDoer class	NEEDSOBJECT	      	>I>	Method NEEDSOBJECT with scope "The RoutineDoer class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\extension\doers.cls
T1	A31	V9	1	*	method	The Coactivity class	RESUME	      	>M>	  "RUNNING" => "2"
T1	A31	V9	1	*	method	The Coactivity class	RESUME	      	>O>	  "<>" => "0"
T1	A31	V9	1	*	method	The Coactivity class	RESUME	      	>>>	  "0"
*/

