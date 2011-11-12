/*
An example of deadlock, and how to avoid it.

This a due to the change of implementation of coactivity :
To let an auto-end, the coactivity has been splitted in two parts :
- a wrapper object (.Coactivity)
- a wrapped object (.CoactivityObj)
The wrapper forwards the messages to the wrapped.

We have a deadlock because .Coactivity~resume was guarded.
When entering this method, the lock is set on V2 :
T1	A9	V2	.	 	method	The Coactivity class	RESUME	      	>I>	Method RESUME with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1	A9	V2	1	*	method	The Coactivity class	RESUME	170	*-*	expose coactivityObj
T1	A9	V2	1	*	method	The Coactivity class	RESUME	171	*-*	forward to (coactivityObj)

From here, the wrapped coactivityObj is started, in the call context of .Coactivity~resume.
The wrapped coactivityObj calls self~yield :
T2	A17	V2	1	 	method	The Coactivity class	YIELD	      	>I>	Method YIELD with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
deadlock... 

...because V2 is already reserved by T1 which is currently waiting here (still in the call context of .Coactivity~resume) :
T1	A10	V3	1	 	method	The CoactivityObj class	RESUME	329	*-*	guard on when status <> .CoactivityObj~running
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>V>	  STATUS => "2"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>E>	  .COACTIVITYOBJ => "The CoactivityObj class"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>M>	  "RUNNING" => "2"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>O>	  "<>" => "0"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>>>	  "0"

To avoid this deadlock, must declare unguarded all the methods of .Coactivity which could start the coactivity :
start
resume


Todo : 
It's not obvious from the trace output that V2 is currently locked by another activity
T2	A17	V2	1	 	method	The Coactivity class	YIELD	      	>I>	Method YIELD with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
There is no * indicating a lock because the '*' is displayed when the current activity gets the lock.
Should see if I can add another column which indicates that the variable dictionary is locked by another activity.

*/

c = .myCoactivity~new
c~resume
c~resume
say "Ended coactivities:" .Coactivity~endAll

::class myCoactivity  inherit Coactivity
::method main -- entry point
    -- Here, self is the coactivity.
    do forever
        self~yield
    end

--::options trace i
::options NOMACROSPACE
::requires "extension/extensions.cls"

/***************************************************************
Trace output (CSV) in case of deadlock
****************************************************************
T1	A1	V1	.	 	method	The Coactivity class	INIT	      	>I>	Method INIT with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1	A1	V1	1	*	method	The Coactivity class	INIT	51	*-*	expose globalCache
T1	A1	V1	1	*	method	The Coactivity class	INIT	53	*-*	globalCache = .Directory~new
T1	A1	V1	1	*	method	The Coactivity class	INIT	      	>E>	  .DIRECTORY => "The Directory class"
T1	A1	V1	1	*	method	The Coactivity class	INIT	      	>M>	  "NEW" => "a Directory"
T1	A1	V1	1	*	method	The Coactivity class	INIT	      	>>>	  "a Directory"
T1	A1	V1	1	*	method	The Coactivity class	INIT	      	>=>	  GLOBALCACHE <= "a Directory"
T1	A1	V1	1	*	method	The Coactivity class	INIT	54	*-*	self~makeArrayLimit = 10000 -- not a constant, not a private attribute, I think it's useful to let the end user change this value
T1	A1	V1	1	*	method	The Coactivity class	INIT	      	>V>	  SELF => "The Coactivity class"
T1	A1	V1	1	*	method	The Coactivity class	INIT	      	>L>	  "10000"
T1	A1	V1	1	*	method	The Coactivity class	INIT	      	>A>	  "10000"
T1	A1	V1	1	*	method	The Coactivity class	INIT	      	>>>	  "10000"
T1	A2	.	.	 	routine		d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls	      	>I>	Routine d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1	A3	.	.	 	routine		d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\extension\doers.cls	      	>I>	Routine d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\extension\doers.cls in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\extension\doers.cls
T1	A4	.	.	 	routine		d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\extension\functionals.cls	      	>I>	Routine d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\extension\functionals.cls in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\extension\functionals.cls
T1	A5	.	.	 				1	*-*	c = .myCoactivity~new
T1	A5	.	.	 				      	>E>	  .MYCOACTIVITY => "The MYCOACTIVITY class"
T1	A6	V2	.	 	method	The Coactivity class	INIT	      	>I>	Method INIT with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1	A6	V2	.	 	method	The Coactivity class	INIT	106	*-*	expose coactivityObj
T1	A6	V2	.	 	method	The Coactivity class	INIT	107	*-*	proxy = .WeakProxy~new(self)
T1	A6	V2	.	 	method	The Coactivity class	INIT	      	>E>	  .WEAKPROXY => "The WeakProxy class"
T1	A6	V2	.	 	method	The Coactivity class	INIT	      	>V>	  SELF => "a MYCOACTIVITY"
T1	A6	V2	.	 	method	The Coactivity class	INIT	      	>A>	  "a MYCOACTIVITY"
T1	A6	V2	.	 	method	The Coactivity class	INIT	      	>M>	  "NEW" => "a WeakProxy"
T1	A6	V2	.	 	method	The Coactivity class	INIT	      	>>>	  "a WeakProxy"
T1	A6	V2	.	 	method	The Coactivity class	INIT	      	>=>	  PROXY <= "a WeakProxy"
T1	A6	V2	.	 	method	The Coactivity class	INIT	108	*-*	use strict arg action="main", start=.false, object=(proxy) -- object must reference the proxy, not directly the coactivity, otherwise the coactivity will never be GC'ed
T1	A6	V2	.	 	method	The Coactivity class	INIT	      	>L>	  "main"
T1	A6	V2	.	 	method	The Coactivity class	INIT	      	>>>	  "main"
T1	A6	V2	.	 	method	The Coactivity class	INIT	      	>=>	  ACTION <= "main"
T1	A6	V2	.	 	method	The Coactivity class	INIT	      	>E>	  .FALSE => "0"
T1	A6	V2	.	 	method	The Coactivity class	INIT	      	>>>	  "0"
T1	A6	V2	.	 	method	The Coactivity class	INIT	      	>=>	  START <= "0"
T1	A6	V2	.	 	method	The Coactivity class	INIT	      	>V>	  PROXY => "a WeakProxy"
T1	A6	V2	.	 	method	The Coactivity class	INIT	      	>>>	  "a WeakProxy"
T1	A6	V2	.	 	method	The Coactivity class	INIT	      	>=>	  OBJECT <= "a WeakProxy"
T1	A6	V2	.	 	method	The Coactivity class	INIT	109	*-*	coactivityObj = .CoactivityObj~new(action, start, object, proxy) -- pass itself as proxy, to be stored on the wrapped coactivityObj (needed for supplier)
T1	A6	V2	.	 	method	The Coactivity class	INIT	      	>E>	  .COACTIVITYOBJ => "The CoactivityObj class"
T1	A6	V2	.	 	method	The Coactivity class	INIT	      	>V>	  ACTION => "main"
T1	A6	V2	.	 	method	The Coactivity class	INIT	      	>A>	  "main"
T1	A6	V2	.	 	method	The Coactivity class	INIT	      	>V>	  START => "0"
T1	A6	V2	.	 	method	The Coactivity class	INIT	      	>A>	  "0"
T1	A6	V2	.	 	method	The Coactivity class	INIT	      	>V>	  OBJECT => "a WeakProxy"
T1	A6	V2	.	 	method	The Coactivity class	INIT	      	>A>	  "a WeakProxy"
T1	A6	V2	.	 	method	The Coactivity class	INIT	      	>V>	  PROXY => "a WeakProxy"
T1	A6	V2	.	 	method	The Coactivity class	INIT	      	>A>	  "a WeakProxy"
T1	A7	V3	.	 	method	The CoactivityObj class	INIT	      	>I>	Method INIT with scope "The CoactivityObj class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1	A7	V3	.	 	method	The CoactivityObj class	INIT	249	*-*	expose proxy doer object status
T1	A7	V3	.	 	method	The CoactivityObj class	INIT	250	*-*	use strict arg action, start, object, proxy
T1	A7	V3	.	 	method	The CoactivityObj class	INIT	      	>>>	  "main"
T1	A7	V3	.	 	method	The CoactivityObj class	INIT	      	>=>	  ACTION <= "main"
T1	A7	V3	.	 	method	The CoactivityObj class	INIT	      	>>>	  "0"
T1	A7	V3	.	 	method	The CoactivityObj class	INIT	      	>=>	  START <= "0"
T1	A7	V3	.	 	method	The CoactivityObj class	INIT	      	>>>	  "a WeakProxy"
T1	A7	V3	.	 	method	The CoactivityObj class	INIT	      	>=>	  OBJECT <= "a WeakProxy"
T1	A7	V3	.	 	method	The CoactivityObj class	INIT	      	>>>	  "a WeakProxy"
T1	A7	V3	.	 	method	The CoactivityObj class	INIT	      	>=>	  PROXY <= "a WeakProxy"
T1	A7	V3	.	 	method	The CoactivityObj class	INIT	251	*-*	doer = action~doer
T1	A7	V3	.	 	method	The CoactivityObj class	INIT	      	>V>	  ACTION => "main"
T1	A8	V4	.	 	method	The StringDoer class	DOER	      	>I>	Method DOER with scope "The StringDoer class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\extension\doers.cls
T1	A8	V4	.	 	method	The StringDoer class	DOER	319	*-*	use strict arg -- none
T1	A8	V4	.	 	method	The StringDoer class	DOER	320	*-*	return self -- When used as a doer factory, a string is a message
T1	A8	V4	.	 	method	The StringDoer class	DOER	      	>V>	  SELF => "main"
T1	A8	V4	.	 	method	The StringDoer class	DOER	      	>>>	  "main"
T1	A7	V3	.	 	method	The CoactivityObj class	INIT	      	>M>	  "DOER" => "main"
T1	A7	V3	.	 	method	The CoactivityObj class	INIT	      	>>>	  "main"
T1	A7	V3	.	 	method	The CoactivityObj class	INIT	      	>=>	  DOER <= "main"
T1	A7	V3	.	 	method	The CoactivityObj class	INIT	252	*-*	status = .CoactivityObj~notStarted
T1	A7	V3	.	 	method	The CoactivityObj class	INIT	      	>E>	  .COACTIVITYOBJ => "The CoactivityObj class"
T1	A7	V3	.	 	method	The CoactivityObj class	INIT	      	>M>	  "NOTSTARTED" => "0"
T1	A7	V3	.	 	method	The CoactivityObj class	INIT	      	>>>	  "0"
T1	A7	V3	.	 	method	The CoactivityObj class	INIT	      	>=>	  STATUS <= "0"
T1	A7	V3	.	 	method	The CoactivityObj class	INIT	253	*-*	if start 
T1	A7	V3	.	 	method	The CoactivityObj class	INIT	      	>V>	  START => "0"
T1	A7	V3	.	 	method	The CoactivityObj class	INIT	      	>>>	  "0"
T1	A6	V2	.	 	method	The Coactivity class	INIT	      	>M>	  "NEW" => "a CoactivityObj"
T1	A6	V2	.	 	method	The Coactivity class	INIT	      	>>>	  "a CoactivityObj"
T1	A6	V2	.	 	method	The Coactivity class	INIT	      	>=>	  COACTIVITYOBJ <= "a CoactivityObj"
T1	A5	.	.	 				      	>M>	  "NEW" => "a MYCOACTIVITY"
T1	A5	.	.	 				      	>>>	  "a MYCOACTIVITY"
T1	A5	.	.	 				      	>=>	  C <= "a MYCOACTIVITY"
T1	A5	.	.	 				2	*-*	c~resume
T1	A5	.	.	 				      	>V>	  C => "a MYCOACTIVITY"
T1	A9	V2	.	 	method	The Coactivity class	RESUME	      	>I>	Method RESUME with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1	A9	V2	1	*	method	The Coactivity class	RESUME	170	*-*	expose coactivityObj
T1	A9	V2	1	*	method	The Coactivity class	RESUME	171	*-*	forward to (coactivityObj)
T1	A9	V2	1	*	method	The Coactivity class	RESUME	      	>V>	  COACTIVITYOBJ => "a CoactivityObj"
T1	A10	V3	.	 	method	The CoactivityObj class	RESUME	      	>I>	Method RESUME with scope "The CoactivityObj class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	322	*-*	expose arguments status yieldValue
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	323	*-*	if status == .CoactivityObj~notStarted 
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>V>	  STATUS => "0"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>E>	  .COACTIVITYOBJ => "The CoactivityObj class"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>M>	  "NOTSTARTED" => "0"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>O>	  "==" => "1"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>>>	  "1"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	323	*-*	  then
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	323	*-*	    self~start
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>V>	      SELF => "a CoactivityObj"
T1	A11	V3	1	 	method	The CoactivityObj class	START	      	>I>	Method START with scope "The CoactivityObj class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T1	A11	V3	2	*	method	The CoactivityObj class	START	268	*-*	expose arguments doer object status
T1	A11	V3	2	*	method	The CoactivityObj class	START	269	*-*	use strict arg -- no arg
T1	A11	V3	2	*	method	The CoactivityObj class	START	270	*-*	if status <> .CoactivityObj~notStarted 
T1	A11	V3	2	*	method	The CoactivityObj class	START	      	>V>	  STATUS => "0"
T1	A11	V3	2	*	method	The CoactivityObj class	START	      	>E>	  .COACTIVITYOBJ => "The CoactivityObj class"
T1	A11	V3	2	*	method	The CoactivityObj class	START	      	>M>	  "NOTSTARTED" => "0"
T1	A11	V3	2	*	method	The CoactivityObj class	START	      	>O>	  "<>" => "0"
T1	A11	V3	2	*	method	The CoactivityObj class	START	      	>>>	  "0"
T1	A11	V3	2	*	method	The CoactivityObj class	START	271	*-*	status = .CoactivityObj~suspended
T1	A11	V3	2	*	method	The CoactivityObj class	START	      	>E>	  .COACTIVITYOBJ => "The CoactivityObj class"
T1	A11	V3	2	*	method	The CoactivityObj class	START	      	>M>	  "SUSPENDED" => "1"
T1	A11	V3	2	*	method	The CoactivityObj class	START	      	>>>	  "1"
T1	A11	V3	2	*	method	The CoactivityObj class	START	      	>=>	  STATUS <= "1"
T1	A11	V3	2	*	method	The CoactivityObj class	START	272	*-*	reply self
T1	A11	V3	2	*	method	The CoactivityObj class	START	      	>V>	  SELF => "a CoactivityObj"
T1	A11	V3	2	*	method	The CoactivityObj class	START	      	>>>	  "a CoactivityObj"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>>>	      "a CoactivityObj"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	324	*-*	if status == .CoactivityObj~killed 
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>V>	  STATUS => "1"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>E>	  .COACTIVITYOBJ => "The CoactivityObj class"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>M>	  "KILLED" => "4"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>O>	  "==" => "0"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>>>	  "0"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	325	*-*	if status == .CoactivityObj~ended 
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>V>	  STATUS => "1"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>E>	  .COACTIVITYOBJ => "The CoactivityObj class"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>M>	  "ENDED" => "3"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>O>	  "==" => "0"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>>>	  "0"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	326	*-*	arguments = arg(1, "a")
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>L>	  "1"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>A>	  "1"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>L>	  "a"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>A>	  "a"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>F>	  ARG => "an Array"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>>>	  "an Array"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>=>	  ARGUMENTS <= "an Array"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	327	*-*	status = .CoactivityObj~running
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>E>	  .COACTIVITYOBJ => "The CoactivityObj class"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>M>	  "RUNNING" => "2"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>>>	  "2"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>=>	  STATUS <= "2"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	328	*-*	guard off
T1	A10	V3	1	 	method	The CoactivityObj class	RESUME	329	*-*	guard on when status <> .CoactivityObj~running
T2	A11	V3	1	*	method	The CoactivityObj class	START	      	>I>	Method START with scope "The CoactivityObj class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T2	A11	V3	1	*	method	The CoactivityObj class	START	273	*-*	.Activity~local~empty
T2	A11	V3	1	*	method	The CoactivityObj class	START	      	>E>	  .ACTIVITY => "The Activity class"
T2	A11	V3	1	*	method	The CoactivityObj class	START	      	>M>	  "LOCAL" => "a Directory"
T2	A11	V3	1	*	method	The CoactivityObj class	START	274	*-*	.Activity~local~coactivityObj = self
T2	A11	V3	1	*	method	The CoactivityObj class	START	      	>E>	  .ACTIVITY => "The Activity class"
T2	A11	V3	1	*	method	The CoactivityObj class	START	      	>M>	  "LOCAL" => "a Directory"
T2	A11	V3	1	*	method	The CoactivityObj class	START	      	>V>	  SELF => "a CoactivityObj"
T2	A11	V3	1	*	method	The CoactivityObj class	START	      	>A>	  "a CoactivityObj"
T2	A11	V3	1	*	method	The CoactivityObj class	START	275	*-*	.Coactivity~register(self)
T2	A11	V3	1	*	method	The CoactivityObj class	START	      	>E>	  .COACTIVITY => "The Coactivity class"
T2	A11	V3	1	*	method	The CoactivityObj class	START	      	>V>	  SELF => "a CoactivityObj"
T2	A11	V3	1	*	method	The CoactivityObj class	START	      	>A>	  "a CoactivityObj"
T2	A12	V1	.	 	method	The Coactivity class	REGISTER	      	>I>	Method REGISTER with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T2	A12	V1	1	*	method	The Coactivity class	REGISTER	58	*-*	expose globalCache
T2	A12	V1	1	*	method	The Coactivity class	REGISTER	59	*-*	use strict arg coactivityObj
T2	A12	V1	1	*	method	The Coactivity class	REGISTER	      	>>>	  "a CoactivityObj"
T2	A12	V1	1	*	method	The Coactivity class	REGISTER	      	>=>	  COACTIVITYOBJ <= "a CoactivityObj"
T2	A12	V1	1	*	method	The Coactivity class	REGISTER	63	*-*	globalCache[coactivityObj~identityHash] = coactivityObj
T2	A12	V1	1	*	method	The Coactivity class	REGISTER	      	>V>	  GLOBALCACHE => "a Directory"
T2	A12	V1	1	*	method	The Coactivity class	REGISTER	      	>V>	  COACTIVITYOBJ => "a CoactivityObj"
T2	A12	V1	1	*	method	The Coactivity class	REGISTER	      	>A>	  "a CoactivityObj"
T2	A12	V1	1	*	method	The Coactivity class	REGISTER	      	>V>	  COACTIVITYOBJ => "a CoactivityObj"
T2	A12	V1	1	*	method	The Coactivity class	REGISTER	      	>M>	  "IDENTITYHASH" => "266507003"
T2	A12	V1	1	*	method	The Coactivity class	REGISTER	      	>A>	  "266507003"
T2	A11	V3	1	*	method	The CoactivityObj class	START	276	*-*	signal on any name trapCondition -- catch all
T2	A11	V3	1	*	method	The CoactivityObj class	START	277	*-*	signal on syntax name trapCondition -- gives better messages
T2	A11	V3	1	*	method	The CoactivityObj class	START	278	*-*	guard off
T2	A11	V3	1	 	method	The CoactivityObj class	START	279	*-*	guard on when status <> .CoactivityObj~suspended
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>V>	  STATUS => "2"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>E>	  .COACTIVITYOBJ => "The CoactivityObj class"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>M>	  "RUNNING" => "2"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>O>	  "<>" => "0"
T1	A10	V3	1	*	method	The CoactivityObj class	RESUME	      	>>>	  "0"
T2	A11	V3	1	*	method	The CoactivityObj class	START	      	>V>	  STATUS => "2"
T2	A11	V3	1	*	method	The CoactivityObj class	START	      	>E>	  .COACTIVITYOBJ => "The CoactivityObj class"
T2	A11	V3	1	*	method	The CoactivityObj class	START	      	>M>	  "SUSPENDED" => "1"
T2	A11	V3	1	*	method	The CoactivityObj class	START	      	>O>	  "<>" => "1"
T2	A11	V3	1	*	method	The CoactivityObj class	START	      	>>>	  "1"
T2	A11	V3	1	*	method	The CoactivityObj class	START	280	*-*	if status == .CoactivityObj~running 
T2	A11	V3	1	*	method	The CoactivityObj class	START	      	>V>	  STATUS => "2"
T2	A11	V3	1	*	method	The CoactivityObj class	START	      	>E>	  .COACTIVITYOBJ => "The CoactivityObj class"
T2	A11	V3	1	*	method	The CoactivityObj class	START	      	>M>	  "RUNNING" => "2"
T2	A11	V3	1	*	method	The CoactivityObj class	START	      	>O>	  "==" => "1"
T2	A11	V3	1	*	method	The CoactivityObj class	START	      	>>>	  "1"
T2	A11	V3	1	*	method	The CoactivityObj class	START	280	*-*	  then
T2	A11	V3	1	*	method	The CoactivityObj class	START	280	*-*	    do
T2	A11	V3	1	*	method	The CoactivityObj class	START	281	*-*	      guard off
T2	A11	V3	.	 	method	The CoactivityObj class	START	283	*-*	      if doer~needsObject 
T2	A11	V3	.	 	method	The CoactivityObj class	START	      	>V>	        DOER => "main"
T2	A13	V4	.	 	method	The StringDoer class	NEEDSOBJECT	      	>I>	Method NEEDSOBJECT with scope "The StringDoer class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\extension\doers.cls
T2	A13	V4	.	 	method	The StringDoer class	NEEDSOBJECT	323	*-*	return .true -- Must pass an object as first argument when calling do or doWith
T2	A13	V4	.	 	method	The StringDoer class	NEEDSOBJECT	      	>E>	  .TRUE => "1"
T2	A13	V4	.	 	method	The StringDoer class	NEEDSOBJECT	      	>>>	  "1"
T2	A11	V3	.	 	method	The CoactivityObj class	START	      	>M>	        "NEEDSOBJECT" => "1"
T2	A11	V3	.	 	method	The CoactivityObj class	START	      	>>>	        "1"
T2	A11	V3	.	 	method	The CoactivityObj class	START	283	*-*	        then
T2	A11	V3	.	 	method	The CoactivityObj class	START	283	*-*	          doer~doWith(object, arguments) -- object needed (message, method)
T2	A11	V3	.	 	method	The CoactivityObj class	START	      	>V>	            DOER => "main"
T2	A11	V3	.	 	method	The CoactivityObj class	START	      	>V>	            OBJECT => "a WeakProxy"
T2	A11	V3	.	 	method	The CoactivityObj class	START	      	>A>	            "a WeakProxy"
T2	A11	V3	.	 	method	The CoactivityObj class	START	      	>V>	            ARGUMENTS => "an Array"
T2	A11	V3	.	 	method	The CoactivityObj class	START	      	>A>	            "an Array"
T2	A14	V4	.	 	method	The StringDoer class	DOWITH	      	>I>	Method DOWITH with scope "The StringDoer class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\extension\doers.cls
T2	A14	V4	.	 	method	The StringDoer class	DOWITH	331	*-*	use strict arg object, array
T2	A14	V4	.	 	method	The StringDoer class	DOWITH	      	>>>	  "a WeakProxy"
T2	A14	V4	.	 	method	The StringDoer class	DOWITH	      	>=>	  OBJECT <= "a WeakProxy"
T2	A14	V4	.	 	method	The StringDoer class	DOWITH	      	>>>	  "an Array"
T2	A14	V4	.	 	method	The StringDoer class	DOWITH	      	>=>	  ARRAY <= "an Array"
T2	A14	V4	.	 	method	The StringDoer class	DOWITH	332	*-*	object~sendWith(self, array)
T2	A14	V4	.	 	method	The StringDoer class	DOWITH	      	>V>	  OBJECT => "a WeakProxy"
T2	A14	V4	.	 	method	The StringDoer class	DOWITH	      	>V>	  SELF => "main"
T2	A14	V4	.	 	method	The StringDoer class	DOWITH	      	>A>	  "main"
T2	A14	V4	.	 	method	The StringDoer class	DOWITH	      	>V>	  ARRAY => "an Array"
T2	A14	V4	.	 	method	The StringDoer class	DOWITH	      	>A>	  "an Array"
T2	A15	V5	.	 	method	The WeakProxy class	UNKNOWN	      	>I>	Method UNKNOWN with scope "The WeakProxy class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
T2	A15	V5	1	*	method	The WeakProxy class	UNKNOWN	38	*-*	use arg msg, args
T2	A15	V5	1	*	method	The WeakProxy class	UNKNOWN	      	>>>	  "MAIN"
T2	A15	V5	1	*	method	The WeakProxy class	UNKNOWN	      	>=>	  MSG <= "MAIN"
T2	A15	V5	1	*	method	The WeakProxy class	UNKNOWN	      	>>>	  "an Array"
T2	A15	V5	1	*	method	The WeakProxy class	UNKNOWN	      	>=>	  ARGS <= "an Array"
T2	A15	V5	1	*	method	The WeakProxy class	UNKNOWN	39	*-*	forward to (self~value) message (msg) arguments (args)
T2	A15	V5	1	*	method	The WeakProxy class	UNKNOWN	      	>V>	  SELF => "a WeakProxy"
T2	A15	V5	1	*	method	The WeakProxy class	UNKNOWN	      	>M>	  "VALUE" => "a MYCOACTIVITY"
T2	A15	V5	1	*	method	The WeakProxy class	UNKNOWN	      	>V>	  MSG => "MAIN"
T2	A15	V5	1	*	method	The WeakProxy class	UNKNOWN	      	>V>	  ARGS => "an Array"
T2	A16	V6	.	 	method	The MYCOACTIVITY class	MAIN	      	>I>	Method MAIN with scope "The MYCOACTIVITY class" in package D:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\deadlock4.rex
T2	A16	V6	1	*	method	The MYCOACTIVITY class	MAIN	8	*-*	do forever
T2	A16	V6	1	*	method	The MYCOACTIVITY class	MAIN	9	*-*	  self~yield
T2	A16	V6	1	*	method	The MYCOACTIVITY class	MAIN	      	>V>	    SELF => "a MYCOACTIVITY"
T2	A17	V2	1	 	method	The Coactivity class	YIELD	      	>I>	Method YIELD with scope "The Coactivity class" in package d:\local\Rexx\ooRexx\svn\sandbox\jlf\samples\concurrency\coactivity.cls
*/
